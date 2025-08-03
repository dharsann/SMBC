from fastapi import FastAPI, HTTPException, Depends, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from bson import ObjectId
from datetime import datetime
import json
from .auth import Web3Auth
from .database import connect_to_mongo, close_mongo_connection, get_database
from .models import *
from .auth import web3_auth, get_current_user
from .websocket import manager

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    await connect_to_mongo()
    yield
    # Shutdown
    await close_mongo_connection()

app = FastAPI(title="Blockchain Chat API", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.post("/auth/request", response_model=dict)
async def auth_request(request: AuthRequest, db = Depends(get_database)):
    wallet_address = request.wallet_address.lower()
    
    # Get or create user
    user_doc = await db.users.find_one({"wallet_address": wallet_address})
    
    if not user_doc:
        # Create new user
        user_data = {
            "wallet_address": wallet_address,
            "is_active": True,
            "created_at": datetime.utcnow(),
            "nonce": web3_auth.generate_nonce()
        }
        result = await db.users.insert_one(user_data)
        user_doc = await db.users.find_one({"_id": result.inserted_id})
    else:
        # Update nonce
        nonce = web3_auth.generate_nonce()
        await db.users.update_one(
            {"_id": user_doc["_id"]},
            {"$set": {"nonce": nonce}}
        )
        user_doc["nonce"] = nonce
    
    message = web3_auth.create_sign_message(wallet_address, user_doc["nonce"])
    
    return {
        "message": message,
        "nonce": user_doc["nonce"]
    }

@app.post("/auth/verify", response_model=AuthResponse)
async def auth_verify(request: AuthVerify, db = Depends(get_database)):
    wallet_address = request.wallet_address.lower()
    
    # Get user
    user_doc = await db.users.find_one({"wallet_address": wallet_address})
    if not user_doc:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Verify signature
    if not web3_auth.verify_signature(request.message, request.signature, wallet_address):
        raise HTTPException(status_code=400, detail="Invalid signature")
    
    # Create token
    token = web3_auth.create_access_token(wallet_address, str(user_doc["_id"]))
    
    # Clear nonce
    await db.users.update_one(
        {"_id": user_doc["_id"]},
        {"$unset": {"nonce": ""}}
    )
    
    user_response = UserResponse(
        id=str(user_doc["_id"]),
        wallet_address=user_doc["wallet_address"],
        username=user_doc.get("username"),
        display_name=user_doc.get("display_name"),
        avatar_url=user_doc.get("avatar_url"),
        created_at=user_doc["created_at"]
    )
    
    return AuthResponse(
        access_token=token,
        user=user_response
    )

@app.get("/users/me", response_model=UserResponse)
async def get_me(current_user: User = Depends(get_current_user)):
    return UserResponse(
        id=str(current_user.id),
        wallet_address=current_user.wallet_address,
        username=current_user.username,
        display_name=current_user.display_name,
        avatar_url=current_user.avatar_url,
        created_at=current_user.created_at
    )

@app.put("/users/me", response_model=UserResponse)
async def update_me(
    user_update: dict,
    current_user: User = Depends(get_current_user),
    db = Depends(get_database)
):
    # Check username uniqueness
    if "username" in user_update and user_update["username"]:
        existing = await db.users.find_one({
            "username": user_update["username"],
            "_id": {"$ne": current_user.id}
        })
        if existing:
            raise HTTPException(status_code=400, detail="Username already taken")
    
    # Update user
    await db.users.update_one(
        {"_id": current_user.id},
        {"$set": user_update}
    )
    
    # Get updated user
    user_doc = await db.users.find_one({"_id": current_user.id})
    return UserResponse(
        id=str(user_doc["_id"]),
        wallet_address=user_doc["wallet_address"],
        username=user_doc.get("username"),
        display_name=user_doc.get("display_name"),
        avatar_url=user_doc.get("avatar_url"),
        created_at=user_doc["created_at"]
    )

@app.get("/users/search")
async def search_users(
    q: str,
    current_user: User = Depends(get_current_user),
    db = Depends(get_database)
):
    cursor = db.users.find({
        "$or": [
            {"username": {"$regex": q, "$options": "i"}},
            {"display_name": {"$regex": q, "$options": "i"}},
            {"wallet_address": {"$regex": q, "$options": "i"}}
        ],
        "_id": {"$ne": current_user.id},
        "is_active": True
    }).limit(20)
    
    users = []
    async for user_doc in cursor:
        users.append(UserResponse(
            id=str(user_doc["_id"]),
            wallet_address=user_doc["wallet_address"],
            username=user_doc.get("username"),
            display_name=user_doc.get("display_name"),
            avatar_url=user_doc.get("avatar_url"),
            created_at=user_doc["created_at"]
        ))
    
    return users

@app.post("/messages", response_model=MessageResponse)
async def send_message(
    message_data: MessageCreate,
    current_user: User = Depends(get_current_user),
    db = Depends(get_database)
):
    # Check if recipient_id is a wallet address or MongoDB ObjectId
    recipient = None
    
    if message_data.recipient_id.startswith("0x"):
        # It's a wallet address
        recipient = await db.users.find_one({"wallet_address": message_data.recipient_id.lower()})
        if not recipient:
            raise HTTPException(status_code=404, detail="Recipient wallet address not found")
        recipient_object_id = recipient["_id"]
    else:
        # It's a user ID (ObjectId string)
        try:
            recipient_object_id = ObjectId(message_data.recipient_id)
            recipient = await db.users.find_one({"_id": recipient_object_id})
            if not recipient:
                raise HTTPException(status_code=404, detail="Recipient user ID not found")
        except:
            raise HTTPException(status_code=400, detail="Invalid recipient_id format")
    
    # Create message using ObjectIds
    message_doc = {
        "sender_id": ObjectId(current_user.id),  # Convert string ID back to ObjectId
        "recipient_id": recipient_object_id,
        "content": message_data.content,
        "created_at": datetime.utcnow()
    }
    
    result = await db.messages.insert_one(message_doc)
    
    # Get message with sender info
    message_with_sender = await db.messages.aggregate([
        {"$match": {"_id": result.inserted_id}},
        {
            "$lookup": {
                "from": "users",
                "localField": "sender_id",
                "foreignField": "_id",
                "as": "sender"
            }
        },
        {"$unwind": "$sender"}
    ]).to_list(1)
    
    msg = message_with_sender[0]
    
    # Send real-time notification (use wallet address for WebSocket user_id if needed)
    await manager.send_personal_message({
        "type": "new_message",
        "message": {
            "id": str(msg["_id"]),
            "sender": {
                "id": str(msg["sender"]["_id"]),
                "wallet_address": msg["sender"]["wallet_address"],
                "username": msg["sender"].get("username"),
                "display_name": msg["sender"].get("display_name")
            },
            "content": msg["content"],
            "created_at": msg["created_at"].isoformat()
        }
    }, str(recipient_object_id))  # or use recipient["wallet_address"] if WebSocket uses wallet addresses
    
    return MessageResponse(
        id=str(msg["_id"]),
        sender={
            "id": str(msg["sender"]["_id"]),
            "wallet_address": msg["sender"]["wallet_address"],
            "username": msg["sender"].get("username"),
            "display_name": msg["sender"].get("display_name")
        },
        recipient_id=str(msg["recipient_id"]),
        content=msg["content"],
        created_at=msg["created_at"]
    )

@app.get("/messages/{user_id}", response_model=List[MessageResponse])
async def get_messages(
    user_id: str,
    skip: int = 0,
    limit: int = 50,
    current_user: User = Depends(get_current_user),
    db = Depends(get_database)
):
    current_user_id = ObjectId(current_user.id)
    other_user_id = ObjectId(user_id)

    cursor = db.messages.aggregate([
        {
            "$match": {
                "$or": [
                    {
                        "sender_id": current_user_id,
                        "recipient_id": other_user_id
                    },
                    {
                        "sender_id": other_user_id,
                        "recipient_id": current_user_id
                    }
                ]
            }
        },
        {"$sort": {"created_at": -1}},
        {"$skip": skip},
        {"$limit": limit},
        {
            "$lookup": {
                "from": "users",
                "localField": "sender_id",
                "foreignField": "_id",
                "as": "sender"
            }
        },
        {"$unwind": "$sender"}
    ])
    
    messages = []
    async for msg in cursor:
        messages.append(MessageResponse(
            id=str(msg["_id"]),
            sender={
                "id": str(msg["sender"]["_id"]),
                "wallet_address": msg["sender"]["wallet_address"],
                "username": msg["sender"].get("username"),
                "display_name": msg["sender"].get("display_name")
            },
            recipient_id=str(msg["recipient_id"]),
            content=msg["content"],
            created_at=msg["created_at"]
        ))
    
    return messages

@app.websocket("/ws/{user_id}")
async def websocket_endpoint(websocket: WebSocket, user_id: str):
    await manager.connect(websocket, user_id)
    try:
        while True:
            data = await websocket.receive_text()
            # Handle ping/pong or other real-time features
            await websocket.send_text(f"Echo: {data}")
    except WebSocketDisconnect:
        manager.disconnect(user_id)


@app.get("/")
async def root():
    return {"message": "Blockchain Chat API is running!"}

@app.get("/health")
async def health_check():
    return {"status": "healthy", "timestamp": datetime.utcnow()}

@app.post("/auth/test-login")
async def test_login(request: AuthRequest, db = Depends(get_database)):
    wallet_address = request.wallet_address.lower()
    
    # Get or create user
    user_doc = await db.users.find_one({"wallet_address": wallet_address})
    
    if not user_doc:
        # Create new user
        user_data = {
            "wallet_address": wallet_address,
            "is_active": True,
            "created_at": datetime.utcnow()
        }
        result = await db.users.insert_one(user_data)
        user_doc = await db.users.find_one({"_id": result.inserted_id})
    
    # Create token
    token = web3_auth.create_access_token(wallet_address, str(user_doc["_id"]))
    
    user_response = UserResponse(
        id=str(user_doc["_id"]),
        wallet_address=user_doc["wallet_address"],
        username=user_doc.get("username"),
        display_name=user_doc.get("display_name"),
        avatar_url=user_doc.get("avatar_url"),
        created_at=user_doc["created_at"]
    )
    return {
        "access_token": token,
        "token_type": "bearer",
        "user": user_response
    }


@app.get("/protected")
def protected(user=Depends(Web3Auth.verify_token)):
    return {"message": "Authorized ✅", "user": user}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)