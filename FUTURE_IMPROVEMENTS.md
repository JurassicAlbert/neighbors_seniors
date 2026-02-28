# Future Improvements — Sąsiedzi & Seniorzy v2.0

This document outlines what is implemented in v2.0, what can be improved, and what should be prioritized next. Use this as a continuation roadmap.

---

## What's Implemented (v2.0 MVP)

### Backend
- [x] Equipment CRUD + reservation lifecycle (available → reserved → inUse → returned → review)
- [x] Friends/trust contacts with friend requests
- [x] Badge & points system (5 seed badges, auto-level calculation)
- [x] Access codes for secure entry (6-digit codes with expiry)
- [x] Check-in/check-out event logging
- [x] Escrow-style payment model (block → release/refund)
- [x] Dispute creation and admin resolution
- [x] Service directory with search (by type, keyword, location)
- [x] v2 API endpoints under /api/v2/*
- [x] All v1 endpoints preserved for backward compatibility
- [x] Multi-capability user model (requester, provider, volunteer, etc.)
- [x] Enhanced stats with equipment, reservations, disputes, friendships counts

### Mobile App
- [x] Equipment browsing with category filters + detail/reservation screens
- [x] Friends management (list, requests, add, remove)
- [x] Badge/points display with level progress bar
- [x] Service directory search with type filter
- [x] Notification center screen
- [x] Capability toggle in profile
- [x] i18n system (Polish primary, English fallback)

### Admin Panel
- [x] Equipment management table
- [x] Dispute resolution with notes dialog
- [x] Enhanced dashboard with v2 stat cards
- [x] Smart Village / Paramedical metrics in reports
- [x] Service offers oversight

---

## Priority Improvements for Next Sprint

### 1. Real Payment Integration (HIGH PRIORITY)
**Current state:** Payment model is database-only (mock escrow).
**Improvement:**
- Integrate Stripe Connect or PayU/Przelewy24 SDK
- Implement actual payment intent creation, capture, and transfer
- Add webhook handlers for payment status updates
- Add Stripe onboarding flow for service providers
- **Files to modify:** `payment_service.dart`, new `stripe_service.dart`, add `stripe` Dart package

### 2. Push Notifications (HIGH PRIORITY)
**Current state:** Notifications are stored in DB but not pushed to devices.
**Improvement:**
- Add Firebase Cloud Messaging (FCM) integration
- Store device tokens on registration/login
- Trigger push on: order status change, friend request, access code delivery, overdue return
- Add `firebase_messaging` and `flutter_local_notifications` to mobile
- **Files to modify:** `mobile/pubspec.yaml`, new `notification_service.dart`, `server.dart`

### 3. Photo Upload for Equipment (MEDIUM PRIORITY)
**Current state:** `photoUrls` field exists but no upload mechanism.
**Improvement:**
- Add multipart file upload endpoint (`POST /api/v2/upload`)
- Store files locally or integrate S3/Cloudflare R2
- Add image picker in equipment creation screen
- Show photo carousel in equipment detail
- **Files to modify:** new `upload_routes.dart`, `equipment_detail_screen.dart`

### 4. Real-time Chat / Messaging (MEDIUM PRIORITY)
**Current state:** No in-app messaging between users.
**Improvement:**
- Add WebSocket support via `shelf_web_socket`
- Create chat rooms per order/reservation
- Store message history in SQLite
- Add chat UI in mobile app (bubble messages, typing indicator)
- **Consider:** Firebase Realtime Database or Supabase as alternatives

### 5. Geolocation & Map Integration (MEDIUM PRIORITY)
**Current state:** Lat/lng fields stored but not displayed on maps.
**Improvement:**
- Add `google_maps_flutter` or `flutter_map` (OpenStreetMap, no API key needed)
- Show equipment locations on map in browse view
- Show provider service areas as circles on map
- Real-time location tracking during service fulfillment
- **Files to modify:** `equipment_screen.dart`, `directory_screen.dart`, `order_detail_screen.dart`

### 6. Calendar / Availability System (MEDIUM PRIORITY)
**Current state:** `availabilitySchedule` is stored as free-text.
**Improvement:**
- Define structured availability schema (weekly recurring slots)
- Add calendar picker widget for providers to set availability
- Show availability on directory/equipment listings
- Conflict detection for overlapping reservations
- Use `table_calendar` Flutter package

### 7. SMS Notifications (LOW PRIORITY)
**Current state:** Not implemented.
**Improvement:**
- Integrate Twilio or SMS API.pl for Polish SMS
- Send SMS for: access code delivery, order confirmation, overdue returns
- Particularly important for seniors who may not use the app actively
- **Files to modify:** new `sms_service.dart`, `server.dart`

### 8. Advanced Review Moderation (LOW PRIORITY)
**Current state:** Reviews stored with category ratings, no moderation workflow.
**Improvement:**
- Add review flagging/reporting by users
- Admin moderation queue (approve, edit, remove reviews)
- Sentiment analysis (optional, via external API)
- Show aggregated category scores as radar chart on profiles

### 9. Export & Reporting (LOW PRIORITY)
**Current state:** Stats displayed in admin panel only.
**Improvement:**
- Add CSV/PDF export for grant reporting
- Automated monthly report generation
- Email delivery of reports to administrators
- Filter reports by date range, region, service type

### 10. Database Migration to PostgreSQL (LOW PRIORITY)
**Current state:** SQLite (single-file, suitable for MVP/dev).
**Improvement:**
- Migrate to PostgreSQL for production scalability
- Add connection pooling
- Use `postgres` Dart package
- Add database migration system (versioned SQL files)
- **Note:** Schema is already PostgreSQL-compatible (no SQLite-specific features used)

---

## Architecture Notes for Future Work

### API Versioning
- v1 routes (`/api/auth/`, `/api/orders/`, etc.) remain for backward compatibility
- v2 routes (`/api/v2/equipment/`, etc.) are the new standard
- When v1 clients are deprecated, consolidate under `/api/v2/`

### Code Organization
- Each module (equipment, social, payments, directory) has its own service + route file
- Shared models are in a separate Dart package (`shared/`) used by all 3 apps
- This pattern should continue for new modules

### Security Hardening
- Add rate limiting middleware
- Add request validation middleware (schema validation)
- Implement refresh token rotation (current: single long-lived JWT)
- Add CSRF protection for web admin
- Encrypt access codes at rest

### Testing Expansion
- Add v2 API integration tests (equipment, friends, payments, directory)
- Add unit tests for services (mock database)
- Add more Flutter widget tests per screen
- Add E2E tests with integration_test package

### Deployment
- Dockerize backend (`Dockerfile` + `docker-compose.yml`)
- Add CI/CD pipeline (GitHub Actions)
- Set up staging and production environments
- Add health check and metrics endpoints for monitoring
