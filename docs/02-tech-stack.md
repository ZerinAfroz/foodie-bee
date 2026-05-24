# 02 — Tech Stack

## Stack Summary

| Layer | Technology | Why |
|-------|------------|-----|
| **Mobile App** | Flutter (Dart) | Single codebase for Android (and iOS later), hot reload, fast development |
| **Auth** | Firebase Authentication (Phone) | Simple SMS OTP, no password management, trusted in Bangladesh |
| **Database** | Cloud Firestore | Real-time NoSQL, offline support, auto-sync, no server management |
| **Storage** | Firebase Cloud Storage | Image upload for food photos |
| **Backend Logic** | Firebase Cloud Functions (Node.js) | Optional for future — notifications, scheduled cleanup of expired listings |
| **Push Notifications** | Firebase Cloud Messaging (FCM) | Free push to Android devices |
| **Maps** | google_maps_flutter package | Google Maps SDK for location-based discovery |
| **Geo Queries** | GeoFlutterFire package | Query Firestore by proximity (lat/lng bounds) |

## Why Flutter + Firebase for MVP

- **Zero server management** — Auth, DB, Storage, Functions all managed
- **Fast iteration** — Hot reload, Firebase emulator for local testing
- **Single language** — Dart everywhere (mobile + cloud functions if needed)
- **Offline support** — Firestore caches data, works without internet
- **Free tier** — Firebase Spark plan is free and generous enough for MVP
- **Bangladesh-friendly** — Phone OTP auth works well; Firebase has good latency in Dhaka region

## Key Flutter Packages

| Package | Purpose |
|---------|---------|
| firebase_core | Firebase initialization |
| firebase_auth | Phone OTP authentication |
| cloud_firestore | Firestore database operations |
| firebase_storage | Image upload |
| firebase_messaging | Push notifications |
| google_maps_flutter | Map display |
| geoflutterfire | Geo queries on Firestore |
| image_picker | Camera/gallery for food photos |
| provider | State management (simple, built-in) |
| flutter_local_notifications | Local notification display |
| intl | Date/formatting |

## Development Tools

| Tool | Purpose |
|------|---------|
| VS Code + Flutter extension | IDE |
| Firebase Console | Project management, analytics |
| Firebase Emulator Suite | Local testing (auth, firestore, functions, storage) |
| Postman / Insomnia | Testing cloud functions (future) |
| Git + GitHub | Version control |
| Android Studio (optional) | Android emulator management |

## Firebase Project Setup

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create new project (e.g. "FoodieBeeBD")
3. Enable **Phone Authentication** in Auth section
4. Create **Cloud Firestore** database (start in test mode, secure later)
5. Enable **Cloud Storage** (default rules)
6. Enable **Firebase Cloud Messaging** (no config needed)
7. Download `google-services.json` and place in `android/app/`
8. Register Android app package name (e.g. `com.foodshare.app`)

## Flutter Setup

```bash
flutter create --org com.foodshare foodshare_app
cd foodshare_app

# Add Firebase
flutter pub add firebase_core firebase_auth cloud_firestore \
  firebase_storage firebase_messaging google_maps_flutter \
  geoflutterfire image_picker provider intl
```
