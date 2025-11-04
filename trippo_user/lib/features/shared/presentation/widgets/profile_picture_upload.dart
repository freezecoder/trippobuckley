import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../data/providers/storage_providers.dart';
import '../../../../data/providers/auth_providers.dart';
import '../../../../data/providers/user_providers.dart';
import '../../../../Container/utils/error_notification.dart';

/// Widget for displaying and uploading profile pictures
class ProfilePictureUpload extends ConsumerStatefulWidget {
  final String? currentImageUrl;
  final bool isDriver;

  const ProfilePictureUpload({
    super.key,
    this.currentImageUrl,
    this.isDriver = false,
  });

  @override
  ConsumerState<ProfilePictureUpload> createState() =>
      _ProfilePictureUploadState();
}

class _ProfilePictureUploadState extends ConsumerState<ProfilePictureUpload> {
  XFile? _pickedImage;
  Uint8List? _pickedImageBytes; // For web platform

  /// Show options dialog for image selection
  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose Profile Picture',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // Only show camera option on mobile platforms
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('Camera', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: Text(
                kIsWeb ? 'Choose File' : 'Gallery',
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (widget.currentImageUrl != null || _pickedImage != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Photo', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _removeImage();
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Pick image from source
  Future<void> _pickImage(ImageSource source) async {
    try {
      final storageRepo = ref.read(storageRepositoryProvider);
      final XFile? image;

      if (source == ImageSource.camera) {
        image = await storageRepo.pickImageFromCamera();
      } else {
        image = await storageRepo.pickImageFromGallery();
      }

      if (image != null) {
        // Read bytes immediately for preview (works on all platforms)
        final bytes = await image.readAsBytes();
        
        setState(() {
          _pickedImage = image;
          _pickedImageBytes = bytes;
        });

        // Automatically upload
        await _uploadImage();
      }
    } catch (e) {
      if (mounted) {
        ErrorNotification().showError(
          context,
          "Failed to pick image: ${e.toString()}",
        );
      }
    }
  }

  /// Upload image to Firebase Storage
  Future<void> _uploadImage() async {
    if (_pickedImage == null) return;

    try {
      ref.read(profilePictureUploadingProvider.notifier).state = true;

      final currentUser = await ref.read(currentUserProvider.future);
      if (currentUser == null) {
        throw Exception('User not found');
      }

      // Upload to Firebase Storage
      final storageRepo = ref.read(storageRepositoryProvider);
      final downloadUrl = await storageRepo.uploadProfilePicture(
        userId: currentUser.uid,
        imageFile: _pickedImage!,
      );

      // Update user document with image URL
      final userRepo = ref.read(userRepositoryProvider);
      await userRepo.updateProfilePictureUrl(
        userId: currentUser.uid,
        imageUrl: downloadUrl,
      );

      ref.read(profilePictureUploadingProvider.notifier).state = false;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ref.read(profilePictureUploadingProvider.notifier).state = false;
      if (mounted) {
        ErrorNotification().showError(
          context,
          "Failed to upload picture: ${e.toString()}",
        );
      }
    }
  }

  /// Remove profile picture
  Future<void> _removeImage() async {
    try {
      ref.read(profilePictureUploadingProvider.notifier).state = true;

      final currentUser = await ref.read(currentUserProvider.future);
      if (currentUser == null) {
        throw Exception('User not found');
      }

      // Delete from Storage
      final storageRepo = ref.read(storageRepositoryProvider);
      await storageRepo.deleteProfilePicture(currentUser.uid);

      // Update user document
      final userRepo = ref.read(userRepositoryProvider);
      await userRepo.updateProfilePictureUrl(
        userId: currentUser.uid,
        imageUrl: '',
      );

      setState(() {
        _pickedImage = null;
        _pickedImageBytes = null;
      });

      ref.read(profilePictureUploadingProvider.notifier).state = false;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture removed'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ref.read(profilePictureUploadingProvider.notifier).state = false;
      if (mounted) {
        ErrorNotification().showError(
          context,
          "Failed to remove picture: ${e.toString()}",
        );
      }
    }
  }

  /// Get the appropriate image provider based on platform
  ImageProvider? _getImageProvider(String? imageUrl) {
    if (_pickedImage != null && _pickedImageBytes != null) {
      // Show picked image using bytes (works on all platforms)
      return MemoryImage(_pickedImageBytes!);
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      // Show existing image from network
      return NetworkImage(imageUrl);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isUploading = ref.watch(profilePictureUploadingProvider);
    final currentUser = ref.watch(currentUserStreamProvider).value;
    final imageUrl = currentUser?.profileImageUrl;

    return GestureDetector(
      onTap: isUploading ? null : _showImageSourceDialog,
      child: Stack(
        children: [
          // Profile Picture Circle
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey[800],
            backgroundImage: _getImageProvider(imageUrl),
            child: (imageUrl == null || imageUrl.isEmpty) && _pickedImage == null
                ? Text(
                    currentUser?.name.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      fontSize: 48,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),

          // Upload/Edit Indicator
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.black,
                  width: 2,
                ),
              ),
              child: isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 16,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

