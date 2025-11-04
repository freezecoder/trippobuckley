/// Stub for non-web platforms
class CloudFunctionsHelper {
  static Future<Map<String, dynamic>> call(String functionName, Map<String, dynamic> data) async {
    throw UnsupportedError('Cloud Functions web helper not supported on this platform');
  }
}

