# AGENTS.md

## Cursor Cloud specific instructions

### Project overview

Sąsiedzi & Seniorzy (Neighbors & Seniors) is a multi-service platform connecting local seniors, their families, and service providers in Poland. It consists of 4 Dart/Flutter sub-projects in a monorepo layout.

| Component | Path | Technology | Default Port |
|-----------|------|-----------|-------------|
| Shared models | `shared/` | Dart package | — |
| Backend API | `backend/` | Dart + Shelf + SQLite | 8080 |
| Mobile app | `mobile/` | Flutter (iOS/Android/Web) | — |
| Admin panel | `admin/` | Flutter Web | 3000 |

### Prerequisites

- Flutter 3.27+ on PATH (installed at `/home/ubuntu/flutter`)
- `libsqlite3-dev` system package (required by the backend's `sqlite3` Dart package)

### Running services

**Backend** (must start first — other services depend on it):
```bash
cd backend && dart run bin/server.dart
```
Seeds 4 demo users + sample orders on every fresh DB. Deleting `backend/neighbors_seniors.db` resets all data.

**Admin panel** (web):
```bash
cd admin && flutter build web && cd build/web && python3 -m http.server 3000
```
Or for dev with hot reload: `cd admin && flutter run -d chrome --web-port 3000`

**Mobile app** (Linux desktop in cloud, or web):
```bash
cd mobile && flutter run -d chrome --web-port 3001
```

### Key commands reference

See `README.md` for the full command table. Quick reference:

| Task | Command |
|------|---------|
| Lint all | `cd shared && dart analyze && cd ../backend && dart analyze && cd ../mobile && flutter analyze && cd ../admin && flutter analyze` |
| Backend tests | `cd backend && dart test` (requires backend server running on :8080) |
| Mobile tests | `cd mobile && flutter test` |
| Admin tests | `cd admin && flutter test` |

### Gotchas

- Backend integration tests (`backend/test/api_test.dart`) are HTTP-based and require the server to be running on port 8080 before `dart test` is invoked.
- `shelf_router` mount paths use trailing slashes. API calls from tests/clients should include trailing slashes for root collection endpoints (e.g. `POST /api/orders/`, `GET /api/reviews/`).
- The mobile app defaults to `http://10.0.2.2:8080` as the API URL (Android emulator loopback). For web or Linux desktop, override `ApiService.baseUrl` to `http://localhost:8080`.
- The admin panel's `AdminApiService.baseUrl` defaults to `http://localhost:8080` which works for web.
- SQLite DB file (`neighbors_seniors.db`) is created in the current working directory when the backend starts. Delete it to reset.
