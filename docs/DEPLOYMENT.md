# Deployment Guide

This project must be deployed with one public backend API that every client can use:

- Spring Boot backend API
- PostgreSQL database
- Flutter clients for Android, iOS, macOS, and web/laptop

The Flutter app then points to the public HTTPS backend URL with `--dart-define=API_ORIGIN=...`.

The backend URL may be passed with or without a trailing slash. The Flutter app normalizes it before calling `/api`.

## Recommended Hosting

For this project, the clean deployment split is:

- Backend API: Render
- PostgreSQL database: Render Postgres
- Laptop/browser frontend: Netlify
- Android/iPhone/macOS apps: Flutter builds that call the same Render API

This keeps one public backend for every client while using Netlify only for the static Flutter web build.

## Deployment Requirements

- Java 21 runtime
- PostgreSQL 14+
- Flutter SDK for client builds
- Android SDK/Android Studio for Android APK or App Bundle builds
- Xcode for iOS and macOS builds
- iOS simulator runtime from Xcode Settings > Components if you want simulator testing
- Apple signing team/provisioning profile if you want to install a release build on a physical iPhone
- Public HTTPS backend URL
- Public web frontend URL if you want browser/laptop access without installing the app
- Secure environment variables
- Persistent file storage if resource photos must survive restarts

## Backend Environment

Use the values from `deploy.env.example` as a checklist.

Required variables:

- `SPRING_PROFILES_ACTIVE=prod`
- `JWT_SECRET`
- `EXPOSE_PASSWORD_RESET_TOKEN=false`

Database configuration may be provided in either of these forms:

1. Render-style provider URL:

```text
DATABASE_URL=postgresql://USER:PASSWORD@HOST:5432/DATABASE
```

2. Explicit JDBC settings:

```text
DB_URL=jdbc:postgresql://HOST:5432/DATABASE?sslmode=require
DB_USERNAME=USER
DB_PASSWORD=PASSWORD
```

The backend includes a boot-time adapter for Render-style Postgres URLs, so `DATABASE_URL` is enough on Render.

## Render Backend Deployment

This repo now includes a root-level `render.yaml` that provisions:

- one Docker-based Spring Boot web service
- one Render Postgres database
- generated `JWT_SECRET`
- internal `DATABASE_URL` wiring from the Render database into the backend service

Steps:

1. Push this repo to GitHub, GitLab, or Bitbucket.
2. In Render, choose `New +` > `Blueprint`.
3. Select the repository that contains `render.yaml`.
4. Review the two resources:
   - `vortex-synergy-api`
   - `vortex-synergy-db`
5. Before the first deploy, set:
   - `CORS_ALLOWED_ORIGIN_PATTERNS=https://YOUR_NETLIFY_SITE.netlify.app,http://localhost:*,http://127.0.0.1:*`
6. Deploy the blueprint.
7. After the backend is live, open:

```text
https://YOUR_RENDER_BACKEND/actuator/health
```

Expected result:

```json
{"status":"UP"}
```

If you later add a custom domain to Netlify, add that domain to `CORS_ALLOWED_ORIGIN_PATTERNS` as well.

### Render Upload Storage Note

Render documents that service filesystems are ephemeral by default, and persistent disks are available for paid services. For Docker services, the common disk mount path is under `/app/storage`.

This project is configured with:

```text
UPLOAD_DIR=/app/storage/uploads
```

Without a persistent disk, uploaded resource photos will be lost when the service restarts or redeploys. For demo use this is acceptable; for longer-lived deployments attach a Render persistent disk and mount it under `/app/storage`.

## Docker Deployment

Build backend image:

```bash
cd "/Users/mohithgowda/Documents/New project/vortex-synergy/backend"
docker build -t vortex-synergy-api .
```

Run locally with production profile:

```bash
docker run --env-file ../deploy.env.example -p 8080:8080 vortex-synergy-api
```

Health check:

```bash
curl https://YOUR_API_DOMAIN/actuator/health
```

Expected result:

```json
{"status":"UP"}
```

Do not use your Mac IP for deployment. `localhost`, `127.0.0.1`, and Wi-Fi IPs are only for local testing.

## One Backend For Mobile And Laptop

All clients must use the same public API:

```text
https://YOUR_API_DOMAIN
```

Use that value as `API_ORIGIN` for every Flutter target:

- Android phone
- iPhone
- macOS desktop app
- Chrome/web/laptop build

Native mobile apps do not use browser CORS, but Flutter web does. If you deploy Flutter web, set:

```text
CORS_ALLOWED_ORIGIN_PATTERNS=https://YOUR_WEB_FRONTEND_DOMAIN,http://localhost:*,http://127.0.0.1:*
```

If you only ship Android/iOS/macOS apps, CORS is still safe to keep configured for local testing and future web access.

## Netlify Web Deployment

