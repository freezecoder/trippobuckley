import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

/// SIMPLE STANDALONE TEST - No dependencies, just pure HTTP
/// This bypasses all the complex JavaScript API loading
void main() {
  runApp(const SimpleSearchTest());
}

class SimpleSearchTest extends StatefulWidget {
  const SimpleSearchTest({super.key});

  @override
  State<SimpleSearchTest> createState() => _SimpleSearchTestState();
}

class _SimpleSearchTestState extends State<SimpleSearchTest> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  String _error = '';
  Timer? _debounceTimer;
  
  // Your actual API key
  static const String apiKey = "AIzaSyAnsK0I2lw7YP3qhUthMBtlsiJ31WVkPrY";

  @override
  void dispose() {
    _controller.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _searchPlaces(String query) async {
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
      print('\n🔍 SIMPLE TEST: Searching for "$query"');
      
      // Build URL - NO country restriction to test broadly
      final url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json'
          '?input=$query'
          '&key=$apiKey';
      
      print('🌐 URL: $url');
      print('⏰ Making HTTP GET request...');
      
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timed out after 10 seconds');
        },
      );

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body length: ${response.body.length} chars');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Decoded JSON successfully');
        print('📊 Status: ${data["status"]}');
        
        if (data["status"] == "OK") {
          final predictions = data["predictions"] as List;
          print('✅ Got ${predictions.length} predictions');
          
          setState(() {
            _results = predictions.cast<Map<String, dynamic>>();
            _isLoading = false;
            _error = '';
          });
          
          // Print each result
          for (var i = 0; i < predictions.length; i++) {
            print('   ${i + 1}. ${predictions[i]["description"]}');
          }
        } else {
          throw Exception('API Status: ${data["status"]} - ${data["error_message"] ?? "No error message"}');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e, stackTrace) {
      print('\n❌ ERROR:');
      print('Type: ${e.runtimeType}');
      print('Message: $e');
      print('Stack: $stackTrace\n');
      
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _onTextChanged(String text) {
    _debounceTimer?.cancel();
    
    if (text.length < 2) {
      setState(() {
        _results = [];
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
          title: const Text('SIMPLE Google Places Test'),
          backgroundColor: Colors.green,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info
              Card(
                color: Colors.green[900],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🧪 SIMPLE REST API TEST',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('• NO JavaScript API'),
                      const Text('• NO CORS proxy'),
                      const Text('• Just pure HTTP GET'),
                      const Text('• Works on ALL platforms'),
                      Text('• API Key: ${apiKey.substring(0, 20)}...'),
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
                  hintText: 'Type here: "Target", "Starbucks", "McDonald\'s"',
                  prefixIcon: const Icon(Icons.search, color: Colors.green),
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
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Status
              if (_isLoading)
                const Row(
                  children: [
                    CircularProgressIndicator(color: Colors.green),
                    SizedBox(width: 16),
                    Text('Searching via REST API...'),
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
                      Text(
                        _error,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              
              // Results Count
              if (_results.isNotEmpty && !_isLoading)
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
                        '✅ Found ${_results.length} results:',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Results List
              Expanded(
                child: _results.isEmpty && !_isLoading && _error.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search, size: 80, color: Colors.grey[600]),
                            const SizedBox(height: 16),
                            const Text(
                              'Type to search',
                              style: TextStyle(fontSize: 20, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try: "Target", "Starbucks", "Pizza"',
                              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final place = _results[index];
                          final mainText = place['structured_formatting']?['main_text'] ?? '';
                          final secondaryText = place['structured_formatting']?['secondary_text'] ?? '';
                          final description = place['description'] ?? 'No description';
                          
                          return Card(
                            color: Colors.grey[850],
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                mainText.isNotEmpty ? mainText : description,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              subtitle: secondaryText.isNotEmpty
                                  ? Text(
                                      secondaryText,
                                      style: TextStyle(color: Colors.grey[400]),
                                    )
                                  : null,
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey,
                              ),
                              onTap: () {
                                print('Selected: $description');
                                print('Place ID: ${place["place_id"]}');
                              },
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

