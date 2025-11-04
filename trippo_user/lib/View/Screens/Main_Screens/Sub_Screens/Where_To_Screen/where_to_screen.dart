import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:btrips_unified/Container/utils/keys.dart';
import 'package:btrips_unified/Model/direction_model.dart';
import 'package:btrips_unified/View/Screens/Main_Screens/Home_Screen/home_providers.dart';
import 'package:btrips_unified/View/Screens/Main_Screens/Home_Screen/home_logics.dart';
import 'package:btrips_unified/data/models/favorite_place_model.dart';
import 'package:btrips_unified/data/providers/favorite_places_providers.dart';
import 'package:btrips_unified/data/providers/auth_providers.dart';
import 'package:btrips_unified/data/repositories/favorite_places_repository.dart';

/// Where To Screen - Works on ALL platforms!
/// - Web: Uses Cloud Functions to bypass CORS
/// - Mobile: Uses google_maps_webservice package directly
class WhereToScreen extends ConsumerStatefulWidget {
  const WhereToScreen({super.key, required this.controller});

  final GoogleMapController controller;

  @override
  ConsumerState<WhereToScreen> createState() => _WhereToScreenState();
}

class _WhereToScreenState extends ConsumerState<WhereToScreen> {
  final TextEditingController _controller = TextEditingController();
  GoogleMapsPlaces? _places; // For mobile
  FirebaseFunctions? _functions; // For web
  List<Map<String, dynamic>> _predictions = [];
  Map<int, String> _distances = {}; // Store calculated distances
  Set<String> _favoritedPlaceIds = {}; // Track which places are favorited
  bool _isLoading = false;
  String _error = '';
  Timer? _debounceTimer;
  bool _showFavorites = false; // Toggle between search and favorites view

