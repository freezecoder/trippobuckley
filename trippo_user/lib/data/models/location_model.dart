/// Model representing a location with coordinates and address information
class LocationModel {
  final String? humanReadableAddress;
  final String? locationName;
  final String? locationId;
  final double? locationLongitude;
  final double? locationLatitude;

  LocationModel({
    this.humanReadableAddress,
    this.locationName,
    this.locationId,
    this.locationLongitude,
    this.locationLatitude,
  });

  /// Create from JSON
  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      humanReadableAddress: json['humanReadableAddress'] as String?,
      locationName: json['locationName'] as String?,
      locationId: json['locationId'] as String?,
      locationLongitude: json['locationLongitude'] as double?,
      locationLatitude: json['locationLatitude'] as double?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'humanReadableAddress': humanReadableAddress,
      'locationName': locationName,
      'locationId': locationId,
      'locationLongitude': locationLongitude,
      'locationLatitude': locationLatitude,
    };
  }

  /// Check if location has valid coordinates
  bool get hasValidCoordinates {
    return locationLatitude != null && 
           locationLongitude != null &&
           locationLatitude != 0.0 &&
           locationLongitude != 0.0;
  }

  /// Get display text for location
  String get displayText {
    return locationName ?? humanReadableAddress ?? 'Unknown Location';
  }

  /// Copy with method
  LocationModel copyWith({
    String? humanReadableAddress,
    String? locationName,
    String? locationId,
    double? locationLongitude,
    double? locationLatitude,
  }) {
    return LocationModel(
      humanReadableAddress: humanReadableAddress ?? this.humanReadableAddress,
      locationName: locationName ?? this.locationName,
      locationId: locationId ?? this.locationId,
      locationLongitude: locationLongitude ?? this.locationLongitude,
      locationLatitude: locationLatitude ?? this.locationLatitude,
    );
  }

  @override
  String toString() {
    return 'LocationModel(name: $locationName, lat: $locationLatitude, lng: $locationLongitude)';
  }
}

// Keep old name for backward compatibility during migration
typedef Direction = LocationModel;

