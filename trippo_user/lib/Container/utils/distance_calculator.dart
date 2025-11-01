import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';

/// Reliable distance calculation utility that doesn't depend on Google Maps API
/// Uses Haversine formula for great-circle distance calculation
class DistanceCalculator {
  /// Earth's radius in meters
  static const double _earthRadiusMeters = 6371000; // 6,371 km

  /// Calculate straight-line distance between two coordinates using Haversine formula
  /// This is reliable and works on all platforms without external APIs
  /// Returns distance in meters
  static double calculateStraightLineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    try {
      // Use Geolocator's built-in distance calculation (uses Haversine)
      return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
    } catch (e) {
      // Fallback to manual Haversine calculation if Geolocator fails
      return _haversineDistance(lat1, lon1, lat2, lon2);
    }
  }

  /// Manual Haversine distance calculation (pure math, no dependencies)
  static double _haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    // Convert to radians
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return _earthRadiusMeters * c;
  }

  /// Convert degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  /// Estimate driving distance from straight-line distance
  /// Uses a multiplier to approximate actual road distance
  /// Typical multiplier is 1.2-1.5 for urban areas
  static double estimateDrivingDistance(
    double straightLineDistanceMeters, {
    double multiplier = 1.3, // 30% longer than straight line
  }) {
    return straightLineDistanceMeters * multiplier;
  }

  /// Estimate driving time based on distance
  /// Uses average speed (default 25 mph for urban, 45 mph for highways)
  static int estimateDrivingTimeSeconds(
    double distanceMeters, {
    double averageSpeedMph = 25.0,
  }) {
    // Convert speed from mph to m/s
    final speedMs = (averageSpeedMph * 1609.34) / 3600; // 1 mile = 1609.34 meters
    return (distanceMeters / speedMs).round();
  }

  /// Format distance as human-readable string (USA format - miles)
  /// Converts meters to miles for display
  static String formatDistance(double distanceMeters) {
    // Convert meters to miles (1 mile = 1609.34 meters)
    final miles = distanceMeters / 1609.34;
    
    if (miles < 0.1) {
      // For very short distances, show in feet
      final feet = distanceMeters * 3.28084; // 1 meter = 3.28084 feet
      return '${feet.round()} ft';
    } else if (miles < 1) {
      // For distances under 1 mile, show in 0.1 mile increments
      return '${(miles * 10).round() / 10} mi';
    } else if (miles < 10) {
      // For distances under 10 miles, show 1 decimal place
      return '${miles.toStringAsFixed(1)} mi';
    } else {
      // For longer distances, round to nearest mile
      return '${miles.round()} mi';
    }
  }
  
  /// Convert meters to miles
  static double metersToMiles(double meters) {
    return meters / 1609.34;
  }
  
  /// Convert miles to meters
  static double milesToMeters(double miles) {
    return miles * 1609.34;
  }

  /// Format duration as human-readable string
  static String formatDuration(int seconds) {
    if (seconds < 60) {
      return '$seconds sec';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      return '$minutes min';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      if (minutes == 0) {
        return '$hours hr';
      } else {
        return '$hours hr $minutes min';
      }
    }
  }

  /// Calculate bearing (direction) from point 1 to point 2
  /// Returns bearing in degrees (0-360)
  static double calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    final dLon = _degreesToRadians(lon2 - lon1);
    final lat1Rad = _degreesToRadians(lat1);
    final lat2Rad = _degreesToRadians(lat2);

    final y = math.sin(dLon) * math.cos(lat2Rad);
    final x = math.cos(lat1Rad) * math.sin(lat2Rad) -
        math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(dLon);

    final bearing = math.atan2(y, x);
    final bearingDegrees = _radiansToDegrees(bearing);
    
    // Normalize to 0-360
    return (bearingDegrees + 360) % 360;
  }

  /// Convert radians to degrees
  static double _radiansToDegrees(double radians) {
    return radians * (180 / math.pi);
  }

  /// Generate intermediate points for polyline approximation
  /// Useful when Google Maps API fails - creates a simple straight-line polyline
  static List<Map<String, double>> generateApproximatePolylinePoints(
    double lat1,
    double lon1,
    double lat2,
    double lon2, {
    int segments = 10, // Number of intermediate points
  }) {
    final points = <Map<String, double>>[];
    
    for (int i = 0; i <= segments; i++) {
      final fraction = i / segments;
      final lat = lat1 + (lat2 - lat1) * fraction;
      final lon = lon1 + (lon2 - lon1) * fraction;
      points.add({'lat': lat, 'lng': lon});
    }
    
    return points;
  }
}

