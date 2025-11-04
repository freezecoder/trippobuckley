import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:btrips_unified/data/providers/stripe_providers.dart';
import 'package:btrips_unified/data/models/payment_method_model.dart';
import 'package:btrips_unified/data/providers/auth_providers.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe_sdk;
import 'simple_add_card_sheet.dart';

class PaymentMethodsScreen extends ConsumerStatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  ConsumerState<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends ConsumerState<PaymentMethodsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final paymentMethodsAsync = ref.watch(paymentMethodsProvider);
    final userAsync = ref.watch(firebaseAuthUserProvider);
    
    // Extract user from AsyncValue (StreamProvider returns AsyncValue)
    final user = userAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          if (paymentMethodsAsync.hasValue && paymentMethodsAsync.value!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.invalidate(paymentMethodsProvider);
              },
            ),
        ],
      ),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: paymentMethodsAsync.when(
          data: (paymentMethods) => Column(
            children: [
              if (paymentMethods.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: paymentMethods.length,
                    itemBuilder: (context, index) {
                      final method = paymentMethods[index];
                      return _buildPaymentCard(method);
                    },
                  ),
                )
              else
                Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.credit_card,
                        size: 64,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No payment methods',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add a payment method to get started',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Add Payment Method Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading || user == null
                        ? null
                        : () => _showAddPaymentSheet(context, user.uid),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add),
                    label: Text(_isLoading ? 'Processing...' : 'Add Payment Method'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.blue),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error loading payment methods',
                  style: TextStyle(color: Colors.grey[400], fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(paymentMethodsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentCard(PaymentMethodModel method) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: method.isDefault ? Colors.blue : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getCardIcon(method.brand),
            color: Colors.blue,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method.fullDisplayString,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Expires ${method.expiryDisplayString}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
                if (method.isDefault)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Default',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (method.isExpired)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Expired',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: Colors.grey[900],
            onSelected: (value) {
              if (value == 'default' && !method.isDefault) {
                _setDefaultPaymentMethod(method);
              } else if (value == 'delete') {
                _confirmDeletePaymentMethod(method);
              }
            },
            itemBuilder: (context) => [
              if (!method.isDefault)
                const PopupMenuItem(
                  value: 'default',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Set as default', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Remove', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Show Stripe card input sheet
  Future<void> _showAddPaymentSheet(BuildContext context, String userId) async {
    setState(() => _isLoading = true);

    try {
      final stripeRepo = ref.read(stripeRepositoryProvider);
      final currentUser = ref.read(firebaseAuthUserProvider).value;

      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Check if customer exists, create if not
      final customerExists = await stripeRepo.customerExists(userId);
      if (!customerExists) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Creating payment account...'),
              duration: Duration(seconds: 2),
            ),
          );
        }

        // Automatically create customer via Cloud Function
        try {
          await stripeRepo.createCustomer(
            userId: userId,
            email: currentUser.email ?? '',
            name: currentUser.displayName ?? currentUser.email ?? 'User',
          );
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Payment account created successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to create payment account: ${e.toString()}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
          return;
        }
      }

      // Show add card sheet using flutter_stripe CardField
      // Works on web, iOS, Android with flutter_stripe_web package!
      final result = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => SimpleAddCardSheet(
          userId: userId,
          onSuccess: () {
            ref.invalidate(paymentMethodsProvider);
          },
        ),
      );

      if (result == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Payment method added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Set payment method as default
  Future<void> _setDefaultPaymentMethod(PaymentMethodModel method) async {
    final currentUser = ref.read(firebaseAuthUserProvider).value;
    if (currentUser == null) return;

    try {
      final stripeRepo = ref.read(stripeRepositoryProvider);
      await stripeRepo.setDefaultPaymentMethod(
        userId: currentUser.uid,
        paymentMethodId: method.id,
      );

      ref.invalidate(paymentMethodsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${method.fullDisplayString} set as default'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Confirm and delete payment method
  Future<void> _confirmDeletePaymentMethod(PaymentMethodModel method) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Remove Payment Method', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to remove ${method.fullDisplayString}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deletePaymentMethod(method);
    }
  }

  /// Delete payment method
  Future<void> _deletePaymentMethod(PaymentMethodModel method) async {
    final currentUser = ref.read(firebaseAuthUserProvider).value;
    if (currentUser == null) return;

    try {
      final stripeRepo = ref.read(stripeRepositoryProvider);
      await stripeRepo.removePaymentMethod(
        userId: currentUser.uid,
        paymentMethodId: method.id,
      );

      ref.invalidate(paymentMethodsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Payment method removed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Get card brand icon
  IconData _getCardIcon(String brand) {
    final brandLower = brand.toLowerCase();
    if (brandLower.contains('visa')) {
      return Icons.credit_card;
    } else if (brandLower.contains('mastercard')) {
      return Icons.credit_card;
    } else if (brandLower.contains('amex') || brandLower.contains('american')) {
      return Icons.credit_card;
    } else if (brandLower.contains('discover')) {
      return Icons.credit_card;
    }
    return Icons.payment;
  }
}

/// Bottom sheet for adding payment method
class _AddPaymentMethodSheet extends ConsumerStatefulWidget {
  final String userId;
  final VoidCallback onSuccess;

  const _AddPaymentMethodSheet({
    required this.userId,
    required this.onSuccess,
  });

  @override
  ConsumerState<_AddPaymentMethodSheet> createState() => _AddPaymentMethodSheetState();
}

class _AddPaymentMethodSheetState extends ConsumerState<_AddPaymentMethodSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _cardComplete = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                'Add Payment Method',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your card details below',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),

              // Cardholder name
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Cardholder Name',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[700]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.blue),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[900],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter cardholder name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Stripe Card Field
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: stripe_sdk.CardField(
                  onCardChanged: (card) {
                    setState(() {
                      _cardComplete = card?.complete ?? false;
                    });
                  },
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Card number',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Info box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, color: Colors.blue[300], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your card details are securely processed by Stripe',
                        style: TextStyle(
                          color: Colors.blue[300],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.grey[700]!),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading || !_cardComplete
                          ? null
                          : _handleAddPaymentMethod,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Add Card'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleAddPaymentMethod() async {
    if (!_formKey.currentState!.validate() || !_cardComplete) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final stripeRepo = ref.read(stripeRepositoryProvider);
      final currentUser = ref.read(firebaseAuthUserProvider).value;

      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Create payment method with Stripe
      await stripeRepo.addPaymentMethod(
        userId: widget.userId,
        billingDetails: stripe_sdk.BillingDetails(
          name: _nameController.text.trim(),
          email: currentUser.email,
        ),
        setAsDefault: true, // Set as default if it's the first payment method
      );

      widget.onSuccess();

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

