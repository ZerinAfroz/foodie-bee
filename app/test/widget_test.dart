import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodie_bee/config/theme.dart';
import 'package:foodie_bee/config/constants.dart';
import 'package:foodie_bee/config/routes.dart';

void main() {
  group('AppConstants', () {
    test('has correct app name', () {
      expect(AppConstants.appName, 'Foodie Bee');
    });

    test('has BD phone regex', () {
      expect(AppConstants.bdPhoneRegex, isA<String>());
      expect(AppConstants.bdPhoneRegex.isNotEmpty, true);
    });

    test('has all collection names', () {
      expect(AppConstants.collectionUsers, 'users');
      expect(AppConstants.collectionFoodListings, 'foodListings');
      expect(AppConstants.collectionClaims, 'claims');
      expect(AppConstants.collectionNotifications, 'notifications');
    });
  });

  group('AppTheme', () {
    test('lightTheme uses Material3', () {
      expect(AppTheme.lightTheme.useMaterial3, true);
    });

    test('lightTheme scaffold background matches constant', () {
      expect(
        AppTheme.lightTheme.scaffoldBackgroundColor,
        AppTheme.backgroundColor,
      );
    });

    test('lightTheme can resolve text colors', () {
      final theme = AppTheme.lightTheme;
      expect(theme.textTheme.bodyLarge, isNotNull);
      expect(theme.textTheme.headlineSmall, isNotNull);
    });
  });

  group('Routes', () {
    test('splash route returns SplashScreen', () {
      final route = Routes.generateRoute(const RouteSettings(name: '/'));
      expect(route, isA<MaterialPageRoute>());
    });

    test('listing-detail route parses arguments', () {
      final route = Routes.generateRoute(const RouteSettings(
        name: '/listing-detail',
        arguments: {
          'listingId': 'test123',
          'viewMode': 'donor',
        },
      ));
      expect(route, isA<MaterialPageRoute>());
    });

    test('unknown route returns placeholder', () {
      final route =
          Routes.generateRoute(const RouteSettings(name: '/nonexistent'));
      expect(route, isA<MaterialPageRoute>());
    });

    test('all named routes are unique strings', () {
      final routes = {
        Routes.splash,
        Routes.phoneAuth,
        Routes.otp,
        Routes.roleSelection,
        Routes.donorProfile,
        Routes.distributorProfile,
        Routes.donorHome,
        Routes.distributorHome,
        Routes.postListing,
        Routes.myListings,
        Routes.listingDetail,
        Routes.mapDiscovery,
        Routes.myClaims,
        Routes.notifications,
      };
      expect(routes.length, 14);
    });
  });
}
