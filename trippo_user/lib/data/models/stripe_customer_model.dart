import 'package:cloud_firestore/cloud_firestore.dart';
import 'payment_method_model.dart';

/// Model representing a Stripe customer linked to a BTrips user
/// This collection stores the Stripe customer ID and billing information
class StripeCustomerModel {
  final String userId; // Firebase Auth UID
  final String stripeCustomerId; // Stripe customer ID (prefixed with BTRP)
  final String email;
  final String name;
  
  // Billing Address
  final BillingAddress? billingAddress;
  
  // Payment Methods (stored as sub-collection in Firestore)
  final List<PaymentMethodModel> paymentMethods;
  final String? defaultPaymentMethodId;
  
  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final Map<String, dynamic> metadata;

  StripeCustomerModel({
    required this.userId,
    required this.stripeCustomerId,
    required this.email,
    required this.name,
    this.billingAddress,
    this.paymentMethods = const [],
    this.defaultPaymentMethodId,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.metadata = const {},
  });

  /// Create StripeCustomerModel from Firestore document
  factory StripeCustomerModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return StripeCustomerModel(
      userId: docId, // Document ID is the user ID
      stripeCustomerId: data['stripeCustomerId'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      billingAddress: data['billingAddress'] != null
          ? BillingAddress.fromMap(data['billingAddress'])
          : null,
      paymentMethods: (data['paymentMethods'] as List<dynamic>?)
              ?.map((pm) => PaymentMethodModel.fromFirestore(pm))
              .toList() ??
          [],
      defaultPaymentMethodId: data['defaultPaymentMethodId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'stripeCustomerId': stripeCustomerId,
      'email': email,
      'name': name,
      'billingAddress': billingAddress?.toMap(),
      'paymentMethods': paymentMethods.map((pm) => pm.toFirestore()).toList(),
      'defaultPaymentMethodId': defaultPaymentMethodId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  /// Get default payment method
  PaymentMethodModel? get defaultPaymentMethod {
    if (defaultPaymentMethodId == null) return null;
    try {
      return paymentMethods.firstWhere(
        (pm) => pm.id == defaultPaymentMethodId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get active payment methods only
  List<PaymentMethodModel> get activePaymentMethods {
    return paymentMethods.where((pm) => pm.isActive).toList();
  }

  /// Check if has any active payment method
  bool get hasPaymentMethod {
    return activePaymentMethods.isNotEmpty;
  }

  /// Copy with method for immutability
  StripeCustomerModel copyWith({
    String? stripeCustomerId,
    String? email,
    String? name,
    BillingAddress? billingAddress,
    List<PaymentMethodModel>? paymentMethods,
    String? defaultPaymentMethodId,
    DateTime? updatedAt,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return StripeCustomerModel(
      userId: userId,
      stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
      email: email ?? this.email,
      name: name ?? this.name,
      billingAddress: billingAddress ?? this.billingAddress,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      defaultPaymentMethodId:
          defaultPaymentMethodId ?? this.defaultPaymentMethodId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'StripeCustomerModel(userId: $userId, stripeCustomerId: $stripeCustomerId, hasPaymentMethod: $hasPaymentMethod)';
  }
}

/// Model for billing address
class BillingAddress {
  final String line1;
  final String? line2;
  final String city;
  final String state;
  final String postalCode;
  final String country;

  BillingAddress({
    required this.line1,
    this.line2,
    required this.city,
    required this.state,
    required this.postalCode,
    this.country = 'US', // Default to US
  });

  /// Create from map
  factory BillingAddress.fromMap(Map<String, dynamic> data) {
    return BillingAddress(
      line1: data['line1'] ?? '',
      line2: data['line2'],
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      postalCode: data['postalCode'] ?? '',
      country: data['country'] ?? 'US',
    );
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'line1': line1,
      'line2': line2,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': country,
    };
  }

  /// Get formatted address string
  String get formattedAddress {
    final parts = <String>[
      line1,
      if (line2 != null && line2!.isNotEmpty) line2!,
      '$city, $state $postalCode',
      country,
    ];
    return parts.join('\n');
  }

  /// Get single line address
  String get singleLineAddress {
    final parts = <String>[
      line1,
      if (line2 != null && line2!.isNotEmpty) line2!,
      city,
      state,
      postalCode,
      country,
    ];
    return parts.join(', ');
  }

  /// Copy with method
  BillingAddress copyWith({
    String? line1,
    String? line2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
  }) {
    return BillingAddress(
      line1: line1 ?? this.line1,
      line2: line2 ?? this.line2,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
    );
  }

  @override
  String toString() => singleLineAddress;
}

