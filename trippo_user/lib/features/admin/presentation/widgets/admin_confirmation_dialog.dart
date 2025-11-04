import 'package:flutter/material.dart';
import '../../../../core/theme/admin_theme.dart';

/// Reusable confirmation dialog for admin actions
class AdminConfirmationDialog extends StatefulWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final bool isDangerous;
  final bool requiresReason;
  final VoidCallback? onConfirm;
  final Future<void> Function(String)? onConfirmWithReason;

  const AdminConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.isDangerous = false,
    this.requiresReason = false,
    this.onConfirm,
    this.onConfirmWithReason,
  });

  @override
  State<AdminConfirmationDialog> createState() => _AdminConfirmationDialogState();
}

class _AdminConfirmationDialogState extends State<AdminConfirmationDialog> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    if (widget.requiresReason && _reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a reason'),
          backgroundColor: AdminTheme.warningColor,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      if (widget.requiresReason && widget.onConfirmWithReason != null) {
        await widget.onConfirmWithReason!(_reasonController.text.trim());
      } else if (widget.onConfirm != null) {
        widget.onConfirm!();
      }
      
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AdminTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final confirmColor = widget.isDangerous ? AdminTheme.dangerColor : AdminTheme.successColor;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            widget.isDangerous ? Icons.warning_amber_rounded : Icons.info_outline,
            color: confirmColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.message,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          
          if (widget.requiresReason) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (required)',
                hintText: 'Please provide a reason for this action',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              enabled: !_isProcessing,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(false),
          child: Text(widget.cancelText),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _handleConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: Colors.white,
          ),
          child: _isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(widget.confirmText),
        ),
      ],
    );
  }
}

/// Helper function to show confirmation dialog
Future<bool> showAdminConfirmation({
  required BuildContext context,
  required String title,
  required String message,
  String confirmText = 'Confirm',
  String cancelText = 'Cancel',
  bool isDangerous = false,
  bool requiresReason = false,
  VoidCallback? onConfirm,
  Future<void> Function(String)? onConfirmWithReason,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AdminConfirmationDialog(
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      isDangerous: isDangerous,
      requiresReason: requiresReason,
      onConfirm: onConfirm,
      onConfirmWithReason: onConfirmWithReason,
    ),
  );
  return result ?? false;
}

