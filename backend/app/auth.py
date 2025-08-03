from web3 import Web3
from eth_account.messages import encode_defunct
from datetime import datetime, timedelta
from jose import JWTError, jwt
from fastapi import HTTPException, status, Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
import secrets
import os
from .models import User
from .database import get_database
from bson import ObjectId, errors as bson_errors


bearer_scheme = HTTPBearer()

# Add default SECRET_KEY if not in environment (for development only!)
SECRET_KEY = "d7e027850d3fe494fed47c756c7b8440ac9c3f991f5079e0740fb2d45f6e1b2b"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 1440  # 24 hours

security = HTTPBearer()

class Web3Auth:
    def __init__(self):
        self.w3 = Web3()
   
    def generate_nonce(self) -> str:
        return secrets.token_hex(16)
   
    def create_sign_message(self, wallet_address: str, nonce: str) -> str:
        return f'''Welcome to Blockchain Chat!
       
        Sign this message to authenticate:

        Wallet: {wallet_address}

        Nonce: {nonce}

        This won't cost any gas.'''
   
    def verify_signature(self, message: str, signature: str, wallet_address: str) -> bool:
        try:
            encoded_message = encode_defunct(text=message)
            recovered_address = self.w3.eth.account.recover_message(
                encoded_message, signature=signature
            )
            return recovered_address.lower() == wallet_address.lower()
        except Exception as e:
            print(f"Signature verification error: {e}")
            return False
   
    def create_access_token(self, wallet_address: str, user_id: str) -> str:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        to_encode = {
            "sub": wallet_address,
            "user_id": user_id,
            "exp": expire
        }
        return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
   
    def verify_token(self, token: str):
        try:
            payload = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
            return payload
        except JWTError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token",
                headers={"WWW-Authenticate": "Bearer"},
            )

web3_auth = Web3Auth()

async def get_current_user(token = Depends(security), db = Depends(get_database)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials"
    )
   
    try:
        # Verify the token
        payload = web3_auth.verify_token(token.credentials)
        if payload is None:
            print("Token verification failed")
            raise credentials_exception
        
        print(f"Token payload: {payload}")  # Debug log
        
        # Get user from database
        user_doc = await db.users.find_one({"_id": ObjectId(payload["user_id"])})
        if user_doc is None:
            print(f"User not found for ID: {payload['user_id']}")
            raise credentials_exception
        
        print(f"Found user: {user_doc['wallet_address']}")  # Debug log
        
        # Convert MongoDB document to User model (simple string conversion)
        user_data = {
            'id': str(user_doc['_id']),
            'wallet_address': user_doc['wallet_address'],
            'username': user_doc.get('username'),
            'display_name': user_doc.get('display_name'),
            'avatar_url': user_doc.get('avatar_url'),
            'is_active': user_doc.get('is_active', True),
            'created_at': user_doc['created_at']
        }
        
        return User(**user_data)
        
    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except Exception as e:
        print(f"Unexpected error in get_current_user: {e}")
        raise credentials_exception
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials"
    )
   
    try:
        # Verify the token
        payload = web3_auth.verify_token(token.credentials)
        if payload is None:
            print("Token verification failed")
            raise credentials_exception
        
        print(f"Token payload: {payload}")  # Debug log
        
        # Get user from database
        user_doc = await db.users.find_one({"_id": ObjectId(payload["user_id"])})
        if user_doc is None:
            print(f"User not found for ID: {payload['user_id']}")
            raise credentials_exception
        
        print(f"Found user: {user_doc['wallet_address']}")  # Debug log
        
        # Convert MongoDB document to User model
        user_data = dict(user_doc)
        user_data['id'] = str(user_data.pop('_id'))  # Convert _id to id as string
        
        return User(**user_data)
        
    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except Exception as e:
        print(f"Unexpected error in get_current_user: {e}")
        raise credentials_exception