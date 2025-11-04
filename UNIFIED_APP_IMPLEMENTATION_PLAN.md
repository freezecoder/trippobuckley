# Unified BTrips App Implementation Plan
## Merging User and Driver Apps into Single Application

**Goal**: Create a single Flutter application that dynamically shows Driver UI or User UI based on the authenticated user's role.

**Benefits**:
- ✅ Single codebase to maintain
- ✅ Shared dependencies and utilities
- ✅ Single build and deployment process
- ✅ Easier feature updates across both user types
- ✅ Reduced code duplication
- ✅ Simplified Firebase configuration

---

## Table of Contents

1. [High-Level Architecture](#1-high-level-architecture)
2. [Firebase Schema Design](#2-firebase-schema-design)
3. [Project Structure](#3-project-structure)
4. [Authentication & Role Detection](#4-authentication--role-detection)
5. [Routing Strategy](#5-routing-strategy)
6. [State Management](#6-state-management)
7. [Implementation Steps](#7-implementation-steps)
8. [Code Organization Guidelines](#8-code-organization-guidelines)
9. [Migration Checklist](#9-migration-checklist)
10. [Testing Strategy](#10-testing-strategy)
11. [Deployment Considerations](#11-deployment-considerations)

---

## 1. High-Level Architecture

### Concept Overview

```
                    ┌─────────────────────────┐
                    │    Unified BTrips App   │
                    └───────────┬─────────────┘
                                │
                    ┌───────────▼─────────────┐
                    │   Authentication        │
                    │   (Firebase Auth)       │
                    └───────────┬─────────────┘
                                │
                    ┌───────────▼─────────────┐
                    │   Fetch User Profile    │
                    │   Check "userType"      │
                    └───────────┬─────────────┘
                                │
                ┌───────────────┴───────────────┐
                │                               │
       ┌────────▼─────────┐          ┌─────────▼────────┐
       │ userType: "user" │          │ userType: "driver"│
       └────────┬─────────┘          └─────────┬────────┘
                │                               │
       ┌────────▼─────────┐          ┌─────────▼────────┐
       │   User Home      │          │  Driver Home     │
       │   (Ride Booking) │          │  (Accept Rides)  │
       └──────────────────┘          └──────────────────┘
                │                               │
       ┌────────▼─────────┐          ┌─────────▼────────┐
       │ User Navigation  │          │ Driver Navigation│
       │ • Ride           │          │ • Home           │
       │ • Profile        │          │ • Payments       │
       └──────────────────┘          │ • History        │
                                     │ • Profile        │
                                     └──────────────────┘
```

### Key Architectural Principles

1. **Single Entry Point**: One main.dart for the entire app
2. **Role-Based Routing**: Route to different screens based on user role
3. **Shared Components**: Maximize code reuse (auth, maps, themes)
4. **Clear Separation**: Keep user-specific and driver-specific code isolated
5. **Feature Flags**: Use role checks for conditional feature access
6. **Clean Abstractions**: Abstract common functionality (location, notifications)

---

## 2. Firebase Schema Design

### 2.1 New Firestore Structure

#### Collection: `users` (NEW - Central User Registry)

This will be the **source of truth** for all users (both regular users and drivers).

```javascript
users/ (Collection)
  └── {userId}/  (Document - using Firebase Auth UID)
      ├── email: string              // User's email
      ├── name: string               // Display name
      ├── userType: string           // "user" | "driver" ⭐ KEY FIELD
      ├── phoneNumber: string        // Phone number (optional)
      ├── createdAt: Timestamp       // Account creation
      ├── lastLogin: Timestamp       // Last login time
      ├── isActive: boolean          // Account status
      ├── fcmToken: string           // For push notifications
      └── profileImageUrl: string    // Profile picture (optional)
```

#### Collection: `drivers` (MODIFIED - Driver-Specific Data)

Keep this for driver-specific information, linked to `users` collection.

```javascript
drivers/ (Collection)
  └── {userId}/  (Document - same ID as in users/)
      ├── carName: string            // "Toyota Camry"
      ├── carPlateNum: string        // "ABC-1234"
      ├── carType: string            // "Car" | "SUV" | "MotorCycle"
      ├── rate: number               // Price multiplier (default 3.0)
      ├── driverStatus: string       // "Idle" | "Busy" | "Offline"
      ├── driverLoc: GeoPoint        // Current location
      ├── geohash: string            // For GeoFire queries
      ├── rating: number             // Average rating (0-5)
      ├── totalRides: number         // Completed rides count
      ├── earnings: number           // Total earnings
      ├── licenseNumber: string      // Driver's license (optional)
      ├── vehicleRegistration: string // Registration docs (optional)
      └── isVerified: boolean        // Admin verification status
```

#### Collection: `userProfiles` (NEW - User-Specific Data)

For regular user-specific information.

```javascript
userProfiles/ (Collection)
  └── {userId}/  (Document - same ID as in users/)
      ├── homeAddress: string        // Saved home location
      ├── workAddress: string        // Saved work location
      ├── favoriteLocations: Array   // Saved favorite places
      ├── paymentMethods: Array      // Saved payment methods
      ├── preferences: Map           // App preferences
      │   ├── notifications: boolean
      │   ├── language: string
      │   └── theme: string
      ├── totalRides: number         // Rides taken
      └── rating: number             // User rating (for drivers to see)
```

#### Collection: `rideRequests` (MODIFIED - Unified Ride Requests)

```javascript
rideRequests/ (Collection)
  └── {requestId}/  (Document)
      ├── userId: string             // Regular user ID
      ├── driverId: string           // Assigned driver ID (null initially)
      ├── userEmail: string          // User email
      ├── driverEmail: string        // Driver email (when assigned)
      ├── status: string             // "pending" | "accepted" | "ongoing" | "completed" | "cancelled"
      ├── pickupLocation: GeoPoint   // Pickup coordinates
      ├── pickupAddress: string      // Human-readable address
      ├── dropoffLocation: GeoPoint  // Dropoff coordinates
      ├── dropoffAddress: string     // Human-readable address
      ├── scheduledTime: Timestamp   // null for immediate, future for scheduled
      ├── requestedAt: Timestamp     // When request was created
      ├── acceptedAt: Timestamp      // When driver accepted
      ├── startedAt: Timestamp       // When ride started
      ├── completedAt: Timestamp     // When ride ended
      ├── vehicleType: string        // Requested vehicle type
      ├── fare: number               // Calculated fare
      ├── distance: number           // Distance in km/miles
      ├── duration: number           // Estimated duration in minutes
      └── route: Map                 // Polyline data
```

#### Collection: `rideHistory` (NEW - Completed Rides)

Archive completed rides for both users and drivers.

```javascript
rideHistory/ (Collection)
  └── {rideId}/  (Document - same as rideRequest ID)
      ├── ... (all fields from rideRequests)
      ├── userRating: number         // User rated driver
      ├── driverRating: number       // Driver rated user
      ├── userFeedback: string       // Optional comment
      └── driverFeedback: string     // Optional comment
```

### 2.2 Firebase Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Helper function to check if user owns the document
    function isOwner(userId) {
      return request.auth.uid == userId;
    }
    
    // Helper function to get user type
    function getUserType() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.userType;
    }
    
    // Users collection - users can read/write their own document
    match /users/{userId} {
      allow read: if isAuthenticated() && isOwner(userId);
      allow create: if isAuthenticated() && isOwner(userId);
      allow update: if isAuthenticated() && isOwner(userId);
      allow delete: if false; // Prevent deletion
    }
    
    // Drivers collection - only drivers can access
    match /drivers/{userId} {
      allow read: if isAuthenticated();
      allow create, update: if isAuthenticated() && isOwner(userId) && getUserType() == 'driver';
      allow delete: if false;
    }
    
    // User profiles - only regular users can access
    match /userProfiles/{userId} {
      allow read, write: if isAuthenticated() && isOwner(userId) && getUserType() == 'user';
      allow delete: if false;
    }
    
    // Ride requests - users and drivers have different permissions
    match /rideRequests/{requestId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && getUserType() == 'user';
      allow update: if isAuthenticated() && 
        (resource.data.userId == request.auth.uid || 
         resource.data.driverId == request.auth.uid);
      allow delete: if isAuthenticated() && resource.data.userId == request.auth.uid;
    }
    
    // Ride history - read-only for participants
    match /rideHistory/{rideId} {
      allow read: if isAuthenticated() && 
        (resource.data.userId == request.auth.uid || 
         resource.data.driverId == request.auth.uid);
      allow write: if false; // Only server can write
    }
  }
}
```

---

## 3. Project Structure

### 3.1 Recommended Folder Structure

```
btrips_unified/
├── android/
├── ios/
├── lib/
│   ├── main.dart                           # App entry point
│   ├── firebase_options.dart               # Firebase config
│   │
│   ├── core/                               # 🆕 Shared core functionality
│   │   ├── constants/
│   │   │   ├── app_constants.dart          # App-wide constants
│   │   │   ├── route_constants.dart        # Route names
│   │   │   └── firebase_constants.dart     # Collection names
│   │   ├── enums/
│   │   │   ├── user_type.dart              # UserType enum (user, driver)
│   │   │   ├── ride_status.dart            # RideStatus enum
│   │   │   └── driver_status.dart          # DriverStatus enum
│   │   ├── utils/
│   │   │   ├── error_notification.dart     # Shared error handling
│   │   │   ├── firebase_messaging_service.dart # FCM service
│   │   │   ├── location_service.dart       # Location utilities
│   │   │   ├── map_utils.dart              # Map helpers
│   │   │   ├── distance_calculator.dart    # Distance/fare calc
│   │   │   └── currency_config.dart        # Currency formatting
│   │   └── theme/
│   │       ├── app_theme.dart              # Shared theme
│   │       ├── colors.dart                 # Color palette
│   │       └── text_styles.dart            # Typography
│   │
│   ├── data/                               # 🆕 Data layer
│   │   ├── models/
│   │   │   ├── user_model.dart             # User base model
│   │   │   ├── driver_model.dart           # Driver model
│   │   │   ├── user_profile_model.dart     # Regular user profile
│   │   │   ├── ride_request_model.dart     # Ride request
│   │   │   ├── ride_history_model.dart     # Completed ride
│   │   │   ├── direction_model.dart        # Route direction
│   │   │   ├── predicted_places_model.dart # Place predictions
│   │   │   └── preset_location_model.dart  # Preset locations
│   │   │
│   │   ├── repositories/
│   │   │   ├── auth_repository.dart        # Authentication
│   │   │   ├── user_repository.dart        # User CRUD
│   │   │   ├── driver_repository.dart      # Driver CRUD
│   │   │   ├── ride_repository.dart        # Ride CRUD
│   │   │   ├── location_repository.dart    # Location services
│   │   │   ├── places_repository.dart      # Google Places API
│   │   │   └── directions_repository.dart  # Google Directions API
│   │   │
│   │   └── providers/                      # Riverpod providers
│   │       ├── auth_provider.dart          # Auth state
│   │       ├── user_provider.dart          # User data
│   │       └── location_provider.dart      # Location state
│   │
│   ├── features/                           # 🆕 Feature-based organization
│   │   │
│   │   ├── auth/                           # Authentication feature
│   │   │   ├── presentation/
│   │   │   │   ├── screens/
│   │   │   │   │   ├── login_screen.dart
│   │   │   │   │   ├── register_screen.dart
│   │   │   │   │   └── role_selection_screen.dart  # 🆕 Choose user type
│   │   │   │   ├── widgets/
│   │   │   │   │   ├── auth_text_field.dart
│   │   │   │   │   └── auth_button.dart
│   │   │   │   └── providers/
│   │   │   │       ├── login_provider.dart
│   │   │   │       └── register_provider.dart
│   │   │   └── domain/
│   │   │       └── use_cases/
│   │   │           ├── login_use_case.dart
│   │   │           └── register_use_case.dart
│   │   │
│   │   ├── user/                           # 👤 User-specific features
│   │   │   ├── home/
│   │   │   │   ├── presentation/
│   │   │   │   │   ├── screens/
│   │   │   │   │   │   ├── user_home_screen.dart
│   │   │   │   │   │   └── where_to_screen.dart
│   │   │   │   │   ├── widgets/
│   │   │   │   │   │   ├── location_input.dart
│   │   │   │   │   │   ├── preset_locations_list.dart
│   │   │   │   │   │   ├── time_selector.dart
│   │   │   │   │   │   └── ride_request_button.dart
│   │   │   │   │   └── providers/
│   │   │   │   │       └── user_home_provider.dart
│   │   │   │   └── domain/
│   │   │   │       └── use_cases/
│   │   │   │           └── request_ride_use_case.dart
│   │   │   │
│   │   │   ├── profile/
│   │   │   │   ├── presentation/
│   │   │   │   │   ├── screens/
│   │   │   │   │   │   ├── user_profile_screen.dart
│   │   │   │   │   │   ├── edit_profile_screen.dart
│   │   │   │   │   │   ├── ride_history_screen.dart
│   │   │   │   │   │   ├── payment_methods_screen.dart
│   │   │   │   │   │   ├── settings_screen.dart
│   │   │   │   │   │   └── help_support_screen.dart
│   │   │   │   │   └── widgets/
│   │   │   │   │       └── profile_menu_item.dart
│   │   │   │   └── providers/
│   │   │   │       └── user_profile_provider.dart
│   │   │   │
│   │   │   └── navigation/
│   │   │       └── user_main_navigation.dart   # 2-tab bottom nav
│   │   │
│   │   ├── driver/                         # 🚗 Driver-specific features
│   │   │   ├── home/
│   │   │   │   ├── presentation/
│   │   │   │   │   ├── screens/
│   │   │   │   │   │   └── driver_home_screen.dart
│   │   │   │   │   ├── widgets/
│   │   │   │   │   │   ├── online_toggle_button.dart
│   │   │   │   │   │   ├── ride_request_card.dart
│   │   │   │   │   │   └── earnings_summary.dart
│   │   │   │   │   └── providers/
│   │   │   │   │       └── driver_home_provider.dart
│   │   │   │   └── domain/
│   │   │   │       └── use_cases/
│   │   │   │           ├── toggle_online_use_case.dart
│   │   │   │           └── accept_ride_use_case.dart
│   │   │   │
│   │   │   ├── config/
│   │   │   │   ├── presentation/
│   │   │   │   │   ├── screens/
│   │   │   │   │   │   └── driver_config_screen.dart
│   │   │   │   │   └── widgets/
│   │   │   │   │       └── vehicle_type_selector.dart
│   │   │   │   └── providers/
│   │   │   │       └── driver_config_provider.dart
│   │   │   │
│   │   │   ├── history/
│   │   │   │   └── presentation/
│   │   │   │       └── screens/
│   │   │   │           └── driver_history_screen.dart
│   │   │   │
│   │   │   ├── payments/
│   │   │   │   └── presentation/
│   │   │   │       └── screens/
│   │   │   │           └── driver_payment_screen.dart
│   │   │   │
│   │   │   ├── profile/
│   │   │   │   └── presentation/
│   │   │   │       └── screens/
│   │   │   │           └── driver_profile_screen.dart
│   │   │   │
│   │   │   └── navigation/
│   │   │       └── driver_main_navigation.dart  # 4-tab bottom nav
│   │   │
│   │   └── splash/                         # Splash screen
│   │       └── presentation/
│   │           └── screens/
│   │               └── splash_screen.dart
│   │
│   └── routes/                             # 🆕 App routing
│       ├── app_router.dart                 # Go Router configuration
│       ├── route_guards.dart               # Auth/role checks
│       └── route_names.dart                # Route constants
│
├── assets/
│   ├── fonts/
│   ├── images/
│   └── lottie/
│
├── test/
├── pubspec.yaml
└── README.md
```

### 3.2 Key Structural Benefits

| Aspect | Benefit |
|--------|---------|
| **core/** | Shared utilities, constants, theme accessible by all features |
| **data/** | Centralized data layer (models, repositories, providers) |
| **features/** | Feature-based organization - easy to find related code |
| **user/** vs **driver/** | Clear separation of role-specific code |
| **domain/** | Business logic separated from UI (clean architecture) |
| **presentation/** | UI layer (screens, widgets, providers) |

---

## 4. Authentication & Role Detection

### 4.1 Registration Flow with Role Selection

```dart
// core/enums/user_type.dart
enum UserType {
  user,
  driver;
  
  String get displayName {
    switch (this) {
      case UserType.user:
        return 'Passenger';
      case UserType.driver:
        return 'Driver';
    }
  }
  
  String get description {
    switch (this) {
      case UserType.user:
        return 'Book rides and travel comfortably';
      case UserType.driver:
        return 'Drive and earn money';
    }
  }
}
```

```dart
// features/auth/presentation/screens/role_selection_screen.dart
class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Join as',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 48),
              
              // User/Passenger option
              _RoleCard(
                userType: UserType.user,
                icon: Icons.person,
                onTap: () {
                  ref.read(selectedUserTypeProvider.notifier).state = UserType.user;
                  context.pushNamed(RouteNames.register);
                },
              ),
              
              const SizedBox(height: 24),
              
              // Driver option
              _RoleCard(
                userType: UserType.driver,
                icon: Icons.local_taxi,
                onTap: () {
                  ref.read(selectedUserTypeProvider.notifier).state = UserType.driver;
                  context.pushNamed(RouteNames.register);
                },
              ),
              
              const SizedBox(height: 32),
              
              TextButton(
                onPressed: () => context.goNamed(RouteNames.login),
                child: const Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final UserType userType;
  final IconData icon;
  final VoidCallback onTap;

  const _RoleCard({
    required this.userType,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            Text(
              userType.displayName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              userType.description,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
```

### 4.2 Modified Registration Logic

```dart
// data/repositories/auth_repository.dart
class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Register new user with role
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
        'email': email,
        'name': name,
        'userType': userType.name,  // "user" or "driver"
        'phoneNumber': '',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'isActive': true,
        'fcmToken': '',
        'profileImageUrl': '',
      };
      
      await _firestore.collection('users').doc(uid).set(userData);
      
      // 4. Create role-specific document
      if (userType == UserType.driver) {
        // Driver will complete this in driver config screen
        await _firestore.collection('drivers').doc(uid).set({
          'carName': '',
          'carPlateNum': '',
          'carType': '',
          'rate': 3.0,
          'driverStatus': 'Offline',
          'rating': 5.0,
          'totalRides': 0,
          'earnings': 0.0,
          'isVerified': false,
        });
      } else {
        // Create user profile document
        await _firestore.collection('userProfiles').doc(uid).set({
          'homeAddress': '',
          'workAddress': '',
          'favoriteLocations': [],
          'paymentMethods': [],
          'preferences': {
            'notifications': true,
            'language': 'en',
            'theme': 'dark',
          },
          'totalRides': 0,
          'rating': 5.0,
        });
      }
      
      // 5. Return user model
      return UserModel.fromFirestore(userData, uid);
      
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  /// Get current user with role
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      
      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!doc.exists) return null;
      
      return UserModel.fromFirestore(doc.data()!, user.uid);
      
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  /// Check if user is driver
  Future<bool> isDriver() async {
    final user = await getCurrentUser();
    return user?.userType == UserType.driver;
  }

  /// Check if user is regular user
  Future<bool> isRegularUser() async {
    final user = await getCurrentUser();
    return user?.userType == UserType.user;
  }
}
```

### 4.3 User Model

```dart
// data/models/user_model.dart
class UserModel {
  final String uid;
  final String email;
  final String name;
  final UserType userType;
  final String phoneNumber;
  final DateTime createdAt;
  final DateTime lastLogin;
  final bool isActive;
  final String fcmToken;
  final String profileImageUrl;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.userType,
    required this.phoneNumber,
    required this.createdAt,
    required this.lastLogin,
    required this.isActive,
    required this.fcmToken,
    required this.profileImageUrl,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      userType: data['userType'] == 'driver' ? UserType.driver : UserType.user,
      phoneNumber: data['phoneNumber'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      fcmToken: data['fcmToken'] ?? '',
      profileImageUrl: data['profileImageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'userType': userType.name,
      'phoneNumber': phoneNumber,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': Timestamp.fromDate(lastLogin),
      'isActive': isActive,
      'fcmToken': fcmToken,
      'profileImageUrl': profileImageUrl,
    };
  }

  bool get isDriver => userType == UserType.driver;
  bool get isRegularUser => userType == UserType.user;

  UserModel copyWith({
    String? name,
    String? phoneNumber,
    DateTime? lastLogin,
    bool? isActive,
    String? fcmToken,
    String? profileImageUrl,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      name: name ?? this.name,
      userType: userType,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isActive: isActive ?? this.isActive,
      fcmToken: fcmToken ?? this.fcmToken,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}
```

### 4.4 Auth State Provider

```dart
// data/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

/// Firebase Auth user stream
final firebaseAuthUserProvider = StreamProvider<firebase_auth.User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Current user model provider
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authRepo = ref.watch(authRepositoryProvider);
  return await authRepo.getCurrentUser();
});

/// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Check if current user is driver
final isDriverProvider = FutureProvider<bool>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  return user?.isDriver ?? false;
});

/// Check if current user is regular user
final isRegularUserProvider = FutureProvider<bool>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  return user?.isRegularUser ?? false;
});
```

---

## 5. Routing Strategy

### 5.1 App Router Configuration

```dart
// routes/app_router.dart
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

final appRouter = GoRouter(
  initialLocation: RouteNames.splash,
  redirect: (context, state) => _handleRedirect(context, state),
  routes: [
    // Splash screen
    GoRoute(
      path: RouteNames.splash,
      name: RouteNames.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    
    // Auth routes
    GoRoute(
      path: RouteNames.roleSelection,
      name: RouteNames.roleSelection,
      builder: (context, state) => const RoleSelectionScreen(),
    ),
    GoRoute(
      path: RouteNames.login,
      name: RouteNames.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: RouteNames.register,
      name: RouteNames.register,
      builder: (context, state) => const RegisterScreen(),
    ),
    
    // Driver-specific routes
    GoRoute(
      path: RouteNames.driverConfig,
      name: RouteNames.driverConfig,
      builder: (context, state) => const DriverConfigScreen(),
    ),
    GoRoute(
      path: RouteNames.driverMain,
      name: RouteNames.driverMain,
      builder: (context, state) => const DriverMainNavigation(),
    ),
    
    // User-specific routes
    GoRoute(
      path: RouteNames.userMain,
      name: RouteNames.userMain,
      builder: (context, state) => const UserMainNavigation(),
      routes: [
        GoRoute(
          path: 'where-to',
          name: RouteNames.whereTo,
          builder: (context, state) => const WhereToScreen(),
        ),
      ],
    ),
  ],
);

/// Handle redirects based on auth state and user role
Future<String?> _handleRedirect(BuildContext context, GoRouterState state) async {
  // Get container to access providers
  final container = ProviderScope.containerOf(context);
  
  // Check auth state
  final authUser = await container.read(firebaseAuthUserProvider.future);
  final isAuthenticated = authUser != null;
  
  // If not authenticated, allow only public routes
  if (!isAuthenticated) {
    final publicRoutes = [
      RouteNames.splash,
      RouteNames.login,
      RouteNames.register,
      RouteNames.roleSelection,
    ];
    
    if (!publicRoutes.contains(state.name)) {
      return RouteNames.login;
    }
    return null; // Allow navigation
  }
  
  // User is authenticated - check if on auth pages
  if (state.name == RouteNames.login || 
      state.name == RouteNames.register ||
      state.name == RouteNames.roleSelection) {
    // Redirect to appropriate home
    final isDriver = await container.read(isDriverProvider.future);
    
    if (isDriver) {
      // Check if driver has completed config
      final driverRepo = container.read(driverRepositoryProvider);
      final hasConfig = await driverRepo.hasCompletedConfiguration(authUser.uid);
      
      return hasConfig ? RouteNames.driverMain : RouteNames.driverConfig;
    } else {
      return RouteNames.userMain;
    }
  }
  
  // Check role-based access
  final isDriver = await container.read(isDriverProvider.future);
  
  // Prevent users from accessing driver routes
  if (!isDriver && state.name?.startsWith('driver') == true) {
    return RouteNames.userMain;
  }
  
  // Prevent drivers from accessing user routes
  if (isDriver && state.name?.startsWith('user') == true) {
    return RouteNames.driverMain;
  }
  
  return null; // Allow navigation
}
```

### 5.2 Route Names

```dart
// routes/route_names.dart
class RouteNames {
  // Splash
  static const String splash = '/';
  
  // Auth
  static const String login = '/login';
  static const String register = '/register';
  static const String roleSelection = '/role-selection';
  
  // Driver
  static const String driverConfig = '/driver-config';
  static const String driverMain = '/driver';
  static const String driverHome = '/driver/home';
  static const String driverPayments = '/driver/payments';
  static const String driverHistory = '/driver/history';
  static const String driverProfile = '/driver/profile';
  
  // User
  static const String userMain = '/user';
  static const String userHome = '/user/home';
  static const String userProfile = '/user/profile';
  static const String whereTo = 'where-to'; // Relative route
  static const String editProfile = '/user/edit-profile';
  static const String rideHistory = '/user/ride-history';
  static const String paymentMethods = '/user/payment-methods';
  static const String settings = '/user/settings';
  static const String helpSupport = '/user/help-support';
}
```

### 5.3 Splash Screen with Role Detection

```dart
// features/splash/presentation/screens/splash_screen.dart
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateBasedOnAuthState();
  }

  Future<void> _navigateBasedOnAuthState() async {
    // Wait a bit for splash effect
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    // Check authentication
    final authUser = await ref.read(firebaseAuthUserProvider.future);
    
    if (authUser == null) {
      // Not authenticated - go to role selection
      context.goNamed(RouteNames.roleSelection);
      return;
    }
    
    // Authenticated - check user type
    final user = await ref.read(currentUserProvider.future);
    
    if (user == null) {
      // Error - logout and go to login
      await FirebaseAuth.instance.signOut();
      if (mounted) context.goNamed(RouteNames.login);
      return;
    }
    
    if (user.isDriver) {
      // Check if driver has completed configuration
      final driverRepo = ref.read(driverRepositoryProvider);
      final hasConfig = await driverRepo.hasCompletedConfiguration(user.uid);
      
      if (hasConfig) {
        if (mounted) context.goNamed(RouteNames.driverMain);
      } else {
        if (mounted) context.goNamed(RouteNames.driverConfig);
      }
    } else {
      // Regular user - go to user main
      if (mounted) context.goNamed(RouteNames.userMain);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            Icon(
              Icons.local_taxi,
              size: 120,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            Text(
              'BTrips',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: Colors.blue),
          ],
        ),
      ),
    );
  }
}
```

---

## 6. State Management

### 6.1 Shared Providers

```dart
// data/providers/location_provider.dart
import 'package:geolocator/geolocator.dart';

/// Current device location
final currentLocationProvider = StreamProvider<Position?>((ref) {
  final locationRepo = ref.watch(locationRepositoryProvider);
  return locationRepo.getLocationStream();
});

/// Location permission status
final locationPermissionProvider = FutureProvider<LocationPermission>((ref) async {
  return await Geolocator.checkPermission();
});
```

```dart
// data/providers/user_provider.dart

/// Current user document listener
final currentUserDocumentProvider = StreamProvider<UserModel?>((ref) {
  final authUser = ref.watch(firebaseAuthUserProvider).value;
  
  if (authUser == null) {
    return Stream.value(null);
  }
  
  return FirebaseFirestore.instance
      .collection('users')
      .doc(authUser.uid)
      .snapshots()
      .map((doc) {
        if (!doc.exists) return null;
        return UserModel.fromFirestore(doc.data()!, doc.id);
      });
});
```

### 6.2 Driver-Specific Providers

```dart
// features/driver/home/presentation/providers/driver_home_provider.dart

/// Driver status (Idle, Busy, Offline)
final driverStatusProvider = StateProvider<String>((ref) => 'Offline');

/// Is driver online?
final isDriverOnlineProvider = Provider<bool>((ref) {
  final status = ref.watch(driverStatusProvider);
  return status != 'Offline';
});

/// Driver location update stream
final driverLocationStreamProvider = StreamProvider<Position?>((ref) {
  final isOnline = ref.watch(isDriverOnlineProvider);
  
  if (!isOnline) {
    return Stream.value(null);
  }
  
  return Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    ),
  );
});

