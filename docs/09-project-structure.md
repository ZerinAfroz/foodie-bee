# 09 — Project Structure

## Overview

Monorepo layout. The root is the GitHub repo containing the Flutter app, Firebase Cloud Functions, and documentation in separate directories.

## Repository Structure

```
foodie-bee/                       ← GitHub repo root
├── app/                          ← Flutter project (flutter create app)
│   ├── android/
│   ├── ios/                      ← (future)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app.dart
│   │   │
│   │   ├── config/
│   │   │   ├── theme.dart
│   │   │   ├── constants.dart
│   │   │   └── routes.dart
│   │   │
│   │   ├── models/
│   │   │   ├── user_model.dart
│   │   │   ├── food_listing_model.dart
│   │   │   ├── claim_model.dart
│   │   │   └── notification_model.dart
│   │   │
│   │   ├── providers/
│   │   │   ├── auth_provider.dart
│   │   │   ├── listing_provider.dart
│   │   │   ├── claim_provider.dart
│   │   │   ├── map_provider.dart
│   │   │   └── notification_provider.dart
│   │   │
│   │   ├── services/
│   │   │   ├── auth_service.dart
│   │   │   ├── firestore_service.dart
│   │   │   ├── storage_service.dart
│   │   │   ├── notification_service.dart
│   │   │   └── location_service.dart
│   │   │
│   │   ├── screens/
│   │   │   ├── splash/
│   │   │   ├── auth/
│   │   │   ├── profile/
│   │   │   ├── donor/
│   │   │   ├── distributor/
│   │   │   ├── claim/
│   │   │   └── notifications/
│   │   │
│   │   └── widgets/
│   │       ├── common/
│   │       ├── food_listing/
│   │       ├── map/
│   │       └── profile/
│   │
│   ├── assets/
│   │   ├── images/
│   │   ├── icons/
│   │   └── fonts/
│   │
│   ├── test/
│   ├── pubspec.yaml
│   └── firebase.json
│
├── functions/                    ← Firebase Cloud Functions (Node.js)
│   ├── index.js
│   └── package.json
│
├── docs/                         ← Plans, architecture, references
│   ├── 01-project-overview.md
│   ├── 02-tech-stack.md
│   ├── 03-database-schema.md
│   ├── 04-auth-and-onboarding.md
│   ├── 05-food-listing-management.md
│   ├── 06-map-and-discovery.md
│   ├── 07-claim-and-pickup-flow.md
│   ├── 08-notifications.md
│   └── 09-project-structure.md
│
├── .gitignore
└── README.md
```

## Naming Conventions

| Item | Convention | Example |
|------|------------|---------|
| Files | `snake_case.dart` | `food_listing_model.dart` |
| Classes | `PascalCase` | `FoodListingModel` |
| Variables | `camelCase` | `pickupDeadline` |
| Firestore collections | `camelCase` | `foodListings` |
| Firestore fields | `camelCase` | `pickupDeadline` |
| Routes | `snake_case` | `/listing_detail` |

## Theme Configuration

```dart
// config/theme.dart
class AppTheme {
  static const primaryColor    = Color(0xFF4CAF50);   // Green (food/nature)
  static const secondaryColor  = Color(0xFFFF9800);   // Orange (energy/warmth)
  static const errorColor      = Color(0xFFF44336);
  static const backgroundColor = Color(0xFFF5F5F5);

  // Status colors
  static const statusAvailable = Color(0xFF4CAF50);
  static const statusClaimed   = Color(0xFFFF9800);
  static const statusConfirmed = Color(0xFF2196F3);
  static const statusPickedUp  = Color(0xFF9C27B0);
  static const statusCompleted = Color(0xFF607D8B);
  static const statusExpired   = Color(0xFF9E9E9E);
  static const statusRejected  = Color(0xFFF44336);
}
```

## Development Order (by screen)

| Step | Screen / Feature | Depends On |
|------|------------------|------------|
| 1 | Firebase + Flutter project setup | — |
| 2 | Splash screen, theme, routing | — |
| 3 | Phone auth + OTP screens | Firebase Auth |
| 4 | Role selection screen | Auth |
| 5 | Donor profile creation | Firestore |
| 6 | Distributor profile creation | Firestore |
| 7 | Post listing screen (Donor) | Firestore, Storage |
| 8 | My listings screen (Donor) | Firestore |
| 9 | Map screen (Distributor) | GeoFlutterFire, Maps SDK |
| 10 | Claim flow (transaction) | Firestore |
| 11 | Claims list screen (Distributor) | Firestore |
| 12 | Pickup/complete flow | Firestore |
| 13 | Push notifications | FCM, Cloud Functions |
| 14 | Notification screen | Firestore |
| 15 | Polish, error handling, edge cases | Everything |

## Git Branches Strategy

```
main        → stable, deployable
develop     → integration branch
feature/    → individual features
  feature/auth
  feature/map
  feature/claims
  feature/notifications
```
