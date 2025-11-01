import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:btrips_unified/Model/driver_model.dart';

import '../../../../Model/direction_model.dart';

final homeScreenCameraMovementProvider = StateProvider<LatLng?>((ref) {
  return null;
});
final homeScreenPickUpLocationProvider = StateProvider<Direction?>((ref) {
  return null;
});
final homeScreenDropOffLocationProvider = StateProvider<Direction?>((ref) {
  return null;
});
final homeScreenSelectedRideProvider = StateProvider<int?>((ref) {
  return null;
});

/// Selected vehicle type for ride request (Sedan, SUV, Luxury SUV)
final homeScreenSelectedVehicleTypeProvider = StateProvider<String?>((ref) {
  return null;
});
final homeScreenStartDriverSearch = StateProvider<bool>((ref) {
  return false;
});
final homeScreenRateProvider = StateProvider<double?>((ref) {
  return null;
});

/// Route distance from pickup to destination in meters
final homeScreenRouteDistanceProvider = StateProvider<double?>((ref) {
  return null;
});

final homeScreenAvailableDriversProvider = StateProvider<List<DriverModel>>((ref) {
  return [];
});

final homeScreenAddressProvider = StateProvider<String?>((ref) {
  return null;
});

final homeScreenMainPolylinesProvider = StateProvider<Set<Polyline>>((ref) {
  return {};
});

final homeScreenMainMarkersProvider = StateProvider<Set<Marker>>((ref) {
  return {};
});

final homeScreenMainCirclesProvider = StateProvider<Set<Circle>>((ref) {
  return {};
});

final homeScreenPresetLocationsModeProvider = StateProvider<bool>((ref) {
  return false; // false = search mode, true = preset locations mode
});

/// Scheduled ride time - null means "now", otherwise contains future DateTime
final homeScreenScheduledTimeProvider = StateProvider<DateTime?>((ref) {
  return null;
});

/// Whether the user is in scheduling mode
final homeScreenIsSchedulingProvider = StateProvider<bool>((ref) {
  return false; // false = ride now, true = schedule for later
});

/// Current ride request ID - used to track the ride and listen for updates
final currentRideRequestIdProvider = StateProvider<String?>((ref) {
  return null;
});