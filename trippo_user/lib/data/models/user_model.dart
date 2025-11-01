import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/enums/user_type.dart';

/// Model representing a user (both regular users and drivers) in the system
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
    this.phoneNumber = '',
    required this.createdAt,
    required this.lastLogin,
    this.isActive = true,
    this.fcmToken = '',
    this.profileImageUrl = '',
  });

  /// Create UserModel from Firestore document
  factory UserModel.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      userType: UserType.fromString(data['userType'] ?? 'user'),
      phoneNumber: data['phoneNumber'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      fcmToken: data['fcmToken'] ?? '',
      profileImageUrl: data['profileImageUrl'] ?? '',
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'userType': userType.toFirestore(),
      'phoneNumber': phoneNumber,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': Timestamp.fromDate(lastLogin),
      'isActive': isActive,
      'fcmToken': fcmToken,
      'profileImageUrl': profileImageUrl,
    };
  }

  /// Check if user is a driver
  bool get isDriver => userType == UserType.driver;

  /// Check if user is a regular user
  bool get isRegularUser => userType == UserType.user;

  /// Copy with method for immutability
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

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, name: $name, userType: $userType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}

