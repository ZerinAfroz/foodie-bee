import 'package:flutter/material.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/phone_auth_screen.dart';
import '../screens/auth/role_selection_screen.dart';
import '../screens/profile/donor_profile_screen.dart';
import '../screens/profile/distributor_profile_screen.dart';
import '../screens/donor/donor_home_screen.dart';
import '../screens/distributor/distributor_home_screen.dart';
import '../screens/distributor/map_discovery_screen.dart';
import '../screens/distributor/my_claims_screen.dart';
import '../screens/food_listing/post_listing_screen.dart';
import '../screens/food_listing/my_listings_screen.dart';
import '../screens/food_listing/listing_detail_screen.dart';
import '../screens/notifications/notifications_screen.dart';

class Routes {
  static const String splash = '/';
  static const String phoneAuth = '/phone-auth';
  static const String otp = '/otp';
  static const String roleSelection = '/role-selection';
  static const String donorProfile = '/donor-profile';
  static const String distributorProfile = '/distributor-profile';
  static const String donorHome = '/donor-home';
  static const String distributorHome = '/distributor-home';
  static const String postListing = '/post-listing';
  static const String myListings = '/my-listings';
  static const String listingDetail = '/listing-detail';
  static const String mapDiscovery = '/map-discovery';
  static const String myClaims = '/my-claims';
  static const String notifications = '/notifications';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case phoneAuth:
        return MaterialPageRoute(
          builder: (_) => const PhoneAuthScreen(),
        );
      case otp:
        return MaterialPageRoute(
          builder: (_) => _placeholder('OTP Verification'),
        );
      case roleSelection:
        return MaterialPageRoute(
          builder: (_) => const RoleSelectionScreen(),
        );
      case donorProfile:
        return MaterialPageRoute(
          builder: (_) => const DonorProfileScreen(),
        );
      case distributorProfile:
        return MaterialPageRoute(
          builder: (_) => const DistributorProfileScreen(),
        );
      case donorHome:
        return MaterialPageRoute(
          builder: (_) => const DonorHomeScreen(),
        );
      case distributorHome:
        return MaterialPageRoute(
          builder: (_) => const DistributorHomeScreen(),
        );
      case postListing:
        return MaterialPageRoute(
          builder: (_) => const PostListingScreen(),
        );
      case myListings:
        return MaterialPageRoute(
          builder: (_) => const MyListingsScreen(),
        );
      case listingDetail:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ListingDetailScreen(
            listingId: args['listingId'] as String,
            viewMode: args['viewMode'] as String? ?? 'donor',
          ),
        );
      case mapDiscovery:
        return MaterialPageRoute(
          builder: (_) => const MapDiscoveryScreen(),
        );
      case myClaims:
        return MaterialPageRoute(
          builder: (_) => const MyClaimsScreen(),
        );
      case notifications:
        return MaterialPageRoute(
          builder: (_) => const NotificationsScreen(),
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
