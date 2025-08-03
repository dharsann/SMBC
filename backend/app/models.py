from pydantic import BaseModel, Field, ConfigDict
from typing import Optional, List, Any
from datetime import datetime
from bson import ObjectId

class PyObjectId(ObjectId):
    @classmethod
    def __get_validators__(cls):
        yield cls.validate

    @classmethod
    def validate(cls, v):
        if not ObjectId.is_valid(v):
            raise ValueError("Invalid objectid")
        return ObjectId(v)

    @classmethod
    def __get_pydantic_json_schema__(cls, field_schema):
        field_schema.update(type="string")
    
class User(BaseModel):
    id: str  # Simple string ID
    wallet_address: str
    username: Optional[str] = None
    display_name: Optional[str] = None
    avatar_url: Optional[str] = None
    is_active: bool = True
    created_at: datetime

class UserResponse(BaseModel):
    id: str
    wallet_address: str
    username: Optional[str] = None
    display_name: Optional[str] = None
    avatar_url: Optional[str] = None
    created_at: datetime

class UserCreate(BaseModel):
    wallet_address: str
    username: Optional[str] = None
    display_name: Optional[str] = None
    avatar_url: Optional[str] = None

# Message Models
class Message(BaseModel):
    model_config = ConfigDict(
        populate_by_name=True,
        arbitrary_types_allowed=True,
        json_encoders={ObjectId: str}
    )
    
    id: Optional[PyObjectId] = Field(default_factory=PyObjectId, alias="_id")
    sender_id: PyObjectId
    recipient_id: Optional[PyObjectId] = None
    content: str
    created_at: datetime = Field(default_factory=datetime.utcnow)

class MessageCreate(BaseModel):
    recipient_id: str = Field(alias="recipient")  
    content: str
    model_config = {"populate_by_name": True}

class MessageResponse(BaseModel):
    id: str
    sender: dict
    recipient_id: str
    content: str
    created_at: datetime

# Auth Models
class AuthRequest(BaseModel):
    wallet_address: str

class AuthVerify(BaseModel):
    wallet_address: str
    signature: str
    message: str

class AuthResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse