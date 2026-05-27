# Changelog

## V3 Production Hardening

### 1. Volunteer Role Removal

- Removed the legacy `VOLUNTEER` enum from the backend role model
- Migrated any existing volunteer users to `RECEIVER` on startup
- Removed Flutter routing to the legacy volunteer screen

Breaking change:
- Volunteer accounts now behave as receiver organizations after migration

### 2. Anti-Hoarding Policy Freeze

- Replaced daily claim-cap language with one consistent fair-access policy
- Backend now blocks duplicate active reservations on the same resource
- Frequent recent claims still reduce priority score instead of hard-blocking claims
- Receiver-facing UI now explains the active policy

Breaking change:
- The product no longer enforces daily food/medicine caps

### 3. Query-Layer Browsing And Reports

- `GET /api/resources` now returns paged results
- Public resource browse filters and sort order now execute at the database/query layer
- CSV reports now use focused report-row queries instead of broad `findAll()` entity loading
- Receiver browse UI now supports page navigation

Breaking change:
- Clients consuming `GET /api/resources` must read `items` from a paged response body

### 4. Forgot / Reset Password

- Added one-time password reset tokens with expiry and hashed token storage
- Added `POST /api/auth/forgot-password` and `POST /api/auth/reset-password`
- Added Flutter forgot-password and reset-password screens
- Local development can expose a preview reset token through `EXPOSE_PASSWORD_RESET_TOKEN=true`

Breaking change:
- None for existing login/register clients

### 5. Donor Certificate Detail And Download

- Added donor certificate detail endpoint and HTML download endpoint
- Added a dedicated donor certificate screen in Flutter
- Added cross-platform HTML download support for the certificate

Breaking change:
- None for existing dashboard summary consumers
