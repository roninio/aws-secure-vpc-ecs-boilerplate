from fastapi import FastAPI, HTTPException, UploadFile, File, Header
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import boto3
import os
import uuid
from datetime import datetime, timedelta
import logging
import jwt
import requests
from functools import lru_cache

logging.basicConfig(level=logging.INFO)

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

dynamodb = boto3.resource(
    "dynamodb", region_name=os.environ.get("AWS_REGION", "us-east-1")
)
s3_client = boto3.client("s3", region_name=os.environ.get("AWS_REGION", "us-east-1"))

table = dynamodb.Table(os.environ.get("TABLE_NAME", "my-secure-app-table"))
s3_bucket = os.environ.get("S3_BUCKET_NAME")
max_file_size_mb = int(os.environ.get("MAX_FILE_SIZE_MB", "40"))
max_file_size_bytes = max_file_size_mb * 1024 * 1024


class TextInput(BaseModel):
    text: str


class FileMetadata(BaseModel):
    file_id: str
    filename: str
    size: int
    uploaded_at: str
    download_url: str


@lru_cache(maxsize=128)
def get_alb_public_key(kid: str, region: str) -> str:
    """Fetch ALB public key for JWT verification"""
    url = f"https://public-keys.auth.elb.{region}.amazonaws.com/{kid}"
    try:
        response = requests.get(url, timeout=5)
        response.raise_for_status()
        return response.text
    except Exception as e:
        logging.error(f"Failed to fetch ALB public key: {str(e)}")
        raise HTTPException(status_code=500, detail="Authentication service unavailable")


def verify_alb_jwt(x_amzn_oidc_data: str = Header(None)) -> dict:
    """Verify ALB JWT token and return payload"""
    if not x_amzn_oidc_data:
        raise HTTPException(status_code=401, detail="Not authenticated")
    
    try:
        # Decode header to get key ID
        header = jwt.get_unverified_header(x_amzn_oidc_data)
        kid = header.get('kid')
        if not kid:
            raise HTTPException(status_code=401, detail="Invalid token")
        
        # Get public key and verify signature
        region = os.environ.get("AWS_REGION", "us-east-1")
        public_key = get_alb_public_key(kid, region)
        
        # Verify and decode token
        payload = jwt.decode(
            x_amzn_oidc_data,
            public_key,
            algorithms=['ES256'],
            options={"verify_exp": True}
        )
        
        logging.info(f"JWT verified for user: {payload.get('sub')}")
        return payload
        
    except jwt.ExpiredSignatureError:
        logging.warning("Expired JWT token")
        raise HTTPException(status_code=401, detail="Token expired")
    except jwt.InvalidTokenError as e:
        logging.warning(f"Invalid JWT token: {str(e)}")
        raise HTTPException(status_code=401, detail="Invalid token")
    except Exception as e:
        logging.error(f"JWT verification error: {str(e)}")
        raise HTTPException(status_code=401, detail="Authentication failed")


def get_user_id_from_headers(x_amzn_oidc_data: str = Header(None)) -> str:
    """Extract and verify user ID from ALB OIDC JWT"""
    payload = verify_alb_jwt(x_amzn_oidc_data)
    return payload.get('sub')  # 'sub' contains the user ID


@app.get("/health")
def health():
    return {"status": "healthy"}


@app.post("/save")
def save_text(input: TextInput):
    try:
        item_id = str(uuid.uuid4())
        table.put_item(
            Item={
                "id": item_id,
                "text": input.text,
                "timestamp": datetime.utcnow().isoformat(),
            }
        )
        return {"id": item_id, "message": "Text saved successfully"}
    except Exception as e:
        logging.error(f"Error saving text: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/items")
