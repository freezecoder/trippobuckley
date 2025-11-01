import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a preset location (e.g., airports, popular destinations)
class PresetLocationModel {
  final String? id; // Firestore document ID
  final String name;
  final String placeId;
  final double? latitude;
  final double? longitude;
  final String category; // e.g., "airport", "station", "landmark"
  final bool isActive; // Admin can disable locations
  final int order; // Display order
  final DateTime? createdAt;

  PresetLocationModel({
    this.id,
    required this.name,
    this.placeId = '',
    this.latitude,
    this.longitude,
    this.category = 'airport',
    this.isActive = true,
    this.order = 0,
    this.createdAt,
  });

  /// Check if location has coordinates
  bool get hasCoordinates => latitude != null && longitude != null;

  /// Preset airport locations
  static List<PresetLocationModel> get airportLocations => [
    PresetLocationModel(
      name: "Newark Liberty Airport",
      placeId: "",
      latitude: 40.6895,
      longitude: -74.1745,
    ),
    PresetLocationModel(
      name: "New York JFK Airport",
      placeId: "",
      latitude: 40.6413,
      longitude: -73.7781,
    ),
    PresetLocationModel(
      name: "New York La Guardia",
      placeId: "",
      latitude: 40.7769,
      longitude: -73.8740,
    ),
    PresetLocationModel(
      name: "Philadelphia Airport",
      placeId: "",
      latitude: 39.8719,
      longitude: -75.2411,
    ),
  ];

  /// Create from Firestore document
  factory PresetLocationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PresetLocationModel(
      id: doc.id,
      name: data['name'] ?? '',
      placeId: data['placeId'] ?? '',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      category: data['category'] ?? 'airport',
      isActive: data['isActive'] ?? true,
      order: data['order'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'placeId': placeId,
      'latitude': latitude,
      'longitude': longitude,
      'category': category,
      'isActive': isActive,
      'order': order,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  /// Create a copy with updated fields
  PresetLocationModel copyWith({
    String? id,
    String? name,
    String? placeId,
    double? latitude,
    double? longitude,
    String? category,
    bool? isActive,
    int? order,
    DateTime? createdAt,
  }) {
    return PresetLocationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      placeId: placeId ?? this.placeId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'PresetLocationModel(id: $id, name: $name, category: $category, lat: $latitude, lng: $longitude)';
  }
}

// Keep old name for backward compatibility during migration
typedef PresetLocation = PresetLocationModel;

