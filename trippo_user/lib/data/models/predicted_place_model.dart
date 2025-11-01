/// Model representing a predicted place from Google Places API autocomplete
class PredictedPlaceModel {
  final String? placeId;
  final String? mainText;
  final String? secondaryText;

  PredictedPlaceModel({
    this.placeId,
    this.mainText,
    this.secondaryText,
  });

  /// Create from Google Places API JSON response
  factory PredictedPlaceModel.fromJson(Map<String, dynamic> jsonData) {
    return PredictedPlaceModel(
      placeId: jsonData["place_id"] as String?,
      mainText: jsonData["structured_formatting"]?["main_text"] as String?,
      secondaryText: jsonData["structured_formatting"]?["secondary_text"] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'place_id': placeId,
      'structured_formatting': {
        'main_text': mainText,
        'secondary_text': secondaryText,
      },
    };
  }

  /// Get full display text
  String get fullText {
    if (mainText != null && secondaryText != null) {
      return '$mainText, $secondaryText';
    }
    return mainText ?? secondaryText ?? 'Unknown Place';
  }

  @override
  String toString() {
    return 'PredictedPlaceModel(placeId: $placeId, text: $fullText)';
  }
}

// Keep old name for backward compatibility during migration  
typedef PredictedPlaces = PredictedPlaceModel;

