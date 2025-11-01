import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/providers/ride_providers.dart';
import '../../../../data/providers/auth_providers.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../data/models/ride_request_model.dart';
import '../Profile_Screen/Ride_History_Screen/ride_history_screen.dart';
import 'widgets/driver_tracking_map.dart';
import 'widgets/driver_info_card.dart';

/// Provider to track rides pending rating (completed but not rated yet)
final ridesPendingRatingProvider = StateProvider<Set<String>>((ref) => {});

/// Passenger's active rides screen showing current rides
class UserRidesScreen extends ConsumerStatefulWidget {
  const UserRidesScreen({super.key});

  @override
  ConsumerState<UserRidesScreen> createState() => _UserRidesScreenState();
}

class _UserRidesScreenState extends ConsumerState<UserRidesScreen> {
  final Map<String, Timer> _ratingTimers = {};

  @override
  void dispose() {
    // Cancel all timers
    for (var timer in _ratingTimers.values) {
      timer.cancel();
    }
    _ratingTimers.clear();
    super.dispose();
  }

  /// Start a 10-minute timer for a completed ride
  void _startRatingTimer(String rideId) {
    // Cancel existing timer if any
    _ratingTimers[rideId]?.cancel();
    
    // Start new 10-minute timer
    _ratingTimers[rideId] = Timer(const Duration(minutes: 10), () {
      // Remove from pending rating set
      final pendingSet = ref.read(ridesPendingRatingProvider);
      ref.read(ridesPendingRatingProvider.notifier).state = 
        {...pendingSet}..remove(rideId);
      
      // Clean up timer
      _ratingTimers.remove(rideId);
      
      debugPrint('⏰ Rating timer expired for ride: $rideId');
    });
    
    debugPrint('⏱️ Started 10-minute rating timer for ride: $rideId');
  }

  @override
  Widget build(BuildContext context) {
    final activeRides = ref.watch(userActiveRidesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Rides'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userActiveRidesProvider);
          await ref.read(userActiveRidesProvider.future);
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
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions_car_outlined, 
                          size: 80, color: Colors.grey),
                        SizedBox(height: 24),
                        Text(
                          'No Active Rides',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Book a ride from the Home tab',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            // Get pending rating set BEFORE filtering (avoid ref.watch in where clause)
            final pendingRatingSet = ref.watch(ridesPendingRatingProvider);
            
            // Filter rides: show pending/accepted/ongoing + completed-not-rated
            final visibleRides = rides.where((ride) {
              // Show if ride is active (pending/accepted/ongoing)
              if (ride.isActive) return true;
              
              // Show if completed and not rated yet
              if (ride.status.name == 'completed' && ride.userRating == null) {
                // Check if still in 10-minute window
                if (pendingRatingSet.contains(ride.id)) {
                  return true;
                }
                
                // If just completed, add to pending and start timer
                if (ride.completedAt != null) {
                  final timeSinceCompletion = DateTime.now().difference(ride.completedAt!);
                  if (timeSinceCompletion.inMinutes < 10) {
                    // Add to pending rating set
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      final pendingSet = ref.read(ridesPendingRatingProvider);
                      ref.read(ridesPendingRatingProvider.notifier).state = 
                        {...pendingSet, ride.id};
                      _startRatingTimer(ride.id);
                    });
                    return true;
                  }
                }
              }
              
              return false;
            }).toList();

