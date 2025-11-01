/// Enum representing the status of a driver
enum DriverStatus {
  /// Driver is offline/not available
  offline,
  
  /// Driver is online and available for rides
  idle,
  
  /// Driver is currently on a ride
  busy;

  /// Get display name for driver status
  String get displayName {
    switch (this) {
      case DriverStatus.offline:
        return 'Offline';
      case DriverStatus.idle:
        return 'Available';
      case DriverStatus.busy:
        return 'On a Ride';
    }
  }

  /// Get description for driver status
  String get description {
    switch (this) {
      case DriverStatus.offline:
        return 'You are not available for rides';
      case DriverStatus.idle:
        return 'You are online and available';
      case DriverStatus.busy:
        return 'You are currently on a ride';
    }
  }

  /// Get color for driver status
  String get colorHex {
    switch (this) {
      case DriverStatus.offline:
        return '#9E9E9E'; // Grey
      case DriverStatus.idle:
        return '#4CAF50'; // Green
      case DriverStatus.busy:
        return '#FFA500'; // Orange
    }
  }

  /// Parse from string (from Firestore)
  static DriverStatus fromString(String value) {
    return DriverStatus.values.firstWhere(
      (status) => status.name.toLowerCase() == value.toLowerCase(),
      orElse: () => DriverStatus.offline,
    );
  }

  /// Convert to string (for Firestore)
  String toFirestore() {
    // Use capitalized first letter for backward compatibility
    return name[0].toUpperCase() + name.substring(1);
  }

  /// Check if driver is available for rides
  bool get isAvailable => this == DriverStatus.idle;

  /// Check if driver is online (idle or busy)
  bool get isOnline => this == DriverStatus.idle || this == DriverStatus.busy;
}

