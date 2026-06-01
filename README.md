# Foodie Bee

**Connecting surplus food donors with distributors in Bangladesh.**

A mobile platform that reduces food waste by connecting restaurants, hotels, caterers, and bakeries with orphanages, mosques, community kitchens, and NGOs — in real time.

---

## The Problem

Bangladesh generates significant food waste daily from restaurants, hotels, caterers, and events, while many organizations struggle to source food for the people they serve. There is no streamlined way to connect surplus supply with demand in real time.

## The Solution

A free Android app where:

- **Donors** post surplus food with details (type, quantity, photos, pickup deadline)
- **Distributors** discover nearby available food on a map
- **Distributors** claim food and arrange pickup
- **Donors** confirm or reject claims
- **Pickup** is tracked from claim to completion

---

## Features

| Feature | Description |
|---------|-------------|
| Phone OTP Auth | Login via SMS verification (Bangladeshi numbers) |
| Role Selection | Choose to participate as Donor or Distributor |
| Donor Profile | Business details, location, operating hours |
| Distributor Profile | Organization details, people served, pickup radius |
| Post Food Listing | Title, category, quantity, up to 3 photos, deadlines, map pin |
| My Listings | Tabbed view: Active / Completed / Expired |
| Listing Detail | Full info with role-specific actions |
| Map Discovery | Browse available food near you with GeoQuery |
| Claim & Pickup | Full lifecycle: claim → confirm/reject → pickup → complete |
| Notifications | In-app notification list with unread badge |
| Auto-Expiry | Past-deadline listings expire automatically |

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | Flutter (Android), Dart ^3.12.0 |
| **Auth** | Firebase Auth (Phone only) |
| **Database** | Cloud Firestore |
| **Images** | Cloudinary |
| **Maps** | flutter_map + OpenStreetMap (no API key) |
| **Push** | Firebase Cloud Messaging + flutter_local_notifications |
| **State** | Provider |
| **Build** | AGP 9.0.1, Kotlin 2.3.20, Kotlin DSL |

---

## Project Structure

```
foodie-bee/
├── app/                  # Flutter application (Android only)
│   └── lib/
│       ├── config/       # Theme, constants, routes, Cloudinary config
│       ├── providers/    # State management (Auth, FoodListing)
│       ├── services/     # Auth, Storage (Cloudinary), Notifications
│       ├── screens/      # UI screens grouped by role/feature
│       ├── models/       # Data models
│       └── widgets/      # Shared widgets
├── docs/                 # Planning and architecture documents
└── AGENTS.md             # Project guide for AI coding assistants
```

---

## Getting Started

### Prerequisites

- Flutter **stable** channel
- Java 21 (`JAVA_HOME` must point to `java-21-openjdk`)
- A connected Android device or emulator

### Setup

```bash
# 1. Clone the repo
git clone https://github.com/ZerinAfroz/foodie-bee.git
cd foodie-bee

# 2. Place google-services.json
#     → app/android/app/google-services.json (gitignored — get from Firebase Console)

# 3. Install dependencies
cd app && flutter pub get

# 4. Run
flutter run

# 5. Build debug APK
flutter build apk --debug
```

### Firebase Configuration

- Phone Auth enabled with test phone numbers (SMS-free OTP for development)
- SHA-1 fingerprint registered in Firebase Console (`~/.android/debug.keystore`)
- Two composite indexes required in Firestore Console:
  - `foodListings`: `status` Asc + `location.geohash` Asc
  - `claims`: `listingId` Asc + `status` Asc

---

## Development Workflow

1. Create a `feature/*` branch from `main`
2. Implement changes
3. Run `flutter analyze` — must pass with zero issues
4. Commit and push
5. Open a pull request to `main`

---

## License

Private — internal development project.
