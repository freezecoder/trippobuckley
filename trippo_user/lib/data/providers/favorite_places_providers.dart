import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:btrips_unified/data/models/favorite_place_model.dart';
import 'package:btrips_unified/data/repositories/favorite_places_repository.dart';
import 'package:btrips_unified/data/providers/auth_providers.dart';

/// Stream of user's favorite places
final userFavoritePlacesProvider = StreamProvider<List<FavoritePlaceModel>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.value;
  
  if (user == null) {
    return Stream.value([]);
  }

  final repository = ref.watch(favoritePlacesRepositoryProvider);
  return repository.getUserFavorites(user.uid);
});

/// Check if a specific place is favorited
final isPlaceFavoritedProvider = FutureProvider.family<bool, String>((ref, placeId) async {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.value;
  
  if (user == null) {
    return false;
  }

  final repository = ref.watch(favoritePlacesRepositoryProvider);
  return await repository.isFavorite(user.uid, placeId);
});