Netlify should host only the built Flutter web files.

Build the web app locally against the Render API:

```bash
cd "/Users/mohithgowda/Documents/New project/vortex-synergy/mobile"
flutter build web --release --dart-define=API_ORIGIN=https://YOUR_RENDER_BACKEND
```

The Flutter web source now includes:

- `mobile/web/_redirects`

That file applies the SPA fallback rule needed for direct URL refreshes on Netlify:

```text
/* /index.html 200
```

Then deploy the generated folder to Netlify:

1. Sign in to Netlify.
2. Go to `Sites`.
3. Use the drag-and-drop deploy flow.
4. Upload:

```text
mobile/build/web
```

After deploy, copy the generated `https://...netlify.app` domain and add it to Render:

```text
CORS_ALLOWED_ORIGIN_PATTERNS=https://YOUR_SITE.netlify.app,http://localhost:*,http://127.0.0.1:*
```

## Flutter Build Against Production API

Android APK:

```bash
cd "/Users/mohithgowda/Documents/New project/vortex-synergy/mobile"
flutter build apk --dart-define=API_ORIGIN=https://YOUR_API_DOMAIN
```

Android App Bundle:

```bash
cd "/Users/mohithgowda/Documents/New project/vortex-synergy/mobile"
flutter build appbundle --dart-define=API_ORIGIN=https://YOUR_API_DOMAIN
```

iOS:

```bash
cd "/Users/mohithgowda/Documents/New project/vortex-synergy/mobile"
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer flutter build ios --dart-define=API_ORIGIN=https://YOUR_API_DOMAIN
```

For iOS device deployment, select an Apple Development Team in Xcode first:

```text
mobile/ios/Runner.xcworkspace > Runner target > Signing & Capabilities > Team
```

For simulator testing, install the iOS runtime in:

```text
Xcode > Settings > Components
```

macOS laptop app:

```bash
cd "/Users/mohithgowda/Documents/New project/vortex-synergy/mobile"
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer flutter build macos --dart-define=API_ORIGIN=https://YOUR_API_DOMAIN
```

Flutter web for laptop/browser access:

```bash
cd "/Users/mohithgowda/Documents/New project/vortex-synergy/mobile"
flutter build web --dart-define=API_ORIGIN=https://YOUR_API_DOMAIN
```

Deploy the generated web files from:

```text
mobile/build/web
```

Run on a connected test device:

```bash
flutter run -d DEVICE_ID --dart-define=API_ORIGIN=https://YOUR_API_DOMAIN
```

## Pre-Deployment Verification

Backend compile:

```bash
cd "/Users/mohithgowda/Documents/New project/vortex-synergy/backend"
export JAVA_HOME=$(/usr/libexec/java_home -v 21)
mvn -q -DskipTests compile
```

Flutter analyze:

```bash
cd "/Users/mohithgowda/Documents/New project/vortex-synergy/mobile"
flutter analyze
```

API smoke test after deployment:

```bash
curl -X POST https://YOUR_API_DOMAIN/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"receiver@vortex.local","password":"Password123!"}'
```

Mobile/laptop smoke test:

- Open Android APK and login.
- Open iPhone/macOS app and login.
- Open deployed Flutter web URL in a laptop browser and login.
- Confirm all three clients show the same resources and dashboard data.

## Deployment Verification Matrix

Use this before final submission or demo:

| Target | Build/run command | Expected result |
| --- | --- | --- |
| Backend API | `curl https://YOUR_API_DOMAIN/actuator/health` | Returns `{"status":"UP"}` |
| Android phone | `flutter build apk --dart-define=API_ORIGIN=https://YOUR_API_DOMAIN` | APK logs in and loads resources |
| iPhone | `flutter build ios --dart-define=API_ORIGIN=https://YOUR_API_DOMAIN` | iOS build logs in and loads resources |
| Laptop browser | `flutter build web --dart-define=API_ORIGIN=https://YOUR_API_DOMAIN` | Hosted web app logs in and loads resources |
| macOS laptop app | `flutter build macos --dart-define=API_ORIGIN=https://YOUR_API_DOMAIN` | Desktop app logs in and loads resources |

If Android/iOS works but laptop web fails, check `CORS_ALLOWED_ORIGIN_PATTERNS`.
If every client fails, check the backend health URL, database connection, and `API_ORIGIN`.

## Important Production Notes

- Set `JWT_SECRET` to a real random secret.
- Keep `EXPOSE_PASSWORD_RESET_TOKEN=false`.
- Do not expose PostgreSQL publicly without IP restrictions.
- Configure persistent storage for `UPLOAD_DIR` if photo uploads matter.
- Use HTTPS for the backend URL before building mobile releases.
- If deploying Flutter web, add the web domain to `CORS_ALLOWED_ORIGIN_PATTERNS`.
