import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:btrips_unified/core/utils/delivery_helpers.dart';

/// Widget to display the delivery verification code
class VerificationCodeDisplay extends StatelessWidget {
  final String verificationCode;
  final bool showCopyButton;

  const VerificationCodeDisplay({
    super.key,
    required this.verificationCode,
    this.showCopyButton = true,
  });

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: verificationCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code copied to clipboard'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[700]!, Colors.deepOrange[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.verified_user,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Verification Code',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Code display with spacing
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DeliveryHelpers.formatVerificationCode(verificationCode),
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                    fontFamily: 'monospace',
                  ),
                ),
                if (showCopyButton) ...[
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: () => _copyToClipboard(context),
                    icon: const Icon(
                      Icons.copy,
                      color: Colors.orange,
                      size: 20,
                    ),
                    tooltip: 'Copy code',
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Instructions
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Share this code with the store staff when your driver arrives',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

