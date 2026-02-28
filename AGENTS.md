# AGENTS.md

## Cursor Cloud specific instructions

### Project overview

Sąsiedzi & Seniorzy (Neighbors & Seniors) v2.0 is a multi-service marketplace platform connecting local seniors, families, and service providers in Poland. Monorepo with 4 Dart/Flutter sub-projects.

| Component | Path | Technology | Default Port |
|-----------|------|-----------|-------------|
| Shared models | `shared/` | Dart package | — |
| Backend API | `backend/` | Dart + Shelf + SQLite | 8080 |
| Mobile app | `mobile/` | Flutter (iOS/Android/Web/Desktop) | — |
| Admin panel | `admin/` | Flutter Web | 3000 |

### Prerequisites

- Flutter 3.27+ on PATH (installed at `/home/ubuntu/flutter`)
- `libsqlite3-dev` system package (required by the backend's `sqlite3` Dart package)

### Running services

**Backend** (must start first):
```bash
cd backend && dart run bin/server.dart
```
Seeds demo users, equipment, badges, and orders on fresh DB. Delete `backend/neighbors_seniors.db` to reset.

**Admin panel** (web):
```bash
cd admin && flutter build web && cd build/web && python3 -m http.server 3000
```

**Mobile app** (web for testing):
```bash
cd mobile && flutter run -d chrome --web-port 3001
```

### API versions
- v1: `/api/auth/`, `/api/users/`, `/api/orders/`, `/api/reviews/`, `/api/admin/` — original endpoints
- v2: `/api/v2/equipment/`, `/api/v2/social/`, `/api/v2/payments/`, `/api/v2/directory/` — new modules

### Key commands

| Task | Command |
|------|---------|
| Lint all | `cd shared && dart analyze && cd ../backend && dart analyze && cd ../mobile && flutter analyze && cd ../admin && flutter analyze` |
| Backend tests | `cd backend && dart test` (requires server running on :8080) |
| Mobile tests | `cd mobile && flutter test` |
| Admin tests | `cd admin && flutter test` |

### Gotchas

- Backend tests are HTTP-based — server must be running on port 8080 first.
- `shelf_router` mount paths use trailing slashes. Include trailing slashes for root collection endpoints.
- Mobile API URL auto-detects platform: Android emulator → `10.0.2.2`, physical device → configure via login screen settings button, desktop/web → `localhost`.
- SQLite DB file created in CWD when backend starts. Delete to reset all data.
- See `FUTURE_IMPROVEMENTS.md` for the v2.0 continuation roadmap.