/// Pending ride requests for driver
final pendingRideRequestsProvider = StreamProvider<List<RideRequestModel>>((ref) {
  final user = ref.watch(currentUserDocumentProvider).value;
  
  if (user == null || !user.isDriver) {
    return Stream.value([]);
  }
  
  // Get nearby ride requests using GeoFlutterFire
  // This would need driver's current location
  final location = ref.watch(currentLocationProvider).value;
  
  if (location == null) {
    return Stream.value([]);
  }
  
  // Query rides within radius
  return FirebaseFirestore.instance
      .collection('rideRequests')
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => RideRequestModel.fromFirestore(doc.data(), doc.id))
            .toList();
      });
});
```

### 6.3 User-Specific Providers

```dart
// features/user/home/presentation/providers/user_home_provider.dart

/// Selected pickup location
final pickupLocationProvider = StateProvider<LocationModel?>((ref) => null);

/// Selected dropoff location
final dropoffLocationProvider = StateProvider<LocationModel?>((ref) => null);

/// Is scheduling ride (vs immediate)
final isSchedulingRideProvider = StateProvider<bool>((ref) => false);

/// Scheduled time
final scheduledTimeProvider = StateProvider<DateTime?>((ref) => null);

/// Preset locations mode
final presetLocationsModeProvider = StateProvider<bool>((ref) => false);

