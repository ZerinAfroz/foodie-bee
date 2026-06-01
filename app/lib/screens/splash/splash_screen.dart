import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../providers/food_listing_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _status = 'Loading...';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    setState(() {
      _hasError = false;
      _status = 'Loading...';
    });

    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      context.read<FoodListingProvider>().expirePastDeadlines();
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _navigate(Routes.phoneAuth);
      return;
    }

    setState(() => _status = 'Loading profile...');

    try {
      final doc = await FirebaseFirestore.instance
          .collection(AppConstants.collectionUsers)
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 10));

      if (!doc.exists) {
        _navigate(Routes.roleSelection);
        return;
      }

      final role = doc.data()?['role'] as String?;
      if (role == 'donor') {
        _navigate(Routes.donorHome);
      } else {
        _navigate(Routes.distributorHome);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _status = AppConstants.msgSomethingWentWrong;
        });
      }
    }
  }

  void _navigate(String route) {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 80,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connecting surplus food with those who need it',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 32),
            if (_hasError) ...[
              Text(
                _status,
                style: TextStyle(color: AppTheme.errorColor, fontSize: 14),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _checkAuth,
                child: const Text(AppConstants.btnRetry),
              ),
            ] else ...[
              Text(
                _status,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
}
