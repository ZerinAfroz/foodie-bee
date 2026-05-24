# 08 — Notifications

## Overview

Push notifications keep both donors and distributors informed of important state changes. Firebase Cloud Messaging (FCM) handles push delivery. Notifications are also stored in Firestore for an in-app notification list.

## Architecture

```
App (Flutter) ──register device token──→ Firestore (users/{uid}/fcmToken)
                         │
Action happens (claim, confirm, etc.)
  ↓
App writes to Firestore
  ↓
Cloud Function (or direct send via Firebase Admin SDK)
  sends FCM push to target user's device
  ↓
App receives push → display notification
  ↓
App also writes notification document to Firestore
  for in-app notification list
```

For MVP, we'll send push notifications **directly from the client app** using Firebase Cloud Functions later for reliability.

## Direct Push from Client (MVP Approach)

Use Firebase Admin SDK via a Cloud Function HTTP callable, OR for MVP simplicity, use **FCM HTTP v1 API** from a lightweight Firebase Function.

**Better MVP approach:** Store notifications in Firestore, and use Firebase's **FCM notifications** triggered from Cloud Functions.

### Cloud Function: Send Notification

```javascript
// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendNotification = functions.firestore
  .document('notifications/{notifId}')
  .onCreate(async (snap, context) => {
    const notif = snap.data();

    // Get user's FCM token
    const userDoc = await admin.firestore()
      .collection('users').doc(notif.userId).get();
    const fcmToken = userDoc.data()?.fcmToken;
    if (!fcmToken) return;

    const message = {
      token: fcmToken,
      notification: {
        title: notif.title,
        body: notif.body,
      },
      data: {
        type: notif.type,
        listingId: notif.listingId ?? '',
        claimId: notif.claimId ?? '',
      },
      android: {
        priority: 'high',
      },
    };

    try {
      await admin.messaging().send(message);
    } catch (error) {
      console.error('FCM send failed:', error);
    }
  });
```

## Notification Types

| Type | Trigger | Sent To | Title | Body |
|------|---------|---------|-------|------|
| `claim_received` | Distributor claims | Donor | "New Claim" | "[Org] wants to pick up [food title]" |
| `claim_confirmed` | Donor confirms | Distributor | "Claim Confirmed" | "Your claim for [food title] has been confirmed. Contact [donor] at [phone]" |
| `claim_rejected` | Donor rejects | Distributor | "Claim Rejected" | "Your claim for [food title] was not accepted" |
| `pickup_completed` | Distributor picks up | Donor | "Food Picked Up" | "[Org] has picked up the food. Confirm completion." |
| `pickup_confirmed` | Donor marks completed | Distributor | "Pickup Complete" | "Pickup for [food title] is complete. Thank you!" |

## Client: FCM Setup

```dart
// In main.dart or a setup service
Future<void> setupFCM() async {
  // Request permission (Android 13+)
  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Get FCM token
  final token = await messaging.getToken();
  await _saveTokenToFirestore(token);

  // Listen for token refresh
  messaging.onTokenRefresh.listen((newToken) {
    _saveTokenToFirestore(newToken);
  });

  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    _showLocalNotification(message);
    _refreshNotificationList();
  });

  // Handle background tap → open specific screen
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    _navigateToScreen(message.data);
  });

  // Handle app opened from terminated state via notification
  final initialMessage = await messaging.getInitialMessage();
  if (initialMessage != null) {
    _navigateToScreen(initialMessage.data);
  }
}

Future<void> _saveTokenToFirestore(String token) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;
  await FirebaseFirestore.instance
      .collection('users').doc(uid)
      .update({'fcmToken': token});
}
```

## Local Notification Display (Foreground)

When app is in foreground, FCM messages don't show system notifications automatically. Use `flutter_local_notifications`:

```dart
Future<void> _showLocalNotification(RemoteMessage message) async {
  const androidDetails = AndroidNotificationDetails(
    'foodshare_channel',
    'FoodShare Notifications',
    importance: Importance.high,
    priority: Priority.high,
  );
  const details = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    message.notification.hashCode,
    message.notification?.title,
    message.notification?.body,
    details,
  );
}
```

## In-App Notification List

Store notifications in Firestore for the notification screen:

```dart
Stream<List<NotificationItem>> getNotifications(String userId) {
  return FirebaseFirestore.instance
      .collection('notifications')
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => NotificationItem.fromFirestore(doc))
          .toList());
}
```

**Notification Screen:**
- List of notification cards
- Unread = bold, read = normal
- Tap → mark as read → navigate to relevant screen (listing detail or claim detail)

## Data Model

```dart
class NotificationItem {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;       // claim_received, claim_confirmed, etc.
  final String? listingId;
  final String? claimId;
  final bool isRead;
  final Timestamp createdAt;

  // Factory from Firestore doc
  // Method: markAsRead() → update Firestore
}
```

## Edge Cases

| Case | Handling |
|------|----------|
| User denies notification permission | No push. App relies on in-app notification badge |
| FCM token changes | `onTokenRefresh` listener updates Firestore |
| User logged out | Clear FCM token from Firestore document |
| Multiple devices | Store only last token for MVP; store token array in v2 |
| Notification arrives but screen is already showing that listing | Just show a snackbar, no duplication |