/// Available drivers nearby
final nearbyDriversProvider = StreamProvider<List<DriverModel>>((ref) {
  final location = ref.watch(currentLocationProvider).value;
  
  if (location == null) {
    return Stream.value([]);
  }
  
  // Use GeoFlutterFire to query nearby drivers
  final geo = GeoFlutterFire();
  final center = geo.point(
    latitude: location.latitude,
    longitude: location.longitude,
  );
  
  return FirebaseFirestore.instance
      .collection('drivers')
      .where('driverStatus', isEqualTo: 'Idle')
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => DriverModel.fromFirestore(doc.data(), doc.id))
            .where((driver) {
              // Filter by distance (e.g., within 5km)
              final distance = Geolocator.distanceBetween(
                location.latitude,
                location.longitude,
                driver.driverLoc.latitude,
                driver.driverLoc.longitude,
              );
              return distance <= 5000; // 5km
            })
            .toList();
      });
});
```

---

## 7. Implementation Steps

### Phase 1: Setup & Foundation (Week 1)

#### Step 1.1: Create New Unified Project
```bash
# Create new Flutter project
flutter create btrips_unified
cd btrips_unified

# Copy assets from existing projects
cp -r ../btrips_user/assets ./assets
```

#### Step 1.2: Update pubspec.yaml
Merge dependencies from both apps:
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_riverpod: ^2.3.6
  
  # Navigation
  go_router: ^10.1.0
  
  # Firebase
  firebase_core: ^2.15.0
  firebase_auth: ^4.7.1
  cloud_firestore: ^4.8.3
  firebase_messaging: ^14.6.7
  flutter_local_notifications: ^15.1.1
  
  # Maps & Location
  google_maps_flutter: ^2.8.0
  geolocator: ^10.0.0
  geocoder2: ^1.4.0
  geocoding: ^4.0.0
  flutter_polyline_points: ^1.0.0
  geoflutterfire2: ^2.3.15
  
  # Networking
  dio: ^5.3.2
  
  # UI
  elegant_notification: ^1.10.1
  lottie: ^2.6.0
  url_launcher: ^6.2.2
  cupertino_icons: ^1.0.2
```

