import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:btrips_unified/data/models/ride_request_model.dart';
import 'package:btrips_unified/data/repositories/stripe_repository.dart';
import 'package:btrips_unified/data/repositories/ride_repository.dart';
import 'package:btrips_unified/data/providers/stripe_providers.dart';
import 'package:btrips_unified/data/providers/ride_providers.dart';
import 'package:btrips_unified/Container/utils/error_notification.dart';
import 'package:btrips_unified/features/shared/presentation/widgets/delivery_timeline_widget.dart';

/// Unified details screen for both rides and deliveries
/// Shows different actions based on user role (driver vs passenger)
class RideDeliveryDetailsScreen extends ConsumerStatefulWidget {
  final String rideId;
  final bool isDriver;

  const RideDeliveryDetailsScreen({
    super.key,
    required this.rideId,
    required this.isDriver,
  });

  @override
  ConsumerState<RideDeliveryDetailsScreen> createState() =>
      _RideDeliveryDetailsScreenState();
}

class _RideDeliveryDetailsScreenState
    extends ConsumerState<RideDeliveryDetailsScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

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

  // Driver Actions
  Future<void> _startRideOrDelivery(RideRequestModel ride) async {
    setState(() => _isProcessing = true);

    try {
      debugPrint('🚀 Starting delivery/ride: ${widget.rideId}');
      debugPrint('   Current status: ${ride.status.name}');
      
      await FirebaseFirestore.instance
          .collection('rideRequests')
          .doc(widget.rideId)
          .update({
        'status': 'ongoing',  // Changed from 'in_progress' to match RideStatus enum
        'startedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Status updated to ongoing');

      if (mounted) {
        ErrorNotification().showSuccess(
          context,
          ride.isDelivery 
              ? '✅ Delivery started! Navigate to customer.'
              : '✅ Ride started! Navigate to destination.',
        );
      }
    } catch (e) {
      debugPrint('❌ Error starting: $e');
      if (mounted) {
        ErrorNotification().showError(context, 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _completeRideOrDelivery(RideRequestModel ride) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          ride.isDelivery ? 'Complete Delivery?' : 'Complete Ride?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          ride.isDelivery
              ? 'Have you delivered the items to the customer?'
              : 'Have you dropped off the passenger?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not Yet'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Yes, Complete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isProcessing = true);

    try {
      debugPrint('📦 Completing delivery/ride: ${widget.rideId}');
      debugPrint('   Current status: ${ride.status.name}');
      debugPrint('   Is delivery: ${ride.isDelivery}');
      debugPrint('   Driver ID: ${ride.driverId}');
      debugPrint('   User ID: ${ride.userId}');
      
      // CRITICAL: Mark as delivered without any other operations
      // Do NOT process payment here - that happens when customer confirms
      debugPrint('🔥 Writing to Firestore...');
      
      await FirebaseFirestore.instance
          .collection('rideRequests')
          .doc(widget.rideId)
          .update({
        'status': 'delivered',
        'deliveredAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Status updated to delivered in Firestore');

      // Verify the update
      final verifyDoc = await FirebaseFirestore.instance
          .collection('rideRequests')
          .doc(widget.rideId)
          .get();
      
      final verifyStatus = verifyDoc.data()?['status'];
      debugPrint('🔍 VERIFICATION: Status in Firebase is now: $verifyStatus');
      
      if (verifyStatus != 'delivered') {
        debugPrint('⚠️ WARNING: Status verification failed! Expected "delivered", got "$verifyStatus"');
        throw Exception('Status update verification failed');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ride.isDelivery
                  ? '✅ Delivery marked as complete! Waiting for customer confirmation.'
                  : '✅ Ride complete! Waiting for customer confirmation.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ ERROR completing delivery: $e');
      if (mounted) {
        ErrorNotification().showError(context, 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // Customer Actions
  Future<void> _cancelRideOrDelivery(RideRequestModel ride) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          ride.isDelivery ? 'Cancel Delivery?' : 'Cancel Ride?',
          style: const TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure? This cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isProcessing = true);

    try {
      final cancelledBy = widget.isDriver ? 'driver' : 'user';
      final reason = ride.isDelivery 
          ? 'Cancelled by ${widget.isDriver ? "driver" : "customer"}'
          : 'Cancelled by ${widget.isDriver ? "driver" : "passenger"}';
      
      debugPrint('❌ Cancelling ${ride.isDelivery ? "delivery" : "ride"}: ${widget.rideId}');
      debugPrint('   Cancelled by: $cancelledBy');
      
      await FirebaseFirestore.instance
          .collection('rideRequests')
          .doc(widget.rideId)
          .update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancelledBy': cancelledBy,
        'cancellationReason': reason,
      });

      debugPrint('✅ Cancellation recorded in Firestore');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ride.isDelivery ? 'Delivery cancelled' : 'Ride cancelled'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.of(context).pop();
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

  Future<void> _confirmReceipt(RideRequestModel ride) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            Text(
              ride.isDelivery ? 'Confirm Delivery?' : 'Confirm Completion?',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          ride.isDelivery
              ? 'Have you received all items in good condition?'
              : 'Was your ride completed successfully?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not Yet'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Yes, Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isProcessing = true);

    try {
      debugPrint('✅ Customer confirming receipt: ${widget.rideId}');
      debugPrint('   Payment method: ${ride.paymentMethod}');
      debugPrint('   Fare: \$${ride.fare}');
      
      final rideRepo = ref.read(rideRepositoryProvider);
      final stripeRepo = ref.read(stripeRepositoryProvider);
      final isCashPayment = ride.paymentMethod == 'cash';

      // Update status to completed with confirmation timestamp
      await FirebaseFirestore.instance
          .collection('rideRequests')
          .doc(widget.rideId)
          .update({
        'status': 'completed',
        'confirmedAt': FieldValue.serverTimestamp(),      // When customer confirmed
        'completedAt': FieldValue.serverTimestamp(),      // Final completion time
        'confirmedByCustomer': true,
      });

      debugPrint('✅ Status updated to completed with confirmation timestamp');

      // Process payment if card payment
      if (!isCashPayment && ride.fare > 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('💳 Processing payment...'),
              backgroundColor: Colors.blue,
            ),
          );
        }

        try {
          debugPrint('💳 Processing card payment via admin invoice...');
          
          await stripeRepo.processAdminInvoice(
            userEmail: ride.userEmail,
            amount: ride.fare,
            description: ride.isDelivery
                ? 'Delivery: ${ride.deliveryItemsDescription ?? "Items"}'
                : 'Ride: ${ride.pickupAddress} → ${ride.dropoffAddress}',
            adminEmail: 'system-delivery-completion',
          );

          debugPrint('✅ Payment processed successfully');

          await FirebaseFirestore.instance
              .collection('rideRequests')
              .doc(widget.rideId)
              .update({
            'paymentStatus': 'completed',
            'paymentProcessedAt': FieldValue.serverTimestamp(),
          });
        } catch (paymentError) {
          debugPrint('❌ Payment processing error: $paymentError');
          // Don't block the completion, but log the error
          await FirebaseFirestore.instance
              .collection('rideRequests')
              .doc(widget.rideId)
              .update({
            'paymentStatus': 'failed',
            'paymentError': paymentError.toString(),
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚠️ Payment processing failed, but delivery confirmed'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 4),
              ),
            );
          }
        }
      } else {
        debugPrint('💵 Cash payment - marking as pending collection');
        await FirebaseFirestore.instance
            .collection('rideRequests')
            .doc(widget.rideId)
            .update({'paymentStatus': 'cash_pending'});
      }

      // Complete the ride (updates earnings, moves to history)
      try {
        await rideRepo.completeRide(widget.rideId);
        debugPrint('✅ Ride completion finalized');
      } catch (e) {
        debugPrint('Note: May already be completed: $e');
      }

      if (mounted) {
        // Show rating dialog for deliveries
        if (ride.isDelivery) {
          await _showDeliveryRatingDialog(ride);
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.grey[900],
              title: Row(
                children: [
                  Icon(Icons.celebration, color: Colors.green, size: 32),
                  const SizedBox(width: 12),
                  const Text('Thank You!', style: TextStyle(color: Colors.white)),
                ],
              ),
              content: const Text(
                'Thank you for using our service!',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Done'),
                ),
              ],
            ),
          );
        }
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

  // Send message in live chat
  Future<void> _sendMessage(String rideId, bool isDriver) async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      await FirebaseFirestore.instance
          .collection('rideRequests')
          .doc(rideId)
          .collection('messages')
          .add({
        'senderId': currentUser.uid,
        'senderEmail': currentUser.email,
        'senderRole': isDriver ? 'driver' : 'customer',
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      _messageController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message sent'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorNotification().showError(context, 'Error sending message: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rideRequests')
          .doc(widget.rideId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: const Color(0xff1a3646),
              foregroundColor: Colors.white,
              title: Text(widget.isDriver ? 'Delivery Details' : 'Track Delivery'),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: const Center(
              child: Text('Not found', style: TextStyle(color: Colors.white)),
            ),
          );
        }

        // Debug logging for status tracking
        final rawStatusFromDB = data['status'] as String?;
        debugPrint('🔄 Stream update for ${widget.rideId}:');
        debugPrint('   Raw status from Firebase: $rawStatusFromDB');
        debugPrint('   Driver ID: ${data['driverId']}');
        debugPrint('   Is Delivery: ${data['isDelivery']}');
        
        final ride = RideRequestModel.fromFirestore(data, widget.rideId);
        final rawStatus = ride.status.name;
        
        // CRITICAL FIX: Use deliveredAt as source of truth if status is wrong
        // If deliveredAt exists but status is not 'delivered' or 'completed', force it
        String status = rawStatus;
        if (ride.deliveredAt != null && 
            rawStatus != 'delivered' && 
            rawStatus != 'completed' &&
            rawStatus != 'cancelled') {
          debugPrint('⚠️ STATUS MISMATCH FIX: deliveredAt exists but status is "$rawStatus"');
          debugPrint('   → Forcing status to "delivered" for UI purposes');
          status = 'delivered';  // Force correct status!
        }
        
        debugPrint('   Parsed status: $rawStatus${rawStatus != status ? " → CORRECTED to: $status" : ""}');
        debugPrint('   For ${widget.isDriver ? "DRIVER" : "CUSTOMER"} view');

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: const Color(0xff1a3646),
            foregroundColor: Colors.white,
            title: Text(ride.isDelivery
                ? (widget.isDriver ? '📦 Delivery Details' : '📦 Track Delivery')
                : (widget.isDriver ? '🚗 Ride Details' : '🚗 Track Ride')),
            actions: [
              // Customer can cancel
              if (!widget.isDriver &&
                  (status == 'pending' ||
                      status == 'accepted' ||
                      status == 'ongoing'))
                IconButton(
                  icon: const Icon(Icons.cancel_outlined),
                  onPressed: _isProcessing ? null : () => _cancelRideOrDelivery(ride),
                  tooltip: ride.isDelivery ? 'Cancel Delivery' : 'Cancel Ride',
                ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Main details
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Header
                      _buildStatusHeader(ride, status),

                      const SizedBox(height: 24),

                      // Verification Code (for deliveries)
                      if (ride.isDelivery)
                        _buildVerificationCode(ride),

                      if (ride.isDelivery) const SizedBox(height: 24),

                      // Progress Steps (Simple View)
                      _buildProgress(ride, status),

                      const SizedBox(height: 24),

                      // Detailed Timeline (if delivery has progressed)
                      if (ride.acceptedAt != null || ride.cancelledAt != null)
                        Column(
                          children: [
                            DeliveryTimelineWidget(
                              ride: ride,
                              compact: false,
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),

                      // Locations
                      _buildLocations(ride),

                      const SizedBox(height: 24),

                      // Contact Section
                      _buildContactSection(ride),

                      const SizedBox(height: 24),

                      // Action Buttons
                      _buildActionButtons(ride, status),

                      const SizedBox(height: 24),

                      // Financial Summary
                      _buildFinancialSummary(ride),

                      // Performance Metrics (if completed)
                      if (ride.status.name == 'completed' && ride.isDelivery) ...[
                        const SizedBox(height: 24),
                        _buildPerformanceMetrics(ride),
                      ],
                    ],
                  ),
                ),

                // Live Chat Section
                _buildLiveChatSection(widget.rideId, widget.isDriver),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusHeader(RideRequestModel ride, String status) {
    // CRITICAL DEBUG: Log status every time header builds
    debugPrint('🎨 Building status header:');
    debugPrint('   Status value: "$status"');
    debugPrint('   Has deliveredAt: ${ride.deliveredAt != null}');
    debugPrint('   Has confirmedAt: ${ride.confirmedAt != null}');
    debugPrint('   Driver ID: ${ride.driverId}');
    
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (widget.isDriver) {
      switch (status) {
        case 'accepted':
          statusText = ride.isDelivery ? 'Pickup Items' : 'Pickup Passenger';
          statusColor = Colors.orange;
          statusIcon = Icons.store;
          break;
        case 'ongoing':
          statusText = ride.isDelivery ? 'Delivering' : 'In Transit';
          statusColor = Colors.blue;
          statusIcon = Icons.local_shipping;
          break;
        case 'delivered':
          statusText = 'Waiting for Confirmation';
          statusColor = Colors.purple;
          statusIcon = Icons.hourglass_empty;
          break;
        default:
          statusText = status;
          statusColor = Colors.grey;
          statusIcon = Icons.info;
      }
    } else {
      switch (status) {
        case 'pending':
          statusText = 'Finding Driver...';
          statusColor = Colors.orange;
          statusIcon = Icons.search;
          break;
        case 'accepted':
          statusText = ride.isDelivery
              ? 'Driver on Way to Pickup'
              : 'Driver Coming to You';
          statusColor = Colors.blue;
          statusIcon = Icons.local_shipping;
          break;
        case 'ongoing':
          statusText = ride.isDelivery ? 'Driver Delivering' : 'Ride in Progress';
          statusColor = Colors.green;
          statusIcon = Icons.delivery_dining;
          break;
        case 'delivered':
          statusText = ride.isDelivery ? 'Delivery Arrived!' : 'Ride Complete!';
          statusColor = Colors.purple;
          statusIcon = Icons.done_all;
          debugPrint('   → Showing "Delivery Arrived!" for delivered status');
          break;
        case 'completed':
          statusText = 'Completed';
          statusColor = Colors.green;
          statusIcon = Icons.check_circle;
          break;
        default:
          statusText = status;
          statusColor = Colors.grey;
          statusIcon = Icons.info;
      }
    }

    return Column(
      children: [
        Container(
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
                    if (ride.isDelivery)
                      Text(
                        _getCategoryIcon(ride.deliveryCategory),
                        style: const TextStyle(fontSize: 24),
                      ),
                    // DEBUG: Show raw status
                    const SizedBox(height: 4),
                    Text(
                      'Status: "$status"${ride.deliveredAt != null ? " | deliveredAt: YES ✅" : ""}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // WARNING: Status mismatch
        if (ride.deliveredAt != null && status != 'delivered' && status != 'completed')
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red, width: 2),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 24),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'STATUS MISMATCH DETECTED',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Driver marked items as delivered (deliveredAt timestamp exists), but status field is "$status" instead of "delivered". This is causing the Accept button to not appear.',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildVerificationCode(RideRequestModel ride) {
    final code = ride.deliveryVerificationCode ?? '00000';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[700]!, Colors.deepOrange[600]!],
        ),
        borderRadius: BorderRadius.circular(16),
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
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Code copied'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, color: Colors.orange, size: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.isDriver
                ? 'Show this code to store staff'
                : 'Share this code with the store',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgress(RideRequestModel ride, String status) {
    final steps = ride.isDelivery
        ? [
            ('Pickup Items', status != 'accepted', Colors.orange),
            ('Deliver to Customer', status == 'ongoing' || status == 'delivered' || status == 'completed', Colors.blue),
            ('Customer Confirms', status == 'completed', Colors.green),
          ]
        : [
            ('Driver Accepts', status != 'pending', Colors.orange),
            ('Ride in Progress', status == 'ongoing' || status == 'delivered' || status == 'completed', Colors.blue),
            ('Ride Complete', status == 'completed', Colors.green),
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
          Text(
            ride.isDelivery ? 'Delivery Progress' : 'Ride Progress',
            style: const TextStyle(
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

  Widget _buildLocations(RideRequestModel ride) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildLocationRow(
            Icons.trip_origin,
            ride.isDelivery ? 'Pickup From' : 'Pickup',
            ride.pickupAddress,
            Colors.orange,
          ),
          const SizedBox(height: 16),
          const Icon(Icons.arrow_downward, color: Colors.grey, size: 20),
          const SizedBox(height: 16),
          _buildLocationRow(
            Icons.location_on,
            ride.isDelivery ? 'Deliver To' : 'Dropoff',
            ride.dropoffAddress,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(
    IconData icon,
    String label,
    String address,
    Color color,
  ) {
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
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
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

  Widget _buildContactSection(RideRequestModel ride) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isDriver ? 'Contact Customer' : 'Contact Driver',
            style: const TextStyle(
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(widget.isDriver
                            ? 'Call customer: ${ride.userEmail}'
                            : 'Call driver: ${ride.driverEmail ?? "Driver"}'),
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
                    // Scroll to chat section
                    Scrollable.ensureVisible(
                      context,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  icon: const Icon(Icons.message, size: 20),
                  label: const Text('Chat'),
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

  Widget _buildActionButtons(RideRequestModel ride, String status) {
    debugPrint('🔘 Building action buttons:');
    debugPrint('   isDriver: ${widget.isDriver}');
    debugPrint('   status: $status');
    debugPrint('   isDelivery: ${ride.isDelivery}');
    
    if (widget.isDriver) {
      debugPrint('   → Rendering DRIVER buttons');
      // DRIVER BUTTONS
      if (status == 'accepted') {
        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : () => _startRideOrDelivery(ride),
            icon: const Icon(Icons.play_arrow, size: 24),
            label: Text(
              ride.isDelivery
                  ? '🚀 Start Delivery to Customer'
                  : '🚗 Start Ride',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        );
      } else if (status == 'ongoing') {
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
                  Expanded(
                    child: Text(
                      ride.isDelivery
                          ? 'Have you delivered the items?'
                          : 'Have you dropped off the passenger?',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
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
                onPressed: _isProcessing ? null : () => _completeRideOrDelivery(ride),
                icon: const Icon(Icons.check_circle, size: 24),
                label: Text(
                  ride.isDelivery
                      ? '✅ I Have Delivered - Complete'
                      : '✅ Complete Ride',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
      } else if (status == 'delivered') {
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
                child: Text(
                  ride.isDelivery
                      ? 'Waiting for customer to confirm receipt'
                      : 'Waiting for customer confirmation',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
        );
      }
    } else {
      debugPrint('   → Rendering CUSTOMER action panel');
      debugPrint('   → Status for button check: $status');
      debugPrint('   → Cancel enabled: ${status == 'pending' || status == 'accepted' || status == 'ongoing'}');
      debugPrint('   → Accept enabled: ${status == 'delivered'}');
      
      // CUSTOMER ACTION PANEL
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Status Indicator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _getStatusColor(status)),
            ),
            child: Row(
              children: [
                Icon(
                  _getStatusIcon(status),
                  color: _getStatusColor(status),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getCustomerStatusTitle(status, ride.isDelivery),
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getCustomerStatusMessage(status, ride.isDelivery),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Action Buttons - Always visible
          Text(
            'Actions',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Cancel Button
          _buildCustomerActionButton(
            icon: Icons.cancel_outlined,
            label: 'Cancel ${ride.isDelivery ? "Delivery" : "Ride"}',
            enabled: status == 'pending' || status == 'accepted' || status == 'ongoing',
            color: Colors.red,
            onPressed: () => _cancelRideOrDelivery(ride),
            helpText: (status == 'pending' || status == 'accepted' || status == 'ongoing')
                ? 'Tap to cancel this ${ride.isDelivery ? "delivery" : "ride"}'
                : 'Cannot cancel after ${ride.isDelivery ? "delivery" : "completion"}',
          ),
          
          const SizedBox(height: 12),
          
          // Accept/Confirm Button  
          _buildCustomerActionButton(
            icon: Icons.check_circle,
            label: ride.isDelivery
                ? 'Accept Delivery - I Received Items'
                : 'Confirm Ride Complete',
            enabled: status == 'delivered',
            color: Colors.green,
            onPressed: () => _confirmReceipt(ride),
            helpText: status == 'delivered'
                ? '✅ ${ride.isDelivery ? "Delivery" : "Ride"} arrived! Tap to confirm'
                : status == 'completed'
                    ? '✅ Already confirmed'
                    : 'Available when ${ride.isDelivery ? "driver delivers" : "ride completes"}',
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildCustomerActionButton({
    required IconData icon,
    required String label,
    required bool enabled,
    required Color color,
    required VoidCallback onPressed,
    required String helpText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled ? color : Colors.grey[700]!,
          width: enabled ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: enabled && !_isProcessing ? onPressed : null,
              icon: Icon(icon, size: 22),
              label: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: enabled ? color : Colors.grey[850],
                foregroundColor: enabled ? Colors.white : Colors.grey[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Icon(
                  enabled ? Icons.info_outline : Icons.lock_outline,
                  size: 14,
                  color: enabled ? color.withOpacity(0.7) : Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    helpText,
                    style: TextStyle(
                      color: enabled ? color.withOpacity(0.8) : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.search;
      case 'accepted':
        return Icons.local_shipping;
      case 'ongoing':
        return Icons.delivery_dining;
      case 'delivered':
        return Icons.check_circle_outline;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'ongoing':
        return Colors.green;
      case 'delivered':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getCustomerStatusTitle(String status, bool isDelivery) {
    switch (status) {
      case 'pending':
        return 'Finding Driver...';
      case 'accepted':
        return 'Driver Assigned';
      case 'ongoing':
        return isDelivery ? 'Out for Delivery' : 'In Progress';
      case 'delivered':
        return isDelivery ? 'Delivery Arrived!' : 'Ride Complete!';
      case 'completed':
        return 'Complete!';
      default:
        return status;
    }
  }

  String _getCustomerStatusMessage(String status, bool isDelivery) {
    switch (status) {
      case 'pending':
        return 'Looking for an available driver in your area...';
      case 'accepted':
        return isDelivery
            ? 'Driver is heading to pickup your items'
            : 'Driver is on the way to pick you up';
      case 'ongoing':
        return isDelivery
            ? 'Driver is delivering to your location now'
            : 'Your ride is in progress';
      case 'delivered':
        return isDelivery
            ? 'Your items have been delivered. Please confirm receipt below.'
            : 'Your ride has completed. Please confirm below.';
      case 'completed':
        return 'Thank you for using our service!';
      default:
        return '';
    }
  }

  Widget _buildPerformanceMetrics(RideRequestModel ride) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[700]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Performance',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (ride.acceptanceDuration != null)
            _buildMetricRow(
              'Driver Response',
              ride.acceptanceDurationFormatted,
              ride.wasFastAcceptance,
            ),
          if (ride.deliveryDuration != null)
            _buildMetricRow(
              'Delivery Time',
              ride.deliveryDurationFormatted,
              ride.wasFastDelivery,
            ),
          if (ride.confirmationDuration != null)
            _buildMetricRow(
              'Confirmation Time',
              ride.confirmationDurationFormatted,
              ride.wasQuickConfirmation,
            ),
          if (ride.totalDuration != null)
            _buildMetricRow(
              'Total Time',
              ride.totalDurationFormatted,
              ride.wasFastOverall,
            ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, bool isFast) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 13,
            ),
          ),
          Row(
            children: [
              if (isFast)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '⚡ FAST',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Text(
                value,
                style: TextStyle(
                  color: isFast ? Colors.green : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary(RideRequestModel ride) {
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
          _buildSummaryRow('Distance', '${ride.distance.toStringAsFixed(1)} mi'),
          if (ride.isDelivery && ride.deliveryItemCost != null && ride.deliveryItemCost! > 0)
            _buildSummaryRow(
              'Item Cost',
              '\$${ride.deliveryItemCost!.toStringAsFixed(2)}',
              valueColor: Colors.orange,
            ),
          _buildSummaryRow(
            widget.isDriver ? 'You Earn' : 'Total',
            '\$${ride.fare.toStringAsFixed(2)}',
            valueColor: Colors.green,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                ride.paymentMethod == 'cash' ? Icons.money : Icons.credit_card,
                color: Colors.grey[400],
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                ride.paymentMethod == 'cash' ? 'Cash Payment' : 'Card Payment',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveChatSection(String rideId, bool isDriver) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rideRequests')
          .doc(rideId)
          .snapshots(),
      builder: (context, rideSnapshot) {
        if (!rideSnapshot.hasData) {
          return const SizedBox.shrink();
        }

        final rideData = rideSnapshot.data!.data() as Map<String, dynamic>?;
        if (rideData == null) return const SizedBox.shrink();

        final status = rideData['status'] as String;
        final isChatActive = status == 'accepted' || status == 'ongoing';
        final isChatDisabled = status == 'completed' || status == 'cancelled' || status == 'delivered';

        return Container(
          color: Colors.grey[850],
          child: Column(
            children: [
              // Chat Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  border: Border(
                    top: BorderSide(color: Colors.grey[700]!),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.chat_bubble,
                      color: isChatActive ? Colors.blue : Colors.grey,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isDriver ? 'Chat with Customer' : 'Chat with Driver',
                      style: TextStyle(
                        color: isChatActive ? Colors.white : Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (isChatActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else if (isChatDisabled)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'CLOSED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

          // Messages List
          SizedBox(
            height: 300,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rideRequests')
                  .doc(rideId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.blue),
                  );
                }

                final messages = snapshot.data!.docs;

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_outlined, size: 48, color: Colors.grey[600]),
                        const SizedBox(height: 12),
                        Text(
                          'No messages yet',
                          style: TextStyle(color: Colors.grey[500], fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Send a message to start the conversation',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>;
                    final currentUser = FirebaseAuth.instance.currentUser;
                    final isMine = msg['senderId'] == currentUser?.uid;
                    final senderRole = msg['senderRole'] as String?;
                    final message = msg['message'] as String;
                    final timestamp = (msg['timestamp'] as Timestamp?)?.toDate();

                    return Align(
                      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        decoration: BoxDecoration(
                          color: isMine ? Colors.blue[700] : Colors.grey[800],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMine)
                              Text(
                                senderRole == 'driver' ? 'Driver' : 'Customer',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            if (!isMine) const SizedBox(height: 4),
                            Text(
                              message,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            if (timestamp != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _formatTime(timestamp),
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Message Input (only if chat is active)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: Border(
                top: BorderSide(color: Colors.grey[700]!),
              ),
            ),
            child: isChatActive
                ? Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          enabled: isChatActive,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            filled: true,
                            fillColor: Colors.grey[850],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        backgroundColor: Colors.blue,
                        radius: 24,
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white, size: 20),
                          onPressed: () => _sendMessage(rideId, isDriver),
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Icon(Icons.lock, color: Colors.grey[600], size: 32),
                      const SizedBox(height: 8),
                      Text(
                        isChatDisabled
                            ? 'Chat is closed. History saved above.'
                            : 'Chat will be available when ride/delivery is active',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
          ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showDeliveryRatingDialog(RideRequestModel ride) async {
    double rating = 3.0;
    final feedbackController = TextEditingController();

    final shouldRate = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Row(
            children: [
              Icon(Icons.star, color: Colors.amber, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Rate Your Delivery',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How was your delivery experience?',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
                const SizedBox(height: 20),
                // Star rating
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1.0;
                      return IconButton(
                        icon: Icon(
                          starValue <= rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 40,
                        ),
                        onPressed: () {
                          setState(() => rating = starValue);
                        },
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _getRatingText(rating),
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Feedback (optional)
                TextField(
                  controller: feedbackController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Add feedback (optional)',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: Colors.grey[850],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Skip'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Submit Rating'),
            ),
          ],
        ),
      ),
    );

    if (shouldRate == true && mounted) {
      // Save rating
      try {
        final rideRepo = ref.read(rideRepositoryProvider);
        await rideRepo.addUserRating(
          rideId: widget.rideId,
          rating: rating,
          feedback: feedbackController.text.isNotEmpty 
              ? feedbackController.text 
              : null,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Thank you for your feedback!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Close the details screen
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      } catch (e) {
        debugPrint('❌ Error saving rating: $e');
      }
    } else if (mounted) {
      // Skipped rating, just close
      Navigator.of(context).pop();
    }

    feedbackController.dispose();
  }

  String _getRatingText(double rating) {
    if (rating >= 4.5) return 'Excellent!';
    if (rating >= 3.5) return 'Good';
    if (rating >= 2.5) return 'Okay';
    if (rating >= 1.5) return 'Poor';
    return 'Very Poor';
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}

