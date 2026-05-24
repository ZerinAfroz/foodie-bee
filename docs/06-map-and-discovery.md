# 06 — Map & Discovery

## Overview

The map screen is the primary way distributors discover available food near them. It shows nearby "available" listings as markers on a Google Map. Distributors tap a marker to view listing details and claim.

## Architecture

```
Distributor opens map
  ↓
Get distributor's current location (or profile location)
  ↓
Query Firestore for "available" listings within pickupRadius km
  ↓
Display markers on Google Map
  ↓
Tap marker → Bottom sheet with listing summary → "View Details"
  ↓
Listing detail screen → "Claim" button
```

## Screens

### 1. Map Screen (Distributor Home)

**Elements:**
- Google Map taking full screen
- Custom markers for available food listings
  - Different icon per category (cooked = pot icon, bakery = bread icon, etc.)
- User's current location blue dot
- Floating action button: "Refresh" / "My Location"
- Bottom: "My Claims" button → navigates to claims list

**Loading state:**
- Circular progress indicator while fetching
- "No food available near you" empty state

**Error state:**
- "Could not load listings. Check your connection." with retry button

### 2. Listing Marker Bottom Sheet

When distributor taps a marker:

```
┌─────────────────────────────────────┐
│  [Photo thumbnail]                  │
│                                     │
│  Chicken Biryani - 5kg             │
│  Cooked Food · 5 kg                │
│  Pickup by: Today 11:00 PM         │
│  📍 Alif Catering · 1.2 km away   │
│                                     │
│  [View Details]  [Claim Now]       │
└─────────────────────────────────────┘
```

### 3. Listing Detail Screen (Distributor View)

**Full listing details:**
- Photo gallery (swipeable)
- Title, category, quantity
- Donor name, phone, address
- Distance from distributor
- Prepared at time
- Pickup deadline (with countdown)
- Special notes
- "Claim This Food" button (disabled if already claimed)

## Geo Query Implementation

Firestore doesn't natively support radius queries on GeoPoints. Use **GeoFlutterFire** (based on geohash ranges).

```dart
import 'package:geoflutterfire/geoflutterfire.dart';

Stream<List<DocumentSnapshot>> getNearbyListings(GeoPoint center, double radiusKm) {
  final geo = GeoFlutterFire();
  final ref = FirebaseFirestore.instance
      .collection('foodListings')
      .where('status', isEqualTo: 'available');

  // GeoFlutterFire converts to geohash bounds query
  return geo.collection(collectionRef: ref)
      .within(
        center: GeoFirePoint(center.latitude, center.longitude),
        radius: radiusKm,
        field: 'location',
        strictMode: true,
      );
}
```

**Important:** You need a composite index on `foodListings` for fields `status` (Ascending) + `location` (Ascending). Create this in Firebase Console > Firestore > Indexes.

## Map Configuration

```dart
GoogleMap(
  initialCameraPosition: CameraPosition(
    target: LatLng(23.8103, 90.4125),  // Dhaka center
    zoom: 12,
  ),
  markers: _listings.map((listing) => Marker(
    markerId: MarkerId(listing.id),
    position: LatLng(listing.lat, listing.lng),
    icon: _getCategoryIcon(listing.category),
    onTap: () => _showListingSheet(listing),
  )).toSet(),
  myLocationEnabled: true,
  myLocationButtonEnabled: true,
  onMapCreated: (controller) => _controller = controller,
)
```

## Permissions

**AndroidManifest.xml** additions:

```xml
<!-- Location -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- Internet (already present for Flutter) -->
<uses-permission android:name="android.permission.INTERNET" />
```

**Google Maps API Key:**

1. Get key from [Google Cloud Console](https://console.cloud.google.com/) → APIs & Services → Credentials
2. Enable "Maps SDK for Android"
3. Add key to `android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data
  android:name="com.google.android.geo.API_KEY"
  android:value="YOUR_API_KEY_HERE"/>
```

## Edge Cases

| Case | Handling |
|------|----------|
| Distributor has no location permission | Show alert: "Enable location to find food near you" + manual address input fallback |
| No listings in range | Show friendly empty state: "No food available nearby. Try expanding your pickup radius." |
| Listing claimed but not yet marked in DB (race) | On "Claim" tap, use Firestore transaction: read listing, check status == "available", then update |
| Distributor pickup radius change | Re-run geo query with new radius |
| Poor GPS signal in dense Dhaka | Allow manual address/map pin placement as fallback |
