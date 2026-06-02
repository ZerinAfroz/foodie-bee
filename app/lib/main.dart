import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'config/constants.dart';
import 'providers/auth_provider.dart';
import 'providers/food_listing_provider.dart';
import 'providers/chat_provider.dart';
import 'services/notification_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FoodListingProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: const FoodieBeeApp(),
    ),
  );

  NotificationService.instance.init(navigatorKey: navigatorKey);

  Timer.periodic(const Duration(seconds: 60), (_) async {
    final provider = FoodListingProvider();
    await provider.expirePastDeadlines();
  });
}

class FoodieBeeApp extends StatelessWidget {
  const FoodieBeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: AppTheme.lightTheme,
      initialRoute: Routes.splash,
      onGenerateRoute: Routes.generateRoute,
    );
  }
}
