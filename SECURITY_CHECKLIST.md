# Security Checklist

## Authentication
- [ ] No password persisted after login
- [ ] Access/refresh tokens stored only in `flutter_secure_storage`
- [ ] Short-lived access tokens with refresh flow
- [ ] Session lock after inactivity
- [ ] Optional PIN unlock for terminals

## Network
- [ ] All API calls use HTTPS in staging/production
- [ ] Cleartext HTTP disabled in production (`android:usesCleartextTraffic="false"`)
- [ ] Certificate pinning implemented
- [ ] Request correlation IDs

## Data Protection
- [ ] Local database backups encrypted or access-controlled
- [ ] Customer data minimized in logs
- [ ] No sensitive data in crash reports

## Financial Operations
- [ ] All mutations use idempotency keys
- [ ] Server-authoritative totals
- [ ] Discount/refund/void operations require permissions and reasons
- [ ] Audit events logged for all financial operations

## Code Quality
- [ ] No hardcoded credentials
- [ ] No credentials in source control
- [ ] No `print()` for diagnostics
- [ ] Sensitive fields redacted in logs
