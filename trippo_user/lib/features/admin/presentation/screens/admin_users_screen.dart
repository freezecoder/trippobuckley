import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/admin_theme.dart';
import '../../../../data/providers/admin_providers.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/models/payment_method_model.dart';
import '../widgets/admin_stats_card.dart';
import '../widgets/admin_search_bar.dart';
import '../widgets/admin_action_button.dart';
import '../widgets/user_data_table.dart';
import '../widgets/admin_confirmation_dialog.dart';
import '../widgets/edit_contact_info_dialog.dart';
import '../widgets/payment_methods_dialog.dart';

/// Admin screen for managing users (passengers)
class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(userStatsProvider);
    final filteredUsersAsync = ref.watch(filteredUsersProvider);
    final searchQuery = ref.watch(userSearchQueryProvider);
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
                    title: 'Total Users',
                    value: '${stats['total']}',
                    icon: Icons.people,
                    iconColor: AdminTheme.primaryColor,
                  ),
                ),
                Expanded(
                  child: AdminStatsCard(
                    title: 'Active Users',
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
                    title: 'New Users',
                    value: '${stats['new']}',
                    icon: Icons.person_add,
                    iconColor: AdminTheme.infoColor,
                    subtitle: 'This month',
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
                    hintText: 'Search users by name, email, or phone...',
                    onChanged: (value) {
                      ref.read(userSearchQueryProvider.notifier).state = value;
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
                  label: 'Export',
                  icon: Icons.download,
                  onPressed: () {
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
                    ref.read(refreshUsersProvider)();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Users list refreshed')),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Users list (with real data)
          Expanded(
            child: Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: filteredUsersAsync.when(
                  data: (users) {
                    return UserDataTable(
                      users: users,
                      onViewDetails: (user) {
                        _showUserDetails(context, user);
                      },
                      onEditContact: (user) async {
                        await _handleEditContact(context, ref, user);
                      },
                      onManagePayments: (user) {
                        _showPaymentMethods(context, user);
                      },
                      onActivate: (user) async {
                        await _handleActivateUser(context, ref, user);
                      },
                      onDeactivate: (user) async {
                        await _handleDeactivateUser(context, ref, user);
                      },
                      onDelete: (user) async {
                        await _handleDeleteUser(context, ref, user);
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
                          'Error loading users',
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
                            ref.read(refreshUsersProvider)();
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

  void _showUserDetails(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.person, color: AdminTheme.primaryColor),
            const SizedBox(width: 8),
            Expanded(child: Text(user.name)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Email', user.email),
              _buildDetailRow('Phone', user.phoneNumber.isNotEmpty ? user.phoneNumber : 'Not provided'),
              _buildDetailRow('Status', user.isActive ? 'Active' : 'Inactive'),
              _buildDetailRow('Join Date', '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}'),
              _buildDetailRow('Last Login', '${user.lastLogin.day}/${user.lastLogin.month}/${user.lastLogin.year}'),
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

  Future<void> _handleEditContact(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditContactInfoDialog(
        userId: user.uid,
        userName: user.name,
        currentPhone: user.phoneNumber,
        currentAddress: '', // TODO: Fetch from userProfiles
        onSave: (phone, address) async {
          await ref.read(adminRepositoryProvider).updateUserContactInfo(
                userId: user.uid,
                phoneNumber: phone,
                homeAddress: address,
                reason: 'Updated by admin',
              );
          
          ref.read(refreshUsersProvider)();
        },
      ),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Contact info updated for ${user.name}'),
          backgroundColor: AdminTheme.successColor,
        ),
      );
    }
  }

  void _showPaymentMethods(BuildContext context, UserModel user) {
    // TODO: Fetch actual payment methods from userProfiles
    final paymentMethods = <PaymentMethodModel>[];

    showDialog(
      context: context,
      builder: (context) => PaymentMethodsDialog(
        userId: user.uid,
        userName: user.name,
        paymentMethods: paymentMethods,
        onRemove: (method) {
          // TODO: Implement remove payment method
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Remove payment method - coming soon'),
              backgroundColor: AdminTheme.infoColor,
            ),
          );
          Navigator.of(context).pop();
        },
        onSetDefault: (method) {
          // TODO: Implement set default
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Set default payment method - coming soon'),
              backgroundColor: AdminTheme.infoColor,
            ),
          );
          Navigator.of(context).pop();
        },
        onAddNew: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Stripe integration will be added later'),
              backgroundColor: AdminTheme.infoColor,
            ),
          );
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _handleActivateUser(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
  ) async {
    final confirmed = await showAdminConfirmation(
      context: context,
      title: 'Activate User',
      message: 'Are you sure you want to activate ${user.name}?',
      confirmText: 'Activate',
      isDangerous: false,
    );

    if (confirmed && context.mounted) {
      try {
        await ref.read(adminRepositoryProvider).updateUserStatus(
              userId: user.uid,
              isActive: true,
              reason: 'Activated by admin',
            );
        
        ref.read(refreshUsersProvider)();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${user.name} has been activated'),
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

  Future<void> _handleDeactivateUser(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
  ) async {
    final confirmed = await showAdminConfirmation(
      context: context,
      title: 'Deactivate User',
      message: 'Are you sure you want to deactivate ${user.name}? They will not be able to book rides.',
      confirmText: 'Deactivate',
      requiresReason: true,
      isDangerous: true,
      onConfirmWithReason: (reason) async {
        try {
          await ref.read(adminRepositoryProvider).updateUserStatus(
                userId: user.uid,
                isActive: false,
                reason: reason,
              );
          
          ref.read(refreshUsersProvider)();
        } catch (e) {
          rethrow;
        }
      },
    );

    if (confirmed && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.name} has been deactivated'),
          backgroundColor: AdminTheme.warningColor,
        ),
      );
    }
  }

  Future<void> _handleDeleteUser(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
  ) async {
    final confirmed = await showAdminConfirmation(
      context: context,
      title: 'Delete User',
      message: 'Are you sure you want to delete ${user.name}? This action cannot be undone.',
      confirmText: 'Delete',
      requiresReason: true,
      isDangerous: true,
    );

    if (confirmed && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delete functionality will be implemented later'),
          backgroundColor: AdminTheme.infoColor,
        ),
      );
    }
  }
}

