import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:btrips_unified/Container/utils/keys.dart';
import 'package:btrips_unified/Container/utils/http_client.dart';
import 'package:btrips_unified/Container/utils/google_places_stub.dart'
    if (dart.library.html) 'package:btrips_unified/Container/utils/google_places_web.dart';
import 'package:btrips_unified/View/Screens/Main_Screens/Home_Screen/home_providers.dart';
import '../../Model/direction_model.dart';
import '../utils/error_notification.dart';

/// [addressParserProvider] used to cache the [AddressParser] class to prevent it from creating multiple instances

final globalAddressParserProvider = Provider<AddressParser>((ref) {
  return AddressParser();
});

/// This [AddressParser] has function [humanReadableAddress] which creates address that is in a readable form
/// from the provided [userPosition]'s latitude and longitude and returns response in form of [DIrection] model.

class AddressParser {
  dynamic humanReadableAddress(
      Position userPosition, context, WidgetRef ref) async {
    try {
      // Use JavaScript API for web to bypass CORS, REST API for mobile/desktop
      if (kIsWeb) {
        try {
          final geocodeData = await GooglePlacesWeb.reverseGeocode(
            userPosition.latitude,
            userPosition.longitude,
          );

          Direction model = Direction(
              locationLatitude: userPosition.latitude,
              locationLongitude: userPosition.longitude,
              humanReadableAddress: geocodeData?["results"][0]["formatted_address"]);
          ref.read(homeScreenPickUpLocationProvider.notifier).update((state) => model);

          return geocodeData?["results"][0]["formatted_address"];
        } catch (e) {
          debugPrint('JavaScript API failed, falling back to REST: $e');
          // Fall through to REST API fallback
        }
      }

      // REST API for mobile/desktop (or fallback for web)
      try {
        String url =
            "https://maps.googleapis.com/maps/api/geocode/json?latlng=${userPosition.latitude},${userPosition.longitude}&key=${Keys.mapKey}";

        final response = await HttpClient.instance.get(url);

        if (response.statusCode == 200) {
          Direction model = Direction(
              locationLatitude: userPosition.latitude,
              locationLongitude: userPosition.longitude,
              humanReadableAddress: response.data["results"][0]["formatted_address"]);
          ref.read(homeScreenPickUpLocationProvider.notifier).update((state) => model);

          return response.data["results"][0]["formatted_address"];
        } else {
          throw Exception("API returned status ${response.statusCode}");
        }
      } catch (restError) {
        // Fallback to geocoding package (uses native platform services, no CORS issues)
        debugPrint('REST API failed, using geocoding package fallback: $restError');
        return await _getAddressFromGeocodingPackage(userPosition, context, ref);
      }
    } catch (e) {
        String errorMessage = "An error occurred while getting address";
        
        // Handle CORS errors specifically for web
        if (kIsWeb && (e.toString().contains("CORS") || 
            e.toString().contains("Access-Control-Allow-Origin"))) {
          errorMessage = "CORS error: Google Geocoding API doesn't support direct browser requests. "
              "Please run the app on mobile/desktop or use a backend proxy for web.";
          debugPrint("CORS Error: $e");
        } else if (e.toString().contains("Network")) {
          errorMessage = "Network error. Please check your internet connection.";
        }
        
        ErrorNotification().showError(context, "$errorMessage: $e");
        return null;
    }
  }

  /// Fallback method using geocoding package
  /// Uses native platform geocoding services (iOS/Android) - no CORS issues
  /// Reference: https://pub.dev/packages/geocoding
  Future<String?> _getAddressFromGeocodingPackage(
    Position userPosition,
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      // Use geocoding package - works on all platforms without CORS issues
      List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
        userPosition.latitude,
        userPosition.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks[0];
        
        // Build formatted address from placemark components
        final addressParts = <String>[];
        if (placemark.street != null && placemark.street!.isNotEmpty) {
          addressParts.add(placemark.street!);
        }
        if (placemark.subThoroughfare != null && placemark.subThoroughfare!.isNotEmpty) {
          addressParts.insert(0, placemark.subThoroughfare!);
        }
        if (placemark.locality != null && placemark.locality!.isNotEmpty) {
          addressParts.add(placemark.locality!);
        }
        if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) {
          addressParts.add(placemark.administrativeArea!);
        }
        if (placemark.postalCode != null && placemark.postalCode!.isNotEmpty) {
          addressParts.add(placemark.postalCode!);
        }
        
        final formattedAddress = addressParts.isEmpty 
            ? placemark.name ?? '${userPosition.latitude.toStringAsFixed(6)}, ${userPosition.longitude.toStringAsFixed(6)}'
            : addressParts.join(', ');

        Direction model = Direction(
          locationLatitude: userPosition.latitude,
          locationLongitude: userPosition.longitude,
          humanReadableAddress: formattedAddress,
        );
        
        ref.read(homeScreenPickUpLocationProvider.notifier).update((state) => model);
        
        debugPrint('✅ Address retrieved using geocoding package: $formattedAddress');
        return formattedAddress;
      } else {
        throw Exception('No placemarks found for coordinates');
      }
    } catch (e) {
      debugPrint('❌ geocoding package failed: $e');
      // Last resort: return coordinates as address
      final fallbackAddress = '${userPosition.latitude.toStringAsFixed(6)}, ${userPosition.longitude.toStringAsFixed(6)}';
      
      Direction model = Direction(
        locationLatitude: userPosition.latitude,
        locationLongitude: userPosition.longitude,
        humanReadableAddress: fallbackAddress,
      );
      
      ref.read(homeScreenPickUpLocationProvider.notifier).update((state) => model);
      return fallbackAddress;
    }
  }
}
