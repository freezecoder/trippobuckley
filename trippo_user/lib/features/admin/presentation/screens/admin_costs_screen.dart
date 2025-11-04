import 'package:flutter/material.dart';
import '../../../../core/theme/admin_theme.dart';
import '../widgets/admin_stats_card.dart';
import '../widgets/admin_action_button.dart';

/// Admin screen for cost analysis and revenue management
class AdminCostsScreen extends StatelessWidget {
  const AdminCostsScreen({super.key});

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
                    title: 'Total Revenue',
                    value: '\$0.00',
                    icon: Icons.attach_money,
                    iconColor: AdminTheme.successColor,
                    subtitle: '+\$0 today',
                  ),
                ),
                Expanded(
                  child: AdminStatsCard(
                    title: 'Driver Earnings',
                    value: '\$0.00',
                    icon: Icons.account_balance_wallet,
                    iconColor: AdminTheme.primaryColor,
                  ),
                ),
                Expanded(
                  child: AdminStatsCard(
                    title: 'Platform Commission',
                    value: '\$0.00',
                    icon: Icons.trending_up,
                    iconColor: AdminTheme.infoColor,
                  ),
                ),
                Expanded(
                  child: AdminStatsCard(
                    title: 'Net Profit',
                    value: '\$0.00',
                    icon: Icons.account_balance,
                    iconColor: AdminTheme.warningColor,
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
                  label: 'Generate Report',
                  icon: Icons.description,
                  onPressed: () {
                    // TODO: Generate financial report
                  },
                  backgroundColor: AdminTheme.infoColor,
                ),
                const SizedBox(width: 8),
                AdminActionButton(
                  label: 'Pricing Settings',
                  icon: Icons.settings,
                  onPressed: () {
                    // TODO: Open pricing configuration
                  },
                  isOutlined: true,
                ),
                const SizedBox(width: 8),
                AdminActionButton(
                  label: 'Export',
                  icon: Icons.download,
                  onPressed: () {
                    // TODO: Export financial data
                  },
                  isOutlined: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Revenue chart and analysis (placeholder)
          Expanded(
            child: Card(
              margin: const EdgeInsets.all(16),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.show_chart,
                      size: 64,
                      color: AdminTheme.textSecondary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No financial data yet',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AdminTheme.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Revenue analytics and cost breakdown will appear here',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AdminTheme.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '🚧 Phase 7: Financial management & reporting coming soon',
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

