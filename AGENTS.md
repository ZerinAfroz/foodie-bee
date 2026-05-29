# Foodie Bee

Android Flutter app — connects surplus food donors with distributors in Bangladesh.

## Tech Stack
- Flutter stable, Dart SDK ^3.12.0, AGP 9.0.1, Kotlin 2.3.20
- Firebase Auth (Phone only), Firestore, Cloud Messaging
- Cloudinary `dl5qk4r74` / `foodie-bee` for image upload (no Firebase Storage)
- flutter_map + OpenStreetMap (no API key), Provider for state

## Build & Run
- `JAVA_HOME` must point to java-21-openjdk (system default is Java 26 — incompatible)
- `cd app && flutter run` on connected device
- `cd app && flutter build apk --debug`
- `cd app && flutter analyze` for lint (flutter_lints defaults, no custom rules)

## Project Structure
- `app/` — Flutter app, Android-only (ios/web/linux/macos/windows removed from tree)
- `app/lib/`: `config/` `providers/` `services/` `screens/` `widgets/` `models/` — `widgets/` and `screens/claim/` are empty scaffolded dirs; `models/` has only `notification_item.dart`
- `docs/` — 10 planning/architecture documents

## Key Conventions
- snake_case files, PascalCase classes, camelCase fields/vars
- Firestore collections: camelCase
- No code comments unless the logic is genuinely non-obvious
- `feature/*` branches → PR to `main`, no direct pushes

## Dependencies (pub.dev)
firebase_core, firebase_auth, cloud_firestore, cloudinary_public,
firebase_messaging, flutter_map, latlong2, geolocator, geoflutterfire_plus,
image_picker, provider, flutter_local_notifications, intl, cupertino_icons

## Critical Notes
- `google-services.json` at `app/android/app/` — gitignored, must be present for build
- Test phone numbers configured in Firebase Console (SMS-free OTP testing)
- SHA-1 fingerprint registered in Firebase Console (debug keystore at `~/.android/debug.keystore`)
- `Geocoding` package not used — map picker returns coordinates only, address typed manually
- KGP warnings about `image_picker_android` / `package_info_plus` are non-blocking
