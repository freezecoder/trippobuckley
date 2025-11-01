import 'package:elegant_notification/elegant_notification.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:btrips_unified/Container/utils/keys.dart';
import 'package:btrips_unified/Container/utils/http_client.dart';
import 'package:btrips_unified/Container/utils/google_places_web.dart';
import 'package:btrips_unified/Container/utils/distance_calculator.dart';
import 'package:btrips_unified/Model/direction_polyline_details_model.dart';
import 'package:btrips_unified/View/Screens/Main_Screens/Home_Screen/home_providers.dart';

import '../utils/error_notification.dart';

/// [directionPolylinesRepoProvider] used to cache the [DirectionPolylines] class to prevent it from creating multiple instances

final globalDirectionPolylinesRepoProvider =
    Provider<DirectionPolylines>((ref) {
  return DirectionPolylines();
});

class DirectionPolylines {
  List<LatLng> pLinesCoordinatedList = [];

  /// [setNewDirectionPolylines] function takes the [DirectionPolylineDetails] model from the [getDirectionsPolylines] function
  ///  and adds the decoded polylines data to [pLinesCoordinatedList] and creates a new [polyline] variable and alots the var to [mainPolylinesProvider] located in the [HomeScreen]
  /// and creates LatLng [Bounds] which would animates the [GoogleMapsController] controller to the new position with polylines on [map] and with 65 [padding]

