# 10 — Polish Checklist

UX/visual improvements to make the app demo-ready.

## High Priority

### 1. Splash screen branding
- `screens/splash/splash_screen.dart`
- Replace `Icons.restaurant_menu` with a custom brand illustration or logo asset
- Add tagline text (e.g. "Connecting surplus food with those who need it")
- Show loading status text ("Signing in...", "Loading...")
- Handle timeout/error — don't leave user stuck on spinner

### 2. Empty states with icons
- `my_listings_screen.dart` — replace `'No listings here yet'` with icon + message + CTA button ("Post your first listing")
- `my_claims_screen.dart` — replace `'No claims here yet'` with icon + message + CTA ("Find food to claim")
- `notifications_screen.dart` — replace `'No notifications yet'` with icon + message
- `map_discovery_screen.dart` — replace plain text with icon + message

### 3. Logout confirmation dialog
- `donor_home_screen.dart` and `distributor_home_screen.dart`
- Show `AlertDialog` with "Are you sure you want to log out?" before calling `auth.logout()`

### 4. Reject/complete confirmation dialogs
- `listing_detail_screen.dart`
- `_rejectClaim()` — show confirm dialog before rejecting
- `_markCompleted()` — show confirm dialog before marking complete

### 5. Listing title in AppBar
- `listing_detail_screen.dart`
- Change AppBar title from `'Listing Details'` to the actual food title (e.g. `data['title']`)

### 6. Profile view screen
- Create a simple read-only profile screen (`/profile`) that shows user data from Firestore
- Add a profile icon button in both home screen AppBars

### 7. Smart navigation after actions
- `post_listing_screen.dart` — after successful post, navigate to My Listings instead of generic `Navigator.pop()`
- `listing_detail_screen.dart` — after confirm/reject/complete, pop back to My Listings

## Medium Priority

### 8. Pull-to-refresh
- Wrap list views in `RefreshIndicator` on:
  - `my_listings_screen.dart`
  - `my_claims_screen.dart`
  - `notifications_screen.dart`

### 9. Error states with retry
- Replace plain `'Something went wrong'` text with icon + message + retry button on:
  - `my_listings_screen.dart`
  - `my_claims_screen.dart`
  - `notifications_screen.dart`
  - `map_discovery_screen.dart`

### 10. Map picker instructions
- `map_picker_screen.dart`
- Add a hint banner: "Tap anywhere on the map to set your pickup location"

### 11. OTP + Role selection AppBar titles
- `otp_screen.dart` — add AppBar title "Verify OTP"
- `role_selection_screen.dart` — add AppBar title "Choose Your Role"

### 12. Post-submit navigation
- Already listed in #7 — navigate to `/my-listings` after posting

## Low Priority (Code Hygiene)

### 13. Replace hardcoded strings with AppConstants
- Move frequently used strings (`'Something went wrong'`, `'No items'`, etc.) into `AppConstants`
- Move category list, unit list, business types, org types into `AppConstants`

### 14. Replace hardcoded route strings
- `donor_home_screen.dart` — use `Routes.postListing`, `Routes.myListings`
- `distributor_home_screen.dart` — use `Routes.mapDiscovery`, `Routes.myClaims`

### 15. Replace hardcoded collection names
- `listing_detail_screen.dart` — use `AppConstants.collectionFoodListings`, `AppConstants.collectionUsers`
