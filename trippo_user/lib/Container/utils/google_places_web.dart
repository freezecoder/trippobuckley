// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
// This file is conditionally imported only on web platform (kIsWeb check in repositories).
// dart:js and dart:js_util are deprecated but dart:js_interop migration requires Dart 3.3+ and significant refactoring.
// The current implementation works correctly and will be migrated in a future update.
import 'dart:async';
import 'dart:js' as js;
import 'dart:js_util' as js_util;
import 'package:flutter/foundation.dart';

/// Web-specific implementation using Google Places JavaScript API
/// This bypasses CORS issues by using the JavaScript API directly
class GooglePlacesWeb {

  /// Check if Google Maps API is fully loaded with all required libraries
  static bool _isGoogleMapsLoaded() {
    try {
      // Access window object
      final window = js.context;
      
      // Check if callback was triggered
      final callbackTriggered = js_util.getProperty(window, 'googleMapsReady') == true;
      
      // Check for google object
      final google = js_util.getProperty(window, 'google');
      if (google == null) {
        return false;
      }

      // Check for maps
      final maps = js_util.getProperty(google as js.JsObject, 'maps');
      if (maps == null) {
        return false;
      }
      
      final mapsObj = maps as js.JsObject;
      
      // Check for required APIs: places, DirectionsService, Geocoder
      final places = js_util.getProperty(mapsObj, 'places');
      final directionsService = js_util.getProperty(mapsObj, 'DirectionsService');
      final geocoder = js_util.getProperty(mapsObj, 'Geocoder');
      final latLng = js_util.getProperty(mapsObj, 'LatLng');
      
      final hasPlaces = places != null;
      final hasDirections = directionsService != null;
      final hasGeocoder = geocoder != null;
      final hasLatLng = latLng != null;

      if (hasPlaces && hasDirections && hasGeocoder && hasLatLng) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Wait for Google Maps API to be loaded with all required libraries
  static Future<void> _waitForGoogleMaps() async {
    if (_isGoogleMapsLoaded()) {
      debugPrint('✅ Google Maps API already loaded');
      return;
    }

    debugPrint('⏳ Waiting for Google Maps API to load...');
    
    // Wait up to 15 seconds for Google Maps to load
    for (int i = 0; i < 150; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (_isGoogleMapsLoaded()) {
        debugPrint('✅ Google Maps API loaded after ${(i + 1) * 100}ms');
        return;
      }
      
      // Log progress every 2 seconds
      if (i > 0 && (i + 1) % 20 == 0) {
        debugPrint('⏳ Still waiting... ${(i + 1) * 100}ms elapsed');
      }
    }

    // Final check - throw exception if still not loaded
    if (!_isGoogleMapsLoaded()) {
      debugPrint('❌ Google Maps API failed to load after 15 seconds');
      debugPrint('💡 Check that web/index.html includes:');
      debugPrint('   <script src="https://maps.googleapis.com/maps/api/js?key=YOUR_KEY&libraries=places,geometry,drawing&callback=googleMapsLoaded"></script>');
      throw Exception('Google Maps API not loaded after 15 seconds. Make sure the script is loaded in index.html with libraries=places,geometry,drawing and a callback function');
    }
  }

  /// Get place predictions using JavaScript API
  static Future<List<Map<String, dynamic>>> getPlacePredictions(
    String input,
    String apiKey,
  ) async {
    if (!kIsWeb) {
      throw UnsupportedError('This method is only for web platform');
    }

    await _waitForGoogleMaps();

    try {
      // Verify API is loaded before using
      if (!_isGoogleMapsLoaded()) {
        throw Exception('Google Maps API not loaded after wait');
      }
      
      final completer = Completer<List<Map<String, dynamic>>>();
      
      // Access Google Maps API using safe property access
      final window = js.context;
      final google = js_util.getProperty(window, 'google') as js.JsObject?;
      if (google == null) throw Exception('Google object not found');
      
      final maps = js_util.getProperty(google, 'maps') as js.JsObject?;
      if (maps == null) throw Exception('Maps object not found');
      
      final places = js_util.getProperty(maps, 'places');
      if (places == null) throw Exception('Places API not found');
      
      // Create AutocompleteService instance
      // ignore: non_constant_identifier_names
      // AutocompleteService matches the Google Maps JavaScript API class name
      final autocompleteServiceClass = js_util.getProperty(places, 'AutocompleteService');
      final autocompleteService = js.JsObject(autocompleteServiceClass);
      
      final request = js.JsObject.jsify({
        'input': input,
        'componentRestrictions': {'country': 'pk'},
      });

      // Call getPlacePredictions
      js_util.callMethod(autocompleteService, 'getPlacePredictions', [
        request,
        js.allowInterop((predictions, status) {
          if (status == 'OK' && predictions != null) {
            final List<Map<String, dynamic>> results = [];
            final jsList = js.JsArray.from(predictions as js.JsArray);
            
            for (int i = 0; i < jsList.length; i++) {
              final prediction = jsList[i] as js.JsObject;
              final structuredFormatting = js_util.getProperty(prediction, 'structured_formatting');
              
              results.add({
                'description': js_util.getProperty(prediction, 'description') ?? '',
                'place_id': js_util.getProperty(prediction, 'place_id') ?? '',
                'structured_formatting': {
                  'main_text': structuredFormatting != null 
                      ? js_util.getProperty(structuredFormatting as js.JsObject, 'main_text') ?? ''
                      : '',
                  'secondary_text': structuredFormatting != null
                      ? js_util.getProperty(structuredFormatting as js.JsObject, 'secondary_text') ?? ''
                      : '',
                },
              });
            }
            completer.complete(results);
          } else {
            completer.completeError(Exception('Places API status: $status'));
          }
        }),
      ]);

      return completer.future;
    } catch (e) {
      debugPrint('Error getting place predictions: $e');
      rethrow;
    }
  }

  /// Get place details using JavaScript API
  static Future<Map<String, dynamic>> getPlaceDetails(String placeId) async {
    if (!kIsWeb) {
      throw UnsupportedError('This method is only for web platform');
    }

    await _waitForGoogleMaps();

    try {
      // Verify API is loaded before using
      if (!_isGoogleMapsLoaded()) {
        throw Exception('Google Maps API not loaded after wait');
      }
      
      final completer = Completer<Map<String, dynamic>>();
      
      // Access Google Maps API using safe property access
      final window = js.context;
      final google = js_util.getProperty(window, 'google') as js.JsObject?;
      if (google == null) throw Exception('Google object not found');
      
      final maps = js_util.getProperty(google, 'maps') as js.JsObject?;
      if (maps == null) throw Exception('Maps object not found');
      
      final places = js_util.getProperty(maps, 'places');
      if (places == null) throw Exception('Places API not found');
      
      // Create PlacesService instance with a dummy div (required by API)
      // ignore: non_constant_identifier_names
      // PlacesService matches the Google Maps JavaScript API class name
      final placesServiceClass = js_util.getProperty(places, 'PlacesService');
      final dummyDiv = js.context.callMethod('document.createElement', ['div']);
      final placesService = js.JsObject(placesServiceClass, [dummyDiv]);
      
      final request = js.JsObject.jsify({
        'placeId': placeId,
        'fields': ['name', 'geometry', 'formatted_address'],
      });

      // Call getDetails
      js_util.callMethod(placesService, 'getDetails', [
        request,
        js.allowInterop((place, status) {
          if (status == 'OK' && place != null) {
            final placeObj = place as js.JsObject;
            final geometry = js_util.getProperty(placeObj, 'geometry') as js.JsObject?;
            final location = geometry != null 
                ? js_util.getProperty(geometry, 'location') as js.JsObject?
                : null;
            
            double lat = 0.0;
            double lng = 0.0;
            if (location != null) {
              final latMethod = js_util.getProperty(location, 'lat');
              final lngMethod = js_util.getProperty(location, 'lng');
              lat = latMethod is js.JsFunction 
                  ? (js_util.callMethod(location, 'lat', []) as num).toDouble()
                  : (latMethod as num?)?.toDouble() ?? 0.0;
              lng = lngMethod is js.JsFunction
                  ? (js_util.callMethod(location, 'lng', []) as num).toDouble()
                  : (lngMethod as num?)?.toDouble() ?? 0.0;
            }
            
            completer.complete({
              'result': {
                'name': js_util.getProperty(placeObj, 'name') ?? '',
                'geometry': {
                  'location': {
                    'lat': lat,
                    'lng': lng,
                  },
                },
                'formatted_address': js_util.getProperty(placeObj, 'formatted_address') ?? '',
              },
            });
          } else {
            completer.completeError(Exception('Places API status: $status'));
          }
        }),
      ]);

      return completer.future;
    } catch (e) {
      debugPrint('Error getting place details: $e');
      rethrow;
    }
  }

  /// Reverse geocode coordinates to address using JavaScript API
  static Future<Map<String, dynamic>> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    if (!kIsWeb) {
      throw UnsupportedError('This method is only for web platform');
    }

    await _waitForGoogleMaps();

    try {
      // Verify API is loaded before using
      if (!_isGoogleMapsLoaded()) {
        throw Exception('Google Maps API not loaded after wait');
      }
      
      final completer = Completer<Map<String, dynamic>>();
      
      // Access Google Maps API using safe property access
      final window = js.context;
      final google = js_util.getProperty(window, 'google') as js.JsObject?;
      if (google == null) throw Exception('Google object not found');
      
      final maps = js_util.getProperty(google, 'maps') as js.JsObject?;
      if (maps == null) throw Exception('Maps object not found');
      
      final geocoder = js_util.getProperty(maps, 'Geocoder');
      if (geocoder == null) throw Exception('Geocoder not found');
      
      // Create Geocoder instance
      final geocoderInstance = js.JsObject(geocoder);
      
      final latLng = js.JsObject(js_util.getProperty(maps, 'LatLng'), [latitude, longitude]);

      // Call geocode
      js_util.callMethod(geocoderInstance, 'geocode', [
        js.JsObject.jsify({'location': latLng}),
        js.allowInterop((results, status) {
          if (status == 'OK' && results != null && (results as js.JsArray).isNotEmpty) {
            final jsResults = js.JsArray.from(results);
            final firstResult = jsResults[0] as js.JsObject;
            
            completer.complete({
              'results': [
                {
                  'formatted_address': js_util.getProperty(firstResult, 'formatted_address') ?? '',
                  'geometry': {
                    'location': {
                      'lat': latitude,
                      'lng': longitude,
                    },
                  },
                },
              ],
            });
          } else {
            completer.completeError(Exception('Geocoding API status: $status'));
          }
        }),
      ]);

      return completer.future;
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
      rethrow;
    }
  }

  /// Get directions using JavaScript API
  static Future<Map<String, dynamic>> getDirections(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) async {
    if (!kIsWeb) {
      throw UnsupportedError('This method is only for web platform');
    }

    await _waitForGoogleMaps();

    try {
      // Verify API is loaded one more time before using it
      if (!_isGoogleMapsLoaded()) {
        throw Exception('Google Maps API not loaded after wait. Please refresh the page.');
      }
      
      final completer = Completer<Map<String, dynamic>>();
      
      // Access Google Maps API using safe property access
      final window = js.context;
      final google = js_util.getProperty(window, 'google') as js.JsObject;
      if (google == null) {
        throw Exception('Google object not found');
      }
      
      final maps = js_util.getProperty(google, 'maps') as js.JsObject;
      if (maps == null) {
        throw Exception('Maps object not found');
      }
      
      final directionsService = js_util.getProperty(maps, 'DirectionsService');
      if (directionsService == null) {
        throw Exception('DirectionsService not found. Make sure libraries=places,geometry is in the script tag.');
      }
      
      // Create DirectionsService instance
      final directions = js.JsObject(directionsService);
      
      final latLngConstructor = js_util.getProperty(maps, 'LatLng');
      if (latLngConstructor == null) {
        throw Exception('LatLng constructor not found');
      }
      
      final origin = js.JsObject(latLngConstructor, [originLat, originLng]);
      final destination = js.JsObject(latLngConstructor, [destLat, destLng]);

      final request = js.JsObject.jsify({
        'origin': origin,
        'destination': destination,
        'travelMode': 'DRIVING',
      });

      // Call route
      js_util.callMethod(directions, 'route', [
        request,
        js.allowInterop((result, status) {
          if (status == 'OK' && result != null) {
            final resultObj = result as js.JsObject;
            final routes = js_util.getProperty(resultObj, 'routes') as js.JsArray;
            
            if (routes.isNotEmpty) {
              final route = routes[0] as js.JsObject;
              final legs = js_util.getProperty(route, 'legs') as js.JsArray;
              
              if (legs.isNotEmpty) {
                final leg = legs[0] as js.JsObject;
                final overviewPolyline = js_util.getProperty(route, 'overview_polyline') as js.JsObject;
                final distance = js_util.getProperty(leg, 'distance') as js.JsObject;
                final duration = js_util.getProperty(leg, 'duration') as js.JsObject;
                
                completer.complete({
                  'routes': [
                    {
                      'overview_polyline': {
                        'points': js_util.getProperty(overviewPolyline, 'points') ?? '',
                      },
                      'legs': [
                        {
                          'distance': {
                            'text': js_util.getProperty(distance, 'text') ?? '',
                            'value': js_util.getProperty(distance, 'value') ?? 0,
                          },
                          'duration': {
                            'text': js_util.getProperty(duration, 'text') ?? '',
                            'value': js_util.getProperty(duration, 'value') ?? 0,
                          },
                        },
                      ],
                    },
                  ],
                });
              } else {
                completer.completeError(Exception('No legs in route'));
              }
            } else {
              completer.completeError(Exception('No routes found'));
            }
          } else {
            completer.completeError(Exception('Directions API status: $status'));
          }
        }),
      ]);

      return completer.future;
    } catch (e) {
      debugPrint('Error getting directions: $e');
      rethrow;
    }
  }
}

