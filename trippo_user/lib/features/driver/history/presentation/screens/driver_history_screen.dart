import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../data/providers/ride_providers.dart';
import '../../../../../core/constants/route_constants.dart';
import '../../../../shared/presentation/widgets/star_rating_widget.dart';

/// Driver ride history screen
class DriverHistoryScreen extends ConsumerWidget {
  const DriverHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rideHistory = ref.watch(driverRideHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride History'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: RefreshIndicator(
        onRefresh: () async {
          // Invalidate the provider to force a refresh
          ref.invalidate(driverRideHistoryProvider);
          // Wait for the new data to load
          await ref.read(driverRideHistoryProvider.future);
        },
        backgroundColor: Colors.white,
        color: Colors.blue,
        child: rideHistory.when(
        data: (rides) {
          if (rides.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No ride history yet',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rides.length,
            itemBuilder: (context, index) {
              final ride = rides[index];
              final hasRating = ride.driverRating != null;
              final isCancelled = ride.status.name == 'cancelled';
              final isCompleted = ride.status.name == 'completed';
              
              return Card(
                color: Colors.grey[900],
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: !hasRating && isCompleted
                      ? () {
                          // Navigate to rating screen if not rated yet
                          context.pushNamed(
                            RouteNames.ratingScreen,
                            extra: {
                              'rideId': ride.id,
                              'isDriver': true,
                            },
                          );
                        }
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Status icon
                            Icon(
                              isCancelled ? Icons.cancel : Icons.check_circle,
                              color: isCancelled ? Colors.orange : Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            // Status badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isCancelled 
                                  ? Colors.orange.withValues(alpha: 0.2)
                                  : Colors.green.withValues(alpha: 0.2),
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
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                ride.dropoffAddress,
                                style: TextStyle(
                                  color: isCancelled ? Colors.grey[400] : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  decoration: isCancelled ? TextDecoration.lineThrough : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              isCancelled ? 'N/A' : '\$${ride.fare.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: isCancelled ? Colors.grey : Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Actual ride duration with fraud detection
                        if (isCompleted && !isCancelled)
                          Row(
                            children: [
                              Icon(
                                ride.isSuspiciouslyShort 
                                  ? Icons.warning_amber_rounded 
                                  : Icons.timer_outlined,
                                size: 14,
                                color: ride.isSuspiciouslyShort 
                                  ? Colors.red 
                                  : Colors.blue,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Duration: ${ride.actualDurationFormatted}',
                                style: TextStyle(
                                  color: ride.isSuspiciouslyShort 
                                    ? Colors.red 
                                    : Colors.blue,
                                  fontSize: 12,
                                  fontWeight: ride.isSuspiciouslyShort 
                                    ? FontWeight.bold 
                                    : FontWeight.normal,
                                ),
                              ),
                              if (ride.isSuspiciouslyShort) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(3),
                                    border: Border.all(
                                      color: Colors.red.withValues(alpha: 0.5),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Text(
                                    'REVIEW',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        const SizedBox(height: 4),
                        Text(
                          ride.pickupAddress,
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Show cancellation reason if cancelled
                        if (isCancelled)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, 
                                  color: Colors.orange, size: 16),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Ride was cancelled',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Rating display or prompt
                        if (hasRating && !isCancelled)
                          Row(
                            children: [
                              const Text(
                                'Your rating: ',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              CompactStarRating(rating: ride.driverRating!, size: 14),
                            ],
                          )
                        else if (isCompleted && !hasRating)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Tap to rate passenger',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 11,
                              ),
                            ),
                          ),
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
          // Check if it's a "no rides" scenario (missing index, empty collection, etc.)
          final errorMessage = error.toString().toLowerCase();
          final isEmptyScenario = errorMessage.contains('index') ||
              errorMessage.contains('no rides') ||
              errorMessage.contains('not found');

          if (isEmptyScenario) {
            // Show friendly empty state instead of error
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 200),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No ride history yet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Start accepting rides to build your history',
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

          // Show actual error for other types of errors
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 200),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.orange),
                  const SizedBox(height: 16),
                  const Text(
                    'Unable to load history',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pull down to refresh',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                ],
              ),
            ],
          );
        },
        ),
      ),
    );
  }
}

