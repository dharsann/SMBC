# Frontend (Flutter)

Flutter app for MetaMask-based login and chat.

## Setup
1. Install Flutter 3.3+.
2. Copy `.env.example` to `.env` and set your backend:
```
API_BASE_URL=http://localhost:8000
WS_BASE_URL=ws://localhost:8000
```
3. Install deps:
```
flutter pub get
```
4. Run on web (Chrome with MetaMask):
```
flutter run -d chrome
```

## Notes
- This build supports MetaMask on web. Mobile WalletConnect integration is scaffolded and can be added later.
- Login flow: Connect MetaMask -> Request message -> personal_sign -> verify -> store JWT.