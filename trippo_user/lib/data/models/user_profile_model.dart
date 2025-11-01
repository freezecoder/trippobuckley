/// Model representing user profile information for regular users (passengers)
class UserProfileModel {
  final String uid;
  final String homeAddress;
  final String workAddress;
  final List<String> favoriteLocations;
  final List<String> paymentMethods;
  final Map<String, dynamic> preferences;
  final int totalRides;
  final double rating;

  UserProfileModel({
    required this.uid,
    this.homeAddress = '',
    this.workAddress = '',
    this.favoriteLocations = const [],
    this.paymentMethods = const [],
    this.preferences = const {},
    this.totalRides = 0,
    this.rating = 5.0,
  });

  /// Create UserProfileModel from Firestore document
  factory UserProfileModel.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserProfileModel(
      uid: uid,
      homeAddress: data['homeAddress'] ?? '',
      workAddress: data['workAddress'] ?? '',
      favoriteLocations: List<String>.from(data['favoriteLocations'] ?? []),
      paymentMethods: List<String>.from(data['paymentMethods'] ?? []),
      preferences: Map<String, dynamic>.from(data['preferences'] ?? {}),
      totalRides: data['totalRides'] ?? 0,
      rating: (data['rating'] ?? 5.0).toDouble(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'homeAddress': homeAddress,
      'workAddress': workAddress,
      'favoriteLocations': favoriteLocations,
      'paymentMethods': paymentMethods,
      'preferences': preferences,
      'totalRides': totalRides,
      'rating': rating,
    };
  }

  /// Get preference value
  T? getPreference<T>(String key, {T? defaultValue}) {
    return preferences[key] as T? ?? defaultValue;
  }

  /// Check if notifications are enabled
  bool get notificationsEnabled => 
      getPreference<bool>('notifications', defaultValue: true) ?? true;

  /// Get preferred language
  String get language => 
      getPreference<String>('language', defaultValue: 'en') ?? 'en';

  /// Get preferred theme
  String get theme => 
      getPreference<String>('theme', defaultValue: 'dark') ?? 'dark';

  /// Copy with method for immutability
  UserProfileModel copyWith({
    String? homeAddress,
    String? workAddress,
    List<String>? favoriteLocations,
    List<String>? paymentMethods,
    Map<String, dynamic>? preferences,
    int? totalRides,
    double? rating,
  }) {
    return UserProfileModel(
      uid: uid,
      homeAddress: homeAddress ?? this.homeAddress,
      workAddress: workAddress ?? this.workAddress,
      favoriteLocations: favoriteLocations ?? this.favoriteLocations,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      preferences: preferences ?? this.preferences,
      totalRides: totalRides ?? this.totalRides,
      rating: rating ?? this.rating,
    );
  }

  @override
  String toString() {
    return 'UserProfileModel(uid: $uid, totalRides: $totalRides, rating: $rating)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfileModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}