def get_items():
    try:
        response = table.scan()
        return {"items": response.get("Items", [])}
    except Exception as e:
        logging.error(f"Error getting items: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


# File upload endpoint
@app.post("/upload")
async def upload_file(
    file: UploadFile = File(...), x_amzn_oidc_data: str = Header(None)
):
    """Upload a file to S3. Only authenticated users can upload."""
    try:
        # Validate authentication
        user_id = get_user_id_from_headers(x_amzn_oidc_data)

        # Read file content
        contents = await file.read()

        # Validate file size
        file_size = len(contents)
        if file_size > max_file_size_bytes:
            raise HTTPException(
                status_code=413, detail=f"File size exceeds {max_file_size_mb}MB limit"
            )

        # Generate unique file ID
        file_id = str(uuid.uuid4())

        # Store file in S3 with user scoping: users/{user_id}/{file_id}
        s3_key = f"users/{user_id}/{file_id}/{file.filename}"

        # Upload to S3
        s3_client.put_object(
            Bucket=s3_bucket,
            Key=s3_key,
            Body=contents,
            ContentType=file.content_type or "application/octet-stream",
        )

        # Store file metadata in DynamoDB
        timestamp = datetime.utcnow().isoformat()
        table.put_item(
            Item={
                "id": file_id,
                "type": "file",
                "user_id": user_id,
                "filename": file.filename,
                "size": file_size,
                "s3_key": s3_key,
                "timestamp": timestamp,
                "content_type": file.content_type or "application/octet-stream",
            }
        )

        logging.info(f"File uploaded: {file_id} by user {user_id}")

        return {
            "file_id": file_id,
            "filename": file.filename,
            "size": file_size,
            "uploaded_at": timestamp,
            "message": "File uploaded successfully",
        }

    except HTTPException:
        raise
    except Exception as e:
        logging.error(f"Error uploading file: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Upload failed: {str(e)}")


# File download endpoint (generates presigned URL)
@app.get("/download/{file_id}")
def download_file(file_id: str, x_amzn_oidc_data: str = Header(None)):
    """Get a presigned download URL for a file. User must own the file."""
    try:
        # Validate authentication
        user_id = get_user_id_from_headers(x_amzn_oidc_data)

        # Get file metadata from DynamoDB
        response = table.get_item(Key={"id": file_id})

        if "Item" not in response:
            raise HTTPException(status_code=404, detail="File not found")

        file_metadata = response["Item"]

        # Verify user owns this file
        if file_metadata.get("user_id") != user_id:
            raise HTTPException(status_code=403, detail="Access denied")

        # Generate presigned URL (valid for 1 hour)
        s3_key = file_metadata["s3_key"]
        presigned_url = s3_client.generate_presigned_url(
            "get_object",
            Params={"Bucket": s3_bucket, "Key": s3_key},
            ExpiresIn=3600,  # 1 hour
        )

        logging.info(f"Download URL generated for file {file_id}")

        return {
            "file_id": file_id,
            "filename": file_metadata["filename"],
            "download_url": presigned_url,
            "expires_in_seconds": 3600,
        }

    except HTTPException:
        raise
    except Exception as e:
        logging.error(f"Error generating download URL: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


# List user files
@app.get("/files")
def list_user_files(x_amzn_oidc_data: str = Header(None)):
    """List all files uploaded by the authenticated user."""
    try:
        # Validate authentication
        user_id = get_user_id_from_headers(x_amzn_oidc_data)

        # Query DynamoDB for user's files
        response = table.scan(
            FilterExpression="#uid = :user_id AND #type = :file_type",
            ExpressionAttributeNames={"#uid": "user_id", "#type": "type"},
            ExpressionAttributeValues={":user_id": user_id, ":file_type": "file"},
        )

        files = []
        for item in response.get("Items", []):
            files.append(
                {
                    "file_id": item["id"],
                    "filename": item["filename"],
                    "size": item["size"],
                    "uploaded_at": item["timestamp"],
                }
            )

        logging.info(f"Found {len(files)} files for user {user_id}")
        return {"files": files}

    except HTTPException:
        raise
    except Exception as e:
        logging.error(f"Error listing files: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


# Delete file
@app.delete("/files/{file_id}")
def delete_file(file_id: str, x_amzn_oidc_data: str = Header(None)):
    """Delete a file. User must own the file."""
    try:
        # Validate authentication
        user_id = get_user_id_from_headers(x_amzn_oidc_data)

        # Get file metadata from DynamoDB
        response = table.get_item(Key={"id": file_id})

        if "Item" not in response:
            raise HTTPException(status_code=404, detail="File not found")

        file_metadata = response["Item"]

        # Verify user owns this file
        if file_metadata.get("user_id") != user_id:
            raise HTTPException(status_code=403, detail="Access denied")

        # Delete from S3
        s3_key = file_metadata["s3_key"]
        s3_client.delete_object(Bucket=s3_bucket, Key=s3_key)

        # Delete metadata from DynamoDB
        table.delete_item(Key={"id": file_id})

        logging.info(f"File deleted: {file_id} by user {user_id}")

        return {"message": "File deleted successfully"}

    except HTTPException:
        raise
    except Exception as e:
        logging.error(f"Error deleting file: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))
