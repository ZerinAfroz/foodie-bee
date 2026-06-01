class AppConstants {
  static const String appName = 'Foodie Bee';

  static const String bdPhoneRegex = r'^01[3-9]\d{8}$';

  static const String collectionUsers = 'users';
  static const String collectionFoodListings = 'foodListings';
  static const String collectionClaims = 'claims';
  static const String collectionNotifications = 'notifications';

  static const double defaultPadding = 16.0;
  static const double defaultRadius = 12.0;
  static const double smallPadding = 8.0;

  static const List<String> businessTypes = [
    'restaurant',
    'hotel',
    'catering',
    'bakery',
    'supermarket',
    'event_hall',
    'other',
  ];

  static const List<String> organizationTypes = [
    'orphanage',
    'shelter',
    'madrasa',
    'mosque',
    'community_kitchen',
    'ngo',
    'other',
  ];

  static const List<String> foodTypes = [
    'cooked',
    'raw',
    'packaged',
    'bakery',
    'fruits_veg',
    'other',
  ];

  static const List<String> quantityUnits = ['kg', 'pieces', 'plates', 'liters'];

  static const Map<String, String> foodListingStatusLabels = {
    'available': 'Available',
    'claimed': 'Claimed',
    'confirmed': 'Confirmed',
    'picked_up': 'Picked Up',
    'completed': 'Completed',
    'expired': 'Expired',
    'cancelled': 'Cancelled',
  };

  static const Map<String, String> claimStatusLabels = {
    'pending': 'Pending',
    'confirmed': 'Confirmed',
    'rejected': 'Rejected',
    'picked_up': 'Picked Up',
    'completed': 'Completed',
  };

  static const String msgNoListings = 'No listings yet';
  static const String msgNoClaims = 'No claims yet';
  static const String msgNoNotifications = 'No notifications yet';
  static const String msgSomethingWentWrong = 'Something went wrong';
  static const String msgNoListingsCta = 'Post your first listing';
  static const String msgNoClaimsCta = 'Find food to claim';

  static const String btnCancel = 'Cancel';
  static const String btnConfirm = 'Confirm';
  static const String btnRetry = 'Retry';
  static const String btnSave = 'Save Profile';
  static const String btnContinue = 'Continue';
  static const String btnLogOut = 'Log out';
  static const String btnPostListing = 'Post Listing';
  static const String btnSendOtp = 'Send OTP';
  static const String btnVerify = 'Verify';
  static const String btnResend = 'Resend';

  static const String notificationChannelName = 'Foodie Bee Notifications';
  static const String notificationChannelDescription =
      'Notifications about food claims and pickups';
}
