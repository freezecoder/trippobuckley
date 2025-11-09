import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/ride_request_model.dart';

/// Visual timeline showing all stages of a delivery/ride with timestamps
class DeliveryTimelineWidget extends StatelessWidget {
  final RideRequestModel ride;
  final bool compact;

  const DeliveryTimelineWidget({
    super.key,
    required this.ride,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final stages = _buildStages();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Timeline',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (ride.totalDuration != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ride.wasFastOverall ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Total: ${ride.totalDurationFormatted}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          ...stages.map((stage) => _buildStageItem(stage, compact)),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _buildStages() {
    final stages = <Map<String, dynamic>>[];

    // 1. Requested
    stages.add({
      'icon': Icons.add_circle_outline,
      'label': ride.isDelivery ? 'Delivery Requested' : 'Ride Requested',
      'timestamp': ride.requestedAt,
      'duration': null,
      'color': Colors.blue,
      'completed': true,
    });

    // 2. Accepted
    if (ride.acceptedAt != null) {
      stages.add({
        'icon': Icons.check_circle_outline,
        'label': 'Driver Accepted',
        'timestamp': ride.acceptedAt,
        'duration': ride.acceptanceDuration,
        'durationText': ride.acceptanceDurationFormatted,
        'isFast': ride.wasFastAcceptance,
        'color': Colors.green,
        'completed': true,
      });
    }

    // 3. Started
    if (ride.startedAt != null) {
      stages.add({
        'icon': Icons.local_shipping,
        'label': ride.isDelivery ? 'Started Delivery' : 'Ride Started',
        'timestamp': ride.startedAt,
        'duration': ride.pickupDuration,
        'durationText': ride.pickupDurationFormatted,
        'color': Colors.blue,
        'completed': true,
      });
    }

    // 4. Delivered
    if (ride.deliveredAt != null) {
      stages.add({
        'icon': Icons.delivery_dining,
        'label': ride.isDelivery ? 'Items Delivered' : 'Ride Completed',
        'timestamp': ride.deliveredAt,
        'duration': ride.deliveryDuration,
        'durationText': ride.deliveryDurationFormatted,
        'isFast': ride.wasFastDelivery,
        'color': Colors.purple,
        'completed': true,
      });
    }

    // 5. Confirmed
    if (ride.confirmedAt != null) {
      stages.add({
        'icon': Icons.verified,
        'label': 'Customer Confirmed',
        'timestamp': ride.confirmedAt,
        'duration': ride.confirmationDuration,
        'durationText': ride.confirmationDurationFormatted,
        'isFast': ride.wasQuickConfirmation,
        'color': Colors.green,
        'completed': true,
      });
    }

    // 6. Completed
    if (ride.completedAt != null) {
      stages.add({
        'icon': Icons.check_circle,
        'label': 'Transaction Complete',
        'timestamp': ride.completedAt,
        'duration': ride.totalDuration,
        'durationText': ride.totalDurationFormatted,
        'color': Colors.green,
        'completed': true,
      });
    }

    // Special: Cancelled
    if (ride.cancelledAt != null) {
      stages.add({
        'icon': Icons.cancel,
        'label': 'Cancelled',
        'timestamp': ride.cancelledAt,
        'duration': ride.cancellationDuration,
        'durationText': ride.cancellationDuration != null 
            ? '${ride.cancellationDuration!.inMinutes}m' 
            : null,
        'cancelledBy': ride.cancelledBy,
        'reason': ride.cancellationReason,
        'color': Colors.red,
        'completed': true,
      });
    }

    return stages;
  }

  Widget _buildStageItem(Map<String, dynamic> stage, bool compact) {
    final icon = stage['icon'] as IconData;
    final label = stage['label'] as String;
    final timestamp = stage['timestamp'] as DateTime?;
    final durationText = stage['durationText'] as String?;
    final isFast = stage['isFast'] as bool?;
    final color = stage['color'] as Color;
    final completed = stage['completed'] as bool;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon with connecting line
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: completed ? color : Colors.grey[800],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: completed ? color : Colors.grey[700]!,
                    width: 2,
                  ),
                ),
                child: Icon(
                  icon,
                  color: completed ? Colors.white : Colors.grey[600],
                  size: 20,
                ),
              ),
              if (!compact)
                Container(
                  width: 2,
                  height: 20,
                  color: Colors.grey[800],
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Stage info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: completed ? Colors.white : Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isFast == true)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'FAST',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                if (timestamp != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d, h:mm a').format(timestamp),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
                if (durationText != null && !compact) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.timer, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Took $durationText',
                        style: TextStyle(
                          color: isFast == true ? Colors.green : Colors.grey[600],
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
                if (stage['cancelledBy'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'By: ${stage['cancelledBy']}',
                    style: TextStyle(
                      color: Colors.red[300],
                      fontSize: 11,
                    ),
                  ),
                  if (stage['reason'] != null)
                    Text(
                      stage['reason'],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

