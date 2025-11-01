class PresetLocation {
  final String name;
  final String placeId; // Can be null, will be searched
  final double? latitude;
  final double? longitude;

  PresetLocation({
    required this.name,
    required this.placeId,
    this.latitude,
    this.longitude,
  });

  // Preset airport locations with coordinates
  static List<PresetLocation> get airportLocations => [
    PresetLocation(
      name: "Newark Liberty Airport",
      placeId: "", // Will be resolved if needed
      latitude: 40.6895,
      longitude: -74.1745,
    ),
    PresetLocation(
      name: "New York JFK Airport",
      placeId: "", // Will be resolved if needed
      latitude: 40.6413,
      longitude: -73.7781,
    ),
    PresetLocation(
      name: "New York La Guardia",
      placeId: "", // Will be resolved if needed
      latitude: 40.7769,
      longitude: -73.8740,
    ),
    PresetLocation(
      name: "Philadelphia Airport",
      placeId: "", // Will be resolved if needed
      latitude: 39.8719,
      longitude: -75.2411,
    ),
  ];
}

