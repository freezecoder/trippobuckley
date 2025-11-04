import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:btrips_unified/Container/utils/keys.dart';

/// Test using google_maps_webservice package
/// This uses direct API proxy that handles CORS
void main() {
  runApp(const WebServiceSearchTest());
}

class WebServiceSearchTest extends StatefulWidget {
  const WebServiceSearchTest({super.key});

  @override
  State<WebServiceSearchTest> createState() => _WebServiceSearchTestState();
}

class _WebServiceSearchTestState extends State<WebServiceSearchTest> {
  final TextEditingController _controller = TextEditingController();
  late GoogleMapsPlaces _places;
  List<Prediction> _predictions = [];
  bool _isLoading = false;
  String _error = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Initialize GoogleMapsPlaces with proxy configuration
    _places = GoogleMapsPlaces(
      apiKey: Keys.mapKey,
      // The package handles the proxy internally
    );
    print('✅ GoogleMapsPlaces initialized');
    print('🔑 API Key: ${Keys.mapKey.substring(0, 20)}...');
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
      print('\n🔍 Searching for: "$query"');
      print('⏰ Time: ${DateTime.now()}');

      final response = await _places.autocomplete(
        query,
        components: [Component(Component.country, "us")],
        language: "en",
      );

      print('📡 Response status: ${response.status}');
      print('📊 Predictions: ${response.predictions.length}');

      if (response.isOkay) {
        setState(() {
          _predictions = response.predictions;
          _isLoading = false;
          _error = '';
        });

        print('✅ SUCCESS! Got ${response.predictions.length} results:');
        for (var i = 0; i < response.predictions.length; i++) {
          print('   ${i + 1}. ${response.predictions[i].description}');
        }
      } else {
        throw Exception('API Error: ${response.status} - ${response.errorMessage}');
      }
    } catch (e, stackTrace) {
      print('\n❌ ERROR:');
      print('Message: $e');
      print('Stack: $stackTrace\n');

      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _getPlaceDetails(String placeId) async {
    try {
      print('\n📍 Getting details for place: $placeId');

      final response = await _places.getDetailsByPlaceId(placeId);

      if (response.isOkay) {
        final result = response.result;
        print('✅ Place: ${result.name}');
        print('📍 Location: ${result.geometry?.location.lat}, ${result.geometry?.location.lng}');
        print('📫 Address: ${result.formattedAddress}');

        // Show dialog with results
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(result.name),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Address: ${result.formattedAddress}'),
                  const SizedBox(height: 8),
                  Text('Lat: ${result.geometry?.location.lat}'),
                  Text('Lng: ${result.geometry?.location.lng}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        }
      } else {
        print('❌ Error: ${response.status} - ${response.errorMessage}');
      }
    } catch (e) {
      print('❌ Error getting place details: $e');
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('google_maps_webservice Test'),
          backgroundColor: Colors.purple,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Card(
                color: Colors.purple[900],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🧪 google_maps_webservice Package Test',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('• Uses GoogleMapsPlaces class'),
                      const Text('• Built-in proxy handling'),
                      const Text('• Should work on web'),
                      Text('• API Key: ${Keys.mapKey.substring(0, 20)}...'),
                      const Text('• Country: USA'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Search Field
              TextField(
                controller: _controller,
                onChanged: _onTextChanged,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search: "Target", "Starbucks", "Walmart"',
                  prefixIcon: const Icon(Icons.search, color: Colors.purple),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _controller.clear();
                            setState(() {
                              _predictions = [];
                              _error = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.purple, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Status
              if (_isLoading)
                const Row(
                  children: [
                    CircularProgressIndicator(color: Colors.purple),
                    SizedBox(width: 16),
                    Text('Searching with GoogleMapsPlaces...'),
                  ],
                ),

              if (_error.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.error, color: Colors.white),
                          SizedBox(width: 12),
                          Text(
                            'Error:',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        _error,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),

              // Results Count
              if (_predictions.isNotEmpty && !_isLoading)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        '✅ Found ${_predictions.length} results',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Results List
              Expanded(
                child: _predictions.isEmpty && !_isLoading && _error.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search, size: 80, color: Colors.grey[600]),
                            const SizedBox(height: 16),
                            const Text(
                              'Type to search',
                              style: TextStyle(fontSize: 20),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Results will appear here',
                              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
                              leading: CircleAvatar(
                                backgroundColor: Colors.purple,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                prediction.structuredFormatting?.mainText ?? 
                                prediction.description ?? 'No description',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              subtitle: Text(
                                prediction.structuredFormatting?.secondaryText ?? '',
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                              trailing: const Icon(
                                Icons.info_outline,
                                color: Colors.purple,
                              ),
                              onTap: () {
                                print('\n👆 Tapped: ${prediction.description}');
                                if (prediction.placeId != null) {
                                  _getPlaceDetails(prediction.placeId!);
                                }
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),

        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            print('\n🧪 MANUAL TEST:');
            print('Controller text: "${_controller.text}"');
            print('Results count: ${_predictions.length}');
            print('Is loading: $_isLoading');
            print('Error: $_error');

            if (_controller.text.isNotEmpty) {
              _searchPlaces(_controller.text);
            } else {
              print('⚠️ Type something first!');
            }
          },
          label: const Text('Force Search'),
          icon: const Icon(Icons.play_arrow),
          backgroundColor: Colors.purple,
        ),
      ),
    );
  }
}

