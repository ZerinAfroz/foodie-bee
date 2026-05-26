import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  Future<String> sendOTP({
    required String phone,
    int? resendToken,
  }) async {
    final completer = Completer<String>();
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (_) {},
      verificationFailed: (e) => completer.completeError(e),
      codeSent: (verificationId, _) => completer.complete(verificationId),
      codeAutoRetrievalTimeout: (_) {},
      timeout: const Duration(seconds: 60),
      forceResendingToken: resendToken,
    );
    return completer.future;
  }

  Future<UserCredential> verifyOTP(
    String verificationId,
    String smsCode,
  ) async {
    return FirebaseAuth.instance.signInWithCredential(
      PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      ),
    );
  }

  User? get currentUser => FirebaseAuth.instance.currentUser;

  Future<void> logout() => FirebaseAuth.instance.signOut();
}
