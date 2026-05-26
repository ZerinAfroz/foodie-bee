import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF4CAF50);
  static const Color secondaryColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);
  static const Color backgroundColor = Color(0xFFF5F5F5);

  static const Color statusAvailable = Color(0xFF4CAF50);
  static const Color statusClaimed = Color(0xFFFF9800);
  static const Color statusConfirmed = Color(0xFF2196F3);
  static const Color statusPickedUp = Color(0xFF9C27B0);
  static const Color statusCompleted = Color(0xFF607D8B);
  static const Color statusExpired = Color(0xFF9E9E9E);
  static const Color statusRejected = Color(0xFFF44336);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
    );
  }
}
