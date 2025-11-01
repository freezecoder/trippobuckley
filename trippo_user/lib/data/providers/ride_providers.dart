import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/ride_repository.dart';
import '../models/ride_request_model.dart';
import 'auth_providers.dart';
import 'driver_providers.dart';

/// Provider for RideRepository
final rideRepositoryProvider = Provider<RideRepository>((ref) {
  return RideRepository();
});

/// Provider for user's active ride requests
final userActiveRidesProvider = StreamProvider<List<RideRequestModel>>((ref) {
  final currentUser = ref.watch(currentUserStreamProvider).value;
  if (currentUser == null || currentUser.isDriver) {
    return Stream.value([]);
  }

  final rideRepo = ref.watch(rideRepositoryProvider);
  return rideRepo.getUserRideRequests(currentUser.uid).map((rides) {
    // Filter only active rides
    return rides.where((ride) => ride.isActive).toList();
  });
});

/// Provider for driver's active rides
final driverActiveRidesProvider = StreamProvider<List<RideRequestModel>>((ref) {
  final currentUser = ref.watch(currentUserStreamProvider).value;
  if (currentUser == null || !currentUser.isDriver) {
    return Stream.value([]);
  }

  final rideRepo = ref.watch(rideRepositoryProvider);
  return rideRepo.getDriverRideRequests(currentUser.uid).map((rides) {
    // Filter only active rides
    return rides.where((ride) => ride.isActive).toList();
  });
});

/// Provider for pending ride requests (for drivers to accept)
/// ✅ Now filters by driver's vehicle type to show only matching rides
/// ✅ Filters out rides the driver has declined
final pendingRideRequestsProvider = StreamProvider<List<RideRequestModel>>((ref) {
  final currentUser = ref.watch(currentUserStreamProvider).value;
  if (currentUser == null || !currentUser.isDriver) {
    return Stream.value([]);
  }

  // ✅ Get the driver's vehicle type for filtering
  final driverVehicleType = ref.watch(currentDriverVehicleTypeProvider);

  final rideRepo = ref.watch(rideRepositoryProvider);
  return rideRepo.getPendingRideRequests(
    driverVehicleType: driverVehicleType,
    driverId: currentUser.uid, // ✅ Pass driver ID to filter declined rides
  );
});

/// Provider for user's ride history
final userRideHistoryProvider = FutureProvider<List<RideRequestModel>>((ref) async {
  final currentUser = await ref.watch(currentUserProvider.future);
  if (currentUser == null || currentUser.isDriver) {
    return [];
  }

  final rideRepo = ref.watch(rideRepositoryProvider);
  return await rideRepo.getUserRideHistory(currentUser.uid);
});

/// Provider for driver's ride history
final driverRideHistoryProvider = FutureProvider<List<RideRequestModel>>((ref) async {
  final currentUser = await ref.watch(currentUserProvider.future);
  if (currentUser == null || !currentUser.isDriver) {
    return [];
  }

  final rideRepo = ref.watch(rideRepositoryProvider);
  return await rideRepo.getDriverRideHistory(currentUser.uid);
});

