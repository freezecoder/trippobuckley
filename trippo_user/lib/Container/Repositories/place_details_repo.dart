import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:btrips_unified/Container/utils/keys.dart';
import 'package:btrips_unified/Container/utils/google_places_stub.dart'
    if (dart.library.html) 'package:btrips_unified/Container/utils/google_places_web.dart';
import 'package:btrips_unified/Container/Repositories/predicted_places_repo.dart';
import 'package:btrips_unified/View/Screens/Main_Screens/Home_Screen/home_providers.dart';
import 'package:btrips_unified/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_providers.dart';
import '../../Model/direction_model.dart';
import '../utils/error_notification.dart';

/// [placeDetailsRepoProvider] used to cache the [PlaceDetailsRepo] class to prevent it from creating multiple instances

final globalPlaceDetailsRepoProvider = Provider<PlaceDetailsRepo>((ref) {
  return PlaceDetailsRepo();
});

class PlaceDetailsRepo {
  /// [getAllPredictedPlaceDetails] gets the details of the location by getting location ID from [placeId] and fetching the
  /// data related to this [placeId] when user Clicks on any item inside of the [ListView] in the [WhereTo] screen and return a [Direction] model which directing user back to [HomeScreen]

  Future<dynamic> getAllPredictedPlaceDetails(
      String placeId, BuildContext context, WidgetRef ref, controller) async {
    try {
      debugPrint('🔍 Getting place details for: $placeId');
      ref.read(whereToLoadingProvider.notifier).update((state) => true);

      // Use JavaScript API for web to bypass CORS, REST API for mobile/desktop
      if (kIsWeb) {
        debugPrint('🌐 Using Web JavaScript API for place details');
        try {
          final placeData = await GooglePlacesWeb.getPlaceDetails(placeId);
          
          final result = placeData?["result"];
          if (result == null) {
            throw Exception('No result data from Google Places');
          }
          
          debugPrint('✅ Got place details: ${result["name"]}');
          debugPrint('📍 Location: ${result["geometry"]["location"]["lat"]}, ${result["geometry"]["location"]["lng"]}');
          
          Direction placeDetails = Direction(
            locationName: result["name"],
            locationId: placeId,
            locationLatitude: result["geometry"]["location"]["lat"],
            locationLongitude: result["geometry"]["location"]["lng"],
          );

          ref
              .read(homeScreenDropOffLocationProvider.notifier)
              .update((state) => placeDetails);

          ref.read(whereToLoadingProvider.notifier).update((state) => false);
          
          // Reset session token after successful place selection
          ref.read(globalPredictedPlacesRepoProvider).resetSessionToken();
          debugPrint('✅ Place details loaded successfully');
          
          return;
        } catch (e) {
          debugPrint('⚠️ JavaScript API failed, falling back to REST: $e');
          // Fall through to REST API fallback
        }
      }

      // REST API for mobile/desktop (or fallback for web)
      // Using simple http.get() instead of Dio to avoid CORS issues
      debugPrint('📱 Using REST API for place details');
      String url =
          "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=${Keys.mapKey}";

      debugPrint('🌐 Request URL: ${url.replaceAll(Keys.mapKey, "***API_KEY***")}');
      
      final response = await http.get(Uri.parse(url));

      debugPrint('📡 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        debugPrint('✅ Got place details: ${jsonResponse["result"]["name"]}');
        
        Direction placeDetails = Direction(
          locationName: jsonResponse["result"]["name"],
          locationId: placeId,
          locationLatitude: jsonResponse["result"]["geometry"]["location"]["lat"],
          locationLongitude: jsonResponse["result"]["geometry"]["location"]["lng"],
        );

        ref
            .read(homeScreenDropOffLocationProvider.notifier)
            .update((state) => placeDetails);

        ref.read(whereToLoadingProvider.notifier).update((state) => false);
        
        // Reset session token after successful place selection
        ref.read(globalPredictedPlacesRepoProvider).resetSessionToken();
        debugPrint('✅ Place details loaded successfully');
      } else {
        debugPrint('❌ API returned error status: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        if (context.mounted) {
          ErrorNotification().showError(context, "Failed to get place details");
        }
      }
    } catch (e, stackTrace) {
      debugPrint("❌ Error getting place details: $e");
      debugPrint('Stack trace: $stackTrace');
      
      ref.read(whereToLoadingProvider.notifier).update((state) => false);
      
      if (context.mounted) {
        String errorMessage = "An error occurred while getting place details";
        
        // Handle CORS errors specifically for web
        if (kIsWeb && (e.toString().contains("CORS") || 
            e.toString().contains("Access-Control-Allow-Origin"))) {
          errorMessage = "CORS error: The app is trying to load. Please wait a moment and try again.";
          debugPrint("💡 Tip: If this persists, check if Google Maps API is loaded in web/index.html");
        } else if (e.toString().contains("Network")) {
          errorMessage = "Network error. Please check your internet connection.";
        } else if (e.toString().contains("API")) {
          errorMessage = "API error. Please check your Google Maps API key.";
        }
        
        ErrorNotification().showError(context, errorMessage);
      }
    }
  }
}
