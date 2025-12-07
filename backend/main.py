from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import boto3
import os
import uuid
from datetime import datetime
import logging

logging.basicConfig(level=logging.INFO)

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

dynamodb = boto3.resource('dynamodb', region_name=os.environ.get('AWS_REGION', 'us-east-1'))
table = dynamodb.Table(os.environ.get('TABLE_NAME', 'my-secure-app-table'))

class TextInput(BaseModel):
    text: str

@app.get("/health")
def health():
    return {"status": "healthy"}

@app.post("/save")
def save_text(input: TextInput):
    try:
        item_id = str(uuid.uuid4())
        table.put_item(Item={
            'id': item_id,
            'text': input.text,
            'timestamp': datetime.utcnow().isoformat()
        })
        return {"id": item_id, "message": "Text saved successfully"}
    except Exception as e:
        logging.error(f"Error saving text: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/items")
def get_items():
    try:
        response = table.scan()
        return {"items": response.get('Items', [])}
    except Exception as e:
        logging.error(f"Error getting items: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))
