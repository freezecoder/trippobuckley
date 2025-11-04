import 'package:flutter/material.dart';
import '../../../../core/theme/admin_theme.dart';
import '../../../../data/models/ride_request_model.dart';
import 'admin_action_button.dart';

/// Data table widget for displaying trips
class TripDataTable extends StatelessWidget {
  final List<RideRequestModel> rides;
  final Function(RideRequestModel) onViewDetails;

  const TripDataTable({
    super.key,
    required this.rides,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    if (rides.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 64,
              color: AdminTheme.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No trips found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AdminTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or date range',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AdminTheme.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
          AdminTheme.primaryColor.withValues(alpha: 0.1),
        ),
        columnSpacing: 24,
        columns: const [
          DataColumn(
            label: Text(
              'ID',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AdminTheme.textPrimary,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Date',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AdminTheme.textPrimary,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'User',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AdminTheme.textPrimary,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Driver',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AdminTheme.textPrimary,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Route',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AdminTheme.textPrimary,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Fare',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AdminTheme.textPrimary,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Distance',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AdminTheme.textPrimary,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Status',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AdminTheme.textPrimary,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Actions',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AdminTheme.textPrimary,
              ),
            ),
          ),
        ],
        rows: rides.map((ride) {
          return DataRow(
            cells: [
              // ID (shortened)
              DataCell(
                Text(
                  ride.id.length > 8 ? '...${ride.id.substring(ride.id.length - 8)}' : ride.id,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
              
              // Date
              DataCell(
                Text(
                  '${ride.requestedAt.day}/${ride.requestedAt.month}/${ride.requestedAt.year}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              
              // User
              DataCell(
                Text(
                  ride.userEmail.length > 20 
                      ? '${ride.userEmail.substring(0, 17)}...' 
                      : ride.userEmail,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              
              // Driver
              DataCell(
                Text(
                  ride.driverEmail != null
                      ? (ride.driverEmail!.length > 20 
                          ? '${ride.driverEmail!.substring(0, 17)}...' 
                          : ride.driverEmail!)
                      : 'Not assigned',
                  style: TextStyle(
                    fontSize: 13,
                    color: ride.driverEmail != null 
                        ? AdminTheme.textPrimary 
                        : AdminTheme.textSecondary,
                  ),
                ),
              ),
              
              // Route
              DataCell(
                SizedBox(
                  width: 200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        ride.pickupAddress.length > 30
                            ? '${ride.pickupAddress.substring(0, 27)}...'
                            : ride.pickupAddress,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '↓ ${ride.dropoffAddress.length > 30 ? '${ride.dropoffAddress.substring(0, 27)}...' : ride.dropoffAddress}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AdminTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Fare
              DataCell(
                Text(
                  '\$${ride.fare.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AdminTheme.successColor,
                  ),
                ),
              ),
              
              // Distance
              DataCell(
                Text(
                  '${ride.distance.toStringAsFixed(1)} km',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              
              // Status
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(ride.status.name).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ride.statusDisplayText,
                    style: TextStyle(
                      color: _getStatusColor(ride.status.name),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              
              // Actions
              DataCell(
                AdminIconButton(
                  icon: Icons.visibility,
                  onPressed: () => onViewDetails(ride),
                  tooltip: 'View Details',
                  color: AdminTheme.infoColor,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AdminTheme.successColor;
      case 'ongoing':
        return AdminTheme.infoColor;
      case 'pending':
        return AdminTheme.warningColor;
      case 'cancelled':
        return AdminTheme.dangerColor;
      default:
        return AdminTheme.textSecondary;
    }
  }
}

