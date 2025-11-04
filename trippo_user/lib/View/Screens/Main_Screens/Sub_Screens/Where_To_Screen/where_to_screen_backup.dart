import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:btrips_unified/Container/utils/keys.dart';
import 'package:btrips_unified/Container/utils/google_places_stub.dart'
    if (dart.library.html) 'package:btrips_unified/Container/utils/google_places_web.dart';
import 'package:btrips_unified/Model/direction_model.dart';
import 'package:btrips_unified/Model/predicted_places.dart';
import 'package:btrips_unified/View/Screens/Main_Screens/Home_Screen/home_providers.dart';

class WhereToScreen extends ConsumerStatefulWidget {
  const WhereToScreen({super.key, required this.controller});

  final GoogleMapController controller;

  @override
  ConsumerState<WhereToScreen> createState() => _WhereToScreenState();
}

class _WhereToScreenState extends ConsumerState<WhereToScreen> {
  final TextEditingController whereToController = TextEditingController();
  Timer? _debounceTimer;
  List<PredictedPlaces> _predictions = [];
  bool _isLoading = false;

  @override
  void dispose() {
    whereToController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // Web: Use JavaScript API (no CORS proxy needed)
  Future<void> _searchPlacesWeb(String text) async {
    if (text.length < 2) {
      setState(() {
        _predictions = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('🌐 Web: Using JavaScript API (no proxy)');
      final predictions = await GooglePlacesWeb.getPlacePredictions(
        text,
        Keys.mapKey,
      );

      setState(() {
        _predictions = predictions
            .map((e) => PredictedPlaces.fromJson(e))
            .toList();
        _isLoading = false;
      });
      
      debugPrint('✅ Got ${_predictions.length} predictions');
    } catch (e) {
      debugPrint('❌ Error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onTextChangedWeb(String text) {
    _debounceTimer?.cancel();
    
    if (text.length < 2) {
      setState(() {
        _predictions = [];
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      _searchPlacesWeb(text);
    });
  }

  Future<void> _selectPlaceWeb(PredictedPlaces place) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final placeData = await GooglePlacesWeb.getPlaceDetails(place.placeId!);
      final result = placeData?["result"];
      
      if (result != null) {
        final direction = Direction(
          locationName: result["name"],
          locationId: place.placeId!,
          locationLatitude: result["geometry"]["location"]["lat"],
          locationLongitude: result["geometry"]["location"]["lng"],
        );

        ref
            .read(homeScreenDropOffLocationProvider.notifier)
            .update((state) => direction);

        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      debugPrint('❌ Error getting place details: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
          child: kIsWeb ? _buildWebSearch() : _buildMobileSearch(),
        ),
      ),
    );
  }

  // Web: Custom implementation using JavaScript API (NO PROXY)
  Widget _buildWebSearch() {
    return Column(
      children: [
        TextField(
          controller: whereToController,
          onChanged: _onTextChangedWeb,
          style: Theme.of(context)
              .textTheme
              .bodySmall!
              .copyWith(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Search location...",
            hintStyle: Theme.of(context)
                .textTheme
                .bodySmall!
                .copyWith(color: Colors.grey[400]),
            prefixIcon: const Icon(Icons.search, color: Colors.blue),
            suffixIcon: whereToController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      whereToController.clear();
                      setState(() {
                        _predictions = [];
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.grey[850],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue),
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
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.blue),
                )
              : _predictions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search, size: 64, color: Colors.grey[600]),
                          const SizedBox(height: 16),
                          Text(
                            whereToController.text.isEmpty
                                ? 'Search for a location'
                                : 'No results found',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge!
                                .copyWith(color: Colors.grey[400]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            whereToController.text.isEmpty
                                ? 'Type in the search box above'
                                : 'Try a different search term',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall!
                                .copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: _predictions.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: Colors.grey[800],
                      ),
                      itemBuilder: (context, index) {
                        final place = _predictions[index];
                        return ListTile(
                          onTap: () => _selectPlaceWeb(place),
                          leading: const Icon(
                            Icons.location_on,
                            color: Colors.blue,
                            size: 24,
                          ),
                          title: Text(
                            place.mainText ?? place.secText ?? '',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(color: Colors.white),
                          ),
                          subtitle: place.secText != null
                              ? Text(
                                  place.secText!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall!
                                      .copyWith(color: Colors.grey[400]),
                                )
                              : null,
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          tileColor: Colors.grey[900],
                        );
                      },
                    ),
        ),
      ],
    );
  }

  // Mobile: Use google_places_flutter package (works great, no proxy needed)
  Widget _buildMobileSearch() {
    return Column(
      children: [
        GooglePlaceAutoCompleteTextField(
          textEditingController: whereToController,
          googleAPIKey: Keys.mapKey,
          inputDecoration: InputDecoration(
            hintText: "Search location...",
            hintStyle: Theme.of(context)
                .textTheme
                .bodySmall!
                .copyWith(color: Colors.grey[400]),
            prefixIcon: const Icon(Icons.search, color: Colors.blue),
            suffixIcon: whereToController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      whereToController.clear();
                      setState(() {});
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.grey[850],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue),
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
          debounceTime: 800,
          countries: const ["us"], // USA
          isLatLngRequired: true,
          getPlaceDetailWithLatLng: (Prediction prediction) {
            debugPrint('✅ Place selected: ${prediction.description}');
            debugPrint('📍 Coordinates: ${prediction.lat}, ${prediction.lng}');
            
            final direction = Direction(
              locationName: prediction.description ?? '',
              locationId: prediction.placeId ?? '',
              locationLatitude: double.tryParse(prediction.lat ?? '0') ?? 0,
              locationLongitude: double.tryParse(prediction.lng ?? '0') ?? 0,
            );

            ref
                .read(homeScreenDropOffLocationProvider.notifier)
                .update((state) => direction);

            Navigator.of(context).pop();
          },
          itemClick: (Prediction prediction) {
            whereToController.text = prediction.description ?? "";
            whereToController.selection = TextSelection.fromPosition(
              TextPosition(offset: prediction.description?.length ?? 0),
            );
          },
          seperatedBuilder: Divider(
            height: 1,
            color: Colors.grey[800],
          ),
          containerHorizontalPadding: 0,
          itemBuilder: (context, index, Prediction prediction) {
            return Container(
              padding: const EdgeInsets.all(15),
              color: Colors.grey[900],
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Colors.blue,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prediction.structuredFormatting?.mainText ?? 
                          prediction.description ?? '',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(color: Colors.white),
                        ),
                        if (prediction.structuredFormatting?.secondaryText != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              prediction.structuredFormatting!.secondaryText!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall!
                                  .copyWith(color: Colors.grey[400]),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          isCrossBtnShown: false,
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search,
                  size: 64,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 16),
                Text(
                  'Search for a location',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge!
                      .copyWith(color: Colors.grey[400]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Type in the search box above',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
