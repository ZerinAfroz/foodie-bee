# 05 — Food Listing Management

## Overview

Donors post surplus food listings. Each listing goes through a state machine from draft to completed or expired. Distributors browse and claim available listings via the map screen.

## State Machine

```
            ┌────────────┐
            │   Draft    │
            └─────┬──────┘
                  │ Donor submits
            ┌─────▼──────┐
            │  Available │ ←──── System auto-expires here
            └─────┬──────┘       if pickup deadline passed
                  │
          ┌───────┴────────┐
          │                │
  ┌───────▼──────┐  ┌─────▼──────┐
  │   Claimed    │  │  Expired   │
  └───────┬──────┘  └────────────┘
          │
    ┌─────┴─────┐
    │           │
┌───▼───┐  ┌───▼────┐
│Confirmed│ │Rejected│
└───┬───┘  └───┬────┘
    │          │
    │          └──→ Available (re-listed)
    │
┌───▼────┐
│PickedUp│
└───┬────┘
    │
┌───▼────┐
│Completed│
└────────┘
```

## Donor: Post New Listing Screen

**Elements:**

| Field | Widget | Notes |
|-------|--------|-------|
| Food title | TextField | e.g. "Chicken Biryani - 5kg" |
| Category | Dropdown | cooked, raw, packaged, bakery, fruits_veg, other |
| Quantity | Number + Unit (dropdown: kg, pieces, plates, liters) | Required |
| Photo(s) | Image picker (up to 3) | Camera or gallery; upload to Firebase Storage on submit |
| Prepared at | Date + Time picker | Default: now |
| Pickup deadline | Date + Time picker | Required. Must be at least 30 min from now |
| Location | Auto-filled from donor profile (editable) | Map pin |
| Address | TextField | Auto-filled, editable |
| Special notes | TextField (multiline) | Optional: "Needs cold storage", "Vegetarian only", etc. |
| Submit button | ElevatedButton | Validates all required fields |

**Submission flow:**

```dart
Future<void> submitListing(ListingData data) async {
  // 1. Upload photos to Cloudinary
  List<String> photoURLs = [];
  for (var image in data.images) {
    String url = await StorageService.uploadFoodImage(image);
    photoURLs.add(url);
  }

  // 2. Save listing to Firestore
  await FirebaseFirestore.instance.collection('foodListings').add({
    'donorId':        currentUser.uid,
    'donorName':      currentUserProfile.name,
    'donorPhone':     currentUserProfile.phone,
    'title':          data.title,
    'category':       data.category,
    'quantity':       data.quantity,
    'quantityUnit':   data.quantityUnit,
    'photoURLs':      photoURLs,
    'preparedAt':     data.preparedAt,
    'pickupDeadline': data.pickupDeadline,
    'location':       data.location,         // GeoPoint
    'address':        data.address,
    'specialNotes':   data.specialNotes,
    'status':         'available',
    'createdAt':      FieldValue.serverTimestamp(),
    'updatedAt':      FieldValue.serverTimestamp(),
  });

  // 3. Send push to nearby distributors (optional v1 — manual for now)
}
```

## Donor: My Listings Screen

Shows donor's listings in a list grouped by status.

**Tabs:**
- **Active** — Available, Claimed, Confirmed
- **Completed** — Picked Up, Completed
- **Expired/Cancelled** — Expired, Cancelled

**Each listing card shows:**
- Photo thumbnail
- Title, quantity
- Status with color badge
- Pickup deadline countdown
- Claim count (if claimed, show claimant info)
- Tap → Listing detail screen

## Listing Detail Screen (Donor View)

**Shows:**
- All listing info
- Claim status + current claimant details (if claimed)
- Action buttons based on status:
  - **Claimed** → "Confirm" / "Reject" buttons
  - **Confirmed** → Awaiting pickup; contact info shown
  - **Picked Up** → "Mark Completed" button
  - **Completed/Expired/Cancelled** → Read-only

## Auto-Expiry

A Firebase Cloud Function (or client-side check on app open) marks listings as "expired" when `pickupDeadline` has passed and status is still "available".

**Cloud Function (post-MVP):**

```javascript
exports.expireListings = functions.pubsub.schedule('every 5 minutes').onRun(async () => {
  const now = admin.firestore.Timestamp.now();
  const expired = await admin.firestore()
    .collection('foodListings')
    .where('status', '==', 'available')
    .where('pickupDeadline', '<', now)
    .get();

  const batch = admin.firestore().batch();
  expired.docs.forEach(doc => batch.update(doc.ref, { status: 'expired', updatedAt: now }));
  await batch.commit();
});
```

## Edge Cases

| Case | Handling |
|------|----------|
| Donor tries to claim own listing | Disabled — only other users can claim |
| Duplicate claims | Check before creating claim: listing must be "available" |
| Pickup deadline passed while claimed | Auto-cancel claim + mark listing expired |
| Donor deletes account | Mark active listings as expired; notify active claimants |
| Network failure during submission | Firestore offline persistence queues the write |
