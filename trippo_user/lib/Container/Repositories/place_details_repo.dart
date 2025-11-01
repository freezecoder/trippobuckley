import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:btrips_unified/Container/utils/keys.dart';
import 'package:btrips_unified/Container/utils/http_client.dart';
import 'package:btrips_unified/Container/utils/google_places_stub.dart'
    if (dart.library.html) 'package:btrips_unified/Container/utils/google_places_web.dart';
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
      ref.read(whereToLoadingProvider.notifier).update((state) => true);

      // Use JavaScript API for web to bypass CORS, REST API for mobile/desktop
      if (kIsWeb) {
        try {
          final placeData = await GooglePlacesWeb.getPlaceDetails(placeId);
          
          Direction placeDetails = Direction(
            locationName: placeData["result"]["name"],
            locationId: placeId,
            locationLatitude: placeData["result"]["geometry"]["location"]["lat"],
            locationLongitude: placeData["result"]["geometry"]["location"]["lng"],
          );

          ref
              .read(homeScreenDropOffLocationProvider.notifier)
              .update((state) => placeDetails);

          ref.read(whereToLoadingProvider.notifier).update((state) => false);
          return;
        } catch (e) {
          debugPrint('JavaScript API failed, falling back to REST: $e');
          // Fall through to REST API fallback
        }
      }

      // REST API for mobile/desktop (or fallback for web)
      String url =
          "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=${Keys.mapKey}";

      final response = await HttpClient.instance.get(url);

      if (response.statusCode == 200) {
        Direction placeDetails = Direction(
          locationName: response.data["result"]["name"],
          locationId: placeId,
          locationLatitude: response.data["result"]["geometry"]["location"]["lat"],
          locationLongitude: response.data["result"]["geometry"]["location"]["lng"],
        );

        ref
            .read(homeScreenDropOffLocationProvider.notifier)
            .update((state) => placeDetails);

        ref.read(whereToLoadingProvider.notifier).update((state) => false);
      } else {
        if (context.mounted) {
          ErrorNotification().showError(context, "Failed to get place details");
        }
      }
    } catch (e) {
      debugPrint("Error getting place details: $e");
      if (context.mounted) {
        String errorMessage = "An error occurred while getting place details";
        
        // Handle CORS errors specifically for web
        if (kIsWeb && (e.toString().contains("CORS") || 
            e.toString().contains("Access-Control-Allow-Origin"))) {
          errorMessage = "CORS error: Google Places API doesn't support direct browser requests. "
              "Please run the app on mobile/desktop or use a backend proxy for web.";
        } else if (e.toString().contains("Network")) {
          errorMessage = "Network error. Please check your internet connection.";
        }
        
        ErrorNotification().showError(context, "$errorMessage: $e");
      }
    }
  }
}
