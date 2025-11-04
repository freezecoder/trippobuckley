import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing an admin action for audit logging
class AdminActionModel {
  final String actionId;
  final String adminId;
  final String adminEmail;
  final String actionType;
  final String targetType;
  final String targetId;
  final String targetEmail;
  final String targetName;
  final String reason;
  final Map<String, dynamic> previousState;
  final Map<String, dynamic> newState;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  AdminActionModel({
    required this.actionId,
    required this.adminId,
    required this.adminEmail,
    required this.actionType,
    required this.targetType,
    required this.targetId,
    required this.targetEmail,
    required this.targetName,
    this.reason = '',
    required this.previousState,
    required this.newState,
    required this.timestamp,
    required this.metadata,
  });

  /// Create AdminActionModel from Firestore document
  factory AdminActionModel.fromFirestore(
    Map<String, dynamic> data,
    String actionId,
  ) {
    return AdminActionModel(
      actionId: actionId,
      adminId: data['adminId'] ?? '',
      adminEmail: data['adminEmail'] ?? '',
      actionType: data['actionType'] ?? '',
      targetType: data['targetType'] ?? '',
      targetId: data['targetId'] ?? '',
      targetEmail: data['targetEmail'] ?? '',
      targetName: data['targetName'] ?? '',
      reason: data['reason'] ?? '',
      previousState: Map<String, dynamic>.from(data['previousState'] ?? {}),
      newState: Map<String, dynamic>.from(data['newState'] ?? {}),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'adminId': adminId,
      'adminEmail': adminEmail,
      'actionType': actionType,
      'targetType': targetType,
      'targetId': targetId,
      'targetEmail': targetEmail,
      'targetName': targetName,
      'reason': reason,
      'previousState': previousState,
      'newState': newState,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
    };
  }

  /// Get human-readable action description
  String get actionDescription {
    switch (actionType) {
      case 'activate_user':
        return 'Activated user';
      case 'deactivate_user':
        return 'Deactivated user';
      case 'delete_user':
        return 'Deleted user';
      case 'activate_driver':
        return 'Activated driver';
      case 'deactivate_driver':
        return 'Deactivated driver';
      case 'delete_driver':
        return 'Deleted driver';
      case 'verify_driver':
        return 'Verified driver';
      case 'suspend_account':
        return 'Suspended account';
      case 'update_user_phone':
        return 'Updated user phone number';
      case 'update_user_address':
        return 'Updated user address';
      case 'add_payment_method':
        return 'Added payment method';
      case 'remove_payment_method':
        return 'Removed payment method';
      case 'deactivate_payment_method':
        return 'Deactivated payment method';
      case 'set_default_payment_method':
        return 'Set default payment method';
      default:
        return actionType;
    }
  }

  @override
  String toString() {
    return 'AdminActionModel(actionId: $actionId, actionType: $actionType, targetType: $targetType, targetId: $targetId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdminActionModel && other.actionId == actionId;
  }

  @override
  int get hashCode => actionId.hashCode;
}

