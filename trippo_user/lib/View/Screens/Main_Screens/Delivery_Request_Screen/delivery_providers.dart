import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:btrips_unified/Model/direction_model.dart';

/// Delivery request state provider
class DeliveryRequestState {
  final Direction? pickupLocation;
  final String? deliveryCategory;
  final String? itemsDescription;
  final double itemCost;
  final String? verificationCode;

  DeliveryRequestState({
    this.pickupLocation,
    this.deliveryCategory,
    this.itemsDescription,
    this.itemCost = 0.0,
    this.verificationCode,
  });

  DeliveryRequestState copyWith({
    Direction? pickupLocation,
    String? deliveryCategory,
    String? itemsDescription,
    double? itemCost,
    String? verificationCode,
  }) {
    return DeliveryRequestState(
      pickupLocation: pickupLocation ?? this.pickupLocation,
      deliveryCategory: deliveryCategory ?? this.deliveryCategory,
      itemsDescription: itemsDescription ?? this.itemsDescription,
      itemCost: itemCost ?? this.itemCost,
      verificationCode: verificationCode ?? this.verificationCode,
    );
  }

  /// Check if all required fields are filled
  bool get isValid {
    return pickupLocation != null &&
        deliveryCategory != null &&
        deliveryCategory!.isNotEmpty &&
        itemsDescription != null &&
        itemsDescription!.trim().length >= 3;
  }
}

/// Provider for delivery request state
final deliveryRequestProvider =
    StateProvider<DeliveryRequestState>((ref) => DeliveryRequestState());

/// Provider for delivery mode flag (true when in delivery mode)
final isDeliveryModeProvider = StateProvider<bool>((ref) => false);

/// Provider for delivery pickup location
final deliveryPickupLocationProvider = StateProvider<Direction?>((ref) => null);

/// Provider for delivery category
final deliveryCategoryProvider = StateProvider<String?>((ref) => null);

/// Provider for delivery items description
final deliveryItemsDescriptionProvider = StateProvider<String?>((ref) => null);

/// Provider for delivery item cost
final deliveryItemCostProvider = StateProvider<double>((ref) => 0.0);

/// Provider for delivery verification code
final deliveryVerificationCodeProvider = StateProvider<String?>((ref) => null);

/// Provider for delivery fare (calculated)
final deliveryFareProvider = StateProvider<double?>((ref) => null);

/// Provider for delivery distance (in miles)
final deliveryDistanceProvider = StateProvider<double?>((ref) => null);

/// Provider for whether the delivery request is being processed
final isCreatingDeliveryProvider = StateProvider<bool>((ref) => false);

