import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:btrips_unified/Container/utils/keys.dart';
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
  // Session token for grouping autocomplete and place details API calls
  // This helps Google track usage and provide better billing
  String? _sessionToken;
  final _uuid = const Uuid();
  
  // Generate a new session token
  String _getSessionToken() {
    _sessionToken ??= _uuid.v4();
    return _sessionToken!;
  }
  
  // Reset session token (call after place selection)
  void resetSessionToken() {
    _sessionToken = null;
    debugPrint('🔄 Session token reset');
  }
  /// [getAllPredictedPlaces] gets the details of the location by getting the string from [text] and fetching the
  /// data related to this [text] and showing them inside the [WhereTo] screen as user adds types more words new [autoComplete] items are added to the
  /// [ListView] in the [WhereTo] screen by adding the newly created list of [predictedPlacesList] to the provider [predictedPlacesProvider] located in the [WhereTo] Screen

  void getAllPredictedPlaces(
      String text, BuildContext context, WidgetRef ref) async {
    try {
      if (text.length < 2) {
        debugPrint('⏭️ Skipping search: input too short ($text)');
        return;
      }

      debugPrint('🔍 Searching for: "$text"');
      final sessionToken = _getSessionToken();
      debugPrint('🎫 Using session token: $sessionToken');

      // Use JavaScript API for web to bypass CORS, REST API for mobile/desktop
      if (kIsWeb) {
        debugPrint('🌐 Using Web JavaScript API');
        try {
          final predictions = await GooglePlacesWeb.getPlacePredictions(
            text,
            Keys.mapKey,
          );

          debugPrint('✅ Got ${predictions.length} predictions from Web API');
          var predictedPlacesList = predictions
              .map((e) => PredictedPlaces.fromJson(e))
              .toList();

          ref
              .read(whereToPredictedPlacesProvider.notifier)
              .update((state) => predictedPlacesList);
          
          if (predictedPlacesList.isNotEmpty) {
            debugPrint('📍 First result: ${predictedPlacesList[0].mainText}');
          }
          return;
        } catch (e) {
          debugPrint('⚠️ JavaScript API failed, falling back to REST: $e');
          // Fall through to REST API fallback
        }
      }

      // REST API for mobile/desktop (or fallback for web)
      // Using simple http.get() instead of Dio to avoid CORS issues
      debugPrint('📱 Using REST API with http package');
      String url =
          "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$text&key=${Keys.mapKey}&sessiontoken=$sessionToken&components=country:pk";

      debugPrint('🌐 Request URL: ${url.replaceAll(Keys.mapKey, "***API_KEY***")}');
      
      final response = await http.get(Uri.parse(url));

      debugPrint('📡 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        var placePrediction = jsonResponse["predictions"];
        debugPrint('✅ Got ${(placePrediction as List).length} predictions from REST API');

        var predictedPlacesList = (placePrediction)
            .map((e) => PredictedPlaces.fromJson(e))
            .toList();

        ref
            .read(whereToPredictedPlacesProvider.notifier)
            .update((state) => predictedPlacesList);
        
        if (predictedPlacesList.isNotEmpty) {
          debugPrint('📍 First result: ${predictedPlacesList[0].mainText}');
        }
      } else {
        debugPrint('❌ API returned error status: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        if (context.mounted) {
          ErrorNotification().showError(context, "Failed to get place suggestions");
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error in getAllPredictedPlaces: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (context.mounted) {
        String errorMessage = "An error occurred while searching for places";
        
        // Handle CORS errors specifically for web
        if (kIsWeb && (e.toString().contains("CORS") || 
            e.toString().contains("Access-Control-Allow-Origin"))) {
          errorMessage = "CORS error: The app is trying to load. Please wait a moment and try again.";
          debugPrint("💡 Tip: If this persists, check if Google Maps API is loaded in web/index.html");
        } else if (e.toString().contains("Network")) {
          errorMessage = "Network error. Please check your internet connection.";
        } else if (e.toString().contains("API")) {
          errorMessage = "API error. Please check your Google Maps API key configuration.";
        }
        
        ErrorNotification().showError(context, errorMessage);
      }
    }
  }
}
