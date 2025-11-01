import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:btrips_unified/core/constants/firebase_constants.dart';
import 'package:btrips_unified/data/models/preset_location_model.dart';

/// Repository for managing preset locations in Firestore
class PresetLocationRepository {
  final FirebaseFirestore _firestore;

  PresetLocationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get reference to preset locations collection
  CollectionReference get _collection =>
      _firestore.collection(FirebaseConstants.presetLocationsCollection);

  /// Get all active preset locations ordered by order field
  Stream<List<PresetLocationModel>> getActivePresetLocations() {
    return _collection
        .where(FirebaseConstants.presetLocationIsActive, isEqualTo: true)
        .orderBy(FirebaseConstants.presetLocationOrder)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PresetLocationModel.fromFirestore(doc))
            .toList());
  }

  /// Get preset locations by category (e.g., "airport")
  Stream<List<PresetLocationModel>> getPresetLocationsByCategory(
      String category) {
    return _collection
        .where(FirebaseConstants.presetLocationIsActive, isEqualTo: true)
        .where(FirebaseConstants.presetLocationCategory, isEqualTo: category)
        .orderBy(FirebaseConstants.presetLocationOrder)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PresetLocationModel.fromFirestore(doc))
            .toList());
  }

  /// Get all preset locations (including inactive) for admin use
  Stream<List<PresetLocationModel>> getAllPresetLocations() {
    return _collection
        .orderBy(FirebaseConstants.presetLocationOrder)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PresetLocationModel.fromFirestore(doc))
            .toList());
  }

  /// Get a specific preset location by ID
  Future<PresetLocationModel?> getPresetLocationById(String id) async {
    final doc = await _collection.doc(id).get();
    if (doc.exists) {
      return PresetLocationModel.fromFirestore(doc);
    }
    return null;
  }

  /// Add a new preset location
  Future<String> addPresetLocation(PresetLocationModel location) async {
    final docRef = await _collection.add(location.toFirestore());
    return docRef.id;
  }

  /// Update an existing preset location
  Future<void> updatePresetLocation(
      String id, PresetLocationModel location) async {
    await _collection.doc(id).update(location.toFirestore());
  }

  /// Delete a preset location
  Future<void> deletePresetLocation(String id) async {
    await _collection.doc(id).delete();
  }

  /// Toggle active status of a preset location
  Future<void> togglePresetLocationStatus(String id, bool isActive) async {
    await _collection.doc(id).update({
      FirebaseConstants.presetLocationIsActive: isActive,
    });
  }

  /// Reorder preset locations
  Future<void> reorderPresetLocations(Map<String, int> orderMap) async {
    final batch = _firestore.batch();
    orderMap.forEach((id, order) {
      batch.update(_collection.doc(id), {
        FirebaseConstants.presetLocationOrder: order,
      });
    });
    await batch.commit();
  }

  /// Seed initial preset locations (for first-time setup)
  Future<void> seedInitialLocations(
      List<PresetLocationModel> locations) async {
    final batch = _firestore.batch();
    
    // Check if collection is empty first
    final snapshot = await _collection.limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      // Collection already has data, skip seeding
      return;
    }

    for (var i = 0; i < locations.length; i++) {
      final location = locations[i].copyWith(order: i);
      final docRef = _collection.doc();
      batch.set(docRef, location.toFirestore());
    }

    await batch.commit();
  }
}

