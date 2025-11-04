import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/enums/user_type.dart';
import '../../core/constants/firebase_constants.dart';
import '../models/user_model.dart';

/// Repository for authentication operations
class AuthRepository {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current Firebase Auth user
  firebase_auth.User? get currentFirebaseUser => _auth.currentUser;

  /// Stream of auth state changes
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  /// Register new user with email, password, and role
  Future<UserModel> registerWithEmailPassword({
    required String email,
    required String password,
    required String name,
    required UserType userType,
  }) async {
    try {
      // 1. Create Firebase Auth account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // 2. Update display name
      await userCredential.user!.updateDisplayName(name);

      // 3. Create user document in 'users' collection
      final userData = {
        FirebaseConstants.userEmail: email,
        FirebaseConstants.userName: name,
        FirebaseConstants.userType: userType.toFirestore(),
        FirebaseConstants.userPhoneNumber: '',
        FirebaseConstants.userCreatedAt: FieldValue.serverTimestamp(),
        FirebaseConstants.userLastLogin: FieldValue.serverTimestamp(),
        FirebaseConstants.userIsActive: true,
        FirebaseConstants.userFcmToken: '',
        FirebaseConstants.userProfileImageUrl: '',
      };

      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(uid)
          .set(userData);

      // 4. Create role-specific document
      if (userType == UserType.driver) {
        // Create empty driver document (will be completed in driver config screen)
        await _firestore
            .collection(FirebaseConstants.driversCollection)
            .doc(uid)
            .set({
          FirebaseConstants.driverCarName: '',
          FirebaseConstants.driverCarPlateNum: '',
          FirebaseConstants.driverCarType: '',
          FirebaseConstants.driverRate: FirebaseConstants.defaultDriverRate,
          FirebaseConstants.driverStatus: 'Offline',
          FirebaseConstants.driverRating: FirebaseConstants.defaultRating,
          FirebaseConstants.driverTotalRides: FirebaseConstants.defaultTotalRides,
          FirebaseConstants.driverEarnings: FirebaseConstants.defaultEarnings,
          FirebaseConstants.driverIsVerified: false,
        });
      } else {
        // Create user profile document
        await _firestore
            .collection(FirebaseConstants.userProfilesCollection)
            .doc(uid)
            .set({
          FirebaseConstants.profileHomeAddress: '',
          FirebaseConstants.profileWorkAddress: '',
          FirebaseConstants.profileFavoriteLocations: [],
          FirebaseConstants.profilePaymentMethods: [],
          FirebaseConstants.profilePreferences: {
            'notifications': true,
            'language': 'en',
            'theme': 'dark',
          },
          'totalRides': 0,
          'rating': FirebaseConstants.defaultRating,
        });
      }

      // 5. Return user model with current timestamps
      return UserModel(
        uid: uid,
        email: email,
        name: name,
        userType: userType,
        phoneNumber: '',
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        isActive: true,
        fcmToken: '',
        profileImageUrl: '',
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  /// Login with email and password
  Future<UserModel> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // Check if user document exists
      final userDoc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        // User authenticated but no Firestore document - create it
        print('⚠️ User document not found, creating...');
        final userData = {
          FirebaseConstants.userEmail: email,
          FirebaseConstants.userName: userCredential.user!.displayName ?? email.split('@')[0],
          FirebaseConstants.userType: 'user', // Default to regular user
          FirebaseConstants.userPhoneNumber: '',
          FirebaseConstants.userCreatedAt: FieldValue.serverTimestamp(),
          FirebaseConstants.userLastLogin: FieldValue.serverTimestamp(),
          FirebaseConstants.userIsActive: true,
          FirebaseConstants.userFcmToken: '',
          FirebaseConstants.userProfileImageUrl: '',
        };

        await _firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(uid)
            .set(userData);

        // Also create user profile
        await _firestore
            .collection(FirebaseConstants.userProfilesCollection)
            .doc(uid)
            .set({
          FirebaseConstants.profileHomeAddress: '',
          FirebaseConstants.profileWorkAddress: '',
          FirebaseConstants.profileFavoriteLocations: [],
          FirebaseConstants.profilePaymentMethods: [],
          FirebaseConstants.profilePreferences: {
            'notifications': true,
            'language': 'en',
            'theme': 'dark',
          },
          'totalRides': 0,
          'rating': FirebaseConstants.defaultRating,
        });

        print('✅ Created user document and profile');
      } else {
        // Update last login time only
        await _firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(uid)
            .update({
          FirebaseConstants.userLastLogin: FieldValue.serverTimestamp(),
        });
      }

      // Get user data
      final user = await getCurrentUser();
      if (user == null) {
        throw Exception('User data not found after creation');
      }

      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  /// Get current user data from Firestore
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(user.uid)
          .get();

      if (!doc.exists) return null;

      return UserModel.fromFirestore(doc.data()!, user.uid);
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  /// Check if user is driver
  Future<bool> isDriver() async {
    final user = await getCurrentUser();
    return user?.isDriver ?? false;
  }

  /// Check if user is regular user
  Future<bool> isRegularUser() async {
    final user = await getCurrentUser();
    return user?.isRegularUser ?? false;
  }
  
  /// Check if user is admin
  Future<bool> isAdmin() async {
    final user = await getCurrentUser();
    return user?.isAdmin ?? false;
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  /// Update user FCM token
  Future<void> updateFcmToken(String token) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(user.uid)
          .update({
        FirebaseConstants.userFcmToken: token,
      });
    } catch (e) {
      throw Exception('Failed to update FCM token: $e');
    }
  }

  /// Handle Firebase Auth exceptions
  String _handleAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication error: ${e.message}';
    }
  }
}

