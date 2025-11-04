import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:btrips_unified/data/models/favorite_place_model.dart';

/// Repository for managing user's favorite places
final favoritePlacesRepositoryProvider = Provider<FavoritePlacesRepository>((ref) {
  return FavoritePlacesRepository();
});

class FavoritePlacesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'favoritePlaces';

  /// Get all favorite places for a user
  Stream<List<FavoritePlaceModel>> getUserFavorites(String userId) {
    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .orderBy('useCount', descending: true) // Most used first
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FavoritePlaceModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Get favorite places as future (one-time fetch)
  Future<List<FavoritePlaceModel>> getUserFavoritesList(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .orderBy('useCount', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => FavoritePlaceModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting favorites: $e');
      return [];
    }
  }

  /// Add a place to favorites
  Future<bool> addFavorite({
    required String userId,
    required String name,
    required String address,
    required String placeId,
    required double latitude,
    required double longitude,
    String category = 'other',
    String? nickname,
  }) async {
    try {
      debugPrint('⭐ Adding favorite: $name');

      // Check if already exists
      final existing = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where('placeId', isEqualTo: placeId)
          .get();

      if (existing.docs.isNotEmpty) {
        debugPrint('ℹ️  Place already in favorites');
        return false; // Already exists
      }

      // Add new favorite
      final favorite = FavoritePlaceModel(
        userId: userId,
        name: name,
        address: address,
        placeId: placeId,
        latitude: latitude,
        longitude: longitude,
        category: category,
        nickname: nickname,
        createdAt: DateTime.now(),
        useCount: 0,
      );

      await _firestore.collection(_collectionName).add(favorite.toFirestore());

      debugPrint('✅ Favorite added successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error adding favorite: $e');
      return false;
    }
  }

  /// Remove a favorite
  Future<bool> removeFavorite(String favoriteId) async {
    try {
      await _firestore.collection(_collectionName).doc(favoriteId).delete();
      debugPrint('✅ Favorite removed');
      return true;
    } catch (e) {
      debugPrint('❌ Error removing favorite: $e');
      return false;
    }
  }

  /// Update favorite (nickname, category)
  Future<bool> updateFavorite({
    required String favoriteId,
    String? nickname,
    String? category,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (nickname != null) updates['nickname'] = nickname;
      if (category != null) updates['category'] = category;

      await _firestore.collection(_collectionName).doc(favoriteId).update(updates);

      debugPrint('✅ Favorite updated');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating favorite: $e');
      return false;
    }
  }

  /// Increment use count when favorite is selected
  Future<void> incrementUseCount(String favoriteId) async {
    try {
      await _firestore.collection(_collectionName).doc(favoriteId).update({
        'useCount': FieldValue.increment(1),
        'lastUsed': FieldValue.serverTimestamp(),
      });
      debugPrint('📊 Incremented use count for favorite');
    } catch (e) {
      debugPrint('❌ Error incrementing use count: $e');
    }
  }

  /// Check if a place is already favorited
  Future<bool> isFavorite(String userId, String placeId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where('placeId', isEqualTo: placeId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Error checking favorite status: $e');
      return false;
    }
  }

  /// Get favorite by placeId
  Future<FavoritePlaceModel?> getFavoriteByPlaceId(String userId, String placeId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where('placeId', isEqualTo: placeId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return FavoritePlaceModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting favorite: $e');
      return null;
    }
  }
}

