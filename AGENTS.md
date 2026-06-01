# Foodie Bee

Android Flutter app — connects surplus food donors with distributors in Bangladesh.

## Tech Stack
- Flutter stable, Dart SDK ^3.12.0, AGP 9.0.1, Kotlin 2.3.20
- Firebase Auth (Phone only), Firestore, Cloud Messaging
- Cloudinary `dl5qk4r74` / `foodie-bee` for image upload (no Firebase Storage)
- flutter_map + OpenStreetMap (no API key), Provider for state

## Build & Run
- `JAVA_HOME` must point to java-21-openjdk (system default is Java 26 — incompatible)
- `cd app && flutter run` on connected device (preferred for iteration — hot reload)
- `cd app && flutter build apk --debug --target-platform=android-arm64` for a shareable debug APK
- `cd app && flutter analyze` for lint (flutter_lints defaults, no custom rules)

### Recommended build commands
- `flutter run --debug` for hot iteration (Dart changes reload in <1 s)
- `flutter build apk --debug --target-platform=android-arm64` to build a single-arch APK ~2x faster than universal or `--split-per-abi`
- Add `--no-pub` to any build command once `pub get` has run (saves a few seconds)
- Avoid `flutter clean` on 8 GB Windows — discards the Dart kernel cache (`app/build/e526d636...dill`) and forces a full rebuild next time

### Low-spec Windows (8 GB) tips
- VS Code is the recommended IDE (Android Studio + Gradle daemon will fight for 8 GB)
- Close Chrome / Edge / Discord / Slack before long builds
- Add `app/build/`, `~/.gradle/caches/`, and `~/.pub-cache/` to **Windows Defender → Virus & threat protection → Exclusions**. Real-time scan can double Gradle's wall time
- Prefer `flutter run --debug` over `flutter build apk && adb install` for hot iteration
- If Gradle daemon OOMs, run `gradle --stop` from `app/android/` and re-launch; check `gradle.log` for the heap dump
- `gradle.properties` heap is capped at `Xmx3G` to leave headroom for the OS — do not raise it on 8 GB Windows

### Build performance baseline
- `app/android/gradle.properties` is tuned for the 8 GB Windows floor: `Xmx3G` heap, 4 workers, parallel + caching enabled
- 14 GB Linux/Arch users can override locally: bump `org.gradle.jvmargs` to `-Xmx6G` and `org.gradle.workers.max` to `6` (uncommitted local change is fine; don't push)
- First clean build: ~3-5 min on 8 GB Windows, ~2-3 min on Linux. Incremental: ~5-15 s.

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
