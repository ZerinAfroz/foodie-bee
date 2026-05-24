# 07 — Claim & Pickup Flow

## Overview

The claim and pickup flow connects a distributor to a donor's food listing. It goes through 5 states: pending → confirmed/rejected → picked_up → completed.

## Flow Diagram

```
Distributor taps "Claim" on available listing
  ↓
┌──────────────────────────────────────┐
│  Create claim document               │
│  Update listing status → "claimed"   │
│  Push notification to donor          │
└──────────────────────────────────────┘
  ↓
Donor opens notification / listing detail
  ↓
┌──────────────────┐  ┌──────────────────┐
│  Confirm Claim   │  │  Reject Claim    │
│  listing →       │  │  listing →       │
│  "confirmed"     │  │  "available"     │
│  claim →         │  │  claim →         │
│  "confirmed"     │  │  "rejected"      │
│  notify          │  │  notify          │
│  distributor     │  │  distributor     │
└────────┬─────────┘  └──────────────────┘
         │
Distributor arrives for pickup
         │
┌──────────────────────────────────────┐
│  Distributor taps "Mark Picked Up"   │
│  listing → "picked_up"               │
│  claim → "picked_up"                 │
│  notify donor                        │
└──────────────────────────────────────┘
  ↓
Donor confirms pickup completion
  ↓
┌──────────────────────────────────────┐
│  Donor taps "Mark Completed"         │
│  listing → "completed"               │
│  claim → "completed"                 │
│  notify distributor                  │
└──────────────────────────────────────┘
```

## Claim Screen (Distributor)

When distributor taps "Claim Now" on a listing:

**Confirmation dialog:**
```
┌─────────────────────────────────────┐
│  Claim This Food?                   │
│                                     │
│  Chicken Biryani - 5kg             │
│  📍 Alif Catering, Gulshan         │
│  📏 1.2 km from you                │
│  ⏰ Pickup by: Today 11:00 PM      │
│                                     │
│  Are you sure you can pick this up  │
│  before the deadline?               │
│                                     │
│  [Cancel]  [Confirm Claim]         │
└─────────────────────────────────────┘
```

**On confirm:**
```dart
Future<void> claimListing(String listingId, String donorId) async {
  await FirebaseFirestore.instance.runTransaction((transaction) async {
    // 1. Read listing — ensure still available
    final listingRef = FirebaseFirestore.instance
        .collection('foodListings').doc(listingId);
    final listing = await transaction.get(listingRef);

    if (listing.data()?['status'] != 'available') {
      throw Exception('This food has already been claimed.');
    }

    // 2. Update listing status
    transaction.update(listingRef, {
      'status': 'claimed',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 3. Create claim document
    final claimRef = FirebaseFirestore.instance
        .collection('claims').doc();
    transaction.set(claimRef, {
      'listingId':      listingId,
      'donorId':        donorId,
      'distributorId':  currentUser.uid,
      'status':         'pending',
      'claimedAt':      FieldValue.serverTimestamp(),
      'createdAt':      FieldValue.serverTimestamp(),
      'updatedAt':      FieldValue.serverTimestamp(),
    });
  });

  // 4. Send push notification to donor
  await NotificationService.sendClaimNotification(donorId, listingId);
}
```

## Donor: Review Claim Screen

When donor opens a listing with "claimed" status:

**Shows:**
- Claimant info: organization name, type, people served, has vehicle?, distance
- Claim timestamp
- Action buttons: **Confirm** / **Reject**

**On Confirm:**
```dart
transaction.update(listingRef, {'status': 'confirmed'});
transaction.update(claimRef, {'status': 'confirmed', 'respondedAt': now});
// Notification to distributor: "Your claim has been confirmed! Pickup details..."
```

**On Reject:**
```dart
transaction.update(listingRef, {'status': 'available'});
transaction.update(claimRef, {'status': 'rejected', 'respondedAt': now});
// Notification to distributor: "Your claim was unfortunately rejected."
```

## Distributor: My Claims Screen

**Tabs:**
- **Active** — Pending, Confirmed claims
- **Completed** — Picked Up, Completed
- **Rejected** — Rejected

**Each claim card:**
- Food photo thumbnail
- Listing title
- Status badge (colored)
- Donor name + distance
- Action button if applicable:
  - **Confirmed** → "Mark Picked Up"
  - **Pending** → "Awaiting confirmation..."
  - **Completed/Rejected** → Read-only

**Mark Picked Up:**
```dart
transaction.update(listingRef, {'status': 'picked_up'});
transaction.update(claimRef, {'status': 'picked_up', 'pickedUpAt': now});
// Notification to donor: "Distributor has picked up the food!"
```

## Donor: Mark Completed

Donor sees "picked_up" status on their listing:

```dart
transaction.update(listingRef, {'status': 'completed'});
transaction.update(claimRef, {'status': 'completed', 'completedAt': now});
// Notification to distributor: "Pickup completed! Thank you for reducing food waste."
```

## Contact Between Parties

For MVP, after confirmation, both parties can see each other's phone numbers:

- **Donor view (confirmed):** "Distributor: [Org Name] — [Phone]"
- **Distributor view (confirmed):** "Donor: [Name] — [Phone] — [Address]"

This keeps it simple without in-app chat. They can call/SMS directly.

## Edge Cases

| Case | Handling |
|------|----------|
| Distributor doesn't show up | No built-in penalty for MVP. Donor can mark as "cancelled" and re-list |
| Distributor claims but can't pick up | Can't cancel claim in MVP — call donor directly (phone shared on confirm) |
| Donor never responds to claim | No auto-timeout in MVP. Distributor sees "pending" until donor acts |
| Multiple claims on same listing | Firestore transaction ensures only one succeeds |
| Listing expires while claim is pending | Auto-cancel claim, mark listing expired, notify both parties |
