import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';
import 'package:btrips_unified/firebase_options.dart';

/// STANDALONE TEST for Cloud Functions
/// Tests the deployed placesAutocomplete and placeDetails functions
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🔥 Initializing Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('✅ Firebase initialized');
  
  runApp(const CloudFunctionTest());
}

class CloudFunctionTest extends StatefulWidget {
  const CloudFunctionTest({super.key});

  @override
  State<CloudFunctionTest> createState() => _CloudFunctionTestState();
}

class _CloudFunctionTestState extends State<CloudFunctionTest> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  String _error = '';
  String _successMessage = '';
  Timer? _debounceTimer;
  late FirebaseFunctions functions;

  @override
  void initState() {
    super.initState();
    functions = FirebaseFunctions.instance;
    print('✅ FirebaseFunctions instance created');
    print('   Region: ${functions.app.options.projectId}');
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _testCloudFunction(String query) async {
    if (query.isEmpty || query.length < 2) {
      setState(() {
        _results = [];
        _error = '';
        _successMessage = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
      _successMessage = '';
    });

    try {
      print('\n🚀 ========================================');
      print('CALLING CLOUD FUNCTION: placesAutocomplete');
      print('==========================================');
      print('📝 Input: "$query"');
      print('🌍 Country: us');
      print('🗣️  Language: en');
      print('⏰ Time: ${DateTime.now()}');

      // Get callable reference
      final callable = functions.httpsCallable('placesAutocomplete');
      print('✅ Got callable reference for: placesAutocomplete');

      // Call the function
      print('📡 Calling function...');
      final result = await callable.call({
        'input': query,
        'country': 'us',
        'language': 'en',
      });

      print('✅ Cloud Function returned!');
      print('📦 Response data type: ${result.data.runtimeType}');
      print('📦 Response data: ${result.data}');

      final Map<String, dynamic> response = Map<String, dynamic>.from(result.data);

      if (response['success'] == true) {
        final predictions = response['predictions'] as List;
        print('✅ SUCCESS! Got ${predictions.length} predictions:');
        
        for (var i = 0; i < predictions.length && i < 5; i++) {
          print('   ${i + 1}. ${predictions[i]['description']}');
        }

        setState(() {
          _results = predictions.cast<Map<String, dynamic>>();
          _isLoading = false;
          _successMessage = '✅ Found ${predictions.length} results via Cloud Function!';
        });
        
        print('==========================================\n');
      } else {
        throw Exception('Cloud Function returned success: false');
      }
    } catch (e, stackTrace) {
      print('\n❌ ========================================');
      print('CLOUD FUNCTION ERROR');
      print('==========================================');
      print('Type: ${e.runtimeType}');
      print('Message: $e');
      print('Stack:\n$stackTrace');
      print('==========================================\n');

      setState(() {
        _isLoading = false;
        _error = 'Error: $e';
      });
    }
  }

  void _onTextChanged(String text) {
    _debounceTimer?.cancel();

    if (text.length < 2) {
      setState(() {
        _results = [];
        _successMessage = '';
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      _testCloudFunction(text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Cloud Function Test'),
          backgroundColor: Colors.orange,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Card(
                color: Colors.orange[900],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🚀 Cloud Function Test',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('✅ Functions deployed:'),
                      const Text('   • placesAutocomplete'),
                      const Text('   • placeDetails'),
                      const Text('📍 Region: us-central1'),
                      const Text('🌐 Bypasses CORS via backend'),
                      const SizedBox(height: 8),
                      const Text(
                        'This test proves Cloud Functions work!',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.orange,
                        ),
                      ),
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
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Type: "Target", "Starbucks", "Pizza Hut"',
                  prefixIcon: const Icon(Icons.cloud, color: Colors.orange),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _controller.clear();
                            setState(() {
                              _results = [];
                              _error = '';
                              _successMessage = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.orange, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Status
              if (_isLoading)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      CircularProgressIndicator(color: Colors.blue),
                      SizedBox(width: 16),
                      Text('Calling Cloud Function...'),
                    ],
                  ),
                ),

              if (_successMessage.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.green[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _successMessage,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_error.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red[900],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.error, color: Colors.red, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'Error Calling Cloud Function:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SelectableText(
                        _error,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),

              // Results List
              Expanded(
                child: _results.isEmpty && !_isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_queue,
                              size: 100,
                              color: _error.isEmpty ? Colors.orange : Colors.grey[700],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _error.isEmpty 
                                  ? 'Cloud Functions Ready!'
                                  : 'Fix error and try again',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: _error.isEmpty ? Colors.white : Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _error.isEmpty
                                  ? 'Type in the search box to test'
                                  : 'Check console for details',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
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
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: Colors.orange,
                                radius: 20,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                mainText.isNotEmpty ? mainText : description,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: secondaryText.isNotEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        secondaryText,
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 13,
                                        ),
                                      ),
                                    )
                                  : null,
                              trailing: const Icon(
                                Icons.cloud_done,
                                color: Colors.green,
                                size: 28,
                              ),
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
            print('\n🧪 MANUAL TEST TRIGGER');
            print('Input: "${_controller.text}"');
            print('Results: ${_results.length}');
            print('Loading: $_isLoading');
            print('Error: $_error\n');
            
            if (_controller.text.isNotEmpty) {
              _testCloudFunction(_controller.text);
            } else {
              print('⚠️  Type something first!');
            }
          },
          label: const Text('Force Test'),
          icon: const Icon(Icons.play_arrow),
          backgroundColor: Colors.orange,
        ),
      ),
    );
  }
}
