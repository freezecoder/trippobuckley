/// Route name constants for navigation
class RouteNames {
  // Splash & Onboarding
  static const String splash = '/';
  static const String onboarding = '/onboarding';

  // Authentication
  static const String roleSelection = '/role-selection';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Driver Routes
  static const String driverConfig = '/driver-config';
  static const String driverMain = '/driver';
  static const String driverHome = '/driver/home';
  static const String driverPayments = '/driver/payments';
  static const String driverHistory = '/driver/history';
  static const String driverProfile = '/driver/profile';
  static const String driverSettings = '/driver/settings';
  static const String driverEarnings = '/driver/earnings';
  static const String driverRideDetails = '/driver/ride-details';

  // User Routes
  static const String userMain = '/user';
  static const String userHome = '/user/home';
  static const String userProfile = '/user/profile';
  static const String userSettings = '/user/settings';
  static const String userRideHistory = '/user/ride-history';
  static const String userRideDetails = '/user/ride-details';
  static const String whereTo = '/user/where-to';
  static const String editProfile = '/user/edit-profile';
  static const String paymentMethods = '/user/payment-methods';
  static const String addPaymentMethod = '/user/add-payment-method';
  static const String helpSupport = '/user/help-support';
  static const String savedPlaces = '/user/saved-places';
  static const String notifications = '/user/notifications';

  // Shared Routes
  static const String rideTracking = '/ride-tracking';
  static const String ratingScreen = '/rating';
  static const String reportIssue = '/report-issue';
  static const String termsAndConditions = '/terms';
  static const String privacyPolicy = '/privacy';
  static const String about = '/about';
}

/// Route paths for programmatic navigation
class RoutePaths {
  // These are used for route matching and can include parameters
  static const String splashPath = '/';
  static const String roleSelectionPath = '/role-selection';
  static const String loginPath = '/login';
  static const String registerPath = '/register';
  
  // Driver paths
  static const String driverConfigPath = '/driver-config';
  static const String driverMainPath = '/driver';
  static const String driverHomePath = '/driver/home';
  
  // User paths
  static const String userMainPath = '/user';
  static const String userHomePath = '/user/home';
  static const String whereToPath = '/user/where-to';
  
  // Parameterized paths
  static const String rideDetailsPath = '/ride-details/:rideId';
  static const String userRideDetailsPath = '/user/ride-details/:rideId';
  static const String driverRideDetailsPath = '/driver/ride-details/:rideId';
}

