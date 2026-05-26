import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../config/constants.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? firebaseUser;
  DocumentSnapshot? userProfile;
  bool isLoading = false;
  int failedAttempts = 0;

  AuthProvider() {
    firebaseUser = _authService.currentUser;
    if (firebaseUser != null) {
      _checkProfile();
    }
  }

  Future<String> sendOTP(String phone) async {
    if (failedAttempts >= 3) {
      throw FirebaseAuthException(
        code: 'too-many-requests',
        message: 'Too many attempts. Try again later.',
      );
    }

    isLoading = true;
    notifyListeners();

    try {
      final vId = await _authService.sendOTP(phone: phone);
      failedAttempts = 0;
      return vId;
    } on FirebaseAuthException {
      failedAttempts++;
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyOTP(String verificationId, String smsCode) async {
    isLoading = true;
    notifyListeners();

    try {
      await _authService.verifyOTP(verificationId, smsCode);
      firebaseUser = _authService.currentUser;
      await _checkProfile();
      return true;
    } on FirebaseAuthException {
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _checkProfile() async {
    if (firebaseUser == null) return;
    final doc = await _firestore
        .collection(AppConstants.collectionUsers)
        .doc(firebaseUser!.uid)
        .get();
    userProfile = doc.exists ? doc : null;
  }

  bool get isLoggedIn => firebaseUser != null;
  bool get hasProfile => userProfile != null;
  String get role => userProfile?['role'] ?? '';

  Future<void> logout() async {
    await _authService.logout();
    firebaseUser = null;
    userProfile = null;
    failedAttempts = 0;
    notifyListeners();
  }
}
