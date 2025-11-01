import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/user_repository.dart';
import '../repositories/driver_repository.dart';
import '../models/user_profile_model.dart';
import '../models/driver_model.dart';
import 'auth_providers.dart';

/// Provider for UserRepository
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

/// Provider for DriverRepository
final driverRepositoryProvider = Provider<DriverRepository>((ref) {
  return DriverRepository();
});

/// Provider for user profile (for regular users)
final userProfileProvider = StreamProvider<UserProfileModel?>((ref) {
  final currentUser = ref.watch(currentUserStreamProvider).value;
  if (currentUser == null || currentUser.isDriver) {
    return Stream.value(null);
  }

  final userRepo = ref.watch(userRepositoryProvider);
  return userRepo.userProfileStream(currentUser.uid);
});

/// Provider for driver data (for drivers)
final driverDataProvider = StreamProvider<DriverModel?>((ref) {
  final currentUser = ref.watch(currentUserStreamProvider).value;
  if (currentUser == null || !currentUser.isDriver) {
    return Stream.value(null);
  }

  final driverRepo = ref.watch(driverRepositoryProvider);
  return driverRepo.driverStream(currentUser.uid);
});

/// Provider to check if driver has completed configuration
final hasCompletedDriverConfigProvider = FutureProvider<bool>((ref) async {
  final currentUser = await ref.watch(currentUserProvider.future);
  if (currentUser == null || !currentUser.isDriver) {
    return false;
  }

  final driverRepo = ref.watch(driverRepositoryProvider);
  return await driverRepo.hasCompletedConfiguration(currentUser.uid);
});

