/// Stub implementation for non-web platforms
/// This file is used when building for mobile/desktop
class StripeWebService {
  static Future<bool> initializeElements(String containerId) async {
    throw UnsupportedError('Web service is not supported on this platform');
  }

  static Future<Map<String, dynamic>> createPaymentMethod({
    required String cardholderName,
  }) async {
    throw UnsupportedError('Web service is not supported on this platform');
  }

  static bool isStripeLoaded() {
    return false;
  }
}

