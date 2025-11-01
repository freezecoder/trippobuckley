import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:btrips_unified/Container/utils/keys.dart';
import 'package:btrips_unified/Container/utils/http_client.dart';
import 'package:btrips_unified/Container/utils/google_places_stub.dart'
    if (dart.library.html) 'package:btrips_unified/Container/utils/google_places_web.dart';
import 'package:btrips_unified/Model/predicted_places.dart';
import 'package:btrips_unified/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_providers.dart';
import '../utils/error_notification.dart';

/// [predictedPlacesRepoProvider] used to cache the [PredictedPlacesRepo] class to prevent it from creating multiple instances

final globalPredictedPlacesRepoProvider = Provider<PredictedPlacesRepo>((ref) {
  return PredictedPlacesRepo();
});

class PredictedPlacesRepo {
  /// [getAllPredictedPlaces] gets the details of the location by getting the string from [text] and fetching the
  /// data related to this [text] and showing them inside the [WhereTo] screen as user adds types more words new [autoComplete] items are added to the
  /// [ListView] in the [WhereTo] screen by adding the newly created list of [predictedPlacesList] to the provider [predictedPlacesProvider] located in the [WhereTo] Screen

  void getAllPredictedPlaces(
      String text, BuildContext context, WidgetRef ref) async {
    try {
      if (text.length < 2) {
        return;
      }

      // Use JavaScript API for web to bypass CORS, REST API for mobile/desktop
      if (kIsWeb) {
        try {
          final predictions = await GooglePlacesWeb.getPlacePredictions(
            text,
            Keys.mapKey,
          );

          var predictedPlacesList = predictions
              .map((e) => PredictedPlaces.fromJson(e))
              .toList();

          ref
              .read(whereToPredictedPlacesProvider.notifier)
              .update((state) => predictedPlacesList);
          return;
        } catch (e) {
          debugPrint('JavaScript API failed, falling back to REST: $e');
          // Fall through to REST API fallback
        }
      }

      // REST API for mobile/desktop (or fallback for web)
      String url =
          "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$text&key=${Keys.mapKey}&components=country:pk";

      final response = await HttpClient.instance.get(url);

      if (response.statusCode == 200) {
        var placePrediction = response.data["predictions"];

        var predictedPlacesList = (placePrediction as List)
            .map((e) => PredictedPlaces.fromJson(e))
            .toList();

        ref
            .read(whereToPredictedPlacesProvider.notifier)
            .update((state) => predictedPlacesList);
      } else {
        if (context.mounted) {
          ErrorNotification().showError(context, "Failed to get place suggestions");
        }
      }
    } catch (e) {
      if (context.mounted) {
        String errorMessage = "An error occurred while searching for places";
        
        // Handle CORS errors specifically for web
        if (kIsWeb && (e.toString().contains("CORS") || 
            e.toString().contains("Access-Control-Allow-Origin"))) {
          errorMessage = "CORS error: Google Places API doesn't support direct browser requests. "
              "Please run the app on mobile/desktop or use a backend proxy for web.";
          debugPrint("CORS Error: $e");
          debugPrint("Note: Google Places API requires requests to go through a backend server when used from web browsers.");
        } else if (e.toString().contains("Network")) {
          errorMessage = "Network error. Please check your internet connection.";
        }
        
        ErrorNotification().showError(context, "$errorMessage: $e");
      }
    }
  }
}
