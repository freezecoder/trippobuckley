import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/enums/ride_status.dart';

/// Model representing a ride request
class RideRequestModel {
  final String id;
  final String userId;
  final String? driverId;
  final String userEmail;
  final String? driverEmail;
  final RideStatus status;
  final GeoPoint pickupLocation;
  final String pickupAddress;
  final GeoPoint dropoffLocation;
  final String dropoffAddress;
  final DateTime? scheduledTime;
  final DateTime requestedAt;
  final DateTime? acceptedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String vehicleType;
  final double fare;
  final double distance;
  final int duration;
  final Map<String, dynamic>? route;
  final double? userRating;
  final double? driverRating;
  final String? userFeedback;
  final String? driverFeedback;
  final List<String>? declinedBy; // List of driver IDs who declined this ride
  
  // Payment fields
  final String paymentMethod; // 'card' or 'cash'
  final String? paymentMethodId; // Stripe payment method ID (null for cash)
  final String? paymentMethodLast4; // Last 4 digits of card (null for cash)
  final String? paymentMethodBrand; // Card brand like 'visa', 'mastercard' (null for cash)
  final String? stripePaymentIntentId; // Stripe payment intent ID (null for cash or before payment)
  final String? paymentStatus; // 'pending', 'completed', 'failed', 'cancelled'

  RideRequestModel({
    required this.id,
    required this.userId,
    this.driverId,
    required this.userEmail,
    this.driverEmail,
    required this.status,
    required this.pickupLocation,
    required this.pickupAddress,
    required this.dropoffLocation,
    required this.dropoffAddress,
    this.scheduledTime,
    required this.requestedAt,
    this.acceptedAt,
    this.startedAt,
    this.completedAt,
    required this.vehicleType,
    required this.fare,
    required this.distance,
    required this.duration,
    this.route,
    this.userRating,
    this.driverRating,
    this.userFeedback,
    this.driverFeedback,
    this.declinedBy,
    this.paymentMethod = 'cash', // Default to cash
    this.paymentMethodId,
    this.paymentMethodLast4,
    this.paymentMethodBrand,
    this.stripePaymentIntentId,
    this.paymentStatus = 'pending',
  });

  /// Create RideRequestModel from Firestore document
  factory RideRequestModel.fromFirestore(Map<String, dynamic> data, String id) {
    return RideRequestModel(
      id: id,
      userId: data['userId'] ?? '',
      driverId: data['driverId'],
      userEmail: data['userEmail'] ?? '',
      driverEmail: data['driverEmail'],
      status: RideStatus.fromString(data['status'] ?? 'pending'),
      pickupLocation: data['pickupLocation'] as GeoPoint,
      pickupAddress: data['pickupAddress'] ?? '',
      dropoffLocation: data['dropoffLocation'] as GeoPoint,
      dropoffAddress: data['dropoffAddress'] ?? '',
      scheduledTime: (data['scheduledTime'] as Timestamp?)?.toDate(),
      requestedAt: (data['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      acceptedAt: (data['acceptedAt'] as Timestamp?)?.toDate(),
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      vehicleType: data['vehicleType'] ?? 'Car',
      fare: (data['fare'] ?? 0.0).toDouble(),
      distance: (data['distance'] ?? 0.0).toDouble(),
      duration: data['duration'] ?? 0,
      route: data['route'] as Map<String, dynamic>?,
      userRating: (data['userRating'] as num?)?.toDouble(),
      driverRating: (data['driverRating'] as num?)?.toDouble(),
      userFeedback: data['userFeedback'] as String?,
      driverFeedback: data['driverFeedback'] as String?,
      declinedBy: (data['declinedBy'] as List<dynamic>?)?.cast<String>(),
      paymentMethod: data['paymentMethod'] ?? 'cash',
      paymentMethodId: data['paymentMethodId'] as String?,
      paymentMethodLast4: data['paymentMethodLast4'] as String?,
      paymentMethodBrand: data['paymentMethodBrand'] as String?,
      stripePaymentIntentId: data['stripePaymentIntentId'] as String?,
      paymentStatus: data['paymentStatus'] ?? 'pending',
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'driverId': driverId,
      'userEmail': userEmail,
      'driverEmail': driverEmail,
      'status': status.toFirestore(),
      'pickupLocation': pickupLocation,
      'pickupAddress': pickupAddress,
      'dropoffLocation': dropoffLocation,
      'dropoffAddress': dropoffAddress,
      'scheduledTime': scheduledTime != null ? Timestamp.fromDate(scheduledTime!) : null,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'vehicleType': vehicleType,
      'fare': fare,
      'distance': distance,
      'duration': duration,
      'route': route,
      'userRating': userRating,
      'driverRating': driverRating,
      'userFeedback': userFeedback,
      'driverFeedback': driverFeedback,
      'declinedBy': declinedBy,
      'paymentMethod': paymentMethod,
      'paymentMethodId': paymentMethodId,
      'paymentMethodLast4': paymentMethodLast4,
      'paymentMethodBrand': paymentMethodBrand,
      'stripePaymentIntentId': stripePaymentIntentId,
      'paymentStatus': paymentStatus,
    };
  }

  /// Check if ride is scheduled for future
  bool get isScheduled => scheduledTime != null;

  /// Check if ride is active
  bool get isActive => status.isActive;

  /// Check if ride is finished
  bool get isFinished => status.isFinished;

  /// Get status display text
  String get statusDisplayText => status.displayName;

  /// Get actual ride duration in minutes (from startedAt to completedAt)
  int? get actualDurationMinutes {
    if (startedAt == null || completedAt == null) return null;
    final duration = completedAt!.difference(startedAt!);
    return duration.inMinutes;
  }

  /// Get actual ride duration formatted as string
  String get actualDurationFormatted {
    final minutes = actualDurationMinutes;
    if (minutes == null) return 'N/A';
    
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hours}h ${mins}m';
    }
  }

  /// Check if ride duration is suspicious (too short, possible fraud)
  bool get isSuspiciouslyShort {
    final minutes = actualDurationMinutes;
    if (minutes == null) return false;
    return minutes < 1; // Less than 1 minute is suspicious
  }

  /// Get elapsed time since ride started (for ongoing rides)
  Duration? get elapsedTime {
    if (startedAt == null) return null;
    return DateTime.now().difference(startedAt!);
  }

  /// Get elapsed time formatted as string (for ongoing rides)
  String get elapsedTimeFormatted {
    final elapsed = elapsedTime;
    if (elapsed == null) return '0m';
    
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;
    
    if (minutes < 60) {
      return '${minutes}m ${seconds}s';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hours}h ${mins}m';
    }
  }

  /// Copy with method for immutability
  RideRequestModel copyWith({
    String? driverId,
    String? driverEmail,
    RideStatus? status,
    DateTime? acceptedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    double? fare,
  }) {
    return RideRequestModel(
      id: id,
      userId: userId,
      driverId: driverId ?? this.driverId,
      userEmail: userEmail,
      driverEmail: driverEmail ?? this.driverEmail,
      status: status ?? this.status,
      pickupLocation: pickupLocation,
      pickupAddress: pickupAddress,
      dropoffLocation: dropoffLocation,
      dropoffAddress: dropoffAddress,
      scheduledTime: scheduledTime,
      requestedAt: requestedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      vehicleType: vehicleType,
      fare: fare ?? this.fare,
      distance: distance,
      duration: duration,
      route: route,
    );
  }

  @override
  String toString() {
    return 'RideRequestModel(id: $id, status: ${status.name}, fare: \$$fare)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RideRequestModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

