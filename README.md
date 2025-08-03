# Blockchain P2P Chat Backend

Simple FastAPI backend for blockchain-based peer-to-peer chat using MetaMask authentication.

## Features

- MetaMask wallet authentication
- User registration and profiles
- Direct messaging
- Real-time chat via WebSocket
- MongoDB Atlas database
- Simple and clean codebase

## Setup

1. Install dependencies:
```bash
pip install -r requirements.txt
```

2. Set up environment variables in `.env`:
```
MONGODB_URL=mongodb+srv://username:password@cluster.mongodb.net/blockchain_chat
SECRET_KEY=your-super-secret-key
```

3. Run the server:
```bash
uvicorn app.main:app --reload
```

## API Endpoints

### Authentication
- `POST /auth/request` - Request authentication message
- `POST /auth/verify` - Verify signature and get JWT token

### Users
- `GET /users/me` - Get current user profile
- `PUT /users/me` - Update current user profile
- `GET /users/search?q=query` - Search users

### Messages
- `POST /messages` - Send a message
- `GET /messages/{user_id}` - Get messages with a user

### WebSocket
- `WS /ws/{user_id}` - Real-time connection

## Usage

1. Frontend calls `/auth/request` with wallet address
2. User signs the returned message with MetaMask
3. Frontend sends signature to `/auth/verify`
4. Use returned JWT token for authenticated requests
5. Connect to WebSocket for real-time features

## Database Schema

### Users Collection
- `_id`: ObjectId
- `wallet_address`: string (unique)
- `username`: string (optional, unique)
- `display_name`: string (optional)
- `avatar_url`: string (optional)
- `created_at`: datetime

### Messages Collection
- `_id`: ObjectId
- `sender_id`: ObjectId (ref: users)
- `recipient_id`: ObjectId (ref: users)
- `content`: string
- `created_at`: datetime
