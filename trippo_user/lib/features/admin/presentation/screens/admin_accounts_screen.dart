import 'package:flutter/material.dart';
import '../../../../core/theme/admin_theme.dart';
import '../widgets/admin_stats_card.dart';
import '../widgets/admin_action_button.dart';

/// Admin screen for account verification and management
class AdminAccountsScreen extends StatelessWidget {
  const AdminAccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                    title: 'Total Accounts',
                    value: '0',
                    icon: Icons.account_circle,
                    iconColor: AdminTheme.primaryColor,
                  ),
                ),
                Expanded(
                  child: AdminStatsCard(
                    title: 'Active Accounts',
                    value: '0',
                    icon: Icons.check_circle,
                    iconColor: AdminTheme.successColor,
                  ),
                ),
                Expanded(
                  child: AdminStatsCard(
                    title: 'Pending Verification',
                    value: '0',
                    icon: Icons.pending_actions,
                    iconColor: AdminTheme.warningColor,
                  ),
                ),
                Expanded(
                  child: AdminStatsCard(
                    title: 'Suspended',
                    value: '0',
                    icon: Icons.block,
                    iconColor: AdminTheme.dangerColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Action buttons row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Spacer(),
                AdminActionButton(
                  label: 'Bulk Verify',
                  icon: Icons.verified_user,
                  onPressed: () {
                    // TODO: Implement bulk verification
                  },
                  backgroundColor: AdminTheme.successColor,
                ),
                const SizedBox(width: 8),
                AdminActionButton(
                  label: 'Export',
                  icon: Icons.download,
                  onPressed: () {
                    // TODO: Implement export
                  },
                  isOutlined: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Verification queue (placeholder)
          Expanded(
            child: Card(
              margin: const EdgeInsets.all(16),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified_user,
                      size: 64,
                      color: AdminTheme.textSecondary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No pending verifications',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AdminTheme.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Account verification queue will appear here',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AdminTheme.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '🚧 Phase 6: Account verification system coming soon',
                      style: TextStyle(
                        color: AdminTheme.warningColor,
                        fontStyle: FontStyle.italic,
                      ),
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
}

