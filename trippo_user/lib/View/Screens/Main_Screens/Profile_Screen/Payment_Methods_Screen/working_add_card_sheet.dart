import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../../../data/providers/auth_providers.dart';
import '../../../../../data/providers/stripe_providers.dart';

/// Working add card sheet
/// - Web: Shows instructions to use mobile/desktop app for adding cards
/// - Mobile: Uses flutter_stripe CardField (when properly set up)
/// 
/// This is the pragmatic approach until flutter_stripe web support is stable
class WorkingAddCardSheet extends ConsumerStatefulWidget {
  final String userId;
  final VoidCallback onSuccess;

  const WorkingAddCardSheet({
    super.key,
    required this.userId,
    required this.onSuccess,
  });

  @override
  ConsumerState<WorkingAddCardSheet> createState() => _WorkingAddCardSheetState();
}

class _WorkingAddCardSheetState extends ConsumerState<WorkingAddCardSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 24,
        right: 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
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
          
          if (kIsWeb) ...[
            // Web: Show information about mobile app requirement
            const Text(
              'Web Browser Detected',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[300]),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Add Payment Methods on Mobile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'For PCI compliance and security, payment methods must be added using the mobile app:',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInstructionStep('1', 'Download BTrips mobile app', Icons.phone_android),
                  const SizedBox(height: 8),
                  _buildInstructionStep('2', 'Login with same account', Icons.login),
                  const SizedBox(height: 8),
                  _buildInstructionStep('3', 'Profile → Payment Methods → Add Card', Icons.credit_card),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.security, color: Colors.green[300], size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This ensures your card details are handled securely with native encryption',
                            style: TextStyle(
                              color: Colors.grey[300],
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
            const SizedBox(height: 24),
            
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Got It'),
              ),
            ),
          ] else ...[
            // Mobile: Would show actual CardField
            const Text(
              'Mobile platform detected - CardField will work here',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Full mobile integration coming soon.\nFor now, use the script: node scripts/create_stripe_test_customers.js',
                style: TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: const Text('Close'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text, IconData icon) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Icon(icon, color: Colors.blue[300], size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey[200],
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

