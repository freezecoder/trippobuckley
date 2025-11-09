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
  final DateTime? deliveredAt;        // When driver marked as delivered
  final DateTime? confirmedAt;        // When customer confirmed receipt
  final DateTime? completedAt;
  final DateTime? cancelledAt;        // If/when delivery was cancelled
  final DateTime? paymentProcessedAt; // When payment was processed
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
  final String? paymentError; // Error message if payment failed
  
  // Delivery fields
  final bool isDelivery; // true if this is a delivery request, false for regular ride
  final String? deliveryCategory; // 'food', 'medicines', 'groceries', 'other'
  final String? deliveryItemsDescription; // Description of items to be delivered
  final double? deliveryItemCost; // Cost of items if driver needs to pay
  final String? deliveryVerificationCode; // 5-digit code for pickup verification
  final bool deliveryCodeVerified; // Whether the verification code was used
  
  // Confirmation & Cancellation tracking
  final bool confirmedByCustomer; // Whether customer confirmed receipt
  final String? cancelledBy; // Who cancelled: 'user', 'driver', 'system'
  final String? cancellationReason; // Reason for cancellation

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
    this.deliveredAt,
    this.confirmedAt,
    this.completedAt,
    this.cancelledAt,
    this.paymentProcessedAt,
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
    this.paymentError,
    this.isDelivery = false, // Default to regular ride
    this.deliveryCategory,
    this.deliveryItemsDescription,
    this.deliveryItemCost,
    this.deliveryVerificationCode,
    this.deliveryCodeVerified = false,
    this.confirmedByCustomer = false,
    this.cancelledBy,
    this.cancellationReason,
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
      deliveredAt: (data['deliveredAt'] as Timestamp?)?.toDate(),
      confirmedAt: (data['confirmedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      cancelledAt: (data['cancelledAt'] as Timestamp?)?.toDate(),
      paymentProcessedAt: (data['paymentProcessedAt'] as Timestamp?)?.toDate(),
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
      paymentError: data['paymentError'] as String?,
      isDelivery: data['isDelivery'] ?? false,
      deliveryCategory: data['deliveryCategory'] as String?,
      deliveryItemsDescription: data['deliveryItemsDescription'] as String?,
      deliveryItemCost: (data['deliveryItemCost'] as num?)?.toDouble(),
      deliveryVerificationCode: data['deliveryVerificationCode'] as String?,
      deliveryCodeVerified: data['deliveryCodeVerified'] ?? false,
      confirmedByCustomer: data['confirmedByCustomer'] ?? false,
      cancelledBy: data['cancelledBy'] as String?,
      cancellationReason: data['cancellationReason'] as String?,
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
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'confirmedAt': confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'paymentProcessedAt': paymentProcessedAt != null ? Timestamp.fromDate(paymentProcessedAt!) : null,
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
      'paymentError': paymentError,
      'isDelivery': isDelivery,
      'deliveryCategory': deliveryCategory,
      'deliveryItemsDescription': deliveryItemsDescription,
      'deliveryItemCost': deliveryItemCost,
      'deliveryVerificationCode': deliveryVerificationCode,
      'deliveryCodeVerified': deliveryCodeVerified,
      'confirmedByCustomer': confirmedByCustomer,
      'cancelledBy': cancelledBy,
      'cancellationReason': cancellationReason,
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

  // ============================================================================
  // NEW: Stage Duration Calculations for Analytics
  // ============================================================================

  /// Time taken for driver to accept after request (in minutes)
  Duration? get acceptanceDuration {
    if (acceptedAt == null) return null;
    return acceptedAt!.difference(requestedAt);
  }

  /// Time from acceptance to starting delivery (driver going to pickup)
  Duration? get pickupDuration {
    if (startedAt == null || acceptedAt == null) return null;
    return startedAt!.difference(acceptedAt!);
  }

  /// Time from start to delivery (actual delivery time)
  Duration? get deliveryDuration {
    if (deliveredAt == null || startedAt == null) return null;
    return deliveredAt!.difference(startedAt!);
  }

  /// Time for customer to confirm after delivery
  Duration? get confirmationDuration {
    if (confirmedAt == null || deliveredAt == null) return null;
    return confirmedAt!.difference(deliveredAt!);
  }

  /// Total time from request to completion
  Duration? get totalDuration {
    if (completedAt == null) return null;
    return completedAt!.difference(requestedAt);
  }

  /// Time until cancellation (if cancelled)
  Duration? get cancellationDuration {
    if (cancelledAt == null) return null;
    return cancelledAt!.difference(requestedAt);
  }

  // Formatted duration strings
  String get acceptanceDurationFormatted => _formatDuration(acceptanceDuration);
  String get pickupDurationFormatted => _formatDuration(pickupDuration);
  String get deliveryDurationFormatted => _formatDuration(deliveryDuration);
  String get confirmationDurationFormatted => _formatDuration(confirmationDuration);
  String get totalDurationFormatted => _formatDuration(totalDuration);

  /// Helper to format durations
  String _formatDuration(Duration? duration) {
    if (duration == null) return 'N/A';
    
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    
    if (minutes < 1) {
      return '${seconds}s';
    } else if (minutes < 60) {
      return '${minutes}m ${seconds}s';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hours}h ${mins}m';
    }
  }

  // Performance indicators
  /// Was driver acceptance fast? (< 2 minutes)
  bool get wasFastAcceptance => acceptanceDuration != null && acceptanceDuration!.inMinutes < 2;

  /// Was delivery fast? (< 30 minutes)
  bool get wasFastDelivery => deliveryDuration != null && deliveryDuration!.inMinutes < 30;

  /// Did customer confirm quickly? (< 5 minutes)
  bool get wasQuickConfirmation => confirmationDuration != null && confirmationDuration!.inMinutes < 5;

  /// Was overall delivery fast? (< 45 minutes total)
  bool get wasFastOverall => totalDuration != null && totalDuration!.inMinutes < 45;

  /// Copy with method for immutability
  RideRequestModel copyWith({
    String? driverId,
    String? driverEmail,
    RideStatus? status,
    DateTime? acceptedAt,
    DateTime? startedAt,
    DateTime? deliveredAt,
    DateTime? confirmedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    DateTime? paymentProcessedAt,
    double? fare,
    bool? confirmedByCustomer,
    String? cancelledBy,
    String? cancellationReason,
    String? paymentError,
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
      deliveredAt: deliveredAt ?? this.deliveredAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      paymentProcessedAt: paymentProcessedAt ?? this.paymentProcessedAt,
      vehicleType: vehicleType,
      fare: fare ?? this.fare,
      distance: distance,
      duration: duration,
      route: route,
      userRating: userRating,
      driverRating: driverRating,
      userFeedback: userFeedback,
      driverFeedback: driverFeedback,
      declinedBy: declinedBy,
      paymentMethod: paymentMethod,
      paymentMethodId: paymentMethodId,
      paymentMethodLast4: paymentMethodLast4,
      paymentMethodBrand: paymentMethodBrand,
      stripePaymentIntentId: stripePaymentIntentId,
      paymentStatus: paymentStatus,
      paymentError: paymentError ?? this.paymentError,
      isDelivery: isDelivery,
      deliveryCategory: deliveryCategory,
      deliveryItemsDescription: deliveryItemsDescription,
      deliveryItemCost: deliveryItemCost,
      deliveryVerificationCode: deliveryVerificationCode,
      deliveryCodeVerified: deliveryCodeVerified,
      confirmedByCustomer: confirmedByCustomer ?? this.confirmedByCustomer,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      cancellationReason: cancellationReason ?? this.cancellationReason,
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

