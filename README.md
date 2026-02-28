# Sąsiedzi & Seniorzy (Neighbors & Seniors)

A community platform connecting neighbors with seniors in Poland, providing paramedical support, local services, tool sharing, and volunteer coordination.

## Architecture

| Component | Technology | Port |
|-----------|-----------|------|
| **Backend** | Dart + Shelf REST API + SQLite | 8080 |
| **Mobile App** | Flutter (iOS/Android) | - |
| **Admin Panel** | Flutter Web | 3000 |
| **Shared Models** | Dart package | - |

## Quick Start

### Prerequisites
- Flutter SDK 3.27+ / Dart 3.6+

### 1. Start the Backend
```bash
cd backend
dart pub get
dart run bin/server.dart
```
The API runs on http://localhost:8080 with demo accounts seeded automatically.

### 2. Run the Admin Panel (Web)
```bash
cd admin
flutter pub get
flutter run -d chrome --web-port 3000
```

### 3. Run the Mobile App
```bash
cd mobile
flutter pub get
flutter run
```

## Demo Accounts

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@sasiedzi.pl | admin1234 |
| Family | rodzina@test.pl | test1234 |
| Worker | wykonawca@test.pl | test1234 |
| Senior | senior@test.pl | test1234 |

## API Endpoints

### Public
- `POST /api/auth/register` – Register new user
- `POST /api/auth/login` – Login
- `GET /health` – Health check

### Protected (Bearer token)
- `GET /api/users/me` – Get current user
- `PUT /api/users/me` – Update profile
- `GET /api/orders` – List orders
- `POST /api/orders` – Create order
- `GET /api/orders/available` – List available orders (for workers)
- `PUT /api/orders/:id/accept` – Accept order
- `PUT /api/orders/:id/complete` – Complete order
- `PUT /api/orders/:id/cancel` – Cancel order
- `POST /api/reviews` – Create review
- `GET /api/reviews/user/:id` – Get reviews for user

### Admin (Bearer token + admin role)
- `GET /api/admin/stats` – Platform statistics
- `GET /api/admin/users` – All users
- `GET /api/admin/orders` – All orders
- `GET /api/admin/verifications` – Pending worker verifications
- `PUT /api/admin/users/:id/verify` – Verify worker
- `PUT /api/admin/users/:id/reject` – Reject worker

## Project Structure
```
├── shared/          # Shared Dart models & constants
├── backend/         # Dart REST API server
├── mobile/          # Flutter mobile app (iOS/Android)
├── admin/           # Flutter web admin panel
└── README.md
```

## Features
- Multi-role system (Senior, Family, Worker, Admin)
- Order management for paramedical, local services, tool sharing
- Worker verification (ID + selfie + phone)
- Ratings and reviews
- Platform commission system
- Admin dashboard with statistics and reports
- Polish language interface
