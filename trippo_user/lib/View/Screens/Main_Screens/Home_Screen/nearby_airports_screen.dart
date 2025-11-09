import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' show cos, sqrt, asin;
import 'package:btrips_unified/Model/direction_model.dart';
import 'package:btrips_unified/View/Screens/Main_Screens/Home_Screen/home_providers.dart';
import 'package:btrips_unified/View/Screens/Main_Screens/Home_Screen/home_logics.dart';

/// Model for airport data
class Airport {
  final String name;
  final String code;
  final String city;
  final String state;
  final double latitude;
  final double longitude;
  final String address;

  Airport({
    required this.name,
    required this.code,
    required this.city,
    required this.state,
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  /// Calculate distance from a position in kilometers
  double distanceFromPosition(Position position) {
    return _calculateDistance(
      position.latitude,
      position.longitude,
      latitude,
      longitude,
    );
  }

  /// Calculate distance between two points using Haversine formula (in km)
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  /// Convert distance to miles
  double get distanceInMiles => distanceFromPosition(
        Position(
          latitude: 0,
          longitude: 0,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        ),
      );
}

/// Major US Airports Database
final List<Airport> _majorUSAirports = [
  // New York/New Jersey Area
  Airport(
    name: 'Newark Liberty International',
    code: 'EWR',
    city: 'Newark',
    state: 'NJ',
    latitude: 40.6895,
    longitude: -74.1745,
    address: '3 Brewster Rd, Newark, NJ 07114',
  ),
  Airport(
    name: 'John F. Kennedy International',
    code: 'JFK',
    city: 'Queens',
    state: 'NY',
    latitude: 40.6413,
    longitude: -73.7781,
    address: 'Queens, NY 11430',
  ),
  Airport(
    name: 'LaGuardia Airport',
    code: 'LGA',
    city: 'Queens',
    state: 'NY',
    latitude: 40.7769,
    longitude: -73.8740,
    address: 'Queens, NY 11371',
  ),
  
  // California
  Airport(
    name: 'Los Angeles International',
    code: 'LAX',
    city: 'Los Angeles',
    state: 'CA',
    latitude: 33.9416,
    longitude: -118.4085,
    address: '1 World Way, Los Angeles, CA 90045',
  ),
  Airport(
    name: 'San Francisco International',
    code: 'SFO',
    city: 'San Francisco',
    state: 'CA',
    latitude: 37.6213,
    longitude: -122.3790,
    address: 'San Francisco, CA 94128',
  ),
  Airport(
    name: 'San Diego International',
    code: 'SAN',
    city: 'San Diego',
    state: 'CA',
    latitude: 32.7336,
    longitude: -117.1897,
    address: '3225 N Harbor Dr, San Diego, CA 92101',
  ),
  
  // Illinois
  Airport(
    name: "O'Hare International",
    code: 'ORD',
    city: 'Chicago',
    state: 'IL',
    latitude: 41.9742,
    longitude: -87.9073,
    address: '10000 W O\'Hare Ave, Chicago, IL 60666',
  ),
  
  // Texas
  Airport(
    name: 'Dallas/Fort Worth International',
    code: 'DFW',
    city: 'Dallas',
    state: 'TX',
    latitude: 32.8998,
    longitude: -97.0403,
    address: '2400 Aviation Dr, Dallas, TX 75261',
  ),
  Airport(
    name: 'George Bush Intercontinental',
    code: 'IAH',
    city: 'Houston',
    state: 'TX',
    latitude: 29.9902,
    longitude: -95.3368,
    address: '2800 N Terminal Rd, Houston, TX 77032',
  ),
  
  // Florida
  Airport(
    name: 'Miami International',
    code: 'MIA',
    city: 'Miami',
    state: 'FL',
    latitude: 25.7959,
    longitude: -80.2870,
    address: '2100 NW 42nd Ave, Miami, FL 33126',
  ),
  Airport(
    name: 'Orlando International',
    code: 'MCO',
    city: 'Orlando',
    state: 'FL',
    latitude: 28.4312,
    longitude: -81.3081,
    address: '1 Jeff Fuqua Blvd, Orlando, FL 32827',
  ),
  
  // Georgia
  Airport(
    name: 'Hartsfield-Jackson Atlanta International',
    code: 'ATL',
    city: 'Atlanta',
    state: 'GA',
    latitude: 33.6407,
    longitude: -84.4277,
    address: '6000 N Terminal Pkwy, Atlanta, GA 30320',
  ),
  
  // Washington
  Airport(
    name: 'Seattle-Tacoma International',
    code: 'SEA',
    city: 'Seattle',
    state: 'WA',
    latitude: 47.4502,
    longitude: -122.3088,
    address: '17801 International Blvd, Seattle, WA 98158',
  ),
  
  // Nevada
  Airport(
    name: 'Harry Reid International',
    code: 'LAS',
    city: 'Las Vegas',
    state: 'NV',
    latitude: 36.0840,
    longitude: -115.1537,
    address: '5757 Wayne Newton Blvd, Las Vegas, NV 89119',
  ),
  
  // Massachusetts
  Airport(
    name: 'Boston Logan International',
    code: 'BOS',
    city: 'Boston',
    state: 'MA',
    latitude: 42.3656,
    longitude: -71.0096,
    address: '1 Harborside Dr, Boston, MA 02128',
  ),
  
  // Pennsylvania
  Airport(
    name: 'Philadelphia International',
    code: 'PHL',
    city: 'Philadelphia',
    state: 'PA',
    latitude: 39.8729,
    longitude: -75.2437,
    address: '8000 Essington Ave, Philadelphia, PA 19153',
  ),
  
  // DC Area
  Airport(
    name: 'Washington Dulles International',
    code: 'IAD',
    city: 'Dulles',
    state: 'VA',
    latitude: 38.9531,
    longitude: -77.4565,
    address: '1 Saarinen Cir, Dulles, VA 20166',
  ),
  Airport(
    name: 'Ronald Reagan Washington National',
    code: 'DCA',
    city: 'Arlington',
    state: 'VA',
    latitude: 38.8521,
    longitude: -77.0377,
    address: '2401 Smith Blvd, Arlington, VA 22202',
  ),
];

/// Screen showing nearby airports for quick booking
class NearbyAirportsScreen extends ConsumerStatefulWidget {
  final GoogleMapController mapController;

  const NearbyAirportsScreen({
    super.key,
    required this.mapController,
  });

  @override
  ConsumerState<NearbyAirportsScreen> createState() => _NearbyAirportsScreenState();
}

class _NearbyAirportsScreenState extends ConsumerState<NearbyAirportsScreen> {
  List<Airport>? _nearbyAirports;
  Position? _currentPosition;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNearbyAirports();
  }

  /// Load nearby airports based on user's location
  Future<void> _loadNearbyAirports() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });

      // Calculate distances and sort
      final airportsWithDistance = _majorUSAirports.map((airport) {
        return {
          'airport': airport,
          'distance': airport.distanceFromPosition(position),
        };
      }).toList();

      // Sort by distance
      airportsWithDistance.sort((a, b) =>
          (a['distance'] as double).compareTo(b['distance'] as double));

      // Get top 6 closest
      final nearest = airportsWithDistance
          .take(6)
          .map((item) => item['airport'] as Airport)
          .toList();

      setState(() {
        _nearbyAirports = nearest;
        _isLoading = false;
      });

      debugPrint('✅ Found ${nearest.length} nearby airports');
    } catch (e) {
      debugPrint('❌ Error loading airports: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Handle airport selection - just set destination and close
  /// Modern home screen will handle the workflow
  void _onAirportTap(Airport airport) {
    try {
      // Set the destination
      final destination = Direction(
        humanReadableAddress: airport.address,
        locationName: '${airport.name} (${airport.code})',
        locationLatitude: airport.latitude,
        locationLongitude: airport.longitude,
        locationId: airport.code,
      );

      // Set destination in provider
      ref.read(homeScreenDropOffLocationProvider.notifier).state = destination;
      
      debugPrint('✅ Airport selected: ${airport.name} (${airport.code})');

      // Close this screen - modern home screen will handle the rest
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('❌ Error selecting airport: $e');
      
      // Only show error if widget is still mounted
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting airport: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Calculate distance in miles
  double _distanceInMiles(Airport airport) {
    if (_currentPosition == null) return 0;
    final km = airport.distanceFromPosition(_currentPosition!);
    return km * 0.621371; // Convert km to miles
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Nearby Airports'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.blue),
              )
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading airports',
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _loadNearbyAirports,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _nearbyAirports == null || _nearbyAirports!.isEmpty
                    ? Center(
                        child: Text(
                          'No airports found',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _nearbyAirports!.length,
                        itemBuilder: (context, index) {
                          final airport = _nearbyAirports![index];
                          final distance = _distanceInMiles(airport);

                          return _buildAirportCard(airport, distance, index);
                        },
                      ),
      ),
    );
  }

  /// Build individual airport card
  Widget _buildAirportCard(Airport airport, double distance, int index) {
    return InkWell(
      onTap: () => _onAirportTap(airport),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[700]!),
        ),
        child: Row(
          children: [
            // Airport icon with ranking
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: index == 0 ? Colors.blue : Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.flight,
                    color: Colors.white,
                    size: index == 0 ? 24 : 20,
                  ),
                  const SizedBox(height: 2),
                  if (index == 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Closest',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Airport info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          airport.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                        child: Text(
                          airport.code,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${airport.city}, ${airport.state}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[400],
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.navigation,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${distance.toStringAsFixed(1)} mi',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[400],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Arrow icon
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[500],
            ),
          ],
        ),
      ),
    );
  }
}