  /// Add place to favorites
  Future<void> _addToFavorites(Map<String, dynamic> prediction) async {
    final userAsync = ref.read(currentUserProvider);
    final user = userAsync.value;
    if (user == null) return;

    final placeId = prediction['place_id'] as String;
    final name = prediction['structured_formatting']?['main_text'] ?? 
                 prediction['description'] ?? '';
    final address = prediction['structured_formatting']?['secondary_text'] ?? 
                    prediction['description'] ?? '';

    // Get coordinates if we have them cached
    double? lat = prediction['_latitude'];
    double? lng = prediction['_longitude'];

    // If not cached, fetch them
    if (lat == null || lng == null) {
      try {
        final details = await _getPlaceCoordinates(placeId);
        lat = details['latitude'];
        lng = details['longitude'];
      } catch (e) {
        debugPrint('❌ Error getting coordinates: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not save favorite')),
          );
        }
        return;
      }
    }

    final success = await ref.read(favoritePlacesRepositoryProvider).addFavorite(
          userId: user.uid,
          name: name,
          address: address,
          placeId: placeId,
          latitude: lat!,
          longitude: lng!,
        );

    if (mounted) {
      if (success) {
        setState(() {
          _favoritedPlaceIds.add(placeId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⭐ Added "$name" to favorites'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Already in favorites')),
        );
      }
    }
  }

  /// Remove from favorites (with confirmation)
  Future<void> _removeFromFavorites(String favoriteId, String name, {bool showConfirmation = true}) async {
    // Show confirmation dialog
    if (showConfirmation) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Remove Favorite?',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Remove "$name" from your favorites?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.orange),
              child: const Text('Remove'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    final success = await ref.read(favoritePlacesRepositoryProvider).removeFavorite(favoriteId);

    if (mounted && success) {
      setState(() {
        // Remove from local set immediately for UI responsiveness
        final placeIds = _favoritedPlaceIds.toList();
        placeIds.removeWhere((id) {
          // Find the matching place ID (need to look it up from favorites)
          return true; // This will be refined below
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Removed "$name" from favorites'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );

      // Reload favorited IDs to sync
      _loadFavoritedPlaceIds();
    }
  }

  /// Remove favorite by place ID (from search results)
  Future<void> _removeFavoriteByPlaceId(String placeId, String name) async {
    final userAsync = ref.read(currentUserProvider);
    final user = userAsync.value;
    if (user == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Remove Favorite?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Remove "$name" from your favorites?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Find the favorite by placeId
    try {
      final favorite = await ref
          .read(favoritePlacesRepositoryProvider)
          .getFavoriteByPlaceId(user.uid, placeId);

      if (favorite?.id != null) {
        final success = await ref
            .read(favoritePlacesRepositoryProvider)
            .removeFavorite(favorite!.id!);

        if (mounted && success) {
          setState(() {
            _favoritedPlaceIds.remove(placeId);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ Removed "$name" from favorites'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error removing favorite: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to remove favorite'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Get coordinates for a place
  Future<Map<String, dynamic>> _getPlaceCoordinates(String placeId) async {
    if (kIsWeb) {
      final result = await _functions!
          .httpsCallable('placeDetails')
          .call({'placeId': placeId});
      return Map<String, dynamic>.from(result.data);
    } else {
      final response = await _places!.getDetailsByPlaceId(placeId);
      if (response.isOkay) {
        return {
          'success': true,
          'latitude': response.result.geometry?.location.lat ?? 0.0,
          'longitude': response.result.geometry?.location.lng ?? 0.0,
          'name': response.result.name,
          'address': response.result.formattedAddress,
        };
      }
      throw Exception('Failed to get place details');
    }
  }

  /// Select a favorite place
  Future<void> _selectFavorite(FavoritePlaceModel favorite) async {
    final direction = Direction(
      locationName: favorite.displayName,
      locationId: favorite.placeId,
      locationLatitude: favorite.latitude,
      locationLongitude: favorite.longitude,
      humanReadableAddress: favorite.address,
    );

    ref
        .read(homeScreenDropOffLocationProvider.notifier)
        .update((state) => direction);

    // Recalculate route and fare
    if (mounted && ref.read(homeScreenPickUpLocationProvider) != null) {
      debugPrint('🔄 Favorite location selected: ${favorite.displayName}');
      await HomeScreenLogics().refreshRouteAndFare(context, ref, widget.controller);
    }

    // Increment use count
    if (favorite.id != null) {
      await ref.read(favoritePlacesRepositoryProvider).incrementUseCount(favorite.id!);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  /// Calculate distance between two coordinates using Haversine formula
  /// Returns distance in miles
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusMiles = 3958.8; // Earth's radius in miles
    
    final dLat = (lat2 - lat1) * pi / 180.0;
    final dLon = (lon2 - lon1) * pi / 180.0;
    
    final lat1Rad = lat1 * pi / 180.0;
    final lat2Rad = lat2 * pi / 180.0;
    
    final a = pow(sin(dLat / 2), 2) +
        pow(sin(dLon / 2), 2) * cos(lat1Rad) * cos(lat2Rad);
    
    final c = 2 * asin(sqrt(a));
    
    return earthRadiusMiles * c;
  }
  
  String _formatDistance(double miles) {
    if (miles < 0.1) {
      final feet = (miles * 5280).round();
      return '$feet ft';
    } else if (miles < 1) {
      return '${(miles * 5280).round()} ft';
    } else {
      return '${miles.toStringAsFixed(1)} mi';
    }
  }
  
  /// Calculate distances from pickup location to predictions
  /// Fetches place details in background to get coordinates and sorts by distance
  Future<void> _calculateDistances() async {
    final pickupLocation = ref.read(homeScreenPickUpLocationProvider);
    if (pickupLocation == null) {
      debugPrint('⚠️  No pickup location set, skipping distance calculation');
      return;
    }
    
    final pickupLat = pickupLocation.locationLatitude ?? 0;
    final pickupLng = pickupLocation.locationLongitude ?? 0;
    
    debugPrint('📍 Calculating distances from pickup: $pickupLat, $pickupLng');
    
    // Store distances with raw values for sorting
    final Map<int, double> rawDistances = {};
    final Map<int, String> formattedDistances = {};
    
    // Calculate distances for all results
    for (var i = 0; i < _predictions.length; i++) {
      final placeId = _predictions[i]['place_id'] as String?;
      if (placeId == null) continue;
      
      try {
        if (kIsWeb) {
          // Web: Get coordinates via Cloud Function
          final result = await _functions!
              .httpsCallable('placeDetails')
              .call({'placeId': placeId});
          
          final data = Map<String, dynamic>.from(result.data);
          if (data['success'] == true) {
            final destLat = data['latitude'] as double;
            final destLng = data['longitude'] as double;
            
            final distanceMiles = _calculateDistance(pickupLat, pickupLng, destLat, destLng);
            rawDistances[i] = distanceMiles;
            formattedDistances[i] = _formatDistance(distanceMiles);
            
            // Store coordinates in prediction for later use
            _predictions[i]['_latitude'] = destLat;
            _predictions[i]['_longitude'] = destLng;
          }
        } else {
          // Mobile: Get coordinates directly
          final response = await _places!.getDetailsByPlaceId(placeId);
          if (response.isOkay) {
            final destLat = response.result.geometry?.location.lat ?? 0;
            final destLng = response.result.geometry?.location.lng ?? 0;
            
            final distanceMiles = _calculateDistance(pickupLat, pickupLng, destLat, destLng);
            rawDistances[i] = distanceMiles;
            formattedDistances[i] = _formatDistance(distanceMiles);
            
            // Store coordinates in prediction for later use
            _predictions[i]['_latitude'] = destLat;
            _predictions[i]['_longitude'] = destLng;
          }
        }
      } catch (e) {
        debugPrint('⚠️  Error calculating distance for index $i: $e');
        // Set high distance for failed calculations (will sort to bottom)
        rawDistances[i] = 999999;
        formattedDistances[i] = 'N/A';
      }
    }
    
    // Sort predictions by distance (nearest first)
    if (rawDistances.isNotEmpty && mounted) {
      debugPrint('📊 Sorting ${_predictions.length} results by distance...');
      
      // Create list of indices with their distances
      final List<MapEntry<int, double>> sortedIndices = rawDistances.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      
      // Reorder predictions based on sorted distances
      final sortedPredictions = <Map<String, dynamic>>[];
      final sortedDistances = <int, String>{};
      
      for (var i = 0; i < sortedIndices.length; i++) {
        final originalIndex = sortedIndices[i].key;
        sortedPredictions.add(_predictions[originalIndex]);
        sortedDistances[i] = formattedDistances[originalIndex]!;
        
        if (i < 5) {
          final placeName = _predictions[originalIndex]['structured_formatting']?['main_text'] ?? 
                           _predictions[originalIndex]['description'] ?? 'Place';
          debugPrint('   ${i + 1}. $placeName - ${formattedDistances[originalIndex]}');
        }
      }
      
      setState(() {
        _predictions = sortedPredictions;
        _distances = sortedDistances;
      });
      
      debugPrint('✅ Results sorted by distance (nearest first)');
    }
  }

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // Web: Use Cloud Functions
      _functions = FirebaseFunctions.instance;
      debugPrint('✅ Using Cloud Functions for web');
    } else {
      // Mobile: Use direct API
      _places = GoogleMapsPlaces(apiKey: Keys.mapKey);
      debugPrint('✅ Using GoogleMapsPlaces for mobile');
    }
    
    // Load favorited place IDs
    _loadFavoritedPlaceIds();
  }

  /// Load IDs of all favorited places
  Future<void> _loadFavoritedPlaceIds() async {
    final userAsync = ref.read(currentUserProvider);
    final user = userAsync.value;
    if (user == null) return;

    try {
      final favorites = await ref
          .read(favoritePlacesRepositoryProvider)
          .getUserFavoritesList(user.uid);

      setState(() {
        _favoritedPlaceIds = favorites.map((f) => f.placeId).toSet();
      });
      
      debugPrint('✅ Loaded ${_favoritedPlaceIds.length} favorited place IDs');
    } catch (e) {
      debugPrint('❌ Error loading favorites: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty || query.length < 2) {
      setState(() {
        _predictions = [];
        _error = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      debugPrint('🔍 Searching for: "$query"');

      if (kIsWeb) {
        // Web: Call Cloud Function
        debugPrint('🌐 Web: Calling placesAutocomplete Cloud Function');
        
        final result = await _functions!
            .httpsCallable('placesAutocomplete')
            .call({
              'input': query,
              'country': 'us',
              'language': 'en',
            });

        final response = Map<String, dynamic>.from(result.data);
        
        if (response['success'] == true) {
          final predictions = (response['predictions'] as List)
              .cast<Map<String, dynamic>>();
          
          debugPrint('✅ Got ${predictions.length} predictions from Cloud Function');
          
          setState(() {
            _predictions = predictions;
            _isLoading = false;
          });
          
          // Calculate distances (will be done when we have coordinates)
          _calculateDistances();
        } else {
          throw Exception('Cloud Function returned success: false');
        }
      } else {
        // Mobile: Direct API call
        debugPrint('📱 Mobile: Calling GoogleMapsPlaces');
        
        final response = await _places!.autocomplete(
          query,
          components: [Component(Component.country, "us")],
          language: "en",
        );

        debugPrint('📡 Status: ${response.status}');

        if (response.isOkay) {
          debugPrint('✅ Got ${response.predictions.length} predictions');
          
          setState(() {
            _predictions = response.predictions.map((p) => {
              'description': p.description,
              'place_id': p.placeId,
              'structured_formatting': {
                'main_text': p.structuredFormatting?.mainText ?? '',
                'secondary_text': p.structuredFormatting?.secondaryText ?? '',
              },
            }).toList();
            _isLoading = false;
          });
          
          // Calculate distances
          _calculateDistances();
        } else {
          throw Exception('${response.status}: ${response.errorMessage}');
        }
      }
    } catch (e) {
      debugPrint('❌ Search error: $e');
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _selectPlace(Map<String, dynamic> prediction) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final placeId = prediction['place_id'] as String;
      debugPrint('📍 Getting details for: $placeId');

      if (kIsWeb) {
        // Web: Call Cloud Function
        debugPrint('🌐 Web: Calling placeDetails Cloud Function');
        
        final result = await _functions!
            .httpsCallable('placeDetails')
            .call({'placeId': placeId});

        final response = Map<String, dynamic>.from(result.data);
        
        if (response['success'] == true) {
          final direction = Direction(
            locationName: response['name'],
            locationId: placeId,
            locationLatitude: response['latitude'],
            locationLongitude: response['longitude'],
            humanReadableAddress: response['address'],
          );

          debugPrint('✅ Location: ${response['latitude']}, ${response['longitude']}');

          ref
              .read(homeScreenDropOffLocationProvider.notifier)
              .update((state) => direction);

          // Recalculate route and fare
          if (mounted && ref.read(homeScreenPickUpLocationProvider) != null) {
            debugPrint('🔄 Search location selected (web): ${response['name']}');
            await HomeScreenLogics().refreshRouteAndFare(context, ref, widget.controller);
          }

          if (mounted) {
            Navigator.of(context).pop();
          }
        } else {
          throw Exception('Cloud Function returned success: false');
        }
      } else {
        // Mobile: Direct API call
        debugPrint('📱 Mobile: Getting place details');
        
        final response = await _places!.getDetailsByPlaceId(placeId);

        if (response.isOkay) {
          final result = response.result;
          final lat = result.geometry?.location.lat ?? 0.0;
          final lng = result.geometry?.location.lng ?? 0.0;

          debugPrint('✅ Location: $lat, $lng');

          final direction = Direction(
            locationName: result.name,
            locationId: placeId,
            locationLatitude: lat,
            locationLongitude: lng,
            humanReadableAddress: result.formattedAddress,
          );

          ref
              .read(homeScreenDropOffLocationProvider.notifier)
              .update((state) => direction);

          // Recalculate route and fare
          if (mounted && ref.read(homeScreenPickUpLocationProvider) != null) {
            debugPrint('🔄 Search location selected: ${result.name}');
            await HomeScreenLogics().refreshRouteAndFare(context, ref, widget.controller);
          }

          if (mounted) {
            Navigator.of(context).pop();
          }
        } else {
          throw Exception('${response.status}: ${response.errorMessage}');
        }
      }
    } catch (e) {
      debugPrint('❌ Error getting details: $e');
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onTextChanged(String text) {
    _debounceTimer?.cancel();

    if (text.length < 2) {
      setState(() {
        _predictions = [];
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      _searchPlaces(text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: const Color(0xff1a3646),
        backgroundColor: const Color(0xff1a3646),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Where To Go",
          style: Theme.of(context)
              .textTheme
              .bodySmall!
              .copyWith(fontFamily: "bold", color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Toggle between Search and Favorites
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _showFavorites = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !_showFavorites ? Colors.blue : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: !_showFavorites ? Colors.blue : Colors.grey,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search,
                              size: 18,
                              color: !_showFavorites ? Colors.white : Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Search',
                              style: TextStyle(
                                color: !_showFavorites ? Colors.white : Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _showFavorites = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _showFavorites ? Colors.amber : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _showFavorites ? Colors.amber : Colors.grey,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.star,
                              size: 18,
                              color: _showFavorites ? Colors.white : Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Favorites',
                              style: TextStyle(
                                color: _showFavorites ? Colors.white : Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Show Search or Favorites based on toggle
              if (!_showFavorites) ...[
                // Search Field
              TextField(
                controller: _controller,
                onChanged: _onTextChanged,
                autofocus: true,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                      decoration: InputDecoration(
                  hintText: 'Search places (e.g., "Target", "Starbucks")',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.search, color: Colors.blue),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _controller.clear();
                            setState(() {
                              _predictions = [];
                              _error = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey[850],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                          enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[700]!),
                  ),
                          focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Status/Error
              if (_isLoading)
                Row(
                  children: [
                    const CircularProgressIndicator(color: Colors.blue),
                    const SizedBox(width: 16),
                    Text(
                      kIsWeb ? 'Calling Cloud Function...' : 'Searching...',
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ],
                ),

              if (_error.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 8),

              // Results
              Expanded(
                child: _predictions.isEmpty && !_isLoading && _error.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search, size: 80, color: Colors.grey[600]),
                            const SizedBox(height: 16),
                            const Text(
                              'Search for a location',
                              style: TextStyle(fontSize: 18, color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Type at least 2 characters',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _predictions.length,
                        itemBuilder: (context, index) {
                          final prediction = _predictions[index];
                          final mainText = prediction['structured_formatting']
                                  ?['main_text'] ??
                              prediction['description'] ??
                              '';
                          final secondaryText =
                              prediction['structured_formatting']
                                  ?['secondary_text'] ??
                              '';
                          final distance = _distances[index];
                          final isNearest = index == 0 && distance != null && distance != 'N/A';
                          final placeId = prediction['place_id'] as String?;
                          final isFavorited = placeId != null && _favoritedPlaceIds.contains(placeId);

                          return Card(
                            color: isNearest ? Colors.green[900]?.withOpacity(0.3) : Colors.grey[850],
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              onTap: () => _selectPlace(prediction),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              leading: Stack(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: isNearest ? Colors.green : Colors.blue,
                                    size: 28,
                                  ),
                                  if (isNearest)
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.star,
                                          size: 10,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              title: Text(
                                mainText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (secondaryText.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                        secondaryText,
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  if (distance != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.route,
                                            size: 14,
                                            color: isNearest ? Colors.green[300] : Colors.blue[300],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            distance,
                                            style: TextStyle(
                                              color: isNearest ? Colors.green[300] : Colors.blue[300],
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            isNearest ? 'nearest' : 'from pickup',
                                            style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 11,
                                            ),
                                          ),
                                          if (isNearest)
                                            Padding(
                                              padding: const EdgeInsets.only(left: 6),
                                              child: Icon(
                                                Icons.star,
                                                size: 12,
                                                color: Colors.green[300],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Favorite button
                                  IconButton(
                                    icon: Icon(
                                      isFavorited ? Icons.star : Icons.star_border,
                                      color: isFavorited ? Colors.amber : Colors.grey,
                                      size: 24,
                                    ),
                                    tooltip: isFavorited ? 'Remove from favorites' : 'Add to favorites',
                                    onPressed: () {
                                      if (isFavorited) {
                                        // Remove from favorites
                                        _removeFavoriteByPlaceId(placeId!, mainText);
                                      } else {
                                        // Add to favorites
                                        _addToFavorites(prediction);
                                      }
                                    },
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                ),
              ],
              
              // Favorites View
              if (_showFavorites)
                Expanded(
                  child: ref.watch(userFavoritePlacesProvider).when(
                    data: (favorites) {
                      if (favorites.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.star_border,
                                size: 80,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No Favorite Places Yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Search for places and tap ⭐ to save favorites',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _showFavorites = false;
                                  });
                                },
                                icon: const Icon(Icons.search),
                                label: const Text('Search for Places'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: favorites.length,
                        itemBuilder: (context, index) {
                          final favorite = favorites[index];
                          return Card(
                            color: Colors.grey[850],
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: Dismissible(
                              key: Key(favorite.id!),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: Colors.red[900],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.delete, color: Colors.white, size: 32),
                                    SizedBox(height: 4),
                                    Text(
                                      'Remove',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              confirmDismiss: (direction) async {
                                return await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: Colors.grey[900],
                                    title: const Text(
                                      'Remove Favorite?',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    content: Text(
                                      'Remove "${favorite.displayName}" from your favorites?',
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                                        child: const Text('Remove'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              onDismissed: (direction) {
                                _removeFromFavorites(
                                  favorite.id!,
                                  favorite.displayName,
                                  showConfirmation: false, // Already confirmed in confirmDismiss
                                );
                              },
                              child: ListTile(
                              onTap: () => _selectFavorite(favorite),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              leading: Stack(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: Colors.amber,
                                    size: 32,
                                  ),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.amber,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.star,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    favorite.categoryIcon,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      favorite.displayName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    favorite.address,
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.history,
                                        size: 14,
                                        color: Colors.grey[500],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Used ${favorite.useCount} times',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Delete button
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: 22,
                                    ),
                                    tooltip: 'Remove from favorites',
                                    onPressed: () => _removeFromFavorites(
                                      favorite.id!,
                                      favorite.displayName,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Colors.amber,
                                  ),
                                ],
                              ),
                            ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: Colors.amber),
                    ),
                    error: (error, stack) {
                      debugPrint('❌ Favorites error: $error');
                      debugPrint('Stack trace: $stack');
                      
                      // Check if it's a composite index error
                      final errorString = error.toString();
                      final isIndexError = errorString.contains('index') || 
                                          errorString.contains('FAILED_PRECONDITION') ||
                                          errorString.contains('composite');
                      
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isIndexError ? Icons.hourglass_empty : Icons.error_outline,
                                size: 64,
                                color: isIndexError ? Colors.orange : Colors.red[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                isIndexError 
                                    ? 'Building Index...' 
                                    : 'Error Loading Favorites',
                                style: TextStyle(
                                  color: isIndexError ? Colors.orange : Colors.red[400],
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                isIndexError
                                    ? 'Database index is being created.\nThis takes 5-10 minutes.\nPlease try again shortly.'
                                    : 'Something went wrong',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () {
                                  // Refresh the provider
                                  ref.invalidate(userFavoritePlacesProvider);
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Try Again'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isIndexError ? Colors.orange : Colors.blue,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                              if (!isIndexError) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'Error: $error',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
