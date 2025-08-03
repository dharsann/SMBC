from motor.motor_asyncio import AsyncIOMotorClient
from pymongo.server_api import ServerApi
from typing import Optional
import os
from dotenv import load_dotenv

load_dotenv()

MONGODB_URL = os.getenv("MONGODB_URL")

class Database:
    def __init__(self):
        self.client: Optional[AsyncIOMotorClient] = None # type: ignore
        self.database = None

db = Database()

async def connect_to_mongo():
    db.client = AsyncIOMotorClient(MONGODB_URL, server_api=ServerApi('1'))
    db.database = db.client.blockchain_chat
    
    # Test connection
    try:
        await db.client.admin.command('ping')
        print("Connected to MongoDB Atlas!")
    except Exception as e:
        print(f"Error connecting to MongoDB: {e}")
    
    # Create indexes
    await db.database.users.create_index("wallet_address", unique=True)
    await db.database.users.create_index("username", unique=True, sparse=True)
    await db.database.messages.create_index([("sender_id", 1), ("created_at", -1)])

async def close_mongo_connection():
    if db.client:
        db.client.close()

def get_database():
    return db.database