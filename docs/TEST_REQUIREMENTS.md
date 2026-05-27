# Vortex Synergy Test Requirements

Use this checklist before deployment. The goal is to prove that the Flutter app, Spring Boot API, and PostgreSQL database remain stable under realistic usage, not only under a single-user demo.

## 1. Test Environment

- Create a staging environment that matches deployment as closely as possible.
- Run Spring Boot with production-like environment variables.
- Use PostgreSQL, not an in-memory database.
- Use a separate staging database, not the demo/local database.
- Use HTTPS for public mobile access before final release.
- Disable local demo-only assumptions where possible.
- Keep test users separate from real users.

Recommended minimum staging size for a college project:

- Backend: 1 CPU, 1-2 GB RAM minimum.
- Database: PostgreSQL with at least 1 GB RAM.
- Test data: 1,000 users, 1,000 resources, 2,000 claims, 500 deliveries, 2,000 notifications.

## 2. Functional Test Requirements

Test all role logins:

- Admin login.
- Donor login.
- Receiver login.
- Doctor/Pharmacist login.
- Logout and login again.
- Invalid password rejection.
- Expired/invalid JWT rejection.

Test donor flow:

- Add food with valid expiry.
- Add medicine with sealed status.
- Add medicine with opened status and confirm rejection path.
- Upload resource photos.
- View my donations.
- Edit/cancel only where valid.
- View donor certificate.

Test medical verification flow:

- Doctor/Pharmacist views pending medicine.
- Approve medicine with notes.
- Reject medicine with notes.
- Expired medicine is rejected.
- Opened medicine is rejected.
- Donor sees verification result.

Test receiver flow:

- Browse resources.
- Search by title/name.
- Filter by type, city, and area.
- Sort by expiry.
- Sort by priority.
- Sort by nearest when coordinates exist.
- Claim available resource.
- Prevent duplicate active reservation on same resource.
- Confirm pickup or assign delivery.

Test delivery flow:

- Receiver assigns delivery agent.
- Donor sees delivery agent details.
- Donor approves pickup only once.
- Delivery moves to in-transit only after pickup approval.
- Delivery cannot become delivered before pickup approval.
- Failed delivery records failure reason.
- Receiver confirms final receipt where available.

Test admin flow:

- Verify users.
- Approve doctor/pharmacist accounts.
- Moderate resources.
- View analytics.
- Export reports.
- Check audit timelines.

## 3. API Load Test Scenarios

Use a backend load testing tool such as `k6`, `JMeter`, or `Gatling`.

Critical endpoints to test:

- `POST /api/auth/login`
- `GET /api/users/me`
- `GET /api/resources`
- `POST /api/resources`
- `GET /api/resources/{id}`
- `POST /api/claims/request`
- `GET /api/claims/my`
- `POST /api/deliveries/assign`
- `POST /api/deliveries/pickup-approve`
- `POST /api/deliveries/in-transit`
- `POST /api/deliveries/delivered`
- `GET /api/notifications/my`
- `GET /api/dashboard/role-summary`
- `GET /api/reports/donations/csv`
- `GET /api/reports/claims/csv`
- `GET /api/reports/medicine/csv`
- `GET /api/reports/delivery/csv`

Minimum load scenarios:

- Smoke load: 5 concurrent users for 5 minutes.
- Normal load: 25 concurrent users for 10 minutes.
- Peak load: 50 concurrent users for 10 minutes.
- Stress load: 100 concurrent users for 5 minutes.
- Soak test: 20 concurrent users for 30-60 minutes.

Suggested traffic mix:

- 35% browse resources.
- 20% login/session/user profile.
- 15% claims and claim history.
- 10% notifications.
- 10% dashboard summaries.
- 5% resource creation.
- 5% reports and exports.

## 4. Performance Acceptance Criteria

For staging:

