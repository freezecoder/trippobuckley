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

  /// Validate phone number (REQUIRED)
  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required for text updates';
    }
    
    final phoneRegex = RegExp(AppConstants.phoneRegex);
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number (e.g., +1 555-123-4567)';
    }
    return null;
  }

  /// Save contact information
  Future<void> _saveContactInfo() async {
    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ Form validation failed');
      return;
    }

    try {
      ref.read(editContactInfoLoadingProvider.notifier).state = true;

      final currentUser = await ref.read(currentUserProvider.future);
      if (currentUser == null) {
        throw Exception('User not found');
      }

      final phoneNumber = phoneController.text.trim();
      final homeAddress = addressController.text.trim();
      
      debugPrint('📞 Saving contact info for user: ${currentUser.uid}');
      debugPrint('   Phone: $phoneNumber');
      debugPrint('   Address: $homeAddress');

      final userRepo = ref.read(userRepositoryProvider);

      // Update phone number in users collection
      debugPrint('💾 Updating phone number in Firestore...');
      await userRepo.updateUserProfile(
        userId: currentUser.uid,
        phoneNumber: phoneNumber,
      );
      debugPrint('✅ Phone number updated in Firestore');

      // Update address based on role
      if (!widget.isDriver) {
        debugPrint('💾 Updating home address in userProfiles...');
        // For regular users, save to userProfiles
        await userRepo.updateAddresses(
          userId: currentUser.uid,
          homeAddress: homeAddress,
        );
        debugPrint('✅ Home address updated in userProfiles');
      }
      // For drivers, address could be saved to drivers collection if needed
      // Currently drivers don't have address field, but can be added

      // Invalidate providers to refresh data
      debugPrint('🔄 Invalidating providers to refresh...');
      ref.invalidate(currentUserProvider);
      if (!widget.isDriver) {
        ref.invalidate(userProfileProvider);
      }

      ref.read(editContactInfoLoadingProvider.notifier).state = false;

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Contact information updated successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate back
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('❌ Error saving contact info: $e');
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
                // Info text - Contact info importance
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
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
                
                const SizedBox(height: 16),

                // Phone number requirement reminder
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.phone_android, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Phone Number Required',
                            style: TextStyle(
                              color: Colors.orange[300],
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your phone number is required to receive important text updates about your rides, including:',
                        style: TextStyle(
                          color: Colors.orange[200],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...['Driver assignment notifications', 'Ride status updates', 'Arrival notifications', 'Emergency contact']
                          .map((item) => Padding(
                                padding: const EdgeInsets.only(left: 8, top: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle, 
                                      color: Colors.orange[300], size: 14),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item,
                                        style: TextStyle(
                                          color: Colors.orange[100],
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),

                // Phone Number Field
                Row(
                  children: [
                    Text(
                      'Phone Number',
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red),
                      ),
                      child: const Text(
                        'REQUIRED',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '+1 (555) 123-4567',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    helperText: 'Required for ride notifications and driver contact',
                    helperStyle: TextStyle(color: Colors.orange[300], fontSize: 11),
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
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
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

