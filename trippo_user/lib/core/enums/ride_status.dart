/// Enum representing the status of a ride request
enum RideStatus {
  /// Ride request created, waiting for driver
  pending,
  
  /// Driver has accepted the ride
  accepted,
  
  /// Ride is in progress
  ongoing,
  
  /// Ride has been completed
  completed,
  
  /// Ride was cancelled (by user or driver)
  cancelled;

  /// Get display name for ride status
  String get displayName {
    switch (this) {
      case RideStatus.pending:
        return 'Finding Driver';
      case RideStatus.accepted:
        return 'Driver Accepted';
      case RideStatus.ongoing:
        return 'In Progress';
      case RideStatus.completed:
        return 'Completed';
      case RideStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Get color for ride status
  String get colorHex {
    switch (this) {
      case RideStatus.pending:
        return '#FFA500'; // Orange
      case RideStatus.accepted:
        return '#2196F3'; // Blue
      case RideStatus.ongoing:
        return '#4CAF50'; // Green
      case RideStatus.completed:
        return '#9E9E9E'; // Grey
      case RideStatus.cancelled:
        return '#F44336'; // Red
    }
  }

  /// Parse from string (from Firestore)
  static RideStatus fromString(String value) {
    return RideStatus.values.firstWhere(
      (status) => status.name == value.toLowerCase(),
      orElse: () => RideStatus.pending,
    );
  }

  /// Convert to string (for Firestore)
  String toFirestore() => name;

  /// Check if ride is active (not completed or cancelled)
  bool get isActive =>
      this == RideStatus.pending ||
      this == RideStatus.accepted ||
      this == RideStatus.ongoing;

  /// Check if ride is finished
  bool get isFinished =>
      this == RideStatus.completed || this == RideStatus.cancelled;
}

