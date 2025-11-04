import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../core/constants/firebase_constants.dart';
import '../models/admin_action_model.dart';
import '../models/user_model.dart';
import '../models/ride_request_model.dart';

/// Repository for admin operations
class AdminRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  /// Log an admin action to the audit trail
  Future<void> logAdminAction({
    required String actionType,
    required String targetType,
    required String targetId,
    required String targetEmail,
    required String targetName,
    String reason = '',
    required Map<String, dynamic> previousState,
    required Map<String, dynamic> newState,
  }) async {
    try {
      final admin = _auth.currentUser;
      if (admin == null) {
        throw Exception('No admin user logged in');
      }

      final actionData = AdminActionModel(
        actionId: '', // Will be set by Firestore
        adminId: admin.uid,
        adminEmail: admin.email ?? '',
        actionType: actionType,
        targetType: targetType,
        targetId: targetId,
        targetEmail: targetEmail,
        targetName: targetName,
        reason: reason,
        previousState: previousState,
        newState: newState,
        timestamp: DateTime.now(),
        metadata: {
          'deviceInfo': 'Web', // TODO: Get actual device info
          'ipAddress': '', // TODO: Get IP address if available
        },
      );

      await _firestore
          .collection('adminActions')
          .add(actionData.toFirestore());
    } catch (e) {
      throw Exception('Failed to log admin action: $e');
    }
  }

  /// Update user status (activate/deactivate)
  Future<void> updateUserStatus({
    required String userId,
    required bool isActive,
    String reason = '',
  }) async {
    try {
      // Get current user data
      final userDoc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final previousState = userDoc.data()!;

      // Update user status
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .update({'isActive': isActive});

      // Log action
      await logAdminAction(
        actionType: isActive ? 'activate_user' : 'deactivate_user',
        targetType: 'user',
        targetId: userId,
        targetEmail: previousState['email'] ?? '',
        targetName: previousState['name'] ?? '',
        reason: reason,
        previousState: {'isActive': previousState['isActive']},
        newState: {'isActive': isActive},
      );
    } catch (e) {
      throw Exception('Failed to update user status: $e');
    }
  }

  /// Update driver status (activate/deactivate)
  Future<void> updateDriverStatus({
    required String driverId,
    required bool isActive,
    String reason = '',
  }) async {
    try {
      // Get current driver data
      final driverDoc = await _firestore
          .collection(FirebaseConstants.driversCollection)
          .doc(driverId)
          .get();

      if (!driverDoc.exists) {
        throw Exception('Driver not found');
      }

      // Get user data for email/name
      final userDoc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(driverId)
          .get();

      final previousState = driverDoc.data()!;
      final userData = userDoc.data()!;

      // Update driver status
      await _firestore
          .collection(FirebaseConstants.driversCollection)
          .doc(driverId)
          .update({'isActive': isActive});

      // Also update user collection
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(driverId)
          .update({'isActive': isActive});

      // Log action
      await logAdminAction(
        actionType: isActive ? 'activate_driver' : 'deactivate_driver',
        targetType: 'driver',
        targetId: driverId,
        targetEmail: userData['email'] ?? '',
        targetName: userData['name'] ?? '',
        reason: reason,
        previousState: {'isActive': previousState['isActive'] ?? true},
        newState: {'isActive': isActive},
      );
    } catch (e) {
      throw Exception('Failed to update driver status: $e');
    }
  }

  /// Get all users (paginated)
  Future<List<UserModel>> getAllUsers({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection(FirebaseConstants.usersCollection)
          .where('userType', isEqualTo: 'user')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Failed to get users: $e');
    }
  }

  /// Get all drivers (paginated)
  Future<List<UserModel>> getAllDrivers({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection(FirebaseConstants.usersCollection)
          .where('userType', isEqualTo: 'driver')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Failed to get drivers: $e');
    }
  }

  /// Get admin actions (audit log) - paginated
  Future<List<AdminActionModel>> getAdminActions({
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection('adminActions')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => AdminActionModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Failed to get admin actions: $e');
    }
  }

  /// Update user contact information
  Future<void> updateUserContactInfo({
    required String userId,
    String? phoneNumber,
    String? homeAddress,
    String reason = '',
  }) async {
    try {
      // Get current user data
      final userDoc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final previousState = userDoc.data()!;
      final updates = <String, dynamic>{};
      final newState = <String, dynamic>{};

      // Update phone number if provided
      if (phoneNumber != null) {
        updates['phoneNumber'] = phoneNumber;
        newState['phoneNumber'] = phoneNumber;
        
        await logAdminAction(
          actionType: 'update_user_phone',
          targetType: 'user',
          targetId: userId,
          targetEmail: previousState['email'] ?? '',
          targetName: previousState['name'] ?? '',
          reason: reason,
          previousState: {'phoneNumber': previousState['phoneNumber'] ?? ''},
          newState: {'phoneNumber': phoneNumber},
        );
      }

      // Update home address if provided
      if (homeAddress != null) {
        updates['homeAddress'] = homeAddress;
        newState['homeAddress'] = homeAddress;
        
        await logAdminAction(
          actionType: 'update_user_address',
          targetType: 'user',
          targetId: userId,
          targetEmail: previousState['email'] ?? '',
          targetName: previousState['name'] ?? '',
          reason: reason,
          previousState: {'homeAddress': previousState['homeAddress'] ?? ''},
          newState: {'homeAddress': homeAddress},
        );
      }

      // Update Firestore
      if (updates.isNotEmpty) {
        await _firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(userId)
            .update(updates);

        // Also update userProfiles if address changed
        if (homeAddress != null) {
          await _firestore
              .collection(FirebaseConstants.userProfilesCollection)
              .doc(userId)
              .update({'homeAddress': homeAddress});
        }
      }
    } catch (e) {
      throw Exception('Failed to update user contact info: $e');
    }
  }

  /// Get all ride requests (paginated)
  Future<List<RideRequestModel>> getAllRides({
    int limit = 100,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection(FirebaseConstants.rideRequestsCollection)
          .orderBy('requestedAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => RideRequestModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Failed to get rides: $e');
    }
  }

  /// Get rides by status
  Future<List<RideRequestModel>> getRidesByStatus({
    required String status,
    int limit = 100,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.rideRequestsCollection)
          .where('status', isEqualTo: status)
          .orderBy('requestedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => RideRequestModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Failed to get rides by status: $e');
    }
  }

  /// Get rides within date range
  Future<List<RideRequestModel>> getRidesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 100,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.rideRequestsCollection)
          .where('requestedAt', 
                 isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('requestedAt', 
                 isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('requestedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => RideRequestModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Failed to get rides by date range: $e');
    }
  }
}

