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
}
