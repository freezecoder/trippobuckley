import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:btrips_unified/data/models/ride_request_model.dart';
import 'package:btrips_unified/data/repositories/stripe_repository.dart';
import 'package:btrips_unified/data/repositories/ride_repository.dart';
import 'package:btrips_unified/data/providers/stripe_providers.dart';
import 'package:btrips_unified/data/providers/ride_providers.dart';
import 'package:btrips_unified/Container/utils/error_notification.dart';

/// Detailed screen for managing an active delivery
class DriverDeliveryDetailsScreen extends ConsumerStatefulWidget {
  final String deliveryId;
  final RideRequestModel delivery;

  const DriverDeliveryDetailsScreen({
    super.key,
    required this.deliveryId,
    required this.delivery,
  });

  @override
  ConsumerState<DriverDeliveryDetailsScreen> createState() =>
      _DriverDeliveryDetailsScreenState();
}

class _DriverDeliveryDetailsScreenState
    extends ConsumerState<DriverDeliveryDetailsScreen> {
  final TextEditingController _codeController = TextEditingController();
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

  Future<void> _startDelivery() async {
    setState(() => _isProcessing = true);

    try {
      await FirebaseFirestore.instance
          .collection('rideRequests')
          .doc(widget.deliveryId)
          .update({
        'status': 'in_progress',
        'startedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ErrorNotification().showSuccess(
          context,
          '✅ Delivery started! Navigate to customer.',
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorNotification().showError(context, 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _completeDelivery() async {
    // Confirm with driver
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Complete Delivery?',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mark this delivery as delivered?\n\nCustomer will be asked to confirm receipt.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            if (widget.delivery.paymentMethod == 'card')
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[900]?.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[700]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.credit_card, color: Colors.green, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Customer will be charged \$${widget.delivery.fare.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[900]?.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[700]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.money, color: Colors.orange, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Collect \$${widget.delivery.fare.toStringAsFixed(2)} in cash',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
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
            child: const Text('Yes, Complete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isProcessing = true);

    try {
      final rideRepo = ref.read(rideRepositoryProvider);
      final stripeRepo = ref.read(stripeRepositoryProvider);
      final isCashPayment = widget.delivery.paymentMethod == 'cash';

      // Mark as delivered (waiting for customer confirmation)
      await FirebaseFirestore.instance
          .collection('rideRequests')
          .doc(widget.deliveryId)
          .update({
        'status': 'delivered',
        'deliveredAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ErrorNotification().showSuccess(
          context,
          '✅ Delivery marked as complete! Waiting for customer confirmation.',
        );
      }

      // Process payment if card payment (charge immediately)
      if (!isCashPayment && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('💳 Processing payment...'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );

        // Process payment in background
        Future.delayed(const Duration(seconds: 2), () async {
          try {
            debugPrint('💳 Processing delivery payment for ${widget.delivery.userEmail}...');

            await stripeRepo.processAdminInvoice(
              userEmail: widget.delivery.userEmail,
              amount: widget.delivery.fare,
              description:
                  'Delivery: ${widget.delivery.deliveryCategory} - ${widget.delivery.deliveryItemsDescription}',
              adminEmail: 'system-delivery-completion',
            );

            debugPrint('✅ Delivery payment processed successfully');
            
            // Update payment status and complete the ride
            await FirebaseFirestore.instance
                .collection('rideRequests')
                .doc(widget.deliveryId)
                .update({
              'paymentStatus': 'completed',
            });
            
            // Also complete the ride in repository for earnings tracking
            await rideRepo.completeRide(widget.deliveryId);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Payment processed successfully!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            debugPrint('❌ Payment processing error: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('⚠️ Payment error: $e'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        });
      } else {
        // Cash payment - mark as completed
        await rideRepo.processCashPayment(widget.deliveryId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCashPayment
                  ? '✅ Delivery completed! Cash collected.'
                  : '✅ Delivery completed! Payment processing...',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Go back to deliveries list
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ErrorNotification().showError(
          context,
          'Failed to complete delivery: $e',
        );
      }
      debugPrint('❌ Error completing delivery: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
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
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) {
          return const Scaffold(
            body: Center(child: Text('Delivery not found')),
          );
        }

        final delivery = RideRequestModel.fromFirestore(data, widget.deliveryId);
        final status = delivery.status.name;
        final codeVerified = delivery.deliveryCodeVerified;

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: const Color(0xff1a3646),
            foregroundColor: Colors.white,
            title: const Text('Delivery Details'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange[700]!, Colors.deepOrange[600]!],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _getCategoryIcon(delivery.deliveryCategory),
                        style: const TextStyle(fontSize: 48),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'DELIVERY',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              delivery.deliveryItemsDescription ?? 'Items',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Workflow Steps
                _buildWorkflowSteps(status, codeVerified),

                const SizedBox(height: 24),

                // Locations
                _buildLocationCard(delivery),

                const SizedBox(height: 24),

                // Verification Code Display (always show)
                _buildVerificationCodeDisplay(delivery),

                const SizedBox(height: 24),

                // Contact Customer Button
                _buildContactCustomerButton(delivery),

                const SizedBox(height: 16),

                // Start Delivery Button (after accepting)
                if (status == 'accepted')
                  _buildStartDeliveryButton(),

                // Complete Delivery Button (when in progress)
                if (status == 'in_progress')
                  _buildCompleteDeliveryButton(),
                
                // Waiting for Customer Confirmation
                if (status == 'delivered')
                  _buildWaitingForConfirmation(),

                const SizedBox(height: 24),

                // Financial Summary
                _buildFinancialSummary(delivery),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWorkflowSteps(String status, bool codeVerified) {
    final steps = [
      ('Pickup Items', status != 'accepted', Colors.orange),
      ('Deliver to Customer', status == 'in_progress' || status == 'delivered' || status == 'completed', Colors.blue),
      ('Customer Confirms', status == 'completed', Colors.green),
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

  Widget _buildLocationCard(RideRequestModel delivery) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildLocationRow(
            icon: Icons.store,
            label: 'Pickup From',
            address: delivery.pickupAddress,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          const Icon(Icons.arrow_downward, color: Colors.grey, size: 20),
          const SizedBox(height: 16),
          _buildLocationRow(
            icon: Icons.location_on,
            label: 'Deliver To',
            address: delivery.dropoffAddress,
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required String label,
    required String address,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                address,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationCodeDisplay(RideRequestModel delivery) {
    final code = delivery.deliveryVerificationCode ?? '00000';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[700]!, Colors.deepOrange[600]!],
        ),
        borderRadius: BorderRadius.circular(12),
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
                'Pickup Verification Code',
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
            child: Text(
              code.split('').join('  '),
              style: TextStyle(
                color: Colors.orange[700],
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
                fontFamily: 'monospace',
              ),
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
                  'Share this code with store staff to verify the order',
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

  Widget _buildStartDeliveryButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _startDelivery,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isProcessing
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                '🚀 Start Delivery to Customer',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
  
  Widget _buildWaitingForConfirmation() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[900]?.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[700]!),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: Colors.blue,
              strokeWidth: 2,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Waiting for Customer Confirmation',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Customer needs to confirm they received the delivery',
                  style: TextStyle(
                    color: Colors.grey[400],
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

  Widget _buildCompleteDeliveryButton() {
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
              Icon(Icons.info_outline, color: Colors.green, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Have you delivered the items to the customer?',
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
            onPressed: _isProcessing ? null : _completeDelivery,
            icon: const Icon(Icons.check_circle, size: 24),
            label: const Text(
              'I Have Delivered - Complete',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
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

  Widget _buildContactCustomerButton(RideRequestModel delivery) {
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
            'Contact Customer',
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
                        content: Text('Call customer: ${delivery.userEmail}'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                  icon: const Icon(Icons.phone, size: 20),
                  label: const Text('Call'),
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
                        content: Text('Message customer: ${delivery.userEmail}'),
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
        ],
      ),
    );
  }

  Widget _buildFinancialSummary(RideRequestModel delivery) {
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
            'Financial Summary',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            'Distance',
            '${delivery.distance.toStringAsFixed(1)} mi',
          ),
          if (delivery.deliveryItemCost != null && delivery.deliveryItemCost! > 0)
            _buildSummaryRow(
              'Item Cost (you paid)',
              '\$${delivery.deliveryItemCost!.toStringAsFixed(2)}',
              valueColor: Colors.orange,
            ),
          _buildSummaryRow(
            'Delivery Fee',
            '\$${delivery.fare.toStringAsFixed(2)}',
            valueColor: Colors.green,
          ),
          const Divider(color: Colors.grey, height: 32),
          _buildSummaryRow(
            'You Earn',
            '\$${delivery.fare.toStringAsFixed(2)}',
            isHighlight: true,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                delivery.paymentMethod == 'cash'
                    ? Icons.money
                    : Icons.credit_card,
                color: Colors.grey[400],
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                delivery.paymentMethod == 'cash'
                    ? 'Cash Payment'
                    : 'Card Payment (Auto-charged)',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    Color? valueColor,
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isHighlight ? Colors.white : Colors.grey[400],
              fontSize: isHighlight ? 18 : 14,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? (isHighlight ? Colors.green : Colors.white),
              fontSize: isHighlight ? 22 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

