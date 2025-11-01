import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:btrips_unified/data/repositories/preset_location_repository.dart';
import 'package:btrips_unified/data/models/preset_location_model.dart';

/// Provider for PresetLocationRepository instance
final presetLocationRepositoryProvider = Provider<PresetLocationRepository>((ref) {
  return PresetLocationRepository();
});

/// Provider for active preset locations stream
final activePresetLocationsProvider =
    StreamProvider<List<PresetLocationModel>>((ref) {
  final repository = ref.watch(presetLocationRepositoryProvider);
  return repository.getActivePresetLocations();
});

/// Provider for preset locations by category
final presetLocationsByCategoryProvider =
    StreamProvider.family<List<PresetLocationModel>, String>((ref, category) {
  final repository = ref.watch(presetLocationRepositoryProvider);
  return repository.getPresetLocationsByCategory(category);
});

/// Provider for all preset locations (for admin)
final allPresetLocationsProvider =
    StreamProvider<List<PresetLocationModel>>((ref) {
  final repository = ref.watch(presetLocationRepositoryProvider);
  return repository.getAllPresetLocations();
});

/// Provider for airport preset locations specifically
final airportPresetLocationsProvider =
    StreamProvider<List<PresetLocationModel>>((ref) {
  final repository = ref.watch(presetLocationRepositoryProvider);
  return repository.getPresetLocationsByCategory('airport');
});