            if (visibleRides.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 200),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'All rides completed!',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Check your Ride History in Profile',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: visibleRides.length,
              itemBuilder: (context, index) {
                final ride = visibleRides[index];
                return _RideCard(ride: ride);
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
          error: (error, stack) {
            // Gracefully handle errors
            debugPrint('⚠️ Error loading rides: $error');
            
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 150),
                Center(
                  child: Column(
                    children: [
                      const Icon(Icons.info_outline, 
                        color: Colors.orange, size: 64),
                      const SizedBox(height: 24),
                      const Text(
                        'Unable to Load Rides',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This could be due to permissions or network',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RideHistoryScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.history),
                        label: const Text('View Ride History'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: const BorderSide(color: Colors.blue),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () {
                          ref.invalidate(userActiveRidesProvider);
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Individual ride card widget
class _RideCard extends ConsumerWidget {
  final RideRequestModel ride;

  const _RideCard({required this.ride});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPending = ride.status.name == 'pending';
    final isAccepted = ride.status.name == 'accepted';
    final isOngoing = ride.status.name == 'ongoing';
    final isCompleted = ride.status.name == 'completed';
    final isCancelled = ride.status.name == 'cancelled';

    // Determine status color and icon
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.help_outline;
    String statusText = 'Unknown';

    if (isPending) {
      statusColor = Colors.orange;
      statusIcon = Icons.hourglass_empty;
      statusText = 'WAITING FOR DRIVER';
    } else if (isAccepted) {
      statusColor = Colors.blue;
      statusIcon = Icons.check_circle_outline;
      statusText = 'DRIVER ACCEPTED';
    } else if (isOngoing) {
      statusColor = Colors.green;
      statusIcon = Icons.local_taxi;
      statusText = 'IN PROGRESS';
    } else if (isCompleted) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'COMPLETED';
    } else if (isCancelled) {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
      statusText = 'CANCELLED';
    }

    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (isAccepted || isOngoing) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Driver: ${ride.driverEmail ?? "Assigned"}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Fare
                Text(
                  '\$${ride.fare.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const Divider(height: 24, color: Colors.grey),

            // Driver Information (for accepted/ongoing rides)
            if ((isAccepted || isOngoing) && ride.driverId != null) ...[
              DriverInfoCard(
                driverId: ride.driverId!,
                driverEmail: ride.driverEmail,
              ),
              const SizedBox(height: 16),
            ],

            // Live Driver Tracking Map (for accepted/ongoing rides)
            if (isAccepted || isOngoing) ...[
              DriverTrackingMap(ride: ride),
              const SizedBox(height: 16),
              const Divider(height: 24, color: Colors.grey),
            ],

            // Route Information
            _buildLocationRow(
              Icons.trip_origin,
              'Pickup',
              ride.pickupAddress,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildLocationRow(
              Icons.location_on,
              'Dropoff',
              ride.dropoffAddress,
              Colors.red,
            ),

            // Distance and Duration
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.straighten, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${ride.distance.toStringAsFixed(1)} km',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${ride.duration} min',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),

            // Scheduled time if applicable
            if (ride.isScheduled && ride.scheduledTime != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule, size: 14, color: Colors.purple),
                    const SizedBox(width: 4),
                    Text(
                      'Scheduled: ${_formatDateTime(ride.scheduledTime!)}',
                      style: const TextStyle(
                        color: Colors.purple,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action Buttons
            if (isCompleted && ride.userRating == null) ...[
              const SizedBox(height: 16),
              const Divider(height: 1, color: Colors.grey),
              const SizedBox(height: 16),
              
              // Rate Driver Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.star_outline, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'How was your ride?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Navigate to rating screen
                          context.pushNamed(
                            RouteNames.ratingScreen,
                            extra: {
                              'rideId': ride.id,
                              'isDriver': false,
                            },
                          );
                        },
                        icon: const Icon(Icons.star),
                        label: const Text('Rate Driver'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rate within 10 minutes to help us improve',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],

            // Cancel button for pending rides
            if (isPending) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    // Show confirmation
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Cancel Ride?'),
                        content: const Text(
                          'Are you sure you want to cancel this ride request?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('No'),
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
                        final currentUser = await ref.read(currentUserProvider.future);
                        if (currentUser == null) return;

                        final rideRepo = ref.read(rideRepositoryProvider);
                        await rideRepo.cancelRideRequest(
                          rideId: ride.id,
                          userId: currentUser.uid,
                          cancellationReason: 'Cancelled by passenger',
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
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel Ride'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
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
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                address,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inMinutes < 60) {
      return 'in ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'in ${difference.inHours}h';
    } else if (dateTime.day == now.day + 1) {
      return 'Tomorrow ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}

