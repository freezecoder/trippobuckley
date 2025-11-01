/// Application-wide constants
class AppConstants {
  // App Info
  static const String appName = 'BTrips';
  static const String appVersion = '2.0.0';
  static const String appDescription = 'Unified ride-hailing app for users and drivers';

  // Map Constants
  static const double defaultMapZoom = 14.0;
  static const double defaultMapTilt = 0.0;
  static const double defaultMapBearing = 0.0;
  static const double driverSearchRadiusKm = 5.0;
  static const int maxNearbyDrivers = 20;

  // Location Constants
  static const double locationAccuracyThresholdMeters = 100.0;
  static const int locationUpdateIntervalSeconds = 10;
  static const int locationUpdateDistanceMeters = 10;

  // Time Constants
  static const int splashScreenDurationSeconds = 2;
  static const int notificationTimeoutSeconds = 30;
  static const int rideRequestTimeoutSeconds = 120;

  // Fare Calculation
  static const double baseFare = 2.50;
  static const double perKmRate = 1.50;
  static const double perMinuteRate = 0.25;
  static const double minimumFare = 5.00;
  static const double maxFare = 500.00;

  // Vehicle Type Multipliers
  static const double sedanMultiplier = 1.0;
  static const double suvMultiplier = 1.5;
  static const double luxurySuvMultiplier = 2.0;

  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 32;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const String emailRegex = r'^[^@]+@[^@]+\.[^@]+$';
  static const String phoneRegex = r'^\+?[\d\s\-()]+$';

  // Map Style
  static const String mapStyleDark = 'assets/map_styles/dark_map_style.json';

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 400);
  static const Duration longAnimationDuration = Duration(milliseconds: 600);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Error Messages
  static const String genericErrorMessage = 'Something went wrong. Please try again.';
  static const String networkErrorMessage = 'No internet connection. Please check your network.';
  static const String locationErrorMessage = 'Unable to get your location. Please enable location services.';
  static const String authErrorMessage = 'Authentication failed. Please try again.';
  static const String permissionDeniedMessage = 'Permission denied. Please grant the required permissions.';

  // Success Messages
  static const String rideRequestedMessage = 'Ride requested successfully!';
  static const String rideAcceptedMessage = 'Ride accepted!';
  static const String rideCompletedMessage = 'Ride completed!';
  static const String profileUpdatedMessage = 'Profile updated successfully!';

  // Storage Keys (SharedPreferences)
  static const String keyUserType = 'user_type';
  static const String keyUserId = 'user_id';
  static const String keyIsFirstLaunch = 'is_first_launch';
  static const String keyLastKnownLat = 'last_known_lat';
  static const String keyLastKnownLng = 'last_known_lng';
  static const String keyPreferredLanguage = 'preferred_language';
  static const String keyThemeMode = 'theme_mode';
}