#### Step 1.3: Setup Firebase
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for unified app
flutterfire configure
```

#### Step 1.4: Create Folder Structure
```bash
# Create core folders
mkdir -p lib/core/{constants,enums,utils,theme}
mkdir -p lib/data/{models,repositories,providers}
mkdir -p lib/features/{auth,user,driver,splash}/presentation/screens
mkdir -p lib/routes
```

### Phase 2: Core Foundation (Week 1-2)

#### Step 2.1: Implement Enums & Constants
- Create `user_type.dart` enum
- Create `ride_status.dart` enum
- Create `driver_status.dart` enum
- Create app constants
- Create Firebase collection constants

#### Step 2.2: Setup Theme
- Copy and merge theme files from both apps
- Create unified color scheme
- Setup typography

#### Step 2.3: Create Data Models
Priority order:
1. `UserModel` (base user with role)
2. `DriverModel` (driver-specific data)
3. `UserProfileModel` (user-specific data)
4. `RideRequestModel`
5. `RideHistoryModel`
6. Other supporting models

#### Step 2.4: Implement Repositories
Priority order:
1. `AuthRepository` (with role-based registration)
2. `UserRepository`
3. `DriverRepository`
4. `RideRepository`
5. `LocationRepository`
6. `PlacesRepository`
7. `DirectionsRepository`

#### Step 2.5: Setup Providers
- Auth providers
- User providers
- Location providers

### Phase 3: Authentication (Week 2)

#### Step 3.1: Build Auth Screens
1. Role Selection Screen
2. Login Screen (shared)
3. Register Screen (with role parameter)

#### Step 3.2: Implement Auth Logic
- Registration with role
- Login flow
- Role detection
- Auto-navigation based on role

#### Step 3.3: Setup Routing
- Configure Go Router
- Implement redirects
- Add route guards

### Phase 4: Driver Features (Week 3)

#### Step 4.1: Driver Configuration
- Vehicle config screen
- Save to Firestore
- Validation

#### Step 4.2: Driver Home Screen
- Map view
- Online/Offline toggle
- Location broadcasting
- Dimmed overlay when offline

#### Step 4.3: Driver Navigation
- Bottom navigation (4 tabs)
- Home, Payments, History, Profile

#### Step 4.4: Ride Management
- Listen for ride requests
- Accept/Decline functionality
- Update driver status

### Phase 5: User Features (Week 4)

#### Step 5.1: User Home Screen
- Map view
- Pickup location (auto-detect)
- Dropoff selection
- Search vs Preset toggle
- Time selection (Now/Schedule)

#### Step 5.2: Location Search
- Where To screen
- Google Places integration
- Preset airport locations

#### Step 5.3: Ride Booking
- Request ride logic
- Find nearby drivers
- Calculate fare
- Send notifications

#### Step 5.4: User Navigation
- Bottom navigation (2 tabs)
- Ride, Profile

### Phase 6: Profile Features (Week 5)

#### Step 6.1: User Profile
- Profile screen
- Edit profile
- Ride history
- Payment methods
- Settings
- Help & Support

#### Step 6.2: Driver Profile
- Basic profile screen
- Earnings display
- Rating display

### Phase 7: Ride Flow (Week 5-6)

#### Step 7.1: Real-time Updates
- Driver location updates
- Ride status updates
- Push notifications

#### Step 7.2: In-Ride Features
- Route display
- ETA updates
- Completion flow

### Phase 8: Testing & Polish (Week 6-7)

#### Step 8.1: Testing
- Unit tests for repositories
- Widget tests for screens
- Integration tests for flows
- Role switching tests

#### Step 8.2: Error Handling
- Network errors
- Permission errors
- Firebase errors
- User-friendly messages

#### Step 8.3: Performance
- Optimize map rendering
- Reduce Firestore reads
- Implement caching

### Phase 9: Migration & Deployment (Week 7-8)

#### Step 9.1: Data Migration
- Export existing users
- Migrate to new schema
- Add userType field
- Create new collections

#### Step 9.2: Documentation
- Update README
- API documentation
- Setup guides

#### Step 9.3: Deployment
- Build APK/IPA
- Test on devices
- Submit to stores

---

## 8. Code Organization Guidelines

### 8.1 Naming Conventions

```dart
// ✅ Good - Clear role-specific naming
class UserHomeScreen extends StatelessWidget {}
class DriverHomeScreen extends StatelessWidget {}

