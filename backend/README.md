# Backend (FastAPI)

FastAPI backend for blockchain-based peer-to-peer chat using MetaMask authentication.

## Features
- MetaMask wallet authentication (SIWE-like message + personal_sign)
- User profiles
- Direct messages
- Real-time chat via WebSocket
- MongoDB Atlas

## Setup
1. Create and fill `.env` from example:
```
cp .env.example .env
```

2. Install dependencies:
```
pip install -r requirements.txt
```

3. Run the server:
```
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## API
- POST `/auth/request`
- POST `/auth/verify`
- GET `/users/me`
- PUT `/users/me`
- GET `/users/search?q=...`
- POST `/messages`
- GET `/messages/{user_id}`
- WS `/ws/{user_id}`

## Env
See `.env.example`.