  void setNewDirectionPolylines(ref, context, controller) async {
    try {
      DirectionPolylineDetails model =
          await getDirectionsPolylines(context, ref);
      await calculateRideRate(context, ref);

      PolylinePoints points = PolylinePoints();
      List<PointLatLng> decodedPolylines =
          points.decodePolyline(model.epoints!);

      pLinesCoordinatedList.clear();

      if (decodedPolylines.isNotEmpty) {
        for (PointLatLng polyline in decodedPolylines) {
          pLinesCoordinatedList
              .add(LatLng(polyline.latitude, polyline.longitude));
        }
      }

      ref.read(homeScreenMainPolylinesProvider).clear();

      Polyline newPolyline = Polyline(
          color: Colors.blue,
          polylineId: const PolylineId("polylineId"),
          jointType: JointType.round,
          points: pLinesCoordinatedList,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          geodesic: true,
          width: 5);

      ref
          .read(homeScreenMainPolylinesProvider.notifier)
          .update((Set<Polyline> state) => {...state, newPolyline});

      double miny = (ref
                  .read(homeScreenPickUpLocationProvider)!
                  .locationLatitude! <=
              ref.read(homeScreenDropOffLocationProvider)!.locationLatitude!)
          ? ref.read(homeScreenPickUpLocationProvider)!.locationLatitude!
          : ref.read(homeScreenDropOffLocationProvider)!.locationLatitude!;

      double minx = (ref
                  .read(homeScreenPickUpLocationProvider)!
                  .locationLongitude <=
              ref.read(homeScreenDropOffLocationProvider)!.locationLongitude!)
          ? ref.read(homeScreenPickUpLocationProvider)!.locationLongitude
          : ref.read(homeScreenDropOffLocationProvider)!.locationLongitude!;
      double maxy = (ref
                  .read(homeScreenPickUpLocationProvider)!
                  .locationLatitude! <=
              ref.read(homeScreenDropOffLocationProvider)!.locationLatitude!)
          ? ref.read(homeScreenDropOffLocationProvider)!.locationLatitude!
          : ref.read(homeScreenPickUpLocationProvider)!.locationLatitude!;
      double maxx = (ref
                  .read(homeScreenPickUpLocationProvider)!
                  .locationLongitude <=
              ref.read(homeScreenDropOffLocationProvider)!.locationLongitude!)
          ? ref.read(homeScreenDropOffLocationProvider)!.locationLongitude!
          : ref.read(homeScreenPickUpLocationProvider)!.locationLongitude;

      double southWestLatitude = miny;
      double southWestLongitude = minx;

      double northEastLatitude = maxy;
      double northEastLongitude = maxx;

      LatLngBounds bounds = LatLngBounds(
          southwest: LatLng(southWestLatitude, southWestLongitude),
          northeast: LatLng(northEastLatitude, northEastLongitude));

      controller!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 65));
    } catch (e) {
      if (context.mounted) {
        ElegantNotification.error(
            description: Text(
          "An Error Occurred $e",
          style: const TextStyle(color: Colors.black),
        )).show(context);
      }
    }
  }

  /// [getDirectionsPolylines] function takes the [pickUpDestination] and  the [dropOffDestination] from the user and fetches the direction data from google maps api
  /// and returns the response in form of [DirectionPolylineDetails]

  Future<dynamic> getDirectionsPolylines(context, WidgetRef ref) async {
    try {
      LatLng pickUpDestination = LatLng(
          ref.read(homeScreenPickUpLocationProvider)!.locationLatitude!,
          ref.read(homeScreenPickUpLocationProvider)!.locationLongitude!);
      LatLng dropOffDestination = LatLng(
          ref.read(homeScreenDropOffLocationProvider)!.locationLatitude!,
          ref.read(homeScreenDropOffLocationProvider)!.locationLongitude!);

      // Use JavaScript API for web to bypass CORS, REST API for mobile/desktop
      if (kIsWeb) {
        try {
          final directionsData = await GooglePlacesWeb.getDirections(
            pickUpDestination.latitude,
            pickUpDestination.longitude,
            dropOffDestination.latitude,
            dropOffDestination.longitude,
          );

          DirectionPolylineDetails model = DirectionPolylineDetails(
            epoints: directionsData["routes"][0]["overview_polyline"]["points"],
            distanceText: directionsData["routes"][0]["legs"][0]["distance"]["text"],
            distanceValue: directionsData["routes"][0]["legs"][0]["distance"]["value"],
            durationText: directionsData["routes"][0]["legs"][0]["duration"]["text"],
            durationValue: directionsData["routes"][0]["legs"][0]["duration"]["value"],
          );

          return model;
        } catch (e) {
          debugPrint('JavaScript Directions API failed, falling back to REST: $e');
          // Fall through to REST API fallback
        }
      }

      // REST API for mobile/desktop (or fallback for web)
      try {
        String url =
            "https://maps.googleapis.com/maps/api/directions/json?origin=${pickUpDestination.latitude},${pickUpDestination.longitude}&destination=${dropOffDestination.latitude},${dropOffDestination.longitude}&key=${Keys.mapKey}";

        final response = await HttpClient.instance.get(url);

        if (response.statusCode == 200) {
          DirectionPolylineDetails model = DirectionPolylineDetails(
            epoints: response.data["routes"][0]["overview_polyline"]["points"],
            distanceText: response.data["routes"][0]["legs"][0]["distance"]["text"],
            distanceValue: response.data["routes"][0]["legs"][0]["distance"]["value"],
            durationText: response.data["routes"][0]["legs"][0]["duration"]["text"],
            durationValue: response.data["routes"][0]["legs"][0]["duration"]["value"],
          );

          return model;
        } else {
          ErrorNotification().showError(context, "Failed to get directions");
        }
      } catch (restError) {
        // If REST API also fails, use fallback calculation
        debugPrint('REST API failed, using fallback distance calculation: $restError');
        return _getFallbackDirections(
          pickUpDestination.latitude,
          pickUpDestination.longitude,
          dropOffDestination.latitude,
          dropOffDestination.longitude,
        );
      }
    } catch (e) {
      String errorMessage = "An error occurred while getting directions";
      
      // Handle CORS errors specifically for web
      if (kIsWeb && (e.toString().contains("CORS") || 
          e.toString().contains("Access-Control-Allow-Origin"))) {
        errorMessage = "CORS error: Google Maps API doesn't support direct browser requests. "
            "Please run the app on mobile/desktop or use a backend proxy for web.";
        debugPrint("CORS Error: $e");
      } else if (e.toString().contains("Network")) {
        errorMessage = "Network error. Please check your internet connection.";
      }
      
      ErrorNotification().showError(context, "$errorMessage: $e");
    }
  }

  /// [calculateRideRate] calculates the fare of the user's travel
  /// 
  /// Distance units: distanceValue is in METERS
  /// Duration units: durationValue is in SECONDS
  /// 
  /// Rate calculation (USA pricing):
  /// - Time-based: $0.25 per minute (converts seconds to minutes)
  /// - Distance-based: $1.50 per mile (converts meters to miles)

  Future<dynamic> calculateRideRate(context, WidgetRef ref) async {
    try {
      DirectionPolylineDetails model =
          await getDirectionsPolylines(context, ref);
      
      // Convert duration from seconds to minutes, then multiply by rate per minute
      // durationValue is in SECONDS, divide by 60 to get minutes
      // USA typical rate: $0.25 per minute
      double travelFarePerMin = model.durationValue != null
          ? (model.durationValue! / 60) * 0.25
          : 0.0;
      
      // Convert distance from meters to miles, then multiply by rate per mile
      // distanceValue is in METERS, divide by 1609.34 to get miles (1 mile = 1609.34 meters)
      // USA typical rate: $1.50 per mile
      double distanceFarePerMile = model.distanceValue != null
          ? (model.distanceValue! / 1609.34) * 1.50
          : 0.0;

      double totalFare = travelFarePerMin + distanceFarePerMile;

      // Store the base fare
      ref
          .read(homeScreenRateProvider.notifier)
          .update((state) => double.parse(totalFare.toStringAsFixed(2)));
      
      // Store the route distance (in meters) for display
      if (model.distanceValue != null) {
        ref
            .read(homeScreenRouteDistanceProvider.notifier)
            .update((state) => model.distanceValue!.toDouble());
      }
    } catch (e) {
      if (context.mounted) {
        ElegantNotification.error(
            description: Text(
          "An Error Occurred $e",
          style: const TextStyle(color: Colors.black),
        )).show(context);
      }
      return 0;
    }
  }

  /// Fallback method when Google Maps API fails
  /// Uses reliable Haversine distance calculation and estimates driving time
  DirectionPolylineDetails _getFallbackDirections(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) {
    debugPrint('Using fallback distance calculation (Google Maps API unavailable)');
    
    // Calculate straight-line distance using Haversine formula
    final straightDistanceMeters = DistanceCalculator.calculateStraightLineDistance(
      originLat,
      originLng,
      destLat,
      destLng,
    );
    
    // Estimate driving distance (typically 20-50% longer than straight line)
    final estimatedDrivingDistanceMeters = DistanceCalculator.estimateDrivingDistance(
      straightDistanceMeters,
      multiplier: 1.35, // 35% longer for urban routes
    );
    
    // Estimate driving time based on average speed (USA speeds in mph)
    // Use slower speed for shorter distances (city), faster for longer (highway)
    final averageSpeedMph = estimatedDrivingDistanceMeters < 16093.4 // ~10 miles
        ? 25.0 // 25 mph for city (under 10 miles)
        : 45.0; // 45 mph for longer routes
    final estimatedDurationSeconds = DistanceCalculator.estimateDrivingTimeSeconds(
      estimatedDrivingDistanceMeters,
      averageSpeedMph: averageSpeedMph,
    );
    
    // Generate approximate polyline points for visualization
    // For fallback, we create intermediate points between origin and destination
    final polylinePoints = <Map<String, double>>[];
    const segments = 20;
    for (int i = 0; i <= segments; i++) {
      final fraction = i / segments;
      final lat = originLat + (destLat - originLat) * fraction;
      final lng = originLng + (destLng - originLng) * fraction;
      polylinePoints.add({'lat': lat, 'lng': lng});
    }
    
    // Encode polyline points using Google's polyline encoding format
    final encodedPolyline = _encodePolyline(polylinePoints);
    
    return DirectionPolylineDetails(
      epoints: encodedPolyline,
      distanceText: DistanceCalculator.formatDistance(estimatedDrivingDistanceMeters),
      distanceValue: estimatedDrivingDistanceMeters.round(),
      durationText: DistanceCalculator.formatDuration(estimatedDurationSeconds),
      durationValue: estimatedDurationSeconds,
    );
  }

  /// Simple polyline encoding (Google's encoded polyline format)
  /// Creates a basic polyline from start to end point
  /// Note: flutter_polyline_points only supports decode, so we implement basic encoding
  String _encodePolyline(List<Map<String, double>> points) {
    if (points.isEmpty) return '';
    
    try {
      // Simple polyline encoding implementation
      // This creates a basic encoded string that can be decoded later
      final encoded = StringBuffer();
      double prevLat = 0;
      double prevLng = 0;
      
      for (int i = 0; i < points.length; i++) {
        final lat = points[i]['lat']!;
        final lng = points[i]['lng']!;
        
        // Encode latitude delta
        int latDelta = ((lat - prevLat) * 1e5).round();
        _encodeValue(encoded, latDelta);
        
        // Encode longitude delta
        int lngDelta = ((lng - prevLng) * 1e5).round();
        _encodeValue(encoded, lngDelta);
        
        prevLat = lat;
        prevLng = lng;
      }
      
      return encoded.toString();
    } catch (e) {
      debugPrint('Error encoding polyline: $e');
      // Fallback: return empty string - the app will use LatLng points directly if needed
      return '';
    }
  }

  /// Helper method to encode a single value using Google's polyline encoding
  void _encodeValue(StringBuffer encoded, int value) {
    value = value < 0 ? ~(value << 1) : value << 1;
    while (value >= 0x20) {
      encoded.writeCharCode((0x20 | (value & 0x1f)) + 63);
      value >>= 5;
    }
    encoded.writeCharCode(value + 63);
  }
}