class UserHomeProvider extends StateNotifier<UserHomeState> {}
class DriverHomeProvider extends StateNotifier<DriverHomeState> {}

// ❌ Bad - Ambiguous naming
class HomeScreen extends StatelessWidget {}  // Which home?
class HomeProvider extends StateNotifier {}  // For who?
```

### 8.2 Shared Components

For components used by both roles, use descriptive names:

```dart
// ✅ Shared components (no role prefix)
class CustomMapView extends StatelessWidget {}
class LocationPicker extends StatelessWidget {}
class AuthTextField extends StatelessWidget {}

// Used in different contexts
UserHomeScreen -> uses CustomMapView
DriverHomeScreen -> uses CustomMapView (same component)
```

### 8.3 Feature Flags

Use role checks for conditional features:

```dart
// ✅ Good - Role-based feature access
Widget build(BuildContext context, WidgetRef ref) {
  final user = ref.watch(currentUserProvider).value;
  
  return Scaffold(
    body: user?.isDriver 
        ? const DriverHomeScreen()
        : const UserHomeScreen(),
  );
}

// ✅ Good - Conditional menu items
if (user.isDriver) {
  _buildMenuItem(
    icon: Icons.attach_money,
    title: 'Earnings',
    onTap: () => context.push(RouteNames.driverPayments),
  ),
}

