/// Firebase Firestore collection and field name constants
class FirebaseConstants {
  // Collections
  static const String usersCollection = 'users';
  static const String driversCollection = 'drivers';
  static const String userProfilesCollection = 'userProfiles';
  static const String rideRequestsCollection = 'rideRequests';
  static const String rideHistoryCollection = 'rideHistory';
  static const String presetLocationsCollection = 'presetLocations';
  
  // Stripe Collections
  static const String stripeCustomersCollection = 'stripeCustomers';
  static const String stripePaymentIntentsCollection = 'stripePaymentIntents';
  static const String stripeTransactionsCollection = 'stripeTransactions';

  // User Fields
  static const String userEmail = 'email';
  static const String userName = 'name';
  static const String userType = 'userType';
  static const String userPhoneNumber = 'phoneNumber';
  static const String userCreatedAt = 'createdAt';
  static const String userLastLogin = 'lastLogin';
  static const String userIsActive = 'isActive';
  static const String userFcmToken = 'fcmToken';
  static const String userProfileImageUrl = 'profileImageUrl';

  // Driver Fields
  static const String driverCarName = 'carName';
  static const String driverCarPlateNum = 'carPlateNum';
  static const String driverCarType = 'carType';
  static const String driverRate = 'rate';
  static const String driverStatus = 'driverStatus';
  static const String driverLoc = 'driverLoc';
  static const String driverGeohash = 'geohash';
  static const String driverRating = 'rating';
  static const String driverTotalRides = 'totalRides';
  static const String driverEarnings = 'earnings';
  static const String driverLicenseNumber = 'licenseNumber';
  static const String driverVehicleRegistration = 'vehicleRegistration';
  static const String driverIsVerified = 'isVerified';

  // User Profile Fields
  static const String profileHomeAddress = 'homeAddress';
  static const String profileWorkAddress = 'workAddress';
  static const String profileFavoriteLocations = 'favoriteLocations';
  static const String profilePaymentMethods = 'paymentMethods';
  static const String profilePreferences = 'preferences';

  // Ride Request Fields
  static const String rideUserId = 'userId';
  static const String rideDriverId = 'driverId';
  static const String rideUserEmail = 'userEmail';
  static const String rideDriverEmail = 'driverEmail';
  static const String rideStatus = 'status';
  static const String ridePickupLocation = 'pickupLocation';
  static const String ridePickupAddress = 'pickupAddress';
  static const String rideDropoffLocation = 'dropoffLocation';
  static const String rideDropoffAddress = 'dropoffAddress';
  static const String rideScheduledTime = 'scheduledTime';
  static const String rideRequestedAt = 'requestedAt';
  static const String rideAcceptedAt = 'acceptedAt';
  static const String rideStartedAt = 'startedAt';
  static const String rideCompletedAt = 'completedAt';
  static const String rideVehicleType = 'vehicleType';
  static const String rideFare = 'fare';
  static const String rideDistance = 'distance';
  static const String rideDuration = 'duration';
  static const String rideRoute = 'route';

  // Ride History Additional Fields
  static const String rideUserRating = 'userRating';
  static const String rideDriverRating = 'driverRating';
  static const String rideUserFeedback = 'userFeedback';
  static const String rideDriverFeedback = 'driverFeedback';

  // FCM Topics
  static const String fcmDriversTopic = 'drivers';
  static const String fcmUsersTopic = 'users';
  static const String fcmAllTopic = 'all';

  // Default Values
  static const double defaultDriverRate = 3.0;
  static const double defaultRating = 5.0;
  static const int defaultTotalRides = 0;
  static const double defaultEarnings = 0.0;

  // Vehicle Types
  static const String vehicleTypeSedan = 'Sedan';
  static const String vehicleTypeSUV = 'SUV';
  static const String vehicleTypeLuxurySUV = 'Luxury SUV';

  // Preset Location Fields
  static const String presetLocationName = 'name';
  static const String presetLocationPlaceId = 'placeId';
  static const String presetLocationLatitude = 'latitude';
  static const String presetLocationLongitude = 'longitude';
  
  // Stripe Customer Fields
  static const String stripeCustomerId = 'stripeCustomerId';
  static const String stripeBillingAddress = 'billingAddress';
  static const String stripeDefaultPaymentMethod = 'defaultPaymentMethodId';
  
  // Payment Method Fields
  static const String paymentMethodId = 'id';
  static const String paymentMethodType = 'type';
  static const String paymentMethodLast4 = 'last4';
  static const String paymentMethodBrand = 'brand';
  static const String paymentMethodExpiry = 'expiryMonth';
  static const String paymentMethodStripeId = 'stripePaymentMethodId';
  static const String presetLocationCategory = 'category';
  static const String presetLocationIsActive = 'isActive';
  static const String presetLocationOrder = 'order';
  static const String presetLocationCreatedAt = 'createdAt';

  // Query Limits
  static const int nearbyDriversLimit = 20;
  static const int rideHistoryLimit = 50;
  static const double nearbyDriversRadiusKm = 5.0;
}

