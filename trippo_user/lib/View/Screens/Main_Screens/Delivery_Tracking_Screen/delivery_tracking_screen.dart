import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:btrips_unified/data/models/ride_request_model.dart';
import 'package:btrips_unified/data/repositories/ride_repository.dart';
import 'package:btrips_unified/data/providers/ride_providers.dart';
import 'package:btrips_unified/Container/utils/error_notification.dart';

/// Screen for users to track their active delivery
class DeliveryTrackingScreen extends ConsumerStatefulWidget {
  final String deliveryId;

  const DeliveryTrackingScreen({
    super.key,
    required this.deliveryId,
  });

  @override
  ConsumerState<DeliveryTrackingScreen> createState() =>
      _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState
    extends ConsumerState<DeliveryTrackingScreen> {
  bool _isProcessing = false;

  String _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'food':
        return '🍔';
      case 'medicines':
        return '💊';
      case 'groceries':
        return '🛒';
      default:
        return '📦';
    }
  }

  Future<void> _cancelDelivery() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Cancel Delivery?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to cancel this delivery request?\n\nThis cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, Keep It'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isProcessing = true);

    try {
      await FirebaseFirestore.instance
          .collection('rideRequests')
          .doc(widget.deliveryId)
          .update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delivery cancelled'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ErrorNotification().showError(context, 'Error cancelling: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _confirmReceipt() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            const Text(
              'Confirm Receipt?',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: const Text(
          'Have you received all items in good condition?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not Yet'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Yes, Received'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isProcessing = true);

    try {
      final rideRepo = ref.read(rideRepositoryProvider);
      
      // Mark as completed and confirmed
      await FirebaseFirestore.instance
          .collection('rideRequests')
          .doc(widget.deliveryId)
          .update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'confirmedByCustomer': true,
      });

      // Complete ride for earnings (if not already done)
      try {
        await rideRepo.completeRide(widget.deliveryId);
      } catch (e) {
        // May already be completed, that's ok
        debugPrint('Note: Ride may already be completed: $e');
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Row(
              children: [
                Icon(Icons.celebration, color: Colors.green, size: 32),
                const SizedBox(width: 12),
                const Text(
                  'Thank You!',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            content: const Text(
              'Delivery confirmed! Thank you for using our service.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back to home
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorNotification().showError(context, 'Error confirming: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rideRequests')
          .doc(widget.deliveryId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Text('Delivery not found'),
            ),
          );
        }

        final delivery = RideRequestModel.fromFirestore(data, widget.deliveryId);
        final status = delivery.status.name;

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: const Color(0xff1a3646),
            foregroundColor: Colors.white,
            title: const Text('Delivery Status'),
            actions: [
              // Cancel button (only if not yet delivered/completed)
              if (status == 'pending' || status == 'accepted' || status == 'in_progress')
                IconButton(
                  icon: const Icon(Icons.cancel_outlined),
                  onPressed: _isProcessing ? null : _cancelDelivery,
                  tooltip: 'Cancel Delivery',
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Header
                _buildStatusHeader(delivery, status),

                const SizedBox(height: 24),

                // Verification Code
                _buildVerificationCodeCard(delivery),

                const SizedBox(height: 24),

                // Progress Steps
                _buildProgressSteps(status),

                const SizedBox(height: 24),

                // Delivery Details
                _buildDeliveryDetails(delivery),

                const SizedBox(height: 24),

                // Contact Driver (if delivery is active)
                if (status == 'accepted' || status == 'in_progress' || status == 'delivered')
                  _buildContactDriverSection(delivery),

                const SizedBox(height: 24),

                // Confirm Receipt Button (when delivered)
                if (status == 'delivered')
                  _buildConfirmReceiptButton(),

                // Completed Message
                if (status == 'completed')
                  _buildCompletedMessage(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusHeader(RideRequestModel delivery, String status) {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'pending':
        statusText = 'Finding Driver...';
        statusColor = Colors.orange;
        statusIcon = Icons.search;
        break;
      case 'accepted':
        statusText = 'Driver on Way to Pickup';
        statusColor = Colors.blue;
        statusIcon = Icons.local_shipping;
        break;
      case 'in_progress':
        statusText = 'Driver Delivering to You';
        statusColor = Colors.green;
        statusIcon = Icons.delivery_dining;
        break;
      case 'delivered':
        statusText = 'Delivery Arrived!';
        statusColor = Colors.purple;
        statusIcon = Icons.done_all;
        break;
      case 'completed':
        statusText = 'Delivery Complete';
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusText = 'Processing...';
        statusColor = Colors.grey;
        statusIcon = Icons.hourglass_empty;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor, width: 2),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getCategoryIcon(delivery.deliveryCategory),
                  style: const TextStyle(fontSize: 24),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCodeCard(RideRequestModel delivery) {
    final code = delivery.deliveryVerificationCode ?? '00000';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[700]!, Colors.deepOrange[600]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_user, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Verification Code',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  code.split('').join('  '),
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Code copied to clipboard'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, color: Colors.orange, size: 20),
                  tooltip: 'Copy code',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Share this code with the store when placing your order',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSteps(String status) {
    final steps = [
      ('Driver Accepts', status != 'pending', Colors.orange),
      ('Picking Up Items', status == 'in_progress' || status == 'delivered' || status == 'completed', Colors.blue),
      ('Delivering to You', status == 'delivered' || status == 'completed', Colors.purple),
      ('Delivery Complete', status == 'completed', Colors.green),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Progress',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isLast = index == steps.length - 1;

            return Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: step.$2 ? step.$3 : Colors.grey[700],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        step.$2 ? Icons.check : Icons.circle,
                        color: Colors.white,
                        size: step.$2 ? 20 : 12,
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 40,
                        color: step.$2 ? step.$3 : Colors.grey[700],
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 40),
                    child: Text(
                      step.$1,
                      style: TextStyle(
                        color: step.$2 ? Colors.white : Colors.grey[500],
                        fontSize: 14,
                        fontWeight: step.$2 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDeliveryDetails(RideRequestModel delivery) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Details',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Items', delivery.deliveryItemsDescription ?? 'N/A'),
          const SizedBox(height: 12),
          _buildDetailRow('Pickup From', delivery.pickupAddress),
          const SizedBox(height: 12),
          _buildDetailRow('Deliver To', delivery.dropoffAddress),
          const SizedBox(height: 12),
          _buildDetailRow('Distance', '${delivery.distance.toStringAsFixed(1)} mi'),
          const SizedBox(height: 12),
          _buildDetailRow(
            'Total',
            '\$${delivery.fare.toStringAsFixed(2)}',
            valueColor: Colors.green,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                delivery.paymentMethod == 'cash' ? Icons.money : Icons.credit_card,
                color: Colors.grey[400],
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                delivery.paymentMethod == 'cash' ? 'Cash Payment' : 'Card Payment',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmReceiptButton() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[900]?.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[700]!),
          ),
          child: Row(
            children: [
              Icon(Icons.delivery_dining, color: Colors.green, size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Your delivery has arrived! Please confirm you received all items.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : _confirmReceipt,
            icon: const Icon(Icons.check_circle, size: 24),
            label: const Text(
              'Accept Delivery - I Received Items',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactDriverSection(RideRequestModel delivery) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Driver',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implement phone call
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Call driver: ${delivery.driverEmail ?? "Driver"}'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                  icon: const Icon(Icons.phone, size: 20),
                  label: const Text('Call Driver'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implement messaging
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Message driver: ${delivery.driverEmail ?? "Driver"}'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  icon: const Icon(Icons.message, size: 20),
                  label: const Text('Message'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Having an issue? Contact your driver directly',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedMessage() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green[900]?.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[700]!),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 32),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivery Complete!',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Thank you for your order!',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

