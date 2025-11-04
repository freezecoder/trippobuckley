import 'package:flutter/material.dart';
import '../../../../core/theme/admin_theme.dart';

/// Reusable action button widget for admin screens
class AdminActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isOutlined;

  const AdminActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: foregroundColor ?? AdminTheme.primaryColor,
          side: BorderSide(
            color: foregroundColor ?? AdminTheme.primaryColor,
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AdminTheme.primaryColor,
        foregroundColor: foregroundColor ?? Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

/// Compact icon button for table rows and quick actions
class AdminIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  final String? tooltip;

  const AdminIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      color: color ?? AdminTheme.primaryColor,
      tooltip: tooltip,
      splashRadius: 20,
    );
  }
}

