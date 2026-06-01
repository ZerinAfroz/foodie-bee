import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';
import '../config/routes.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  GlobalKey<NavigatorState>? _navigatorKey;
  String? _currentToken;
  int _notificationId = 0;

  void init({required GlobalKey<NavigatorState> navigatorKey}) {
    _navigatorKey = navigatorKey;
    _setupLocalNotifications();
    _setupFCM();
  }

  Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );
  }

  Future<void> _setupFCM() async {
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    _currentToken = await messaging.getToken();
    if (_currentToken != null) _saveToken(_currentToken!);

    messaging.onTokenRefresh.listen((token) {
      _currentToken = token;
      _saveToken(token);
    });

    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null && _currentToken != null) {
        _saveToken(_currentToken!);
      }
    });

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleRemoteMessage(initialMessage.data);
      });
    }
  }

  Future<void> _saveToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection(AppConstants.collectionUsers)
        .doc(uid)
        .set({'fcmToken': token}, SetOptions(merge: true));
  }

  void _onForegroundMessage(RemoteMessage message) async {
    final title = message.notification?.title ?? AppConstants.appName;
    final body = message.notification?.body ?? '';
    if (title.isEmpty && body.isEmpty) return;

    const androidDetails = AndroidNotificationDetails(
      'foodie_bee_channel',
      AppConstants.notificationChannelName,
      channelDescription: AppConstants.notificationChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      id: _notificationId++,
      title: title,
      body: body,
      notificationDetails: details,
      payload: jsonEncode(message.data),
    );
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    _handleRemoteMessage(message.data);
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    if (response.payload == null) return;
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      _handleRemoteMessage(data);
    } catch (_) {}
  }

  void _handleRemoteMessage(Map<String, dynamic> data) {
    final navigator = _navigatorKey?.currentState;
    if (navigator == null) return;

    final listingId = data['listingId'] as String?;
    final type = data['type'] as String? ?? '';

    if (listingId != null && listingId.isNotEmpty) {
      final viewMode = (type == 'claim_received' || type == 'pickup_completed')
          ? 'donor'
          : 'distributor';
      navigator.pushNamed(Routes.listingDetail, arguments: {
        'listingId': listingId,
        'viewMode': viewMode,
      });
    }
  }

  Future<void> clearToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection(AppConstants.collectionUsers)
        .doc(uid)
        .update({'fcmToken': FieldValue.delete()});
  }

  Stream<int> unreadCount(String userId) {
    return FirebaseFirestore.instance
        .collection(AppConstants.collectionNotifications)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }
}
