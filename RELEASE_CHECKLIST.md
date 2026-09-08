# Release Checklist

## Pre-release
- [ ] `flutter analyze` passes with no errors
- [ ] All tests pass (`flutter test`)
- [ ] `dart format --set-exit-if-changed .` passes
- [ ] No mock data in production code paths
- [ ] No hardcoded API URLs or credentials
- [ ] Keystores and secrets outside source control
- [ ] Environment-specific config validated

## Android
- [ ] `android/app/build.gradle` signing configured
- [ ] `android/app/src/main/AndroidManifest.xml` has `usesCleartextTraffic="false"`
- [ ] ProGuard/R8 rules applied
- [ ] Target SDK up to date
- [ ] Release build succeeds (`flutter build appbundle --release`)

## iOS
- [ ] Code signing configured in Xcode
- [ ] App Transport Security enforced
- [ ] Release build succeeds (`flutter build ios --release`)

## Backend
- [ ] API deployed to production
- [ ] Database migrations run
- [ ] Monitoring and alerting active
- [ ] Backup and restore tested

## Post-release
- [ ] Crash reporting active
- [ ] Log aggregation configured
- [ ] Rollback plan documented
- [ ] Support team notified
