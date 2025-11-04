import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Repository for Firebase Storage operations
class StorageRepository {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  /// Pick image from gallery
  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  /// Pick image from camera
  Future<XFile?> pickImageFromCamera() async {
    try {
      // Camera is not available on web
      if (kIsWeb) {
        throw Exception('Camera is not available on web. Please use gallery.');
      }
      
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      throw Exception('Failed to take photo: $e');
    }
  }

  /// Upload profile picture to Firebase Storage
  /// Works on both mobile and web platforms
  Future<String> uploadProfilePicture({
    required String userId,
    required XFile imageFile,
  }) async {
    try {
      // Get file extension
      final fileName = imageFile.name;
      final extension = fileName.split('.').last;
      
      // Create reference to storage location
      // Pattern: profile_pictures/{userId}/profile.{extension}
      final storageRef = _storage.ref().child('profile_pictures/$userId/profile.$extension');

      // Upload file with metadata
      final metadata = SettableMetadata(
        contentType: 'image/$extension',
        customMetadata: {
          'uploadedBy': userId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // Use putData for all platforms (works everywhere)
      // XFile.readAsBytes() works on both web and mobile
      final bytes = await imageFile.readAsBytes();
      final uploadTask = await storageRef.putData(bytes, metadata);

      // Get download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload profile picture: $e');
    }
  }

  /// Delete profile picture from Firebase Storage
  Future<void> deleteProfilePicture(String userId) async {
    try {
      // Try to delete common image formats
      final extensions = ['jpg', 'jpeg', 'png', 'webp'];
      
      for (final ext in extensions) {
        try {
          final storageRef = _storage.ref().child('profile_pictures/$userId/profile.$ext');
          await storageRef.delete();
        } catch (e) {
          // Continue if this format doesn't exist
          continue;
        }
      }
    } catch (e) {
      // Ignore error if file doesn't exist
      if (!e.toString().contains('object-not-found')) {
        throw Exception('Failed to delete profile picture: $e');
      }
    }
  }

  /// Upload vehicle image (optional feature for future)
  /// Works on both mobile and web platforms
  Future<String> uploadVehicleImage({
    required String driverId,
    required XFile imageFile,
  }) async {
    try {
      final fileName = imageFile.name;
      final extension = fileName.split('.').last;
      
      final storageRef = _storage.ref().child('vehicle_images/$driverId/vehicle.$extension');
      
      final metadata = SettableMetadata(
        contentType: 'image/$extension',
        customMetadata: {
          'uploadedBy': driverId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );
      
      // Use putData for all platforms (works everywhere)
      // XFile.readAsBytes() works on both web and mobile
      final bytes = await imageFile.readAsBytes();
      final uploadTask = await storageRef.putData(bytes, metadata);
      
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload vehicle image: $e');
    }
  }

  /// Delete vehicle image
  Future<void> deleteVehicleImage(String driverId) async {
    try {
      final extensions = ['jpg', 'jpeg', 'png', 'webp'];
      
      for (final ext in extensions) {
        try {
          final storageRef = _storage.ref().child('vehicle_images/$driverId/vehicle.$ext');
          await storageRef.delete();
        } catch (e) {
          continue;
        }
      }
    } catch (e) {
      if (!e.toString().contains('object-not-found')) {
        throw Exception('Failed to delete vehicle image: $e');
      }
    }
  }
}

