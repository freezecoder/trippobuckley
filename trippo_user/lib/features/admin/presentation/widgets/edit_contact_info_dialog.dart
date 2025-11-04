import 'package:flutter/material.dart';
import '../../../../core/theme/admin_theme.dart';

/// Dialog for admin to edit user contact information
class EditContactInfoDialog extends StatefulWidget {
  final String userId;
  final String userName;
  final String currentPhone;
  final String currentAddress;
  final Future<void> Function(String phone, String address) onSave;

  const EditContactInfoDialog({
    super.key,
    required this.userId,
    required this.userName,
    required this.currentPhone,
    required this.currentAddress,
    required this.onSave,
  });

  @override
  State<EditContactInfoDialog> createState() => _EditContactInfoDialogState();
}

class _EditContactInfoDialogState extends State<EditContactInfoDialog> {
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.currentPhone);
    _addressController = TextEditingController(text: widget.currentAddress);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();

    setState(() => _isProcessing = true);

    try {
      await widget.onSave(phone, address);
      
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
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.edit, color: AdminTheme.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Edit Contact Info - ${widget.userName}'),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Phone number field
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '+1-555-123-4567',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              enabled: !_isProcessing,
            ),
            
            const SizedBox(height: 16),
            
            // Address field
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Home Address',
                hintText: '123 Main St, City, State, ZIP',
                prefixIcon: Icon(Icons.home),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              enabled: !_isProcessing,
            ),
            
            const SizedBox(height: 16),
            
            // Info message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AdminTheme.infoColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AdminTheme.infoColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will update both users and userProfiles collections',
                      style: TextStyle(
                        color: AdminTheme.infoColor,
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
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminTheme.primaryColor,
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
              : const Text('Save Changes'),
        ),
      ],
    );
  }
}

