import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:btrips_unified/Container/utils/keys.dart';
import 'package:btrips_unified/Model/direction_model.dart';
import 'package:btrips_unified/View/Screens/Main_Screens/Home_Screen/home_providers.dart';

/// Where To Screen - Works on MOBILE, shows message on WEB
/// Web requires backend proxy due to CORS restrictions
class WhereToScreen extends ConsumerStatefulWidget {
  const WhereToScreen({super.key, required this.controller});

  final GoogleMapController controller;

  @override
  ConsumerState<WhereToScreen> createState() => _WhereToScreenState();
}

class _WhereToScreenState extends ConsumerState<WhereToScreen> {
  final TextEditingController _controller = TextEditingController();
  late GoogleMapsPlaces _places;
  List<Prediction> _predictions = [];
  bool _isLoading = false;
  String _error = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      // Only initialize on mobile (works there)
      _places = GoogleMapsPlaces(apiKey: Keys.mapKey);
      debugPrint('✅ GoogleMapsPlaces initialized for mobile');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _searchPlaces(String query) async {
    if (kIsWeb) {
      setState(() {
        _error = 'Web search requires backend. Please use mobile app.';
      });
      return;
    }

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

      final response = await _places.autocomplete(
        query,
        components: [Component(Component.country, "us")],
        language: "en",
      );

      debugPrint('📡 Status: ${response.status}');

      if (response.isOkay) {
        setState(() {
          _predictions = response.predictions;
          _isLoading = false;
        });
        debugPrint('✅ Found ${response.predictions.length} results');
      } else {
        throw Exception('${response.status}: ${response.errorMessage}');
      }
    } catch (e) {
      debugPrint('❌ Error: $e');
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _selectPlace(Prediction prediction) async {
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('📍 Getting details for: ${prediction.description}');

      final response = await _places.getDetailsByPlaceId(prediction.placeId!);

      if (response.isOkay) {
        final result = response.result;
        final lat = result.geometry?.location.lat ?? 0.0;
        final lng = result.geometry?.location.lng ?? 0.0;

        debugPrint('✅ Location: $lat, $lng');

        final direction = Direction(
          locationName: result.name,
          locationId: prediction.placeId!,
          locationLatitude: lat,
          locationLongitude: lng,
          humanReadableAddress: result.formattedAddress,
        );

        ref
            .read(homeScreenDropOffLocationProvider.notifier)
            .update((state) => direction);

        if (mounted) {
          Navigator.of(context).pop();
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
              .copyWith(fontFamily: "bold"),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: kIsWeb ? _buildWebMessage() : _buildMobileSearch(),
        ),
      ),
    );
  }

  // Web: Show message that backend is needed
  Widget _buildWebMessage() {
    return Center(
      child: Card(
        color: Colors.orange[900],
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.web, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                'Web Search Not Available',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Google Places API requires a backend server for web.\n\n'
                'Please use:',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // Switch to preset locations
                  ref.read(homeScreenPresetLocationsModeProvider.notifier)
                      .update((state) => true);
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.flight_takeoff),
                label: const Text('Use Preset Airports'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Or use the mobile app for full search',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Mobile: Full search functionality
  Widget _buildMobileSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          const Row(
            children: [
              CircularProgressIndicator(color: Colors.blue),
              SizedBox(width: 16),
              Text('Searching...'),
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
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _error,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

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
                        style: TextStyle(fontSize: 18),
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
                    return Card(
                      color: Colors.grey[850],
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        onTap: () => _selectPlace(prediction),
                        leading: const Icon(
                          Icons.location_on,
                          color: Colors.blue,
                        ),
                        title: Text(
                          prediction.structuredFormatting?.mainText ??
                              prediction.description ??
                              '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: prediction.structuredFormatting?.secondaryText !=
                                null
                            ? Text(
                                prediction.structuredFormatting!.secondaryText!,
                                style: TextStyle(color: Colors.grey[400]),
                              )
                            : null,
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

