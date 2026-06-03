# Changelog

## [0.2.1] — 2026-06-04

### Bug Fixes
- Fix release-only badge layout: restructure Positioned as direct Stack child with clipBehavior none
- Fix chat name not showing when navigating from notifications (resolve otherUserId from chat doc)
- Fix chat screen opening at first message instead of most recent (reversed ListView and query)

## [0.2.0] — 2026-06-02

### In-App Chat
- Real-time chat between donors and distributors on confirmed claims
- Chat created automatically when donor confirms a claim
- Chat list screen with WhatsApp-style layout, cached names, relative time
- Chat detail screen with date separators, input bar with animated send button
- Unread badge on home screen chat icon (green filled avatar + red dot)
- Unread count stream combining both donor and distributor roles
- chat_message notification type wired through notification system

### Mark All as Read
- Batch mark all notifications as read from notifications screen
- Confirmation dialog before marking all as read
- Snackbar confirmation after completion

### UI Bugfixes
- Badge tap fix: IgnorePointer on notification/chat badge prevents tap interception
- Left-aligned AppBar titles on home screens for better layout with 4 action icons
- Navigation stack clearing at all reset points (splash, OTP, profile creation) removes unwanted back button
- System navigation bar overlap fix in map picker and post listing screens
- Null guard on home screens prevents crash during logout

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
