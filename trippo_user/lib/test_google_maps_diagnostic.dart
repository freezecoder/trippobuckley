import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// DIAGNOSTIC PAGE - Check what Google Maps APIs are loaded
/// This helps us understand why the JavaScript API isn't working
void main() {
  runApp(const GoogleMapsDiagnostic());
}

class GoogleMapsDiagnostic extends StatefulWidget {
  const GoogleMapsDiagnostic({super.key});

  @override
  State<GoogleMapsDiagnostic> createState() => _GoogleMapsDiagnosticState();
}

class _GoogleMapsDiagnosticState extends State<GoogleMapsDiagnostic> {
  String _diagnosticResults = 'Checking...';
  
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (kIsWeb) {
        _runDiagnostics();
      }
    });
  }

  void _runDiagnostics() {
    // This will be executed via JavaScript console
    setState(() {
      _diagnosticResults = '''
PLEASE RUN THESE COMMANDS IN BROWSER CONSOLE (F12):

1. Check if Google Maps script loaded:
   typeof window.google

2. Check if maps object exists:
   typeof window.google?.maps

3. Check if places library loaded:
   typeof window.google?.maps?.places

4. Check callback status:
   window.googleMapsReady

5. List all window properties with "google":
   Object.keys(window).filter(k => k.toLowerCase().includes('google'))

6. Check for errors in console (look for red errors about script loading)

7. Check Network tab:
   - Look for "maps.googleapis.com" request
   - Check if it loaded (green) or failed (red)
   - Check the response

8. Try manually loading the API:
   var script = document.createElement('script');
   script.src = 'https://maps.googleapis.com/maps/api/js?key=AIzaSyAnsK0I2lw7YP3qhUthMBtlsiJ31WVkPrY&libraries=places';
   document.head.appendChild(script);
   
Then refresh and try again.
''';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Google Maps Diagnostic'),
          backgroundColor: Colors.orange,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Colors.orange[900],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.orange),
                          const SizedBox(width: 12),
                          Text(
                            'Diagnostic Mode',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This page helps diagnose why Google Maps JavaScript API isn\'t loading.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              Card(
                color: Colors.grey[850],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    _diagnosticResults,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Quick Actions
              Card(
                color: Colors.blue[900],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Checks:',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      _buildCheckItem(
                        '1. Open Browser Console',
                        'Press F12 or Cmd+Option+I',
                      ),
                      _buildCheckItem(
                        '2. Look for Google Maps console logs',
                        'Should see "✅ Google Maps API callback triggered"',
                      ),
                      _buildCheckItem(
                        '3. Check Network tab',
                        'Look for "maps.googleapis.com" - did it load?',
                      ),
                      _buildCheckItem(
                        '4. Run diagnostic commands above',
                        'Copy/paste into console',
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Common Issues
              Card(
                color: Colors.red[900],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Common Issues:',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      _buildIssue(
                        'Network Error',
                        'Google Maps script failed to download',
                        'Check internet, try VPN, check firewall',
                      ),
                      _buildIssue(
                        'API Key Invalid',
                        'Script loads but API returns errors',
                        'Check Google Cloud Console',
                      ),
                      _buildIssue(
                        'Script Blocked',
                        'Content Security Policy or ad blocker',
                        'Disable browser extensions, check CSP headers',
                      ),
                      _buildIssue(
                        'Timing Issue',
                        'Script loads too slowly',
                        'Increase wait time or move script earlier in HTML',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            print('\n🔄 RERUNNING DIAGNOSTICS...\n');
            if (kIsWeb) {
              print('Run these commands in browser console (F12):');
              print('');
              print('1. window.google');
              print('2. window.google?.maps?.places');
              print('3. window.googleMapsReady');
              print('');
              print('Check Network tab for maps.googleapis.com request');
              print('');
            }
          },
          label: const Text('Show Console Commands'),
          icon: const Icon(Icons.terminal),
          backgroundColor: Colors.orange,
        ),
      ),
    );
  }

  Widget _buildCheckItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_box_outline_blank, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssue(String issue, String cause, String solution) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, size: 18, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                issue,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 26, top: 4),
            child: Text(
              'Cause: $cause',
              style: TextStyle(color: Colors.grey[300], fontSize: 12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 26, top: 2),
            child: Text(
              'Fix: $solution',
              style: TextStyle(color: Colors.grey[400], fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}

