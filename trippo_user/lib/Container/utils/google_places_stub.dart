/// Stub implementation for non-web platforms
/// This file provides empty implementations that won't be called on non-web platforms

class GooglePlacesWeb {
  static Future<bool> isGoogleMapsLoaded() async {
    throw UnsupportedError('Google Places Web is not supported on this platform');
  }

  static Future<List<Map<String, dynamic>>> searchPlaces(String input) async {
    throw UnsupportedError('Google Places Web is not supported on this platform');
  }

  static Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    throw UnsupportedError('Google Places Web is not supported on this platform');
  }

  static Future<Map<String, dynamic>?> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    throw UnsupportedError('Google Places Web is not supported on this platform');
  }

  static Future<Map<String, dynamic>?> getDirections(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) async {
    throw UnsupportedError('Google Places Web is not supported on this platform');
  }
}

