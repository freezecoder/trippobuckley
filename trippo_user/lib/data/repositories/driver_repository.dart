import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/enums/driver_status.dart';
import '../models/driver_model.dart';

/// Repository for driver-specific operations
class DriverRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GeoFlutterFire _geo = GeoFlutterFire();

  /// Get driver data by ID
  Future<DriverModel?> getDriverById(String driverId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.driversCollection)
          .doc(driverId)
          .get();

      if (!doc.exists) return null;

      return DriverModel.fromFirestore(doc.data()!, driverId);
    } catch (e) {
      throw Exception('Failed to get driver: $e');
    }
  }

  /// Stream of driver data
  Stream<DriverModel?> driverStream(String driverId) {
    return _firestore
        .collection(FirebaseConstants.driversCollection)
        .doc(driverId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return DriverModel.fromFirestore(doc.data()!, driverId);
    });
  }

  /// Update driver configuration (vehicle info)
  Future<void> updateDriverConfiguration({
    required String driverId,
    required String carName,
    required String carPlateNum,
    required String carType,
  }) async {
    try {
      await _firestore
          .collection(FirebaseConstants.driversCollection)
          .doc(driverId)
          .update({
        FirebaseConstants.driverCarName: carName,
        FirebaseConstants.driverCarPlateNum: carPlateNum,
        FirebaseConstants.driverCarType: carType,
      });
    } catch (e) {
      throw Exception('Failed to update driver configuration: $e');
    }
  }

  /// Check if driver has completed configuration
  Future<bool> hasCompletedConfiguration(String driverId) async {
    try {
      final driver = await getDriverById(driverId);
      return driver?.hasCompletedConfiguration ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Update driver status (Offline, Idle, Busy)
  Future<void> updateDriverStatus({
    required String driverId,
    required DriverStatus status,
  }) async {
    try {
      await _firestore
          .collection(FirebaseConstants.driversCollection)
          .doc(driverId)
          .update({
        FirebaseConstants.driverStatus: status.toFirestore(),
      });
    } catch (e) {
      throw Exception('Failed to update driver status: $e');
    }
  }

  /// Update driver location
  Future<void> updateDriverLocation({
    required String driverId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final geoPoint = _geo.point(
        latitude: latitude,
        longitude: longitude,
      );

      await _firestore
          .collection(FirebaseConstants.driversCollection)
          .doc(driverId)
          .update({
        FirebaseConstants.driverLoc: geoPoint.data,
        FirebaseConstants.driverGeohash: geoPoint.hash,
      });
    } catch (e) {
      throw Exception('Failed to update driver location: $e');
    }
  }

  /// Get nearby available drivers
  Stream<List<DriverModel>> getNearbyDrivers({
    required double latitude,
    required double longitude,
    double radiusInKm = FirebaseConstants.nearbyDriversRadiusKm,
  }) {
    try {
      final center = _geo.point(
        latitude: latitude,
        longitude: longitude,
      );

      // Query drivers within radius
      return _geo
          .collection(
            collectionRef: _firestore.collection(FirebaseConstants.driversCollection),
          )
          .within(
            center: center,
            radius: radiusInKm,
            field: FirebaseConstants.driverLoc,
          )
          .map((docs) {
        return docs
            .where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final status = data[FirebaseConstants.driverStatus] as String?;
              return status == 'Idle'; // Only show available drivers
            })
            .map((doc) => DriverModel.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to get nearby drivers: $e');
    }
  }

  /// Update driver rating
  Future<void> updateRating({
    required String driverId,
    required double newRating,
  }) async {
    try {
      final driver = await getDriverById(driverId);
      if (driver == null) return;

      // Calculate new average rating
      final totalRides = driver.totalRides;
      final currentRating = driver.rating;
      final updatedRating =
          ((currentRating * totalRides) + newRating) / (totalRides + 1);

      await _firestore
          .collection(FirebaseConstants.driversCollection)
          .doc(driverId)
          .update({
        FirebaseConstants.driverRating: updatedRating,
      });
    } catch (e) {
      throw Exception('Failed to update rating: $e');
    }
  }

  /// Increment total rides
  Future<void> incrementTotalRides(String driverId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.driversCollection)
          .doc(driverId)
          .update({
        FirebaseConstants.driverTotalRides: FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to increment total rides: $e');
    }
  }

  /// Update earnings
  Future<void> addEarnings({
    required String driverId,
    required double amount,
  }) async {
    try {
      await _firestore
          .collection(FirebaseConstants.driversCollection)
          .doc(driverId)
          .update({
        FirebaseConstants.driverEarnings: FieldValue.increment(amount),
      });
    } catch (e) {
      throw Exception('Failed to update earnings: $e');
    }
  }

  /// Update driver profile
  Future<void> updateDriverProfile({
    required String driverId,
    String? licenseNumber,
    String? vehicleRegistration,
  }) async {
    try {
      final Map<String, dynamic> updates = {};

      if (licenseNumber != null) {
        updates[FirebaseConstants.driverLicenseNumber] = licenseNumber;
      }
      if (vehicleRegistration != null) {
        updates[FirebaseConstants.driverVehicleRegistration] =
            vehicleRegistration;
      }

      if (updates.isNotEmpty) {
        await _firestore
            .collection(FirebaseConstants.driversCollection)
            .doc(driverId)
            .update(updates);
      }
    } catch (e) {
      throw Exception('Failed to update driver profile: $e');
    }
  }

  /// Set driver verification status (admin only)
  Future<void> setVerificationStatus({
    required String driverId,
    required bool isVerified,
  }) async {
    try {
      await _firestore
          .collection(FirebaseConstants.driversCollection)
          .doc(driverId)
          .update({
        FirebaseConstants.driverIsVerified: isVerified,
      });
    } catch (e) {
      throw Exception('Failed to update verification status: $e');
    }
  }
}

