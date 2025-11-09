import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/ride_request_model.dart';

/// Provider for recent trips
final recentTripsProvider = StateProvider<List<RideRequestModel>>((ref) {
  return [];
});

/// Provider for loading state of recent trips
final recentTripsLoadingProvider = StateProvider<bool>((ref) {
  return false;
});

/// Provider to toggle between modern and classic home screen
final useModernHomeScreenProvider = StateProvider<bool>((ref) {
  return true; // Default to modern home screen
});

/// Provider for current tab index in main navigation
final mainNavigationTabIndexProvider = StateProvider<int>((ref) {
  return 0; // Default to home tab
});

