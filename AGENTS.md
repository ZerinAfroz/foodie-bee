# Foodie Bee

Android Flutter app — connects surplus food donors with distributors in Bangladesh.

## Tech Stack
- Flutter stable, Dart SDK ^3.12.0, AGP 9.0.1, Kotlin 2.3.20
- Firebase Auth (Phone only), Firestore, Cloud Messaging
- Cloudinary `dl5qk4r74` / `foodie-bee` for image upload (no Firebase Storage)
- flutter_map + OpenStreetMap (no API key), Provider for state

## Build & Run
- `JAVA_HOME` must point to java-21-openjdk (system default is Java 26 — incompatible)
- All flutter commands run from `app/`: `cd app && flutter run`, `cd app && flutter build apk`, etc.
- `flutter analyze` — zero issues required before merge
- `flutter build apk --debug --target-platform=android-arm64` for shareable debug APK
- Add `--no-pub` to any build command once `pub get` has run (saves a few seconds)
- Avoid `flutter clean` on 8 GB Windows — discards the Dart kernel cache, forces full rebuild

### Low-spec Windows (8 GB) tips
- VS Code recommended (Android Studio + Gradle daemon will fight for 8 GB)
- Close Chrome / Edge / Discord / Slack before long builds
- Add `app/build/`, `~/.gradle/caches/`, and `~/.pub-cache/` to **Windows Defender → Exclusions**. Real-time scan can double Gradle wall time
- If Gradle daemon OOMs: `gradle --stop` from `app/android/`, then re-launch

### Build performance baseline
- `gradle.properties` tuned for 8 GB Windows floor: `Xmx3G`, 4 workers, parallel + caching
- Linux/Arch users can override locally: bump to `Xmx6G` / `workers.max=6` (uncommitted change; don't push)
- Incremental rebuild: ~5-15 s on either machine

## Project Structure
- `app/` — Flutter app, Android-only (ios/web/linux/macos/windows removed from tree)
- `app/lib/config/` — Theme, `constants.dart` (single source of truth for strings, reference data, status labels), `routes.dart` (15 named routes), Cloudinary config
- `app/lib/providers/` — AuthProvider, FoodListingProvider
- `app/lib/services/` — AuthService, StorageService (Cloudinary), NotificationService (FCM + local)
- `app/lib/screens/` — UI grouped by role/feature
- `app/lib/models/` — `notification_item.dart` only
- `app/lib/widgets/` — empty scaffold
- `docs/` — 10 planning/architecture docs

## Key Conventions
- No code comments unless the logic is genuinely non-obvious
- Commit prefixes: `Fix:`, `Feat:`, `Chore:` + kebab-case imperative (e.g. `Feat: add pull-to-refresh to notifications screen`)
- `feature/*` branches → PR to `main`, no direct pushes
- **Always ask for confirmation before committing, pushing, or opening a PR.** Show what will happen (commit message, branch name, PR title) and wait for explicit user approval.
- All shared UI strings, reference data, status labels, and collection names live in `AppConstants` (`config/constants.dart`)
- Android-only — do not add iOS/web/desktop scaffolding or platform guards
- Cloudinary for images only — no `firebase_storage`
- flutter_map + OpenStreetMap — no `google_maps_flutter` or Google API keys

## Dependencies (pub.dev)
firebase_core, firebase_auth, cloud_firestore, cloudinary_public,
firebase_messaging, flutter_map, latlong2, geolocator, geoflutterfire_plus,
image_picker, provider, flutter_local_notifications, intl, cupertino_icons

## Critical Notes
- `google-services.json` at `app/android/app/` — gitignored, must be present for build
- Test phone numbers configured in Firebase Console (SMS-free OTP testing with custom codes e.g. `123456`)
- SHA-1 fingerprint registered in Firebase Console (debug keystore at `~/.android/debug.keystore`)
- `Geocoding` package not used — map picker returns coordinates only, address typed manually
- KGP warnings about `image_picker_android` / `package_info_plus` are non-blocking
- Release keystore + `key.properties` at `app/android/` (gitignored); signing config is conditional (skipped if `key.properties` missing)
- `ListingDetailScreen` route requires `Map<String, dynamic>` args: `{'listingId': String, 'viewMode': String}` — `viewMode` defaults to `'donor'` if omitted
- Two Firestore composite indexes required for geo queries and claim lookups (configured in Firebase Console):
  - `foodListings`: `status` Asc + `location.geohash` Asc
  - `claims`: `listingId` Asc + `status` Asc
