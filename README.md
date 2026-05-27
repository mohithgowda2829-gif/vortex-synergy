# Vortex Synergy

Vortex Synergy is a production-style food and medicine distribution platform aligned to SDG 2 and SDG 3. The codebase now includes the original V1 MVP, V2 operational extensions, and the V3 stability, validation, and UX polish pass.

## Recommended Structure

### Backend

```text
backend/
├── pom.xml
├── src/main/java/com/vortexsynergy/backend
│   ├── config
│   ├── controller
│   ├── dto
│   ├── exception
│   ├── model
│   ├── repository
│   ├── security
│   └── service
└── src/main/resources
    └── application.yml
```

### Flutter Mobile App

```text
mobile/
├── android/
├── ios/
├── lib
│   ├── api
│   ├── config
│   ├── models
│   ├── providers
│   ├── screens
│   └── widgets
└── pubspec.yaml
```

## V3 Highlights

- Modern Flutter design system updates with animated backgrounds, role hero dashboards, glass-style panels, animated cards, clearer badges, loading states, empty states, and safer success/error messaging
- Stronger backend and frontend validation for auth, resources, medicine compliance, delivery assignment, and workflow state changes
- Receiver-managed delivery workflow with stricter state integrity and donor-side pickup approval protections
- Notification center completion with unread counts, mark-all-read support, and improved role visibility
- Role-aware dashboard summaries for donors, receivers, doctors/pharmacists, and admins
- Audit timeline UI for claims and resources with clear operational event sequencing
- Search, filter, and sort improvements including text query, location filtering, nearest sorting, and priority sorting
- CSV operational reports rendered in-app as table previews for cleaner review
- Query and schema cleanup with added indexes, better dashboard counting, and stricter service boundaries
- Legacy volunteer cleanup, paged public resource browsing, secure password reset, and donor certificate detail/download flow

## Implemented Scope

- JWT authentication with role-based access control
- Placeholder email and phone verification flow
- Admin approval flow for doctor/pharmacist accounts
- Medicine donor approval flow plus doctor/pharmacist resource verification
- Food and medicine listing workflows with structured location fields and photos
- Photo upload support for food and medicine listings
- Resource browsing by type, city, area, nearest coordinates, query-layer sorting, and pagination
- Anti-hoarding policy: no fixed daily cap, no duplicate active reservation on the same listing, and a fairness-based priority penalty for frequent recent claims
- Claim reservation, confirmation, cancellation, expiry, and secure pickup-code handover
- Self-pickup by default, with receiver-managed delivery assignment for non-self pickup claims
- Donor-side pickup approval, delivery status tracking, optional coordinate updates, and failure handling
- In-app notifications center for claim, medicine, expiry, and delivery events
- Notification summary endpoint plus unread badge support
- Audit timeline APIs and timeline screens for claims and resources
- CSV report exports for donations, claims, expiry, medicine, and delivery operations
- V3 report center with table-style CSV preview and raw CSV toggle
- Scheduled expiry management for resources and reservations
- Impact dashboard plus donor certificate summary, detail view, and HTML download
- Admin moderation, verification queue, analytics, operational monitoring, and resource removal
- Audit logging for important actions
- Forgot/reset password with hashed one-time reset tokens and expiry

## Backend Setup

### Prerequisites

- Java 21
- Maven 3.9+
- PostgreSQL 14+

### Run PostgreSQL

Use the included Compose file:

```bash
cd vortex-synergy
docker compose up -d postgres
```

### Run Backend

```bash
cd vortex-synergy/backend
export JAVA_HOME=$(/usr/libexec/java_home -v 21)
mvn spring-boot:run
```

Backend defaults:

- Base URL: `http://localhost:8080/api`
- Database: `jdbc:postgresql://localhost:5432/vortex_synergy`
- Username: `postgres`
- Password: `postgres`

### Key Backend Endpoints

- `POST /api/auth/register`
- `POST /api/auth/login`
- `POST /api/auth/forgot-password`
- `POST /api/auth/reset-password`
- `GET /api/users/me`
- `POST /api/users/me/verify-placeholder`
- `POST /api/resources`
- `GET /api/resources`
- `GET /api/resources/{id}`
- `GET /api/resources/mine`
- `POST /api/uploads/resource-photo`
- `POST /api/claims/request`
- `POST /api/claims/confirm`
- `POST /api/claims/cancel`
- `POST /api/claims/pickup-details`
- `POST /api/claims/approve-pickup-details`
- `POST /api/claims/handover`
- `GET /api/claims/my`
- `GET /api/claims/donor`
- `POST /api/deliveries/assign`
- `GET /api/deliveries/{claimId}`
- `POST /api/deliveries/pickup-approve`
- `POST /api/deliveries/in-transit`
- `POST /api/deliveries/delivered`
- `POST /api/deliveries/fail`
- `GET /api/deliveries/receiver`
- `GET /api/deliveries/donor`
- `GET /api/notifications/my`
- `GET /api/notifications/summary`
- `PATCH /api/notifications/{id}/read`
- `PATCH /api/notifications/read-all`
- `GET /api/audit/resource/{resourceId}`
- `GET /api/audit/claim/{claimId}`
- `GET /api/reports/donations/csv`
- `GET /api/reports/claims/csv`
- `GET /api/reports/expiry/csv`
- `GET /api/reports/medicine/csv`
- `GET /api/reports/delivery/csv`
- `GET /api/medical/pending`
- `POST /api/medical/verify/{resourceId}`
- `POST /api/medical/reject/{resourceId}`
- `GET /api/dashboard/summary`
- `GET /api/dashboard/role-summary`
- `GET /api/dashboard/donor-certificate`
- `GET /api/dashboard/donor-certificate/detail`
- `GET /api/dashboard/donor-certificate/download`
- `GET /api/admin/verifications/pending`
- `POST /api/admin/verifications/{verificationId}/decision`
- `GET /api/admin/resources`
- `POST /api/admin/resources/{resourceId}/remove`
- `GET /api/admin/analytics`

