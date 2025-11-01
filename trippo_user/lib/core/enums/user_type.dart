/// Enum representing the type of user in the BTrips system
enum UserType {
  /// Regular user/passenger who books rides
  user,
  
  /// Driver who provides rides
  driver;

  /// Get display name for user type
  String get displayName {
    switch (this) {
      case UserType.user:
        return 'Passenger';
      case UserType.driver:
        return 'Driver';
    }
  }

  /// Get description for user type
  String get description {
    switch (this) {
      case UserType.user:
        return 'Book rides and travel comfortably';
      case UserType.driver:
        return 'Drive and earn money';
    }
  }

  /// Get icon name for user type
  String get iconName {
    switch (this) {
      case UserType.user:
        return 'person';
      case UserType.driver:
        return 'local_taxi';
    }
  }

  /// Parse from string (from Firestore)
  static UserType fromString(String value) {
    return UserType.values.firstWhere(
      (type) => type.name == value.toLowerCase(),
      orElse: () => UserType.user,
    );
  }

  /// Convert to string (for Firestore)
  String toFirestore() => name;
}

