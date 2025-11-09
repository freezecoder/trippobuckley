import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../data/providers/ride_providers.dart';
import '../../../../../core/constants/route_constants.dart';
import '../../../../../features/shared/presentation/widgets/star_rating_widget.dart';

/// User's ride history screen (completed/cancelled rides)
class RideHistoryScreen extends ConsumerWidget {
  const RideHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rideHistory = ref.watch(userRideHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride & Delivery History'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userRideHistoryProvider);
          await ref.read(userRideHistoryProvider.future);
        },
        backgroundColor: Colors.white,
        color: Colors.blue,
        child: rideHistory.when(
          data: (rides) {
            if (rides.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 200),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 80,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No ride history yet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[300],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your completed rides will appear here',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
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
              itemCount: rides.length,
              itemBuilder: (context, index) {
                final ride = rides[index];
                final hasRating = ride.userRating != null;
                final isCancelled = ride.status.name == 'cancelled';
                final isCompleted = ride.status.name == 'completed';

                return Card(
                  color: Colors.grey[900],
                  margin: const EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    onTap: !hasRating && isCompleted
                        ? () {
                            // Navigate to rating screen if not rated yet
                            context.pushNamed(
                              RouteNames.ratingScreen,
                              extra: {
                                'rideId': ride.id,
                                'isDriver': false,
                              },
                            );
                          }
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Delivery Badge (if it's a delivery)
                          if (ride.isDelivery)
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.orange[700]!, Colors.deepOrange[600]!],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    '📦 DELIVERY',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (ride.deliveryCategory != null) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      _getCategoryIcon(ride.deliveryCategory),
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          // Status and Fare Row
                          Row(
                            children: [
                              Icon(
                                isCancelled ? Icons.cancel : Icons.check_circle,
                                color: isCancelled ? Colors.orange : Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isCancelled
                                      ? Colors.orange.withOpacity(0.2)
                                      : Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isCancelled ? 'CANCELLED' : 'COMPLETED',
                                  style: TextStyle(
                                    color: isCancelled ? Colors.orange : Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              const Spacer(),
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

                          const SizedBox(height: 12),

                          // Pickup Location
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.trip_origin, color: Colors.blue, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  ride.pickupAddress,
                                  style: TextStyle(color: Colors.grey[300], fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Dropoff Location
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on, color: Colors.red, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  ride.dropoffAddress,
                                  style: TextStyle(color: Colors.grey[300], fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Driver Info
                          if (ride.driverEmail != null)
                            Row(
                              children: [
                                Icon(Icons.person, size: 16, color: Colors.grey[500]),
                                const SizedBox(width: 8),
                                Text(
                                  'Driver: ${ride.driverEmail}',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),

                          // Date
                          if (ride.completedAt != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Text(
                                  _formatDate(ride.completedAt!),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          // Rating Display or Action
                          if (isCompleted && !isCancelled) ...[
                            const SizedBox(height: 12),
                            const Divider(height: 1, color: Colors.grey),
                            const SizedBox(height: 12),
                            
                            if (hasRating)
                              // Show the rating given
                              Row(
                                children: [
                                  const Text(
                                    'Your rating: ',
                                    style: TextStyle(color: Colors.grey, fontSize: 13),
                                  ),
                                  CompactStarRating(rating: ride.userRating!, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${ride.userRating!.toStringAsFixed(1)}/5',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            else
                              // Show rate button
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.blue.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star_outline, 
                                      color: Colors.blue, size: 18),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'Tap to rate this driver',
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios,
                                      color: Colors.blue, size: 14),
                                  ],
                                ),
                              ),
                          ],

                          // Cancellation Notice
                          if (isCancelled) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.3),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.info_outline, 
                                    color: Colors.orange, size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    'This ride was cancelled',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
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
          error: (error, stack) {
            final errorMessage = error.toString().toLowerCase();
            final isEmptyScenario = errorMessage.contains('index') ||
                errorMessage.contains('no rides') ||
                errorMessage.contains('not found');

            if (isEmptyScenario) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 200),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.history, size: 80, color: Colors.grey[600]),
                        const SizedBox(height: 24),
                        Text(
                          'No ride history yet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[300],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your completed rides will appear here',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 200),
                Center(
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 64),
                      const SizedBox(height: 16),
                      const Text(
                        'Unable to load history',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pull down to refresh',
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
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

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final rideDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (rideDate == today) {
      return 'Today ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (rideDate == yesterday) {
      return 'Yesterday ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}

