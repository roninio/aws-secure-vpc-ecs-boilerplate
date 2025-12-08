from fastapi import FastAPI, HTTPException, UploadFile, File, Header
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import boto3
import os
import uuid
from datetime import datetime, timedelta
import logging

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


def get_user_id_from_headers(x_amzn_oidc_identity: str = Header(None)) -> str:
    """Extract user ID from ALB OIDC headers"""
    if not x_amzn_oidc_identity:
        raise HTTPException(status_code=401, detail="Not authenticated")
    return x_amzn_oidc_identity


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
    file: UploadFile = File(...), x_amzn_oidc_identity: str = Header(None)
):
    """Upload a file to S3. Only authenticated users can upload."""
    try:
        # Validate authentication
        user_id = get_user_id_from_headers(x_amzn_oidc_identity)

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
def download_file(file_id: str, x_amzn_oidc_identity: str = Header(None)):
    """Get a presigned download URL for a file. User must own the file."""
    try:
        # Validate authentication
        user_id = get_user_id_from_headers(x_amzn_oidc_identity)

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
def list_user_files(x_amzn_oidc_identity: str = Header(None)):
    """List all files uploaded by the authenticated user."""
    try:
        # Debug logging
        logging.info(f"Files endpoint called with header: {x_amzn_oidc_identity}")

        # Validate authentication
        user_id = get_user_id_from_headers(x_amzn_oidc_identity)

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
def delete_file(file_id: str, x_amzn_oidc_identity: str = Header(None)):
    """Delete a file. User must own the file."""
    try:
        # Validate authentication
        user_id = get_user_id_from_headers(x_amzn_oidc_identity)

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
