import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../data/providers/ride_providers.dart';
import '../../../../../data/providers/auth_providers.dart';
import '../../../../../data/providers/stripe_providers.dart';
import '../../../../../core/enums/ride_status.dart';
import '../../../../../data/models/ride_request_model.dart';
import '../widgets/passenger_info_card.dart';

/// Screen showing active/ongoing rides for the driver
class DriverActiveRidesScreen extends ConsumerWidget {
  const DriverActiveRidesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeRides = ref.watch(driverActiveRidesProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(driverActiveRidesProvider);
        await Future.delayed(const Duration(milliseconds: 500));
      },
      backgroundColor: Colors.white,
      color: Colors.blue,
      child: activeRides.when(
        data: (rides) {
          if (rides.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 200),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.local_taxi, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No active rides',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Accept a ride to see it here',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Pull down to refresh',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: rides.length,
            itemBuilder: (context, index) {
              final ride = rides[index];
              final isAccepted = ride.status == RideStatus.accepted;
              final isOngoing = ride.status == RideStatus.ongoing;
              final isCompleted = ride.status == RideStatus.completed;
              final isCashPayment = ride.paymentMethod == 'cash';
              final paymentPending = ride.paymentStatus == 'pending';
              final needsCashConfirmation = isCompleted && isCashPayment && paymentPending;
              
              return Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Badge
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isOngoing ? Colors.green : Colors.blue,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isOngoing ? Icons.navigation : Icons.check_circle,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isOngoing ? 'In Progress' : 'Accepted',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Scheduled indicator
                          if (ride.scheduledTime != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.schedule, 
                                    size: 12, color: Colors.purple),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatScheduledTime(ride.scheduledTime!),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.purple,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '\$${ride.fare.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              // Payment method indicator
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: ride.paymentMethod == 'cash' 
                                      ? Colors.orange.withValues(alpha: 0.2)
                                      : Colors.blue.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      ride.paymentMethod == 'cash' 
                                          ? Icons.payments 
                                          : Icons.credit_card,
                                      size: 12,
                                      color: ride.paymentMethod == 'cash' 
                                          ? Colors.orange 
                                          : Colors.blue,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      ride.paymentMethod == 'cash' ? 'Cash' : 'Card',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: ride.paymentMethod == 'cash' 
                                            ? Colors.orange 
                                            : Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      const Divider(height: 24),
                      
                      // Real-time trip duration (only for ongoing rides)
                      if (isOngoing) ...[
                        Center(
                          child: RideElapsedTimer(ride: ride),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Passenger Information Card (Enhanced)
                      PassengerInfoCard(
                        userId: ride.userId,
                        userEmail: ride.userEmail,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Route Information
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            // Pickup
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.trip_origin, color: Colors.blue, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'PICKUP',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        ride.pickupAddress,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.visible,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Distance/Duration Info
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.straighten, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  '${ride.distance.toStringAsFixed(1)} km',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  '${ride.duration} min',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Dropoff
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on, color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'DROPOFF',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        ride.dropoffAddress,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.visible,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Action Buttons
                      if (isAccepted)
                        Column(
                          children: [
                            // "Start Trip" button (pick up passenger)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  // Start the trip (passenger picked up)
                                  try {
                                    final rideRepo = ref.read(rideRepositoryProvider);
                                    
                                    await rideRepo.startRide(ride.id);

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Trip started! Passenger picked up.'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.play_arrow, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Start Trip (Passenger Picked Up)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // "On the Way" button (navigate to pickup)
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () {
                                  // TODO: Open Google Maps navigation to pickup location
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Navigating to pickup location...'),
                                      backgroundColor: Colors.blue,
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue,
                                  side: const BorderSide(color: Colors.blue),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.navigation, size: 18),
                                    SizedBox(width: 8),
                                    Text('Navigate to Pickup'),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () async {
                                  // Show confirmation dialog
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Cancel Ride?'),
                                      content: const Text(
                                        'Are you sure you want to cancel this ride? The passenger will be notified.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('No, Keep Ride'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                          child: const Text('Yes, Cancel'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirmed == true && context.mounted) {
                                    try {
                                      final currentUser = await ref.read(
                                        currentUserProvider.future);
                                      if (currentUser == null) return;

                                      final rideRepo = ref.read(rideRepositoryProvider);
                                      
                                      await rideRepo.cancelRideRequest(
                                        rideId: ride.id,
                                        userId: currentUser.uid,
                                        cancellationReason: 'Cancelled by driver',
                                      );

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Ride cancelled'),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Error: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text('Cancel Ride'),
                              ),
                            ),
                          ],
                        ),
                      if (isOngoing)
                        Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  // Complete the ride (drop off passenger)
                                  try {
                                    final rideRepo = ref.read(rideRepositoryProvider);
                                    final stripeRepo = ref.read(stripeRepositoryProvider);
                                    final fareAmount = ride.fare;
                                    final isCashPayment = ride.paymentMethod == 'cash';
                                    
                                    await rideRepo.completeRide(ride.id);

                                    // Handle automatic credit card payment
                                    if (!isCashPayment && context.mounted) {
                                      // Show message that payment will be processed
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Row(
                                                children: [
                                                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Ride Completed!',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'You earned: \$${fareAmount.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.greenAccent,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              const Text(
                                                'Payment will be processed in 5 seconds...',
                                                style: TextStyle(fontSize: 13),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: Colors.green[700],
                                          duration: const Duration(seconds: 4),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );

                                      // Process payment after 5 seconds using admin invoice function
                                      Future.delayed(const Duration(seconds: 5), () async {
                                        try {
                                          final currentUser = await ref.read(currentUserProvider.future);
                                          
                                          print('💳 Processing ride payment for ${ride.userEmail}...');
                                          
                                          // Use admin invoice function for consolidated payment processing
                                          await stripeRepo.processAdminInvoice(
                                            userEmail: ride.userEmail,
                                            amount: fareAmount,
                                            description: 'Ride: ${ride.pickupAddress.length > 30 ? ride.pickupAddress.substring(0, 30) + "..." : ride.pickupAddress} → ${ride.dropoffAddress.length > 30 ? ride.dropoffAddress.substring(0, 30) + "..." : ride.dropoffAddress}',
                                            adminEmail: 'system-ride-completion',
                                          );

                                          print('✅ Payment processed successfully');
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Payment processed successfully!'),
                                                backgroundColor: Colors.green,
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                          
                                          // Update ride payment status  
                                          final rideRepo = ref.read(rideRepositoryProvider);
                                          await rideRepo.processCashPayment(ride.id); // Marks as completed
                                        } catch (e) {
                                          print('❌ Payment processing failed: $e');
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Payment processing failed: $e'),
                                                backgroundColor: Colors.orange,
                                                duration: const Duration(seconds: 3),
                                              ),
                                            );
                                          }
                                        }
                                      });
                                    } else if (context.mounted) {
                                      // Cash payment - show message to collect cash
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Row(
                                                children: [
                                                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Ride Completed!',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Collect Cash: \$${fareAmount.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.orangeAccent,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              const Text(
                                                'Click "Accept Cash Payment" below',
                                                style: TextStyle(fontSize: 13),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: Colors.orange[700],
                                          duration: const Duration(seconds: 4),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Complete Ride (Passenger Dropped Off)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Navigate to dropoff
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () {
                                  // TODO: Open Google Maps navigation to dropoff
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Navigating to dropoff location...'),
                                      backgroundColor: Colors.blue,
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue,
                                  side: const BorderSide(color: Colors.blue),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.navigation, size: 18),
                                    SizedBox(width: 8),
                                    Text('Navigate to Dropoff'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      // Accept Cash Payment button (for completed cash rides)
                      if (needsCashConfirmation)
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.orange.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.payments,
                                    color: Colors.orange,
                                    size: 32,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Cash Payment Pending',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Colors.orange,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Amount: \$${ride.fare.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  // Process cash payment
                                  try {
                                    final rideRepo = ref.read(rideRepositoryProvider);
                                    
                                    await rideRepo.processCashPayment(ride.id);

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Row(
                                                children: [
                                                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Cash Payment Accepted!',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Amount received: \$${ride.fare.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.greenAccent,
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: Colors.green[700],
                                          duration: const Duration(seconds: 3),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.payments, size: 20),
                                label: const Text(
                                  'Accept Cash Payment',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  elevation: 4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Confirm that you have received the cash payment',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 200),
            Center(child: CircularProgressIndicator()),
          ],
        ),
        error: (error, stack) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 200),
            Column(
              children: [
                const Icon(Icons.error_outline, color: Colors.orange, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Unable to load active rides',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pull down to refresh',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Format scheduled time for display
String _formatScheduledTime(DateTime scheduledTime) {
  final now = DateTime.now();
  final difference = scheduledTime.difference(now);

  if (difference.inMinutes < 60) {
    return 'in ${difference.inMinutes}m';
  } else if (difference.inHours < 24) {
    return 'in ${difference.inHours}h';
  } else if (difference.inDays == 1) {
    return 'Tomorrow ${scheduledTime.hour}:${scheduledTime.minute.toString().padLeft(2, '0')}';
  } else {
    return '${scheduledTime.month}/${scheduledTime.day} ${scheduledTime.hour}:${scheduledTime.minute.toString().padLeft(2, '0')}';
  }
}

/// Real-time timer widget that shows elapsed time since ride started
class RideElapsedTimer extends StatefulWidget {
  final RideRequestModel ride;
  
  const RideElapsedTimer({
    super.key,
    required this.ride,
  });

  @override
  State<RideElapsedTimer> createState() => _RideElapsedTimerState();
}

class _RideElapsedTimerState extends State<RideElapsedTimer> {
  late Timer _timer;
  String _elapsedTime = '0m 0s';

  @override
  void initState() {
    super.initState();
    _updateElapsedTime();
    
    // Update every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        _updateElapsedTime();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateElapsedTime() {
    if (widget.ride.startedAt == null) {
      setState(() {
        _elapsedTime = 'Not started';
      });
      return;
    }

    final elapsed = DateTime.now().difference(widget.ride.startedAt!);
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes % 60;
    final seconds = elapsed.inSeconds % 60;

    setState(() {
      if (hours > 0) {
        _elapsedTime = '${hours}h ${minutes}m ${seconds}s';
      } else {
        _elapsedTime = '${minutes}m ${seconds}s';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.timer,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Trip Duration',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _elapsedTime,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFeatures: [
                    FontFeature.tabularFigures(), // Monospaced digits
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

