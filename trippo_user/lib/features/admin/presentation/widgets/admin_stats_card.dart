import 'package:flutter/material.dart';
import '../../../../core/theme/admin_theme.dart';

/// Reusable statistics card widget for admin dashboard
class AdminStatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final String? subtitle;
  final VoidCallback? onTap;

  const AdminStatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon and value row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (iconColor ?? AdminTheme.primaryColor)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor ?? AdminTheme.primaryColor,
                      size: 28,
                    ),
                  ),
                  
                  // Value
                  Text(
                    value,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AdminTheme.textPrimary,
                        ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Title
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AdminTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              
              // Optional subtitle
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AdminTheme.successColor,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

