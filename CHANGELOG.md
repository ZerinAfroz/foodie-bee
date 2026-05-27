# Changelog

## [0.1.0] — 2026-05-27

### Initial MVP Release

#### Auth & Onboarding
- Phone OTP authentication with Bangladeshi number validation
- Role selection screen (Donor / Distributor)
- Donor profile creation (business name, type, address, operating hours)
- Distributor profile creation (org name, type, address, people served)

#### Food Listing (Donor)
- Post food listing with title, category, quantity, unit, and up to 3 photos
- Datetime pickers for prepared-at and pickup deadline
- Map pin placement for pickup location
- Special notes field
- My Listings screen with Active / Completed / Expired tabs

#### Map Discovery (Distributor)
- Full-screen OpenStreetMap with current location
- GeoQuery-powered markers for nearby available listings
- Tap marker → bottom sheet with listing summary
- Navigate to listing detail from bottom sheet

#### Claim & Pickup Flow
- Claim listing with atomic Firestore transaction
- Donor confirms or rejects claim
- Distributor marks picked up
- Donor marks completed
- Claim lifecycle tracked end-to-end

#### Notifications
- In-app notification list with real-time Firestore stream
- Unread badge on home screen bell icon
- Notification docs written on every claim lifecycle event
- FCM infrastructure ready (token registration, foreground/background handlers)
- Tap notification → navigate to relevant listing detail

#### Auto-Expiry
- Listings past pickup deadline auto-expire
- Batch sweep on app startup + periodic timer every 60s
- Pending claims auto-cancelled when listing expires

#### Project
- Clean project structure with Provider state management
- Cloudinary image upload (no Firebase Storage)
- OpenStreetMap (no API key required)
- 10 smoke tests covering constants, theme, and routes
- AGENTS.md with project conventions for AI-assisted development
