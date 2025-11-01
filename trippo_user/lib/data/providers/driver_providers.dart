import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/driver_repository.dart';
import '../models/driver_model.dart';
import 'auth_providers.dart';

/// Provider for DriverRepository
final driverRepositoryProvider = Provider<DriverRepository>((ref) {
  return DriverRepository();
});

/// Provider for current driver's data (if user is a driver)
final currentDriverProvider = StreamProvider<DriverModel?>((ref) {
  final currentUser = ref.watch(currentUserStreamProvider).value;
  
  // Only fetch driver data if user is a driver
  if (currentUser == null || !currentUser.isDriver) {
    return Stream.value(null);
  }
  
  final driverRepo = ref.watch(driverRepositoryProvider);
  return driverRepo.driverStream(currentUser.uid);
});

/// Provider for current driver's vehicle type (for filtering rides)
final currentDriverVehicleTypeProvider = Provider<String?>((ref) {
  final driver = ref.watch(currentDriverProvider).value;
  return driver?.carType;
});

