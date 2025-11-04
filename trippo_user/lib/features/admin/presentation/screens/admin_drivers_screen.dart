import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/admin_theme.dart';
import '../../../../data/providers/admin_providers.dart';
import '../../../../data/models/user_model.dart';
import '../widgets/admin_stats_card.dart';
import '../widgets/admin_search_bar.dart';
import '../widgets/admin_action_button.dart';
import '../widgets/driver_data_table.dart';
import '../widgets/admin_confirmation_dialog.dart';

/// Admin screen for managing drivers
class AdminDriversScreen extends ConsumerWidget {
  const AdminDriversScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(driverStatsProvider);
    final filteredDriversAsync = ref.watch(filteredDriversProvider);
    final searchQuery = ref.watch(driverSearchQueryProvider);
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
                    title: 'Total Drivers',
                    value: '${stats['total']}',
                    icon: Icons.local_taxi,
                    iconColor: AdminTheme.primaryColor,
                  ),
                ),
                Expanded(
                  child: AdminStatsCard(
                    title: 'Active Drivers',
                    value: '${stats['active']}',
                    icon: Icons.check_circle,
                    iconColor: AdminTheme.successColor,
                  ),
                ),
                Expanded(
                  child: AdminStatsCard(
                    title: 'Inactive',
                    value: '${stats['inactive']}',
                    icon: Icons.block,
                    iconColor: AdminTheme.warningColor,
                  ),
                ),
                Expanded(
                  child: AdminStatsCard(
                    title: 'Pending',
                    value: '${stats['pending']}',
                    icon: Icons.hourglass_empty,
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
                    hintText: 'Search drivers by name, email, or phone...',
                    onChanged: (value) {
                      ref.read(driverSearchQueryProvider.notifier).state = value;
                    },
                    onFilterTap: () {
                      // TODO: Show filter dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Filters coming in next update')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                AdminActionButton(
                  label: 'Export',
                  icon: Icons.download,
                  onPressed: () {
                    // TODO: Implement export to CSV
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Export feature coming soon')),
                    );
                  },
                  isOutlined: true,
                ),
                const SizedBox(width: 8),
                AdminActionButton(
                  label: 'Refresh',
                  icon: Icons.refresh,
                  onPressed: () {
                    ref.read(refreshDriversProvider)();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Drivers list refreshed')),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Drivers list (with data)
          Expanded(
            child: Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: filteredDriversAsync.when(
                  data: (drivers) {
                    return DriverDataTable(
                      drivers: drivers,
                      onViewDetails: (driver) {
                        _showDriverDetails(context, driver);
                      },
                      onActivate: (driver) async {
                        await _handleActivateDriver(context, ref, driver);
                      },
                      onDeactivate: (driver) async {
                        await _handleDeactivateDriver(context, ref, driver);
                      },
                      onDelete: (driver) async {
                        await _handleDeleteDriver(context, ref, driver);
                      },
                    );
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
                          'Error loading drivers',
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
                            ref.read(refreshDriversProvider)();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDriverDetails(BuildContext context, UserModel driver) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.local_taxi, color: AdminTheme.primaryColor),
            const SizedBox(width: 8),
            Expanded(child: Text(driver.name)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Email', driver.email),
              _buildDetailRow('Phone', driver.phoneNumber.isNotEmpty ? driver.phoneNumber : 'Not provided'),
              _buildDetailRow('Status', driver.isActive ? 'Active' : 'Inactive'),
              _buildDetailRow('Join Date', '${driver.createdAt.day}/${driver.createdAt.month}/${driver.createdAt.year}'),
              _buildDetailRow('Last Login', '${driver.lastLogin.day}/${driver.lastLogin.month}/${driver.lastLogin.year}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
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

  Future<void> _handleActivateDriver(
    BuildContext context,
    WidgetRef ref,
    UserModel driver,
  ) async {
    final confirmed = await showAdminConfirmation(
      context: context,
      title: 'Activate Driver',
      message: 'Are you sure you want to activate ${driver.name}?',
      confirmText: 'Activate',
      isDangerous: false,
    );

    if (confirmed && context.mounted) {
      try {
        await ref.read(adminRepositoryProvider).updateDriverStatus(
              driverId: driver.uid,
              isActive: true,
              reason: 'Activated by admin',
            );
        
        ref.read(refreshDriversProvider)();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${driver.name} has been activated'),
              backgroundColor: AdminTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AdminTheme.dangerColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleDeactivateDriver(
    BuildContext context,
    WidgetRef ref,
    UserModel driver,
  ) async {
    final confirmed = await showAdminConfirmation(
      context: context,
      title: 'Deactivate Driver',
      message: 'Are you sure you want to deactivate ${driver.name}? They will not be able to accept rides.',
      confirmText: 'Deactivate',
      requiresReason: true,
      isDangerous: true,
      onConfirmWithReason: (reason) async {
        try {
          await ref.read(adminRepositoryProvider).updateDriverStatus(
                driverId: driver.uid,
                isActive: false,
                reason: reason,
              );
          
          ref.read(refreshDriversProvider)();
        } catch (e) {
          rethrow;
        }
      },
    );

    if (confirmed && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${driver.name} has been deactivated'),
          backgroundColor: AdminTheme.warningColor,
        ),
      );
    }
  }

  Future<void> _handleDeleteDriver(
    BuildContext context,
    WidgetRef ref,
    UserModel driver,
  ) async {
    final confirmed = await showAdminConfirmation(
      context: context,
      title: 'Delete Driver',
      message: 'Are you sure you want to delete ${driver.name}? This action cannot be undone.',
      confirmText: 'Delete',
      requiresReason: true,
      isDangerous: true,
    );

    if (confirmed && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delete functionality will be implemented in Phase 4'),
          backgroundColor: AdminTheme.infoColor,
        ),
      );
    }
  }
}

