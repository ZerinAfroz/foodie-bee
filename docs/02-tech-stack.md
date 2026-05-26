# 02 — Tech Stack

## Stack Summary

| Layer | Technology | Why |
|-------|------------|-----|
| **Mobile App** | Flutter (Dart) | Single codebase for Android (and iOS later), hot reload, fast development |
| **Auth** | Firebase Authentication (Phone) | Simple SMS OTP, no password management, trusted in Bangladesh |
| **Database** | Cloud Firestore | Real-time NoSQL, offline support, auto-sync, no server management |
| **Storage** | Cloudinary | Image upload for food photos (25GB free tier, no Firebase Storage lock-in) |
| **Backend Logic** | Firebase Cloud Functions (Node.js) | Optional for future — notifications, scheduled cleanup of expired listings |
| **Push Notifications** | Firebase Cloud Messaging (FCM) | Free push to Android devices |
| **Maps** | google_maps_flutter package | Google Maps SDK for location-based discovery |
| **Geo Queries** | GeoFlutterFire package | Query Firestore by proximity (lat/lng bounds) |

## Why Flutter + Firebase for MVP

- **Zero server management** — Auth, DB, Functions all managed; Cloudinary for image upload
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
| cloudinary_public | Image upload (Cloudinary CDN) |
| firebase_messaging | Push notifications |
| google_maps_flutter | Map display |
| geoflutterfire_plus | Geo queries on Firestore (compatible with latest Firestore) |
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
5. Enable **Firebase Cloud Messaging** (no config needed)
6. Download `google-services.json` and place in `android/app/`
7. Register Android app package name (e.g. `com.foodshare.app`)

## Cloudinary Setup

1. Create free account at [cloudinary.com](https://cloudinary.com)
2. From dashboard, copy your **Cloud Name**
3. Go to **Settings > Upload > Upload Presets > Enable Unsigned Uploading**
4. Create a new unsigned preset (name it e.g. `foodie_bee_preset`)
5. Note your **Cloud Name** and **Upload Preset** — needed in `storage_service.dart`

## Flutter Setup

```bash
flutter create --org com.foodshare foodshare_app
cd foodshare_app

# Add Firebase
flutter pub add firebase_core firebase_auth cloud_firestore \
  cloudinary_public firebase_messaging google_maps_flutter \
  geoflutterfire_plus image_picker provider intl
```
