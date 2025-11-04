import 'package:flutter/material.dart';
import '../../../../core/theme/admin_theme.dart';
import '../../../../data/models/user_model.dart';
import 'admin_action_button.dart';

/// Data table widget for displaying drivers
class DriverDataTable extends StatelessWidget {
  final List<UserModel> drivers;
  final Function(UserModel) onViewDetails;
  final Function(UserModel) onActivate;
  final Function(UserModel) onDeactivate;
  final Function(UserModel) onDelete;

  const DriverDataTable({
    super.key,
    required this.drivers,
    required this.onViewDetails,
    required this.onActivate,
    required this.onDeactivate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (drivers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_taxi_outlined,
              size: 64,
              color: AdminTheme.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No drivers found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AdminTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
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
        columns: const [
          DataColumn(
            label: Text(
              'Name',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AdminTheme.textPrimary,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Email',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AdminTheme.textPrimary,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Phone',
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
              'Join Date',
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
        rows: drivers.map((driver) {
          return DataRow(
            cells: [
              // Name
              DataCell(
                Text(
                  driver.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              // Email
              DataCell(
                Text(driver.email),
              ),
              
              // Phone
              DataCell(
                Text(driver.phoneNumber.isNotEmpty 
                    ? driver.phoneNumber 
                    : 'Not provided'),
              ),
              
              // Status
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: driver.isActive
                        ? AdminTheme.successColor.withValues(alpha: 0.1)
                        : AdminTheme.dangerColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    driver.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: driver.isActive
                          ? AdminTheme.successColor
                          : AdminTheme.dangerColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              
              // Join Date
              DataCell(
                Text(
                  '${driver.createdAt.day}/${driver.createdAt.month}/${driver.createdAt.year}',
                  style: const TextStyle(
                    color: AdminTheme.textSecondary,
                  ),
                ),
              ),
              
              // Actions
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AdminIconButton(
                      icon: Icons.visibility,
                      onPressed: () => onViewDetails(driver),
                      tooltip: 'View Details',
                      color: AdminTheme.infoColor,
                    ),
                    const SizedBox(width: 4),
                    if (driver.isActive)
                      AdminIconButton(
                        icon: Icons.block,
                        onPressed: () => onDeactivate(driver),
                        tooltip: 'Deactivate',
                        color: AdminTheme.warningColor,
                      )
                    else
                      AdminIconButton(
                        icon: Icons.check_circle,
                        onPressed: () => onActivate(driver),
                        tooltip: 'Activate',
                        color: AdminTheme.successColor,
                      ),
                    const SizedBox(width: 4),
                    AdminIconButton(
                      icon: Icons.delete,
                      onPressed: () => onDelete(driver),
                      tooltip: 'Delete',
                      color: AdminTheme.dangerColor,
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

