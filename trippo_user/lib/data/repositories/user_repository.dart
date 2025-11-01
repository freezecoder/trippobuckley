import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firebase_constants.dart';
import '../models/user_model.dart';
import '../models/user_profile_model.dart';

/// Repository for user operations (regular users/passengers)
class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get user data by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .get();

      if (!doc.exists) return null;

      return UserModel.fromFirestore(doc.data()!, userId);
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  /// Stream of user data
  Stream<UserModel?> userStream(String userId) {
    return _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc.data()!, userId);
    });
  }

  /// Update user profile (name, phone, etc.)
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    try {
      final Map<String, dynamic> updates = {};

      if (name != null) {
        updates[FirebaseConstants.userName] = name;
      }
      if (phoneNumber != null) {
        updates[FirebaseConstants.userPhoneNumber] = phoneNumber;
      }
      if (profileImageUrl != null) {
        updates[FirebaseConstants.userProfileImageUrl] = profileImageUrl;
      }

      if (updates.isNotEmpty) {
        await _firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(userId)
            .update(updates);
      }
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  /// Get user profile data (for regular users)
  Future<UserProfileModel?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.userProfilesCollection)
          .doc(userId)
          .get();

      if (!doc.exists) return null;

      return UserProfileModel.fromFirestore(doc.data()!, userId);
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  /// Stream of user profile data
  Stream<UserProfileModel?> userProfileStream(String userId) {
    return _firestore
        .collection(FirebaseConstants.userProfilesCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return UserProfileModel.fromFirestore(doc.data()!, userId);
    });
  }

  /// Update user profile addresses
  Future<void> updateAddresses({
    required String userId,
    String? homeAddress,
    String? workAddress,
  }) async {
    try {
      final Map<String, dynamic> updates = {};

      if (homeAddress != null) {
        updates[FirebaseConstants.profileHomeAddress] = homeAddress;
      }
      if (workAddress != null) {
        updates[FirebaseConstants.profileWorkAddress] = workAddress;
      }

      if (updates.isNotEmpty) {
        await _firestore
            .collection(FirebaseConstants.userProfilesCollection)
            .doc(userId)
            .update(updates);
      }
    } catch (e) {
      throw Exception('Failed to update addresses: $e');
    }
  }

  /// Add favorite location
  Future<void> addFavoriteLocation({
    required String userId,
    required String location,
  }) async {
    try {
      await _firestore
          .collection(FirebaseConstants.userProfilesCollection)
          .doc(userId)
          .update({
        FirebaseConstants.profileFavoriteLocations:
            FieldValue.arrayUnion([location]),
      });
    } catch (e) {
      throw Exception('Failed to add favorite location: $e');
    }
  }

  /// Remove favorite location
  Future<void> removeFavoriteLocation({
    required String userId,
    required String location,
  }) async {
    try {
      await _firestore
          .collection(FirebaseConstants.userProfilesCollection)
          .doc(userId)
          .update({
        FirebaseConstants.profileFavoriteLocations:
            FieldValue.arrayRemove([location]),
      });
    } catch (e) {
      throw Exception('Failed to remove favorite location: $e');
    }
  }

  /// Add payment method
  Future<void> addPaymentMethod({
    required String userId,
    required String paymentMethod,
  }) async {
    try {
      await _firestore
          .collection(FirebaseConstants.userProfilesCollection)
          .doc(userId)
          .update({
        FirebaseConstants.profilePaymentMethods:
            FieldValue.arrayUnion([paymentMethod]),
      });
    } catch (e) {
      throw Exception('Failed to add payment method: $e');
    }
  }

  /// Remove payment method
  Future<void> removePaymentMethod({
    required String userId,
    required String paymentMethod,
  }) async {
    try {
      await _firestore
          .collection(FirebaseConstants.userProfilesCollection)
          .doc(userId)
          .update({
        FirebaseConstants.profilePaymentMethods:
            FieldValue.arrayRemove([paymentMethod]),
      });
    } catch (e) {
      throw Exception('Failed to remove payment method: $e');
    }
  }

  /// Update user preferences
  Future<void> updatePreferences({
    required String userId,
    required Map<String, dynamic> preferences,
  }) async {
    try {
      await _firestore
          .collection(FirebaseConstants.userProfilesCollection)
          .doc(userId)
          .update({
        FirebaseConstants.profilePreferences: preferences,
      });
    } catch (e) {
      throw Exception('Failed to update preferences: $e');
    }
  }

  /// Update specific preference
  Future<void> updatePreference({
    required String userId,
    required String key,
    required dynamic value,
  }) async {
    try {
      await _firestore
          .collection(FirebaseConstants.userProfilesCollection)
          .doc(userId)
          .update({
        '${FirebaseConstants.profilePreferences}.$key': value,
      });
    } catch (e) {
      throw Exception('Failed to update preference: $e');
    }
  }

  /// Increment total rides
  Future<void> incrementTotalRides(String userId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.userProfilesCollection)
          .doc(userId)
          .update({
        'totalRides': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to increment total rides: $e');
    }
  }

  /// Update user rating
  Future<void> updateRating({
    required String userId,
    required double newRating,
  }) async {
    try {
      // Try to get profile to calculate average, but don't fail if it doesn't exist
      try {
        final profile = await getUserProfile(userId);
        if (profile != null) {
          // Calculate new average rating
          final totalRides = profile.totalRides;
          final currentRating = profile.rating;
          final updatedRating =
              ((currentRating * totalRides) + newRating) / (totalRides + 1);

          await _firestore
              .collection(FirebaseConstants.userProfilesCollection)
              .doc(userId)
              .update({
            'rating': updatedRating,
          });
          return;
        }
      } catch (e) {
        // Profile doesn't exist or can't be accessed
        print('ℹ️ User profile not found, creating with initial rating');
      }
      
      // If profile doesn't exist, create it with the new rating
      await _firestore
          .collection(FirebaseConstants.userProfilesCollection)
          .doc(userId)
          .set({
        'rating': newRating,
        'totalRides': 0,
        'homeAddress': '',
        'workAddress': '',
        'favoriteLocations': [],
      }, SetOptions(merge: true));
    } catch (e) {
      // Don't throw error - rating is optional
      print('⚠️ Could not update user rating: $e');
    }
  }

  /// Delete user account (soft delete - set isActive to false)
  Future<void> deactivateAccount(String userId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .update({
        FirebaseConstants.userIsActive: false,
      });
    } catch (e) {
      throw Exception('Failed to deactivate account: $e');
    }
  }

  /// Reactivate user account
  Future<void> reactivateAccount(String userId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .update({
        FirebaseConstants.userIsActive: true,
      });
    } catch (e) {
      throw Exception('Failed to reactivate account: $e');
    }
  }

  /// Update profile picture URL
  Future<void> updateProfilePictureUrl({
    required String userId,
    required String imageUrl,
  }) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .update({
        FirebaseConstants.userProfileImageUrl: imageUrl,
      });
    } catch (e) {
      throw Exception('Failed to update profile picture: $e');
    }
  }
}