- Login p95 response time under 800 ms.
- Resource browse p95 response time under 1,000 ms.
- Claim request p95 response time under 1,200 ms.
- Delivery updates p95 response time under 1,000 ms.
- Dashboard summary p95 response time under 1,000 ms.
- CSV reports p95 response time under 3,000 ms for staging-sized data.
- Error rate below 1% during normal load.
- Error rate below 3% during stress load.
- No database connection pool exhaustion.
- No backend crash or restart during soak testing.

## 5. Mobile App Test Requirements

Android:

- Test on at least one physical Android phone.
- Test on Android emulator if available.
- Confirm login, browse, claim, add resource, and delivery flows.
- Confirm image upload works.
- Confirm app can reach the public/staging backend without same-Wi-Fi dependency.

iOS:

- Test on macOS desktop first.
- Test on iPhone simulator if available.
- Test on a physical iPhone if signing is configured.
- Confirm login, browse, claim, add resource, and delivery flows.
- Confirm local HTTP is not used for release builds.

Screen checks:

- No bottom overflow warnings.
- All long screens scroll.
- Form validation messages are readable.
- Empty states show correctly.
- Network failure shows user-friendly messages.
- App does not show raw stack traces.

## 6. Security Test Requirements

- Passwords are stored hashed, never plain text.
- JWT is required for protected endpoints.
- Donor cannot access admin endpoints.
- Receiver cannot approve medicine.
- Doctor/Pharmacist cannot moderate admin-only resources.
- Receiver cannot claim unavailable/expired resources.
- Donor cannot approve delivery not linked to their resource.
- Expired JWT is rejected.
- Invalid reset password token is rejected.
- Used reset password token cannot be reused.
- File upload rejects invalid file types where applicable.

## 7. Database Test Requirements

- Resource status transitions are correct.
- Claim and delivery foreign keys remain valid.
- Audit logs are created for major actions.
- Notifications are created for major actions.
- Expiry job changes expired resources to `EXPIRED`.
- Report queries do not require full table scans for common cases where possible.
- Pagination works for resource browsing.
- Duplicate active reservation on the same resource is blocked.

## 8. Report Test Requirements

Verify CSV exports:

- Donation report.
- Claims report.
- Expiry report.
- Medicine verification report.
- Delivery status report.

Each report should:

- Return HTTP 200 for allowed users.
- Return a CSV content type or downloadable CSV response.
- Include headers.
- Include real stored system data.
- Reject unauthorized users.

## 9. Deployment Readiness Gate

Do not deploy until:

- Backend compile passes.
- Flutter analyze passes.
- All demo accounts can login.
- Android or iOS app points to a public/staging API URL.
- Backend is deployed with HTTPS.
- PostgreSQL is reachable from backend only, not exposed openly.
- Load test normal and peak scenarios pass.
- No critical role-based access failures exist.
- README has final run/deploy instructions.

## 10. Recommended Final Test Command Checklist

Backend compile:

```bash
cd "/Users/mohithgowda/Documents/New project/vortex-synergy/backend"
export JAVA_HOME=$(/usr/libexec/java_home -v 21)
mvn -q -DskipTests compile
```

Flutter static analysis:

```bash
cd "/Users/mohithgowda/Documents/New project/vortex-synergy/mobile"
flutter analyze
```

Run app against deployed or staging API:

```bash
cd "/Users/mohithgowda/Documents/New project/vortex-synergy/mobile"
flutter run -d <device-id> --dart-define=API_ORIGIN=https://your-api-domain.com
```

Build Android APK against deployed or staging API:

```bash
cd "/Users/mohithgowda/Documents/New project/vortex-synergy/mobile"
flutter build apk --dart-define=API_ORIGIN=https://your-api-domain.com
```

Build iOS against deployed or staging API:

```bash
cd "/Users/mohithgowda/Documents/New project/vortex-synergy/mobile"
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer flutter build ios --dart-define=API_ORIGIN=https://your-api-domain.com
```