if (user.isRegularUser) {
  _buildMenuItem(
    icon: Icons.payment,
    title: 'Payment Methods',
    onTap: () => context.push(RouteNames.paymentMethods),
  ),
}
```

### 8.4 Repository Abstraction

```dart
// ✅ Good - Single repository with role-aware methods
class RideRepository {
  // User calls this
  Future<RideRequestModel> createRideRequest({
    required String userId,
    required LocationModel pickup,
    required LocationModel dropoff,
  }) async {
    // Implementation
  }
  
  // Driver calls this
  Future<void> acceptRideRequest({
    required String rideId,
    required String driverId,
  }) async {
    // Implementation
  }
  
  // Both can call this
  Future<RideRequestModel?> getRideRequest(String rideId) async {
    // Implementation
  }
}

// ❌ Bad - Separate repositories for same entity
class UserRideRepository {}
class DriverRideRepository {}
```

### 8.5 Widget Composition

```dart
// ✅ Good - Compose role-specific screens from shared widgets
class UserHomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: [
          SharedMapView(),              // Shared
          UserLocationInputSheet(),     // User-specific
          UserRideRequestButton(),      // User-specific
        ],
      ),
    );
  }
}

class DriverHomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: [
          SharedMapView(),              // Shared
          DriverStatusToggle(),         // Driver-specific
          DriverRideRequestsPanel(),    // Driver-specific
        ],
      ),
    );
  }
}
```

---

## 9. Migration Checklist

### 9.1 Pre-Migration

- [ ] Backup existing Firebase data
- [ ] Export user lists from both apps
- [ ] Document current Firebase rules
- [ ] List all active users/drivers
- [ ] Create migration script

### 9.2 Firebase Migration

- [ ] Create `users` collection
- [ ] Migrate user data from btrips_user
- [ ] Migrate driver data from btrips_driver
- [ ] Add `userType` field to all users
- [ ] Create `userProfiles` collection
- [ ] Update `drivers` collection schema
- [ ] Create `rideRequests` collection (unified)
- [ ] Create `rideHistory` collection
- [ ] Update security rules
- [ ] Test security rules

### 9.3 Code Migration

#### From btrips_user:
- [ ] Copy auth screens
- [ ] Copy user home screen
- [ ] Copy where-to screen
- [ ] Copy profile screens (5 sub-screens)
- [ ] Copy user navigation
- [ ] Copy place search logic
- [ ] Copy direction logic
- [ ] Copy preset locations
- [ ] Copy user repositories
- [ ] Copy user providers

#### From btrips_driver:
- [ ] Copy driver config screen
- [ ] Copy driver home screen
- [ ] Copy driver navigation
- [ ] Copy online/offline toggle
- [ ] Copy driver repositories
- [ ] Copy driver providers

#### Merge Common:
- [ ] Merge themes
- [ ] Merge auth logic
- [ ] Merge Firebase messaging
- [ ] Merge map utilities
- [ ] Merge location services
- [ ] Merge error handling
- [ ] Merge constants

### 9.4 New Implementation

- [ ] Create role selection screen
- [ ] Implement role-based routing
- [ ] Create unified auth flow
- [ ] Implement user type detection
- [ ] Create conditional navigation
- [ ] Setup route guards
- [ ] Implement role-based FCM topics
- [ ] Create unified models
- [ ] Update repositories for roles

### 9.5 Testing

- [ ] Test user registration
- [ ] Test driver registration
- [ ] Test user login → user home
- [ ] Test driver login → driver home
- [ ] Test driver config flow
- [ ] Test role switching (logout/login different role)
- [ ] Test user ride booking
- [ ] Test driver ride acceptance
- [ ] Test FCM notifications (both roles)
- [ ] Test offline functionality
- [ ] Test permissions (location, notifications)
- [ ] Test on Android
- [ ] Test on iOS

### 9.6 Deployment

- [ ] Update app name/bundle ID
- [ ] Update Firebase project settings
- [ ] Build Android APK
- [ ] Build iOS IPA
- [ ] Test builds on physical devices
- [ ] Create release notes
- [ ] Submit to Play Store
- [ ] Submit to App Store

---

## 10. Testing Strategy

### 10.1 Unit Tests

```dart
// test/data/repositories/auth_repository_test.dart
void main() {
  group('AuthRepository', () {
    test('registerWithEmailPassword creates user with correct role', () async {
      // Arrange
      final authRepo = AuthRepository();
      
      // Act
      final user = await authRepo.registerWithEmailPassword(
        email: 'test@example.com',
        password: 'password123',
        name: 'Test User',
        userType: UserType.user,
      );
      
      // Assert
      expect(user.userType, UserType.user);
      expect(user.email, 'test@example.com');
    });
    
    test('isDriver returns true for driver accounts', () async {
      // Test implementation
    });
  });
}
```

### 10.2 Widget Tests

```dart
// test/features/auth/presentation/screens/role_selection_screen_test.dart
void main() {
  testWidgets('RoleSelectionScreen shows both role options', (tester) async {
    // Build widget
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: RoleSelectionScreen(),
        ),
      ),
    );
    
    // Verify both options are shown
    expect(find.text('Passenger'), findsOneWidget);
    expect(find.text('Driver'), findsOneWidget);
  });
  
  testWidgets('Tapping user role navigates to register', (tester) async {
    // Test implementation
  });
}
```

### 10.3 Integration Tests

```dart
// integration_test/user_flow_test.dart
void main() {
  group('User Flow', () {
    testWidgets('Complete user registration and ride booking', (tester) async {
      // 1. Start app
      // 2. Select "Passenger" role
      // 3. Register account
      // 4. Verify navigation to user home
      // 5. Select destination
      // 6. Request ride
      // 7. Verify ride request created
    });
  });
  
  group('Driver Flow', () {
    testWidgets('Complete driver registration and configuration', (tester) async {
      // 1. Start app
      // 2. Select "Driver" role
      // 3. Register account
      // 4. Verify navigation to driver config
      // 5. Enter vehicle details
      // 6. Submit configuration
      // 7. Verify navigation to driver home
    });
  });
}
```

### 10.4 Role Switching Tests

```dart
// test/features/auth/role_switching_test.dart
void main() {
  testWidgets('User cannot access driver routes', (tester) async {
    // Login as user
    // Attempt to navigate to driver route
    // Verify redirect to user home
  });
  
  testWidgets('Driver cannot access user routes', (tester) async {
    // Login as driver
    // Attempt to navigate to user route
    // Verify redirect to driver home
  });
}
```

---

## 11. Deployment Considerations

### 11.1 App Naming

**Option 1: Same Name for Both Roles**
- App Name: "BTrips"
- Users and drivers download the same app
- Role determined at registration
- **Pros**: Single brand, easier marketing
- **Cons**: Might confuse users initially

**Option 2: Branded by Role** (Recommended)
- Keep same bundle ID
- Use role-specific branding in stores
- Description mentions both modes
- **Pros**: Clear purpose, better SEO
- **Cons**: Need to explain dual nature

### 11.2 Store Listings

**App Store Description:**
```
BTrips - Ride Booking & Driving Platform

