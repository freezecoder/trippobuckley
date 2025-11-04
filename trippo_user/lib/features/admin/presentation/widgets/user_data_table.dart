import 'package:flutter/material.dart';
import '../../../../core/theme/admin_theme.dart';
import '../../../../data/models/user_model.dart';
import 'admin_action_button.dart';

/// Data table widget for displaying users (passengers)
class UserDataTable extends StatelessWidget {
  final List<UserModel> users;
  final Function(UserModel) onViewDetails;
  final Function(UserModel) onEditContact;
  final Function(UserModel) onManagePayments;
  final Function(UserModel) onActivate;
  final Function(UserModel) onDeactivate;
  final Function(UserModel) onDelete;

  const UserDataTable({
    super.key,
    required this.users,
    required this.onViewDetails,
    required this.onEditContact,
    required this.onManagePayments,
    required this.onActivate,
    required this.onDeactivate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: AdminTheme.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No users found',
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
        rows: users.map((user) {
          return DataRow(
            cells: [
              // Name
              DataCell(
                Text(
                  user.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              // Email
              DataCell(
                Text(user.email),
              ),
              
              // Phone
              DataCell(
                Text(user.phoneNumber.isNotEmpty 
                    ? user.phoneNumber 
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
                    color: user.isActive
                        ? AdminTheme.successColor.withValues(alpha: 0.1)
                        : AdminTheme.dangerColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: user.isActive
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
                  '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
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
                      onPressed: () => onViewDetails(user),
                      tooltip: 'View Details',
                      color: AdminTheme.infoColor,
                    ),
                    const SizedBox(width: 4),
                    AdminIconButton(
                      icon: Icons.edit,
                      onPressed: () => onEditContact(user),
                      tooltip: 'Edit Contact Info',
                      color: AdminTheme.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    AdminIconButton(
                      icon: Icons.credit_card,
                      onPressed: () => onManagePayments(user),
                      tooltip: 'Manage Payments',
                      color: AdminTheme.successColor,
                    ),
                    const SizedBox(width: 4),
                    if (user.isActive)
                      AdminIconButton(
                        icon: Icons.block,
                        onPressed: () => onDeactivate(user),
                        tooltip: 'Deactivate',
                        color: AdminTheme.warningColor,
                      )
                    else
                      AdminIconButton(
                        icon: Icons.check_circle,
                        onPressed: () => onActivate(user),
                        tooltip: 'Activate',
                        color: AdminTheme.successColor,
                      ),
                    const SizedBox(width: 4),
                    AdminIconButton(
                      icon: Icons.delete,
                      onPressed: () => onDelete(user),
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

