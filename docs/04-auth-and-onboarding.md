# 04 — Auth & Onboarding

## Overview

Phone OTP authentication via Firebase Auth. No email/password. After auth, user selects their role and fills in their profile.

## Flow

```
App Launch
  ↓
┌──────────────────────────────────────┐
│          Splash Screen               │
│  Check if user is already logged in  │
└──────────┬───────────────────────────┘
           │
    ┌──────┴──────┐
    │ Logged in?  │
    └──┬───┬──────┘
       │   │
      YES  NO
       │   │
       │   └──→ Phone Auth Screen
       │         │
       │         ↓
       │     OTP Verification Screen
       │         │
       │         ↓ (success)
       │    ┌────┴────┐
       │    │ Profile │
       │    │ exists? │
       │    └──┬──────┘
       │       │   │
       │      NO  YES
       │       │   │
       │       ↓   └──→ Home Screen
       │   Role Selection Screen
       │       │
       │       ↓
       │   Profile Creation Screen
       │   (Donor or Distributor)
       │       │
       │       ↓
       │   Home Screen
```

## Screens in Detail

### 1. Phone Auth Screen

**Elements:**
- Country code picker (default: +880)
- Phone number input (10 digits, BD numbers)
- "Send OTP" button
- Terms & Privacy notice

**Behavior:**
- Validates BD phone format `01XXXXXXXXX`
- Firebase `PhoneAuthProvider.verifyPhoneNumber()` sends SMS
- Auto-retrieval via SMS if Android Play Services available
- Falls back to manual OTP entry

**Edge case:** If phone fails to send OTP after 3 tries, show "Try again later" with a cooldown.

### 2. OTP Verification Screen

**Elements:**
- 6-digit OTP input (one box per digit)
- Resend timer (30s cooldown)
- "Verify" button
- "Change number" link

**Behavior:**
- Auto-submit on 6 digits entered
- Firebase `PhoneAuthCredential` → `signInWithCredential`
- On success, navigate to role selection (new user) or home (existing user)

**Error handling:**
- Wrong OTP: "Invalid code. Please try again."
- Expired OTP: "Code expired. Request a new one."
- Too many attempts: "Too many attempts. Try again later."

### 3. Role Selection Screen

**Elements:**
- Two large cards with icons:
  - **"I have surplus food to donate"** (Donor)
  - **"I need food to distribute"** (Distributor)
- Brief description under each
- "Continue" button (disabled until selection made)

**Behavior:**
- Stores `role` in local state
- Navigates to appropriate profile creation screen

### 4. Profile Creation — Donor

**Fields:**
| Field | Widget | Validation |
|-------|--------|------------|
| Business name | TextField | Required, 2-100 chars |
| Business type | Dropdown | restaurant, hotel, catering, bakery, supermarket, event_hall, other |
| Address | TextField | Required |
| Pin location on map | Map picker | Required (GeoPoint) |
| Operating hours | Two TimePickers | Required (open, close) |
| Preferred pickup window | Two TimePickers | Optional |

**Behavior:**
- Saves to Firestore `users/{uid}` with role = "donor"
- Map picker: show Google Maps, user drops a pin, store GeoPoint

### 5. Profile Creation — Distributor

**Fields:**
| Field | Widget | Validation |
|-------|--------|------------|
| Organization name | TextField | Required, 2-100 chars |
| Organization type | Dropdown | orphanage, shelter, madrasa, mosque, community_kitchen, ngo, other |
| Address | TextField | Required |
| Pin location on map | Map picker | Required (GeoPoint) |
| People served daily | Number input | Required, 1+ |
| Can you pick up food? | Switch (Yes/No) | Required |
| Pickup radius (km) | Slider (1-20) | Default 5 |
| Preferred food types | Multi-select chips | Optional |

**Behavior:**
- Saves to Firestore `users/{uid}` with role = "distributor"

## Firebase Auth Configuration

1. **Android SHA-1/SHA-256 fingerprints** must be added in Firebase console
   - For debug: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`
   - For release: use your app signing key

2. **Phone numbers for testing** — add test phone numbers in Firebase Console > Auth > Phone > Test phone numbers to avoid SMS charges during development

## State Management (Provider)

```dart
class AuthProvider extends ChangeNotifier {
  User? firebaseUser;
  DocumentSnapshot? userProfile;  // from Firestore users/{uid}
  bool isLoading = false;

  Future<void> sendOTP(String phone) async { ... }
  Future<void> verifyOTP(String code) async { ... }
  Future<void> createProfile(Map data) async { ... }
  Future<void> logout() async { ... }
  bool get isLoggedIn => firebaseUser != null;
  bool get hasProfile => userProfile != null;
  String get role => userProfile?['role'] ?? '';
}
```