ONE APP, TWO WAYS TO RIDE:

🚗 FOR PASSENGERS:
• Book rides instantly or schedule in advance
• Choose from multiple vehicle types (Car, SUV, Motorcycle)
• Track your driver in real-time
• Save favorite locations
• View complete ride history

💼 FOR DRIVERS:
• Set your own schedule - go online/offline anytime
• Accept rides in your area
• Track earnings in real-time
• Navigate to pickups and destinations
• Build your driver rating

FEATURES:
✓ Secure Firebase authentication
✓ Real-time GPS tracking
✓ Push notifications
✓ Multiple payment methods
✓ 24/7 support

Download now and choose your experience!
```

### 11.3 Version Management

```yaml
# pubspec.yaml
version: 2.0.0+1

# Version 2.0.0 - Unified app (breaking change from separate apps)
# +1 - Build number
```

### 11.4 Migration Notice

For existing users:
1. Send push notification about app update
2. Auto-detect user type on first login
3. Migrate existing data seamlessly
4. Show welcome screen explaining new unified app

---

## 12. Timeline Summary

| Phase | Duration | Deliverables |
|-------|----------|--------------|
| **Phase 1: Setup** | 1 week | Project structure, dependencies, Firebase |
| **Phase 2: Core** | 1 week | Models, repositories, providers, theme |
| **Phase 3: Auth** | 1 week | Role selection, login, register, routing |
| **Phase 4: Driver** | 1 week | Config, home, navigation, ride management |
| **Phase 5: User** | 1 week | Home, search, booking, navigation |
| **Phase 6: Profiles** | 1 week | User & driver profile features |
| **Phase 7: Ride Flow** | 1-2 weeks | Real-time updates, in-ride features |
| **Phase 8: Testing** | 1-2 weeks | Unit, widget, integration tests |
| **Phase 9: Deployment** | 1 week | Migration, builds, store submission |
| **TOTAL** | **7-10 weeks** | Production-ready unified app |

---

## 13. Key Benefits Summary

### Development Benefits
- ✅ **50% Less Code to Maintain**: Shared utilities, theme, auth
- ✅ **Single Build Process**: One build for both user types
- ✅ **Easier Updates**: Update once, deploy to all
- ✅ **Consistent Features**: Same Firebase, maps, notifications
- ✅ **Better Code Reuse**: Repositories, models, providers shared

### User Benefits
- ✅ **Seamless Experience**: Switch roles if needed (future feature)
- ✅ **Single Download**: One app, choose your role
- ✅ **Unified Branding**: Consistent look and feel
- ✅ **Better Support**: Single support channel

### Business Benefits
- ✅ **Faster Development**: Parallel feature development
- ✅ **Lower Costs**: One codebase, one deployment
- ✅ **Easier Testing**: Test once for both roles
- ✅ **Better Analytics**: Unified analytics platform

---

## 14. Risk Mitigation

### Potential Risks & Solutions

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| **Route conflicts** | High | Medium | Clear naming, route guards, comprehensive testing |
| **State management complexity** | Medium | High | Use Riverpod family providers, clear provider naming |
| **Data migration errors** | High | Low | Backup data, migration scripts, rollback plan |
| **Performance issues** | Medium | Low | Optimize providers, lazy loading, caching |
| **User confusion** | Low | Medium | Clear onboarding, role selection screen |
| **Security vulnerabilities** | High | Low | Strong Firestore rules, role validation |

---

## Conclusion

This unified app architecture provides a clean, maintainable solution for merging the BTrips user and driver apps. By following this implementation plan, you'll create a single codebase that:

1. **Clearly separates** user and driver features
2. **Maximizes code reuse** through shared components
3. **Maintains clean architecture** with proper organization
4. **Scales easily** for future features
5. **Reduces maintenance overhead** significantly

The role-based routing and state management ensure that users and drivers see only their relevant features, while the shared foundation prevents code duplication.

---

**Next Steps:**
1. Review this plan with your team
2. Set up the project structure
3. Begin Phase 1 implementation
4. Schedule regular check-ins to track progress

**Questions to Consider:**
- Do you want users to be able to switch roles (e.g., a user becomes a driver)?
- Should there be an admin role for platform management?
- What analytics do you want to track for both user types?

Good luck with the implementation! 🚀

