import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Platform-specific imports
import 'package:btrips_unified/Container/utils/cloud_functions_stub.dart'
    if (dart.library.html) 'package:btrips_unified/Container/utils/cloud_functions_web.dart';

/// Repository for calling Google Places Cloud Functions
/// Used on web to bypass CORS restrictions
final placesCloudFunctionRepoProvider = Provider<PlacesCloudFunctionRepo>((ref) {
  return PlacesCloudFunctionRepo();
});

class PlacesCloudFunctionRepo {
  /// Search for places using Cloud Function proxy
  Future<List<Map<String, dynamic>>> searchPlaces({
    required String input,
    String country = 'us',
    String language = 'en',
  }) async {
    try {
      debugPrint('🔍 Calling placesAutocomplete Cloud Function');
      debugPrint('   Input: $input');
      debugPrint('   Country: $country');

      final result = await CloudFunctionsHelper.call(
        'placesAutocomplete',
        {
          'input': input,
          'country': country,
          'language': language,
        },
      );

      debugPrint('✅ Cloud Function response received');

      if (result['success'] == true) {
        final predictions = result['predictions'] as List;
        debugPrint('📍 Got ${predictions.length} predictions');
        return predictions.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Cloud Function returned success: false');
      }
    } catch (e) {
      debugPrint('❌ Error calling placesAutocomplete: $e');
      rethrow;
    }
  }

  /// Get place details (coordinates) using Cloud Function proxy
  Future<Map<String, dynamic>> getPlaceDetails({
    required String placeId,
  }) async {
    try {
      debugPrint('📍 Calling placeDetails Cloud Function');
      debugPrint('   Place ID: $placeId');

      final result = await CloudFunctionsHelper.call(
        'placeDetails',
        {'placeId': placeId},
      );

      debugPrint('✅ Cloud Function response received');

      if (result['success'] == true) {
        debugPrint('📍 Place: ${result['name']}');
        debugPrint('   Lat: ${result['latitude']}');
        debugPrint('   Lng: ${result['longitude']}');
        return result;
      } else {
        throw Exception('Cloud Function returned success: false');
      }
    } catch (e) {
      debugPrint('❌ Error calling placeDetails: $e');
      rethrow;
    }
  }
}