## Flutter Setup

### Prerequisites

- Flutter 3.41+
- Dart SDK bundled with Flutter
- Android Studio plus Android SDK for Android builds
- Xcode plus iOS simulator runtime for simulator testing
- Apple Development Team/provisioning profile for physical iPhone deployment

### Run Mobile App

```bash
cd vortex-synergy/mobile
flutter pub get
flutter run
```

Quick options:

```bash
flutter run -d chrome
flutter run -d macos
```

The Flutter app targets the backend configured in:

- `mobile/lib/config/app_config.dart`

For phones, laptop web, or macOS desktop builds, do not hardcode the server URL in source code. Pass the deployed backend URL at build/run time:

```bash
flutter run -d DEVICE_ID --dart-define=API_ORIGIN=https://YOUR_API_DOMAIN
```

## Seed Data

The backend seeds demo users and starter records automatically when the `users` table is empty.

Seed password for every demo account:

- `Password123!`

Demo accounts:

- `admin@vortex.local`
- `donor@vortex.local`
- `receiver@vortex.local`
- `doctor@vortex.local`

## College Project Pack

Submission-ready project notes are available here:

- [docs/college-project/README.md](/Users/mohithgowda/Documents/New%20project/vortex-synergy/docs/college-project/README.md)
- [docs/college-project/PRESENTATION_OUTLINE.md](/Users/mohithgowda/Documents/New%20project/vortex-synergy/docs/college-project/PRESENTATION_OUTLINE.md)

## Deployment

Deployment instructions and production environment requirements are available here:

- [docs/DEPLOYMENT.md](/Users/mohithgowda/Documents/New%20project/vortex-synergy/docs/DEPLOYMENT.md)

The backend now includes:

- Dockerfile for Java 21 deployment
- Production Spring profile
- Render blueprint at `render.yaml`
- Render `DATABASE_URL` support for Postgres connection strings
- Health endpoint at `/actuator/health`
- Configurable CORS origins through `CORS_ALLOWED_ORIGIN_PATTERNS`
- Production env template at `deploy.env.example`

Build mobile releases against the deployed backend URL:

```bash
flutter build apk --dart-define=API_ORIGIN=https://YOUR_API_DOMAIN
```

Use the same backend URL for laptop/browser access:

```bash
flutter build web --dart-define=API_ORIGIN=https://YOUR_API_DOMAIN
```

The generated laptop/browser build is in `mobile/build/web`.

Use the same backend URL for macOS laptop app builds:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer flutter build macos --dart-define=API_ORIGIN=https://YOUR_API_DOMAIN
```

## Security Notes

- Passwords are hashed with BCrypt
- All protected endpoints use JWT bearer authentication
- Password reset tokens are stored as SHA-256 hashes, expire automatically, and are one-time use
- Admin and doctor/pharmacist endpoints are restricted by role
- Medicine listings remain hidden from public claims until approved
- Opened or expired medicines are rejected at creation time
- Receiver-managed delivery assignments require donor pickup approval before transit
- Pickup completion for self-pickup still requires a secure pickup code/token match
- Legacy volunteer accounts are migrated to receiver organizations on startup and the volunteer role is removed from V3 routing
- V3 enforces stricter delivery transitions, consistent notification counts, and safer validation/error responses

## Breaking Changes

- `GET /api/resources` now returns a paged object with `items`, `page`, `size`, `totalElements`, `totalPages`, `first`, and `last`
- Public resource browsing now requires `page` and `size` semantics; the old `limit` query is treated as a fallback only
- The `VOLUNTEER` role is no longer part of the active role model; legacy rows are migrated to `RECEIVER`
- Anti-hoarding behavior no longer uses daily caps; fairness is enforced through duplicate-reservation blocking and priority penalties
- Local password reset previews are controlled by `EXPOSE_PASSWORD_RESET_TOKEN` and should be disabled in production

## What Changed From V2 To V3

- Polished shared UI components and more consistent dashboards across every role
- Expanded frontend fallback states for loading, empty, retry, and validation feedback
- Tightened delivery integrity checks so incomplete coordinate updates and invalid transitions are rejected
- Improved search and resource discovery UX with better filtering and clearer compliance visibility
- Completed notification center behavior with unread count synchronization and mark-all-read support
- Refined role dashboard summaries so counts reflect each role's operational responsibility more accurately
- Improved admin usability for verification, moderation, reporting, and monitoring screens
- Updated report previews to render as tables inside the app instead of raw CSV only
- Removed the legacy volunteer role from runtime routing and migrated old volunteer rows to receiver accounts
- Froze the fair-access policy around duplicate-resource blocking and recent-claim priority penalties instead of daily caps
- Moved public resource browsing to database-backed filtering, sorting, and pagination
- Refactored CSV report generation to use targeted query projections instead of full entity loads
- Added secure forgot/reset password endpoints plus Flutter reset screens
- Added donor certificate detail APIs, a dedicated certificate screen, and downloadable HTML certificate output

## Local Verification Commands

```bash
cd vortex-synergy/backend
export JAVA_HOME=$(/usr/libexec/java_home -v 21)
mvn -q -DskipTests compile

cd ../mobile
flutter analyze
```

## Current Local Run State

- Spring Boot backend runs on `http://localhost:8080`
- Flutter mobile/web app can be launched from `mobile/`
- Demo receiver login:
  - email: `receiver@vortex.local`
  - password: `Password123!`
