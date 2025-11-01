import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/storage_repository.dart';

/// Provider for StorageRepository
final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return StorageRepository();
});

/// Provider for profile picture upload loading state
final profilePictureUploadingProvider = StateProvider<bool>((ref) => false);

