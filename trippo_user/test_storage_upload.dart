/// Test script to verify Firebase Storage upload functionality
/// Run this to test profile picture upload without using the full app
/// 
/// Usage: dart run test_storage_upload.dart

import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'lib/firebase_options.dart';

void main() async {
  print('🧪 Testing Firebase Storage Upload...\n');
  
  try {
    // Initialize Firebase
    print('1️⃣ Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('   ✅ Firebase initialized\n');
    
    // Check if user is logged in
    print('2️⃣ Checking authentication...');
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    
    if (user == null) {
      print('   ⚠️  No user logged in');
      print('   Please login to the app first, then run this test again\n');
      exit(1);
    }
    
    print('   ✅ User authenticated: ${user.email}');
    print('   UID: ${user.uid}\n');
    
    // Test Storage connection
    print('3️⃣ Testing Storage connection...');
    final storage = FirebaseStorage.instance;
    final bucket = storage.bucket;
    print('   ✅ Connected to bucket: $bucket\n');
    
    // List existing files (if any)
    print('4️⃣ Checking existing files...');
    try {
      final listResult = await storage.ref('profile_pictures').listAll();
      if (listResult.prefixes.isEmpty) {
        print('   📁 No profile pictures uploaded yet\n');
      } else {
        print('   📁 Found ${listResult.prefixes.length} user folders:');
        for (var prefix in listResult.prefixes) {
          print('      - ${prefix.name}');
          final files = await prefix.listAll();
          for (var file in files.items) {
            print('        └─ ${file.name}');
          }
        }
        print('');
      }
    } catch (e) {
      print('   ℹ️  Could not list files (normal if empty): $e\n');
    }
    
    // Verify rules allow upload for current user
    print('5️⃣ Testing upload permissions...');
    final testRef = storage.ref('profile_pictures/${user.uid}/test_connection.txt');
    
    try {
      // Try to upload a tiny test file
      await testRef.putString('Test upload from CLI');
      print('   ✅ Upload permission verified\n');
      
      // Get download URL
      print('6️⃣ Testing download URL generation...');
      final downloadUrl = await testRef.getDownloadURL();
      print('   ✅ Download URL generated:');
      print('   ${downloadUrl.substring(0, 60)}...\n');
      
      // Clean up test file
      print('7️⃣ Cleaning up test file...');
      await testRef.delete();
      print('   ✅ Test file deleted\n');
      
      // Summary
      print('╔════════════════════════════════════════╗');
      print('║  ✅ ALL STORAGE TESTS PASSED!         ║');
      print('╚════════════════════════════════════════╝\n');
      print('Firebase Storage is ready for profile pictures! 🎉\n');
      print('Next steps:');
      print('1. Run the app: flutter run');
      print('2. Go to Profile tab');
      print('3. Tap profile picture to upload');
      print('4. Choose camera or gallery');
      print('5. Upload will work! 📸\n');
      
    } catch (e) {
      print('   ❌ Upload failed: $e');
      print('   This might mean:');
      print('   - Storage rules not deployed yet');
      print('   - Permission issue');
      print('   - Network problem\n');
      exit(1);
    }
    
  } catch (e) {
    print('❌ Error: $e\n');
    exit(1);
  }
}

