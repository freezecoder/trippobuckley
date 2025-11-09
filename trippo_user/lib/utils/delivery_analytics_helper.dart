import '../data/models/ride_request_model.dart';

/// Helper class for delivery analytics and insights
class DeliveryAnalyticsHelper {
  /// Calculate average delivery time for a list of deliveries
  static Duration? calculateAverageDeliveryTime(List<RideRequestModel> deliveries) {
    final completedDeliveries = deliveries
        .where((d) => d.isDelivery && d.deliveryDuration != null)
        .toList();

    if (completedDeliveries.isEmpty) return null;

    final totalMinutes = completedDeliveries
        .map((d) => d.deliveryDuration!.inMinutes)
        .reduce((a, b) => a + b);

    final avgMinutes = totalMinutes ~/ completedDeliveries.length;
    return Duration(minutes: avgMinutes);
  }

  /// Get performance metrics for a delivery
  static Map<String, dynamic> getDeliveryMetrics(RideRequestModel delivery) {
    return {
      'deliveryId': delivery.id,
      'totalDuration': delivery.totalDurationFormatted,
      'acceptanceTime': delivery.acceptanceDurationFormatted,
      'pickupTime': delivery.pickupDurationFormatted,
      'deliveryTime': delivery.deliveryDurationFormatted,
      'confirmationTime': delivery.confirmationDurationFormatted,
      'wasFastAcceptance': delivery.wasFastAcceptance,
      'wasFastDelivery': delivery.wasFastDelivery,
      'wasQuickConfirmation': delivery.wasQuickConfirmation,
      'wasFastOverall': delivery.wasFastOverall,
      'performanceScore': _calculatePerformanceScore(delivery),
    };
  }

  /// Calculate overall performance score (0-100)
  static int _calculatePerformanceScore(RideRequestModel delivery) {
    int score = 50; // Start at 50

    // Fast acceptance: +15 points
    if (delivery.wasFastAcceptance) score += 15;

    // Fast delivery: +20 points
    if (delivery.wasFastDelivery) score += 20;

    // Quick confirmation: +10 points
    if (delivery.wasQuickConfirmation) score += 10;

    // Fast overall: +5 points
    if (delivery.wasFastOverall) score += 5;

    return score.clamp(0, 100);
  }

  /// Get stage breakdown for display
  static List<Map<String, dynamic>> getStageBreakdown(RideRequestModel delivery) {
    return [
      {
        'stage': 'Requested',
        'timestamp': delivery.requestedAt,
        'duration': null,
      },
      if (delivery.acceptedAt != null)
        {
          'stage': 'Accepted',
          'timestamp': delivery.acceptedAt,
          'duration': delivery.acceptanceDuration,
          'durationText': delivery.acceptanceDurationFormatted,
          'isFast': delivery.wasFastAcceptance,
        },
      if (delivery.startedAt != null)
        {
          'stage': 'Started Delivery',
          'timestamp': delivery.startedAt,
          'duration': delivery.pickupDuration,
          'durationText': delivery.pickupDurationFormatted,
        },
      if (delivery.deliveredAt != null)
        {
          'stage': 'Delivered',
          'timestamp': delivery.deliveredAt,
          'duration': delivery.deliveryDuration,
          'durationText': delivery.deliveryDurationFormatted,
          'isFast': delivery.wasFastDelivery,
        },
      if (delivery.confirmedAt != null)
        {
          'stage': 'Confirmed',
          'timestamp': delivery.confirmedAt,
          'duration': delivery.confirmationDuration,
          'durationText': delivery.confirmationDurationFormatted,
          'isFast': delivery.wasQuickConfirmation,
        },
      if (delivery.completedAt != null)
        {
          'stage': 'Completed',
          'timestamp': delivery.completedAt,
          'duration': delivery.totalDuration,
          'durationText': delivery.totalDurationFormatted,
        },
      if (delivery.cancelledAt != null)
        {
          'stage': 'Cancelled',
          'timestamp': delivery.cancelledAt,
          'duration': delivery.cancellationDuration,
          'cancelledBy': delivery.cancelledBy,
          'reason': delivery.cancellationReason,
        },
    ];
  }

  /// Generate summary text for delivery
  static String generateDeliverySummary(RideRequestModel delivery) {
    final buffer = StringBuffer();
    
    buffer.writeln('Delivery #${delivery.id.substring(0, 8)}');
    buffer.writeln('Category: ${delivery.deliveryCategory ?? "N/A"}');
    buffer.writeln('Items: ${delivery.deliveryItemsDescription ?? "N/A"}');
    buffer.writeln('');
    
    if (delivery.acceptanceDuration != null) {
      buffer.writeln('⏱️ Driver accepted in: ${delivery.acceptanceDurationFormatted}');
    }
    
    if (delivery.deliveryDuration != null) {
      buffer.writeln('🚚 Delivery time: ${delivery.deliveryDurationFormatted}');
    }
    
    if (delivery.confirmationDuration != null) {
      buffer.writeln('✅ Customer confirmed in: ${delivery.confirmationDurationFormatted}');
    }
    
    if (delivery.totalDuration != null) {
      buffer.writeln('📊 Total time: ${delivery.totalDurationFormatted}');
    }
    
    return buffer.toString();
  }

  /// Check if delivery needs attention (taking too long)
  static bool needsAttention(RideRequestModel delivery) {
    // Pending for > 5 minutes
    if (delivery.status.name == 'pending') {
      final waitTime = DateTime.now().difference(delivery.requestedAt);
      if (waitTime.inMinutes > 5) return true;
    }

    // Accepted but not started after 15 minutes
    if (delivery.status.name == 'accepted' && delivery.acceptedAt != null) {
      final waitTime = DateTime.now().difference(delivery.acceptedAt!);
      if (waitTime.inMinutes > 15) return true;
    }

    // Ongoing for > 45 minutes
    if (delivery.status.name == 'ongoing' && delivery.startedAt != null) {
      final duration = DateTime.now().difference(delivery.startedAt!);
      if (duration.inMinutes > 45) return true;
    }

    // Delivered but not confirmed after 10 minutes
    if (delivery.status.name == 'delivered' && delivery.deliveredAt != null) {
      final waitTime = DateTime.now().difference(delivery.deliveredAt!);
      if (waitTime.inMinutes > 10) return true;
    }

    return false;
  }
}

