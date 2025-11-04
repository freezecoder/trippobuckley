import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for user's favorite/saved places
class FavoritePlaceModel {
  final String? id; // Firestore document ID
  final String userId;
  final String name;
  final String address;
  final String placeId;
  final double latitude;
  final double longitude;
  final String category; // 'home', 'work', 'other'
  final String? nickname; // Optional custom name like "Mom's House"
  final DateTime createdAt;
  final DateTime? lastUsed;
  final int useCount; // Track how often used

  FavoritePlaceModel({
    this.id,
    required this.userId,
    required this.name,
    required this.address,
    required this.placeId,
    required this.latitude,
    required this.longitude,
    this.category = 'other',
    this.nickname,
    required this.createdAt,
    this.lastUsed,
    this.useCount = 0,
  });

  /// Create from Firestore document
  factory FavoritePlaceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FavoritePlaceModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      placeId: data['placeId'] ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      category: data['category'] ?? 'other',
      nickname: data['nickname'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUsed: (data['lastUsed'] as Timestamp?)?.toDate(),
      useCount: data['useCount'] ?? 0,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'address': address,
      'placeId': placeId,
      'latitude': latitude,
      'longitude': longitude,
      'category': category,
      'nickname': nickname,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUsed': lastUsed != null ? Timestamp.fromDate(lastUsed!) : null,
      'useCount': useCount,
    };
  }

  /// Display name (nickname or name)
  String get displayName => nickname?.isNotEmpty == true ? nickname! : name;

  /// Category icon
  String get categoryIcon {
    switch (category) {
      case 'home':
        return '🏠';
      case 'work':
        return '💼';
      default:
        return '⭐';
    }
  }

  /// Copy with method
  FavoritePlaceModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? address,
    String? placeId,
    double? latitude,
    double? longitude,
    String? category,
    String? nickname,
    DateTime? createdAt,
    DateTime? lastUsed,
    int? useCount,
  }) {
    return FavoritePlaceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      address: address ?? this.address,
      placeId: placeId ?? this.placeId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      category: category ?? this.category,
      nickname: nickname ?? this.nickname,
      createdAt: createdAt ?? this.createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
      useCount: useCount ?? this.useCount,
    );
  }

  @override
  String toString() {
    return 'FavoritePlaceModel(id: $id, name: $name, category: $category)';
  }
}

