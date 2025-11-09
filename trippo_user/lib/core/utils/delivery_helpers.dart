import 'dart:math';

/// Helper utilities for delivery feature
class DeliveryHelpers {
  /// Generate a random 5-digit verification code
  static String generateVerificationCode() {
    final random = Random();
    final code = random.nextInt(90000) + 10000; // Generates 10000-99999
    return code.toString();
  }

  /// Validate delivery request data
  static Map<String, dynamic> validateDeliveryRequest({
    required String? pickupAddress,
    required String? deliveryCategory,
    required String? itemsDescription,
    required double? itemCost,
  }) {
    final errors = <String>[];

    if (pickupAddress == null || pickupAddress.trim().isEmpty) {
      errors.add('Please select a pickup location');
    }

    if (deliveryCategory == null || deliveryCategory.trim().isEmpty) {
      errors.add('Please select a delivery category');
    }

    if (itemsDescription == null || itemsDescription.trim().isEmpty) {
      errors.add('Please enter a description of items');
    } else if (itemsDescription.trim().length < 3) {
      errors.add('Item description must be at least 3 characters');
    }

    if (itemCost != null && (itemCost < 0 || itemCost > 500)) {
      errors.add('Item cost must be between \$0 and \$500');
    }

    return {
      'isValid': errors.isEmpty,
      'errors': errors,
    };
  }

  /// Calculate delivery fare based on distance and item cost
  /// Base fare + distance charge + item cost handling fee (10% of item cost)
  static double calculateDeliveryFare({
    required double distanceMiles,
    required double itemCost,
  }) {
    const baseFare = 5.0; // Base delivery fee
    const perMileRate = 2.0; // Per mile charge
    const itemCostFeePercent = 0.10; // 10% handling fee on item cost

    final distanceFee = distanceMiles * perMileRate;
    final itemHandlingFee = itemCost > 0 ? itemCost * itemCostFeePercent : 0.0;

    return baseFare + distanceFee + itemHandlingFee;
  }

  /// Get category icon emoji
  static String getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return '🍔';
      case 'medicines':
        return '💊';
      case 'groceries':
        return '🛒';
      case 'other':
        return '📦';
      default:
        return '📦';
    }
  }

  /// Get category display name
  static String getCategoryDisplayName(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return 'Food';
      case 'medicines':
        return 'Medicines';
      case 'groceries':
        return 'Groceries';
      case 'other':
        return 'Other';
      default:
        return 'Other';
    }
  }

  /// Format verification code for display (e.g., "12345" -> "1 2 3 4 5")
  static String formatVerificationCode(String code) {
    return code.split('').join(' ');
  }

  /// Get delivery categories list
  static List<String> getDeliveryCategories() {
    return ['food', 'medicines', 'groceries', 'other'];
  }
}

