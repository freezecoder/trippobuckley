import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';
import '../models/user_model.dart';

/// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Provider for Firebase Auth user stream
final firebaseAuthUserProvider = StreamProvider<firebase_auth.User?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges;
});

/// Provider for current UserModel
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authRepo = ref.watch(authRepositoryProvider);
  return await authRepo.getCurrentUser();
});

/// Provider for current UserModel as a stream
final currentUserStreamProvider = StreamProvider<UserModel?>((ref) async* {
  final authRepo = ref.watch(authRepositoryProvider);
  
  // Listen to auth changes
  await for (final firebaseUser in authRepo.authStateChanges) {
    if (firebaseUser == null) {
      yield null;
    } else {
      // Fetch user data when auth state changes
      yield await authRepo.getCurrentUser();
    }
  }
});

/// Provider to check if current user is a driver
final isDriverProvider = FutureProvider<bool>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  return user?.isDriver ?? false;
});

/// Provider to check if current user is a regular user
final isRegularUserProvider = FutureProvider<bool>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  return user?.isRegularUser ?? false;
});

/// Provider to check if current user is an admin
final isAdminProvider = FutureProvider<bool>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  return user?.isAdmin ?? false;
});

/// Provider for checking if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authUser = ref.watch(firebaseAuthUserProvider).value;
  return authUser != null;
});

