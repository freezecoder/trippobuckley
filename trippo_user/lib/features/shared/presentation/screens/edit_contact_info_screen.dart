import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../data/providers/auth_providers.dart';
import '../../../../data/providers/user_providers.dart';
import '../../../../Container/utils/error_notification.dart';

/// Provider for loading state
final editContactInfoLoadingProvider = StateProvider.autoDispose<bool>((ref) => false);

/// Screen for editing contact information (phone and address)
/// Works for both users and drivers
class EditContactInfoScreen extends ConsumerStatefulWidget {
  final bool isDriver;

  const EditContactInfoScreen({
    super.key,
    this.isDriver = false,
  });

  @override
  ConsumerState<EditContactInfoScreen> createState() =>
      _EditContactInfoScreenState();
}

class _EditContactInfoScreenState
    extends ConsumerState<EditContactInfoScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  /// Load current phone and address data
  Future<void> _loadCurrentData() async {
    try {
      final currentUser = await ref.read(currentUserProvider.future);
      if (currentUser == null) return;

      // Load phone from user document
      phoneController.text = currentUser.phoneNumber;

      // Load address based on role
      if (widget.isDriver) {
        // For drivers, we'll store address in the users collection as a custom field
        // or we can add it to drivers collection
        // For now, leaving empty - can be enhanced
      } else {
        final userProfile = await ref.read(userProfileProvider.future);
        if (userProfile != null) {
          addressController.text = userProfile.homeAddress;
        }
      }
    } catch (e) {
      debugPrint('Error loading contact info: $e');
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  /// Validate phone number
  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Phone is optional
    }
    
    final phoneRegex = RegExp(AppConstants.phoneRegex);
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  /// Save contact information
  Future<void> _saveContactInfo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      ref.read(editContactInfoLoadingProvider.notifier).state = true;

      final currentUser = await ref.read(currentUserProvider.future);
      if (currentUser == null) {
        throw Exception('User not found');
      }

      final userRepo = ref.read(userRepositoryProvider);

      // Update phone number in users collection
      await userRepo.updateUserProfile(
        userId: currentUser.uid,
        phoneNumber: phoneController.text.trim(),
      );

      // Update address based on role
      if (!widget.isDriver) {
        // For regular users, save to userProfiles
        await userRepo.updateAddresses(
          userId: currentUser.uid,
          homeAddress: addressController.text.trim(),
        );
      }
      // For drivers, address could be saved to drivers collection if needed
      // Currently drivers don't have address field, but can be added

      ref.read(editContactInfoLoadingProvider.notifier).state = false;

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppConstants.profileUpdatedMessage),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate back
        Navigator.of(context).pop();
      }
    } catch (e) {
      ref.read(editContactInfoLoadingProvider.notifier).state = false;
      if (mounted) {
        ErrorNotification().showError(
          context,
          "Failed to update contact info: ${e.toString()}",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(editContactInfoLoadingProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Edit Contact Info'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info text
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Update your contact information to help ${widget.isDriver ? "users" : "drivers"} reach you',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),

                // Phone Number Field
                Text(
                  'Phone Number',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '+1 (555) 123-4567',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: Colors.grey[900],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[700]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[700]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                    prefixIcon: const Icon(Icons.phone, color: Colors.blue),
                  ),
                  validator: _validatePhone,
                ),

                const SizedBox(height: 24),

                // Address Field (for users only currently)
                if (!widget.isDriver) ...[
                  Text(
                    'Home Address',
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: addressController,
                    keyboardType: TextInputType.streetAddress,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: '123 Main St, City, State, ZIP',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[700]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[700]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.blue),
                      ),
                      prefixIcon: const Icon(Icons.home, color: Colors.blue),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _saveContactInfo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      isLoading ? 'Saving...' : 'Save Changes',
                      style:
                          const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

