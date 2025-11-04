import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../../../data/providers/auth_providers.dart';
import '../../../../../data/providers/stripe_providers.dart';

/// Simple add card sheet using flutter_stripe CardField
/// Based on official flutter_stripe examples
/// Works on Web, iOS, and Android!
class SimpleAddCardSheet extends ConsumerStatefulWidget {
  final String userId;
  final VoidCallback onSuccess;

  const SimpleAddCardSheet({
    super.key,
    required this.userId,
    required this.onSuccess,
  });

  @override
  ConsumerState<SimpleAddCardSheet> createState() => _SimpleAddCardSheetState();
}

class _SimpleAddCardSheetState extends ConsumerState<SimpleAddCardSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cardController = CardEditController();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cardController.addListener(_update);
  }

  void _update() => setState(() {});

  @override
  void dispose() {
    _cardController.removeListener(_update);
    _cardController.dispose();
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
      child: SingleChildScrollView(
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
                const Text(
                  'Enter your card details below',
                  style: TextStyle(
                    color: Colors.white70,
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

                // Stripe CardField (works on web, iOS, Android!)
                // IMPORTANT: Web requires explicit width AND height!
                // Note: On web, CardField uses iframe so styling is limited
                Container(
                  height: 60,  // Explicit height
                  width: double.infinity,  // Explicit width
                  decoration: BoxDecoration(
                    color: Colors.white,  // White background for better visibility
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: CardField(
                    controller: _cardController,
                    style: const TextStyle(
                      color: Colors.black,  // Dark text on white background
                      fontSize: 16,
                    ),
                    cursorColor: Colors.black,
                    enablePostalCode: false,
                    countryCode: 'US',
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
                        onPressed: _isLoading || !_cardController.complete
                            ? null
                            : _handleAddCard,
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
      ),
    );
  }

  Future<void> _handleAddCard() async {
    if (!_formKey.currentState!.validate() || !_cardController.complete) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('\n💳 ===== ADDING PAYMENT METHOD =====');
      print('📝 Cardholder: ${_nameController.text.trim()}');
      
      final currentUser = ref.read(firebaseAuthUserProvider).value;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Step 1: Create payment method using flutter_stripe SDK
      // This works on web, iOS, and Android!
      print('🔒 Creating payment method with Stripe SDK...');
      
      final billingDetails = BillingDetails(
        name: _nameController.text.trim(),
        email: currentUser.email,
      );

      final paymentMethod = await Stripe.instance.createPaymentMethod(
        params: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: billingDetails,
          ),
        ),
      );

      print('✅ Payment method created: ${paymentMethod.id}');
      print('   Card: ${paymentMethod.card.brand} •••• ${paymentMethod.card.last4}');

      // Step 2: Attach to customer via Cloud Function
      print('\n📤 Attaching to customer via Cloud Function...');
      
      final response = await http.post(
        Uri.parse('https://us-central1-trippo-42089.cloudfunctions.net/attachPaymentMethod'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'userId': widget.userId,
          'paymentMethodId': paymentMethod.id,
          'setAsDefault': true,
        }),
      ).timeout(const Duration(seconds: 30));

      print('📥 Cloud Function response: ${response.statusCode}');

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to attach payment method');
      }

      print('✅ Payment method attached to customer!');
      print('💳 ===== COMPLETE =====\n');

      // Refresh payment methods
      widget.onSuccess();

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('❌ Error: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
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

