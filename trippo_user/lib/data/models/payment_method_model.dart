import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a payment method (credit/debit card)
class PaymentMethodModel {
  final String id;
  final String type; // "card", "cash", "wallet"
  final bool isDefault;
  
  // Card-specific fields (only for Stripe tokenized cards)
  final String last4;
  final String brand; // "Visa", "Mastercard", etc.
  final String expiryMonth;
  final String expiryYear;
  final String cardholderName;
  final String stripePaymentMethodId; // Stripe token
  
  // Metadata
  final DateTime addedAt;
  final String addedBy; // "user" or "admin"
  final DateTime? lastUsedAt;
  final bool isActive;

  PaymentMethodModel({
    required this.id,
    required this.type,
    this.isDefault = false,
    this.last4 = '',
    this.brand = '',
    this.expiryMonth = '',
    this.expiryYear = '',
    this.cardholderName = '',
    this.stripePaymentMethodId = '',
    required this.addedAt,
    this.addedBy = 'user',
    this.lastUsedAt,
    this.isActive = true,
  });

  /// Create PaymentMethodModel from Firestore document
  factory PaymentMethodModel.fromFirestore(Map<String, dynamic> data) {
    // Parse addedAt - can be either Timestamp or milliseconds number
    DateTime parsedAddedAt = DateTime.now();
    final addedAtData = data['addedAt'];
    if (addedAtData is Timestamp) {
      parsedAddedAt = addedAtData.toDate();
    } else if (addedAtData is int) {
      parsedAddedAt = DateTime.fromMillisecondsSinceEpoch(addedAtData);
    } else if (addedAtData is double) {
      parsedAddedAt = DateTime.fromMillisecondsSinceEpoch(addedAtData.toInt());
    }

    // Parse lastUsedAt - same logic
    DateTime? parsedLastUsedAt;
    final lastUsedAtData = data['lastUsedAt'];
    if (lastUsedAtData is Timestamp) {
      parsedLastUsedAt = lastUsedAtData.toDate();
    } else if (lastUsedAtData is int) {
      parsedLastUsedAt = DateTime.fromMillisecondsSinceEpoch(lastUsedAtData);
    } else if (lastUsedAtData is double) {
      parsedLastUsedAt = DateTime.fromMillisecondsSinceEpoch(lastUsedAtData.toInt());
    }

    return PaymentMethodModel(
      id: data['id'] ?? '',
      type: data['type'] ?? 'card',
      isDefault: data['isDefault'] ?? false,
      last4: data['last4'] ?? '',
      brand: data['brand'] ?? '',
      expiryMonth: data['expiryMonth'] ?? '',
      expiryYear: data['expiryYear'] ?? '',
      cardholderName: data['cardholderName'] ?? '',
      stripePaymentMethodId: data['stripePaymentMethodId'] ?? '',
      addedAt: parsedAddedAt,
      addedBy: data['addedBy'] ?? 'user',
      lastUsedAt: parsedLastUsedAt,
      isActive: data['isActive'] ?? true,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'type': type,
      'isDefault': isDefault,
      'last4': last4,
      'brand': brand,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      'cardholderName': cardholderName,
      'stripePaymentMethodId': stripePaymentMethodId,
      'addedAt': Timestamp.fromDate(addedAt),
      'addedBy': addedBy,
      'lastUsedAt': lastUsedAt != null ? Timestamp.fromDate(lastUsedAt!) : null,
      'isActive': isActive,
    };
  }

  /// Get display string for card (e.g., "•••• 4242")
  String get displayString {
    if (type == 'cash') return 'Cash';
    if (type == 'wallet') return 'Wallet';
    return '•••• $last4';
  }

  /// Get full display string with brand (e.g., "Visa •••• 4242")
  String get fullDisplayString {
    if (type == 'cash') return 'Cash';
    if (type == 'wallet') return 'Wallet';
    return '$brand •••• $last4';
  }

  /// Get expiry display string (e.g., "12/25")
  String get expiryDisplayString {
    if (expiryMonth.isEmpty || expiryYear.isEmpty) return '';
    return '$expiryMonth/$expiryYear';
  }

  /// Check if card is expired
  bool get isExpired {
    if (expiryMonth.isEmpty || expiryYear.isEmpty) return false;
    
    try {
      final month = int.parse(expiryMonth);
      final year = int.parse('20$expiryYear'); // Assuming 2-digit year
      final expiryDate = DateTime(year, month + 1, 0); // Last day of month
      return DateTime.now().isAfter(expiryDate);
    } catch (e) {
      return false;
    }
  }

  /// Copy with method for immutability
  PaymentMethodModel copyWith({
    String? id,
    String? type,
    bool? isDefault,
    String? last4,
    String? brand,
    String? expiryMonth,
    String? expiryYear,
    String? cardholderName,
    String? stripePaymentMethodId,
    DateTime? addedAt,
    String? addedBy,
    DateTime? lastUsedAt,
    bool? isActive,
  }) {
    return PaymentMethodModel(
      id: id ?? this.id,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
      last4: last4 ?? this.last4,
      brand: brand ?? this.brand,
      expiryMonth: expiryMonth ?? this.expiryMonth,
      expiryYear: expiryYear ?? this.expiryYear,
      cardholderName: cardholderName ?? this.cardholderName,
      stripePaymentMethodId: stripePaymentMethodId ?? this.stripePaymentMethodId,
      addedAt: addedAt ?? this.addedAt,
      addedBy: addedBy ?? this.addedBy,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'PaymentMethodModel(id: $id, type: $type, brand: $brand, last4: $last4)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentMethodModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

