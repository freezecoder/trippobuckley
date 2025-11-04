import 'package:flutter/material.dart';
import '../../../../core/theme/admin_theme.dart';
import '../../../../data/models/payment_method_model.dart';

/// Dialog for admin to view and manage user payment methods
class PaymentMethodsDialog extends StatelessWidget {
  final String userId;
  final String userName;
  final List<PaymentMethodModel> paymentMethods;
  final Function(PaymentMethodModel)? onRemove;
  final Function(PaymentMethodModel)? onSetDefault;
  final VoidCallback? onAddNew;

  const PaymentMethodsDialog({
    super.key,
    required this.userId,
    required this.userName,
    required this.paymentMethods,
    this.onRemove,
    this.onSetDefault,
    this.onAddNew,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.credit_card, color: AdminTheme.primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Payment Methods - $userName',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            
            const Divider(height: 32),
            
            // Payment methods list
            if (paymentMethods.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.credit_card_off,
                        size: 64,
                        color: AdminTheme.textSecondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No payment methods',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AdminTheme.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'User hasn\'t added any payment methods yet',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AdminTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: paymentMethods.length,
                  itemBuilder: (context, index) {
                    final method = paymentMethods[index];
                    return _buildPaymentMethodCard(context, method);
                  },
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Add new button (placeholder)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAddNew ?? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Stripe integration coming soon'),
                      backgroundColor: AdminTheme.infoColor,
                    ),
                  );
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Payment Method'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Info note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AdminTheme.warningColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AdminTheme.warningColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Stripe integration will be added later. For now, this shows existing payment methods.',
                      style: TextStyle(
                        color: AdminTheme.warningColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(BuildContext context, PaymentMethodModel method) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Card icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AdminTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getCardIcon(method.brand),
                color: AdminTheme.primaryColor,
                size: 32,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Card details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        method.fullDisplayString,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (method.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AdminTheme.successColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'DEFAULT',
                            style: TextStyle(
                              color: AdminTheme.successColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Exp: ${method.expiryDisplayString}',
                    style: const TextStyle(
                      color: AdminTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  if (method.cardholderName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      method.cardholderName,
                      style: const TextStyle(
                        color: AdminTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!method.isDefault && onSetDefault != null)
                  TextButton(
                    onPressed: () => onSetDefault!(method),
                    child: const Text('Set Default'),
                  ),
                if (onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => onRemove!(method),
                    color: AdminTheme.dangerColor,
                    tooltip: 'Remove',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCardIcon(String brand) {
    switch (brand.toLowerCase()) {
      case 'visa':
        return Icons.credit_card;
      case 'mastercard':
        return Icons.credit_card;
      case 'amex':
      case 'american express':
        return Icons.credit_card;
      default:
        return Icons.credit_card;
    }
  }
}

