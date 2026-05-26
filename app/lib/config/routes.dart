import 'package:flutter/material.dart';
import '../screens/splash/splash_screen.dart';

class Routes {
  static const String splash = '/';
  static const String phoneAuth = '/phone-auth';
  static const String otp = '/otp';
  static const String roleSelection = '/role-selection';
  static const String donorProfile = '/donor-profile';
  static const String distributorProfile = '/distributor-profile';
  static const String donorHome = '/donor-home';
  static const String distributorHome = '/distributor-home';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case phoneAuth:
        return MaterialPageRoute(
          builder: (_) => _placeholder('Phone Auth'),
        );
      case otp:
        return MaterialPageRoute(
          builder: (_) => _placeholder('OTP Verification'),
        );
      case roleSelection:
        return MaterialPageRoute(
          builder: (_) => _placeholder('Role Selection'),
        );
      case donorProfile:
        return MaterialPageRoute(
          builder: (_) => _placeholder('Donor Profile'),
        );
      case distributorProfile:
        return MaterialPageRoute(
          builder: (_) => _placeholder('Distributor Profile'),
        );
      case donorHome:
        return MaterialPageRoute(
          builder: (_) => _placeholder('Donor Home'),
        );
      case distributorHome:
        return MaterialPageRoute(
          builder: (_) => _placeholder('Distributor Home'),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => _placeholder('Unknown Route'),
        );
    }
  }

  static Scaffold _placeholder(String title) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(
        child: Text('Coming soon'),
      ),
    );
  }
}
