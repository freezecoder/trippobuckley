import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import '../../core/enums/driver_status.dart';
import '../../core/constants/firebase_constants.dart';

/// Model representing driver-specific information
class DriverModel {
  final String uid;
  final String carName;
  final String carPlateNum;
  final String carType;
  final double rate;
  final DriverStatus driverStatus;
  final GeoFirePoint? driverLoc;
  final double rating;
  final int totalRides;
  final double earnings;
  final String licenseNumber;
  final String vehicleRegistration;
  final bool isVerified;

  DriverModel({
    required this.uid,
    required this.carName,
    required this.carPlateNum,
    required this.carType,
    this.rate = FirebaseConstants.defaultDriverRate,
    this.driverStatus = DriverStatus.offline,
    this.driverLoc,
    this.rating = FirebaseConstants.defaultRating,
    this.totalRides = FirebaseConstants.defaultTotalRides,
    this.earnings = FirebaseConstants.defaultEarnings,
    this.licenseNumber = '',
    this.vehicleRegistration = '',
    this.isVerified = false,
  });

  /// Create DriverModel from Firestore document
  factory DriverModel.fromFirestore(Map<String, dynamic> data, String uid) {
    GeoFirePoint? geoPoint;
    
    // Parse GeoFirePoint from driverLoc field
    if (data['driverLoc'] != null) {
      final locData = data['driverLoc'];
      if (locData is Map) {
        final geopoint = locData['geopoint'] as GeoPoint?;
        if (geopoint != null) {
          final geo = GeoFlutterFire();
          geoPoint = geo.point(
            latitude: geopoint.latitude,
            longitude: geopoint.longitude,
          );
        }
      }
    }

    return DriverModel(
      uid: uid,
      carName: data['carName'] ?? '',
      carPlateNum: data['carPlateNum'] ?? '',
      carType: data['carType'] ?? '',
      rate: (data['rate'] ?? FirebaseConstants.defaultDriverRate).toDouble(),
      driverStatus: DriverStatus.fromString(data['driverStatus'] ?? 'Offline'),
      driverLoc: geoPoint,
      rating: (data['rating'] ?? FirebaseConstants.defaultRating).toDouble(),
      totalRides: data['totalRides'] ?? FirebaseConstants.defaultTotalRides,
      earnings: (data['earnings'] ?? FirebaseConstants.defaultEarnings).toDouble(),
      licenseNumber: data['licenseNumber'] ?? '',
      vehicleRegistration: data['vehicleRegistration'] ?? '',
      isVerified: data['isVerified'] ?? false,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    final Map<String, dynamic> data = {
      'carName': carName,
      'carPlateNum': carPlateNum,
      'carType': carType,
      'rate': rate,
      'driverStatus': driverStatus.toFirestore(),
      'rating': rating,
      'totalRides': totalRides,
      'earnings': earnings,
      'licenseNumber': licenseNumber,
      'vehicleRegistration': vehicleRegistration,
      'isVerified': isVerified,
    };

    // Add location if available
    if (driverLoc != null) {
      data['driverLoc'] = driverLoc!.data;
      data['geohash'] = driverLoc!.hash;
    }

    return data;
  }

  /// Check if driver has completed configuration
  bool get hasCompletedConfiguration {
    return carName.isNotEmpty && 
           carPlateNum.isNotEmpty && 
           carType.isNotEmpty;
  }

  /// Check if driver is available for rides
  bool get isAvailable => driverStatus == DriverStatus.idle;

  /// Check if driver is online
  bool get isOnline => driverStatus.isOnline;

  /// Get display status text
  String get statusDisplayText => driverStatus.displayName;

  /// Copy with method for immutability
  DriverModel copyWith({
    String? carName,
    String? carPlateNum,
    String? carType,
    double? rate,
    DriverStatus? driverStatus,
    GeoFirePoint? driverLoc,
    double? rating,
    int? totalRides,
    double? earnings,
    String? licenseNumber,
    String? vehicleRegistration,
    bool? isVerified,
  }) {
    return DriverModel(
      uid: uid,
      carName: carName ?? this.carName,
      carPlateNum: carPlateNum ?? this.carPlateNum,
      carType: carType ?? this.carType,
      rate: rate ?? this.rate,
      driverStatus: driverStatus ?? this.driverStatus,
      driverLoc: driverLoc ?? this.driverLoc,
      rating: rating ?? this.rating,
      totalRides: totalRides ?? this.totalRides,
      earnings: earnings ?? this.earnings,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      vehicleRegistration: vehicleRegistration ?? this.vehicleRegistration,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  @override
  String toString() {
    return 'DriverModel(uid: $uid, carName: $carName, status: ${driverStatus.name})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DriverModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}

