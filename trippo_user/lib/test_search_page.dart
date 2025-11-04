import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:btrips_unified/Container/utils/keys.dart';
import 'package:btrips_unified/Container/utils/google_places_stub.dart'
    if (dart.library.html) 'package:btrips_unified/Container/utils/google_places_web.dart';
import 'package:btrips_unified/Model/predicted_places.dart';

/// Simple standalone test page for Google Places Search
/// Run this to test if the API works independently
class TestSearchPage extends StatefulWidget {
  const TestSearchPage({super.key});

  @override
  State<TestSearchPage> createState() => _TestSearchPageState();
}

class _TestSearchPageState extends State<TestSearchPage> {
  final TextEditingController _controller = TextEditingController();
  List<PredictedPlaces> _results = [];
  bool _isLoading = false;
  String _error = '';
  Timer? _debounceTimer;

  @override
  void dispose() {
    _controller.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _testSearch(String query) async {
    if (query.isEmpty || query.length < 2) {
      setState(() {
        _results = [];
        _error = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      print('\n═══ SEARCH TEST START ═══');
      print('🔍 TEST: Searching for: "$query"');
      print('🔑 TEST: Using API key: ${Keys.mapKey.substring(0, 20)}...');
      print('🌐 TEST: Platform: ${kIsWeb ? "WEB" : "MOBILE"}');

      if (kIsWeb) {
        print('📱 TEST: About to call GooglePlacesWeb.getPlacePredictions()');
        print('⏰ TEST: Starting at ${DateTime.now()}');
        
        final predictions = await GooglePlacesWeb.getPlacePredictions(
          query,
          Keys.mapKey,
        ).timeout(
          const Duration(seconds: 20),
          onTimeout: () {
            print('⏱️ TEST: Timeout after 20 seconds');
            throw TimeoutException('Search timed out after 20 seconds');
          },
        );

        print('✅ TEST: Got ${predictions.length} raw predictions');
        
        final List<PredictedPlaces> places = [];
        for (var p in predictions) {
          print('   📍 ${p["description"]}');
          places.add(PredictedPlaces.fromJson(p));
        }

        setState(() {
          _results = places;
          _isLoading = false;
          _error = '';
        });
        
        print('✅ TEST: Successfully parsed ${places.length} places');
        print('═══ SEARCH TEST END ═══\n');
      } else {
        setState(() {
          _isLoading = false;
          _error = 'Mobile testing not implemented yet';
        });
      }
    } catch (e, stackTrace) {
      print('\n❌ TEST ERROR CAUGHT ═══');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace:\n$stackTrace');
      print('═══════════════════════\n');
      
      setState(() {
        _isLoading = false;
        _error = 'Error: $e';
      });
    }
  }

  void _onTextChanged(String text) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      _testSearch(text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Google Places Search Test'),
          backgroundColor: Colors.blue,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Card(
                color: Colors.blue[900],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Test Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Platform: ${kIsWeb ? "Web" : "Mobile"}'),
                      Text('API Key: ${Keys.mapKey.substring(0, 20)}...'),
                      const Text('Country: USA (no restriction)'),
                      const Text('Debounce: 800ms'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Search Field
              TextField(
                controller: _controller,
                onChanged: _onTextChanged,
                decoration: InputDecoration(
                  hintText: 'Search for places (e.g., "Target", "Starbucks")',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _controller.clear();
                            setState(() {
                              _results = [];
                              _error = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Status
              if (_isLoading)
                const Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Text('Searching...'),
                  ],
                ),
              
              if (_error.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
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
              
              // Results Count
              if (_results.isNotEmpty && !_isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Found ${_results.length} results:',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              
              // Results List
              Expanded(
                child: _results.isEmpty && !_isLoading && _error.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Type to search',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Try: "Target", "Starbucks", "McDonald\'s"',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final place = _results[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue,
                                child: Text('${index + 1}'),
                              ),
                              title: Text(
                                place.mainText ?? 'No name',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(place.secText ?? ''),
                              trailing: Text(
                                'ID: ${place.placeId?.substring(0, 8) ?? "N/A"}...',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        
        // Console Log Button
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            print('=== MANUAL TEST TRIGGER ===');
            print('Controller text: ${_controller.text}');
            print('Results count: ${_results.length}');
            print('Is loading: $_isLoading');
            print('Error: $_error');
            print('Platform: ${kIsWeb ? "Web" : "Mobile"}');
            
            // Force a test search
            if (_controller.text.isNotEmpty) {
              _testSearch(_controller.text);
            }
          },
          label: const Text('Force Test'),
          icon: const Icon(Icons.play_arrow),
        ),
      ),
    );
  }
}

/// Run this to test the search independently
void main() {
  runApp(const TestSearchPage());
}

