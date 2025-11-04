import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/admin_theme.dart';
import '../../../../data/providers/admin_providers.dart';
import '../../../../data/models/ride_request_model.dart';
import '../widgets/admin_stats_card.dart';
import '../widgets/admin_search_bar.dart';
import '../widgets/admin_action_button.dart';
import '../widgets/trip_data_table.dart';
import '../widgets/trip_analytics_dashboard.dart';

/// Admin screen for monitoring trips and analytics
class AdminTripsScreen extends ConsumerStatefulWidget {
  const AdminTripsScreen({super.key});

  @override
  ConsumerState<AdminTripsScreen> createState() => _AdminTripsScreenState();
}

class _AdminTripsScreenState extends ConsumerState<AdminTripsScreen> {
  bool _showAnalytics = false;

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(rideStatsProvider);
    final filteredRidesAsync = ref.watch(filteredRidesProvider);
    final searchQuery = ref.watch(rideSearchQueryProvider);
    return Scaffold(
      backgroundColor: AdminTheme.backgroundColor,
      body: Column(
        children: [
          // Stats cards row
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: AdminStatsCard(
                    title: 'Total Rides',
                    value: '${stats['total']}',
                    icon: Icons.map,
                    iconColor: AdminTheme.primaryColor,
                  ),
                ),
                Expanded(
                  child: AdminStatsCard(
                    title: 'Completed',
                    value: '${stats['completed']}',
                    icon: Icons.check_circle,
                    iconColor: AdminTheme.successColor,
                    subtitle: '\$${(stats['totalRevenue'] as double).toStringAsFixed(2)}',
                  ),
                ),
                Expanded(
                  child: AdminStatsCard(
                    title: 'Ongoing',
                    value: '${stats['ongoing']}',
                    icon: Icons.directions_car,
                    iconColor: AdminTheme.infoColor,
                  ),
                ),
                Expanded(
                  child: AdminStatsCard(
                    title: 'Cancelled',
                    value: '${stats['cancelled']}',
                    icon: Icons.cancel,
                    iconColor: AdminTheme.dangerColor,
                  ),
                ),
              ],
            ),
          ),

          // Search and actions bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: AdminSearchBar(
                    hintText: 'Search rides by ID, user, driver, or location...',
                    onChanged: (value) {
                      ref.read(rideSearchQueryProvider.notifier).state = value;
                    },
                    onFilterTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Filters coming in next update')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                AdminActionButton(
                  label: _showAnalytics ? 'Show Table' : 'Analytics',
                  icon: _showAnalytics ? Icons.table_chart : Icons.analytics,
                  onPressed: () {
                    setState(() {
                      _showAnalytics = !_showAnalytics;
                    });
                  },
                  backgroundColor: AdminTheme.infoColor,
                ),
                const SizedBox(width: 8),
                AdminActionButton(
                  label: 'Refresh',
                  icon: Icons.refresh,
                  onPressed: () {
                    ref.read(refreshRidesProvider)();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Trips list refreshed')),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Trips list or analytics (with real data)
          Expanded(
            child: filteredRidesAsync.when(
              data: (rides) {
                if (_showAnalytics) {
                  // Show analytics dashboard
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: TripAnalyticsDashboard(rides: rides),
                  );
                } else {
                  // Show trips table
                  return Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TripDataTable(
                        rides: rides,
                        onViewDetails: (ride) {
                          _showTripDetails(context, ride);
                        },
                      ),
                    ),
                  );
                }
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AdminTheme.dangerColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading trips',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AdminTheme.textSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    AdminActionButton(
                      label: 'Retry',
                      icon: Icons.refresh,
                      onPressed: () {
                        ref.read(refreshRidesProvider)();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTripDetails(BuildContext context, RideRequestModel ride) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(Icons.map, color: AdminTheme.primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Trip Details',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                
                const Divider(height: 32),
                
                // Trip Information
                _buildSectionTitle(context, 'Trip Information'),
                _buildDetailRow('Trip ID', ride.id),
                _buildDetailRow('Status', ride.statusDisplayText),
                _buildDetailRow('Vehicle Type', ride.vehicleType),
                _buildDetailRow('Requested At', _formatDateTime(ride.requestedAt)),
                if (ride.acceptedAt != null)
                  _buildDetailRow('Accepted At', _formatDateTime(ride.acceptedAt!)),
                if (ride.startedAt != null)
                  _buildDetailRow('Started At', _formatDateTime(ride.startedAt!)),
                if (ride.completedAt != null)
                  _buildDetailRow('Completed At', _formatDateTime(ride.completedAt!)),
                
                const SizedBox(height: 24),
                
                // Participants
                _buildSectionTitle(context, 'Participants'),
                _buildDetailRow('User Email', ride.userEmail),
                _buildDetailRow('Driver Email', ride.driverEmail ?? 'Not assigned'),
                if (ride.userRating != null)
                  _buildDetailRow('User Rating', '${ride.userRating} ⭐'),
                if (ride.driverRating != null)
                  _buildDetailRow('Driver Rating', '${ride.driverRating} ⭐'),
                
                const SizedBox(height: 24),
                
                // Route
                _buildSectionTitle(context, 'Route'),
                _buildDetailRow('Pickup', ride.pickupAddress),
                _buildDetailRow('Dropoff', ride.dropoffAddress),
                _buildDetailRow('Distance', '${ride.distance.toStringAsFixed(2)} km'),
                _buildDetailRow('Est. Duration', '${ride.duration} min'),
                if (ride.actualDurationMinutes != null)
                  _buildDetailRow('Actual Duration', ride.actualDurationFormatted),
                
                const SizedBox(height: 24),
                
                // Pricing
                _buildSectionTitle(context, 'Pricing'),
                _buildDetailRow('Fare', '\$${ride.fare.toStringAsFixed(2)}'),
                
                const SizedBox(height: 24),
                
                // Close button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AdminTheme.primaryColor,
            ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AdminTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AdminTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

