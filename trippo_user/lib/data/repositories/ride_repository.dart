import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/enums/ride_status.dart';
import '../models/ride_request_model.dart';

/// Custom exception for when driver already has an active ride
class AlreadyHasActiveRideException implements Exception {
  final String message;
  AlreadyHasActiveRideException(this.message);
  
  @override
  String toString() => message;
}

/// Custom exception for when ride is no longer available (taken by another driver)
class RideNoLongerAvailableException implements Exception {
  final String message;
  RideNoLongerAvailableException(this.message);
  
  @override
  String toString() => message;
}

/// Repository for ride request operations
class RideRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Decline ride request (driver)
  /// Adds driver to declinedBy array so they won't see this ride again
  Future<void> declineRideRequest({
    required String rideId,
    required String driverId,
  }) async {
    try {
      // Add driver to the declinedBy array
      await _firestore
          .collection(FirebaseConstants.rideRequestsCollection)
          .doc(rideId)
          .update({
        'declinedBy': FieldValue.arrayUnion([driverId]),
      });
      
      print('✅ Driver $driverId declined ride $rideId');
    } catch (e) {
      throw Exception('Failed to decline ride request: $e');
    }
  }

  /// Create a new ride request
  Future<String> createRideRequest({
    required String userId,
    required String userEmail,
    required GeoPoint pickupLocation,
    required String pickupAddress,
    required GeoPoint dropoffLocation,
    required String dropoffAddress,
    DateTime? scheduledTime,
    required String vehicleType,
    required double fare,
    required double distance,
    required int duration,
    Map<String, dynamic>? route,
  }) async {
    try {
      final rideData = {
        FirebaseConstants.rideUserId: userId,
        FirebaseConstants.rideDriverId: null,
        FirebaseConstants.rideUserEmail: userEmail,
        FirebaseConstants.rideDriverEmail: null,
        FirebaseConstants.rideStatus: RideStatus.pending.toFirestore(),
        FirebaseConstants.ridePickupLocation: pickupLocation,
        FirebaseConstants.ridePickupAddress: pickupAddress,
        FirebaseConstants.rideDropoffLocation: dropoffLocation,
        FirebaseConstants.rideDropoffAddress: dropoffAddress,
        FirebaseConstants.rideScheduledTime:
            scheduledTime != null ? Timestamp.fromDate(scheduledTime) : null,
        FirebaseConstants.rideRequestedAt: FieldValue.serverTimestamp(),
        FirebaseConstants.rideAcceptedAt: null,
        FirebaseConstants.rideStartedAt: null,
        FirebaseConstants.rideCompletedAt: null,
        FirebaseConstants.rideVehicleType: vehicleType,
        FirebaseConstants.rideFare: fare,
        FirebaseConstants.rideDistance: distance,
        FirebaseConstants.rideDuration: duration,
        FirebaseConstants.rideRoute: route,
      };

      final docRef = await _firestore
          .collection(FirebaseConstants.rideRequestsCollection)
          .add(rideData);

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create ride request: $e');
    }
  }

  /// Get ride request by ID
  Future<RideRequestModel?> getRideRequest(String rideId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.rideRequestsCollection)
          .doc(rideId)
          .get();

      if (!doc.exists) return null;

      return RideRequestModel.fromFirestore(doc.data()!, rideId);
    } catch (e) {
      throw Exception('Failed to get ride request: $e');
    }
  }

  /// Stream of ride request
  Stream<RideRequestModel?> rideRequestStream(String rideId) {
    return _firestore
        .collection(FirebaseConstants.rideRequestsCollection)
        .doc(rideId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return RideRequestModel.fromFirestore(doc.data()!, rideId);
    });
  }

  /// Get pending ride requests (for drivers)
  /// Optionally filter by vehicle type to match driver's car
  /// Filters out rides the driver has declined
  Stream<List<RideRequestModel>> getPendingRideRequests({
    String? driverVehicleType,
    String? driverId,
  }) {
    // Note: Removed orderBy to avoid requiring a composite index
    // Sorting is done in-memory instead
    
    Query<Map<String, dynamic>> query = _firestore
        .collection(FirebaseConstants.rideRequestsCollection)
        .where(FirebaseConstants.rideStatus, isEqualTo: RideStatus.pending.toFirestore());
    
    // ✅ Filter by vehicle type if driver's vehicle type is provided
    if (driverVehicleType != null && driverVehicleType.isNotEmpty) {
      query = query.where(
        FirebaseConstants.rideVehicleType,
        isEqualTo: driverVehicleType,
      );
      print('🚗 Filtering pending rides for vehicle type: $driverVehicleType');
    }
    
    return query
        .limit(50) // Get more since we'll sort in-memory
        .snapshots()
        .handleError((error) {
          // Handle errors gracefully
          print('⚠️ Error loading pending rides: $error');
        })
        .map((snapshot) {
      final rides = snapshot.docs
          .map((doc) => RideRequestModel.fromFirestore(doc.data(), doc.id))
          .toList();
      
      // ✅ Filter out rides declined by this driver
      final filteredRides = driverId != null
          ? rides.where((ride) {
              final declinedBy = ride.declinedBy ?? [];
              return !declinedBy.contains(driverId);
            }).toList()
          : rides;
      
      // Sort by requestedAt in memory (newest first)
      filteredRides.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
      
      // Limit to reasonable number
      return filteredRides.take(FirebaseConstants.nearbyDriversLimit).toList();
    });
  }

  /// Get user's ride requests
  Stream<List<RideRequestModel>> getUserRideRequests(String userId) {
    return _firestore
        .collection(FirebaseConstants.rideRequestsCollection)
        .where(FirebaseConstants.rideUserId, isEqualTo: userId)
        .orderBy(FirebaseConstants.rideRequestedAt, descending: true)
        .limit(FirebaseConstants.rideHistoryLimit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RideRequestModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  /// Get driver's ride requests (active rides)
  Stream<List<RideRequestModel>> getDriverRideRequests(String driverId) {
    // Note: Removed orderBy to avoid requiring a composite index
    // Sorting is done in-memory instead
    return _firestore
        .collection(FirebaseConstants.rideRequestsCollection)
        .where(FirebaseConstants.rideDriverId, isEqualTo: driverId)
        .limit(50)
        .snapshots()
        .handleError((error) {
          // Handle errors gracefully
          print('⚠️ Error loading driver rides: $error');
        })
        .map((snapshot) {
      final rides = snapshot.docs
          .map((doc) => RideRequestModel.fromFirestore(doc.data(), doc.id))
          .toList();
      
      // Sort by requestedAt in memory (newest first)
      rides.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
      
      // Limit to reasonable number
      return rides.take(FirebaseConstants.rideHistoryLimit).toList();
    });
  }

  /// Accept ride request (driver)
  Future<void> acceptRideRequest({
    required String rideId,
    required String driverId,
    required String driverEmail,
  }) async {
    try {
      // ✅ CHECK 1: Verify driver doesn't already have an active ride
      final driverActiveRides = await _firestore
          .collection(FirebaseConstants.rideRequestsCollection)
          .where(FirebaseConstants.rideDriverId, isEqualTo: driverId)
          .where(FirebaseConstants.rideStatus, 
                 whereIn: [RideStatus.accepted.toFirestore(), RideStatus.ongoing.toFirestore()])
          .get();

      if (driverActiveRides.docs.isNotEmpty) {
        throw AlreadyHasActiveRideException(
          'You already have an active ride. Please complete your current ride before accepting another one.'
        );
      }

      // ✅ CHECK 2: Verify ride is still pending (not taken by another driver)
      final rideDoc = await _firestore
          .collection(FirebaseConstants.rideRequestsCollection)
          .doc(rideId)
          .get();
      
      if (!rideDoc.exists) {
        throw RideNoLongerAvailableException(
          'This ride request no longer exists.'
        );
      }
      
      final rideData = rideDoc.data()!;
      final currentStatus = rideData[FirebaseConstants.rideStatus] as String?;
      
      if (currentStatus != RideStatus.pending.toFirestore()) {
        throw RideNoLongerAvailableException(
          'This ride has already been accepted by another driver.'
        );
      }

      // ✅ All checks passed - Accept the ride
      await _firestore
          .collection(FirebaseConstants.rideRequestsCollection)
          .doc(rideId)
          .update({
        FirebaseConstants.rideDriverId: driverId,
        FirebaseConstants.rideDriverEmail: driverEmail,
        FirebaseConstants.rideStatus: RideStatus.accepted.toFirestore(),
        FirebaseConstants.rideAcceptedAt: FieldValue.serverTimestamp(),
      });
      
      print('✅ Ride $rideId accepted by driver $driverId');
    } on AlreadyHasActiveRideException {
      rethrow; // Rethrow custom exception as-is
    } on RideNoLongerAvailableException {
      rethrow; // Rethrow custom exception as-is
    } catch (e) {
      throw Exception('Failed to accept ride request: $e');
    }
  }

  /// Cancel ride request (driver or user)
  Future<void> cancelRideRequest({
    required String rideId,
    required String userId,
    String? cancellationReason,
  }) async {
    try {
      final updates = {
        FirebaseConstants.rideStatus: RideStatus.cancelled.toFirestore(),
        FirebaseConstants.rideCompletedAt: FieldValue.serverTimestamp(),
      };

      if (cancellationReason != null) {
        updates['cancellationReason'] = cancellationReason;
      }

      await _firestore
          .collection(FirebaseConstants.rideRequestsCollection)
          .doc(rideId)
          .update(updates);

      // Move cancelled ride to history
      await _moveToRideHistory(rideId);
    } catch (e) {
      throw Exception('Failed to cancel ride: $e');
    }
  }

  /// Start ride (driver arrived, passenger in vehicle)
  Future<void> startRide(String rideId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.rideRequestsCollection)
          .doc(rideId)
          .update({
        FirebaseConstants.rideStatus: RideStatus.ongoing.toFirestore(),
        FirebaseConstants.rideStartedAt: FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to start ride: $e');
    }
  }

  /// Complete ride
  Future<void> completeRide(String rideId) async {
    try {
      // First, get the ride data to extract fare and driver info
      final rideDoc = await _firestore
          .collection(FirebaseConstants.rideRequestsCollection)
          .doc(rideId)
          .get();
      
      if (!rideDoc.exists) {
        throw Exception('Ride not found');
      }
      
      final rideData = rideDoc.data()!;
      final driverId = rideData[FirebaseConstants.rideDriverId] as String?;
      final fare = (rideData[FirebaseConstants.rideFare] as num?)?.toDouble() ?? 0.0;
      
      // Update ride status to completed
      await _firestore
          .collection(FirebaseConstants.rideRequestsCollection)
          .doc(rideId)
          .update({
        FirebaseConstants.rideStatus: RideStatus.completed.toFirestore(),
        FirebaseConstants.rideCompletedAt: FieldValue.serverTimestamp(),
      });

      // Update driver earnings and ride count (only if driver exists and fare > 0)
      if (driverId != null && fare > 0) {
        await _firestore
            .collection(FirebaseConstants.driversCollection)
            .doc(driverId)
            .update({
          FirebaseConstants.driverEarnings: FieldValue.increment(fare),
          FirebaseConstants.driverTotalRides: FieldValue.increment(1),
        });
        
        print('✅ Driver earnings updated: +\$${fare.toStringAsFixed(2)}');
      }

      // Move to ride history collection
      await _moveToRideHistory(rideId);
    } catch (e) {
      throw Exception('Failed to complete ride: $e');
    }
  }

  /// Cancel ride
  Future<void> cancelRide(String rideId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.rideRequestsCollection)
          .doc(rideId)
          .update({
        FirebaseConstants.rideStatus: RideStatus.cancelled.toFirestore(),
        FirebaseConstants.rideCompletedAt: FieldValue.serverTimestamp(),
      });

      // Move cancelled ride to history
      await _moveToRideHistory(rideId);
    } catch (e) {
      throw Exception('Failed to cancel ride: $e');
    }
  }

  /// Update ride fare
  Future<void> updateRideFare({
    required String rideId,
    required double fare,
  }) async {
    try {
      await _firestore
          .collection(FirebaseConstants.rideRequestsCollection)
          .doc(rideId)
          .update({
        FirebaseConstants.rideFare: fare,
      });
    } catch (e) {
      throw Exception('Failed to update ride fare: $e');
    }
  }

  /// Add rating to ride (from user)
  Future<void> addUserRating({
    required String rideId,
    required double rating,
    String? feedback,
  }) async {
    try {
      final Map<String, dynamic> updates = {
        FirebaseConstants.rideUserRating: rating,
      };

      if (feedback != null && feedback.isNotEmpty) {
        updates[FirebaseConstants.rideUserFeedback] = feedback;
      }

      await _firestore
          .collection(FirebaseConstants.rideHistoryCollection)
          .doc(rideId)
          .update(updates);
    } catch (e) {
      throw Exception('Failed to add user rating: $e');
    }
  }

  /// Add rating to ride (from driver)
  Future<void> addDriverRating({
    required String rideId,
    required double rating,
    String? feedback,
  }) async {
    try {
      final Map<String, dynamic> updates = {
        FirebaseConstants.rideDriverRating: rating,
      };

      if (feedback != null && feedback.isNotEmpty) {
        updates[FirebaseConstants.rideDriverFeedback] = feedback;
      }

      await _firestore
          .collection(FirebaseConstants.rideHistoryCollection)
          .doc(rideId)
          .update(updates);
    } catch (e) {
      throw Exception('Failed to add driver rating: $e');
    }
  }

  /// Get user's ride history
  Future<List<RideRequestModel>> getUserRideHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.rideHistoryCollection)
          .where(FirebaseConstants.rideUserId, isEqualTo: userId)
          .orderBy(FirebaseConstants.rideCompletedAt, descending: true)
          .limit(FirebaseConstants.rideHistoryLimit)
          .get();

      return snapshot.docs
          .map((doc) => RideRequestModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      // Handle missing index or empty collection gracefully
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('index') || 
          errorMessage.contains('failed-precondition')) {
        // Index doesn't exist yet (no rides in collection)
        print('ℹ️ Ride history collection empty or index not created yet');
        return [];
      }
      throw Exception('Failed to get ride history: $e');
    }
  }

  /// Get driver's ride history
  Future<List<RideRequestModel>> getDriverRideHistory(String driverId) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.rideHistoryCollection)
          .where(FirebaseConstants.rideDriverId, isEqualTo: driverId)
          .orderBy(FirebaseConstants.rideCompletedAt, descending: true)
          .limit(FirebaseConstants.rideHistoryLimit)
          .get();

      return snapshot.docs
          .map((doc) => RideRequestModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      // Handle missing index or empty collection gracefully
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('index') || 
          errorMessage.contains('failed-precondition')) {
        // Index doesn't exist yet (no rides in collection)
        print('ℹ️ Ride history collection empty or index not created yet');
        return [];
      }
      throw Exception('Failed to get ride history: $e');
    }
  }

  /// Move completed ride to history collection (private helper)
  Future<void> _moveToRideHistory(String rideId) async {
    try {
      // Get ride data
      final rideDoc = await _firestore
          .collection(FirebaseConstants.rideRequestsCollection)
          .doc(rideId)
          .get();

      if (!rideDoc.exists) return;

      // Copy to history collection
      await _firestore
          .collection(FirebaseConstants.rideHistoryCollection)
          .doc(rideId)
          .set(rideDoc.data()!);

      // Note: We don't delete from rideRequests immediately
      // This allows for a grace period for any ongoing operations
    } catch (e) {
      // Don't throw error, as the main operation (completing ride) succeeded
      print('Warning: Failed to move ride to history: $e');
    }
  }

  /// Delete old completed rides (cleanup task)
  Future<void> cleanupOldRides({int daysOld = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      final cutoffTimestamp = Timestamp.fromDate(cutoffDate);

      final snapshot = await _firestore
          .collection(FirebaseConstants.rideRequestsCollection)
          .where(FirebaseConstants.rideStatus,
              whereIn: [RideStatus.completed.toFirestore(), RideStatus.cancelled.toFirestore()])
          .where(FirebaseConstants.rideCompletedAt, isLessThan: cutoffTimestamp)
          .get();

      // Delete old rides in batch
      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to cleanup old rides: $e');
    }
  }
}

