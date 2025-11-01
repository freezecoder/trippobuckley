import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../data/models/ride_request_model.dart';
import '../../../../../Container/utils/set_blackmap.dart';

/// Provider for driver's real-time location
final driverLocationStreamProvider = StreamProvider.family<GeoPoint?, String>((ref, driverId) {
  if (driverId.isEmpty) return Stream.value(null);
  
  return FirebaseFirestore.instance
      .collection('drivers')
      .doc(driverId)
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists) return null;
    
    final data = snapshot.data();
    if (data == null) return null;
    
    final driverLoc = data['driverLoc'];
    if (driverLoc == null) return null;
    
    if (driverLoc is Map) {
      final geopoint = driverLoc['geopoint'] as GeoPoint?;
      return geopoint;
    }
    
    return null;
  });
});

/// Widget showing driver's live location on map (for passengers)
class DriverTrackingMap extends ConsumerStatefulWidget {
  final RideRequestModel ride;
  
  const DriverTrackingMap({
    super.key,
    required this.ride,
  });

  @override
  ConsumerState<DriverTrackingMap> createState() => _DriverTrackingMapState();
}

class _DriverTrackingMapState extends ConsumerState<DriverTrackingMap> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  BitmapDescriptor? _carIcon;
  
  @override
  void initState() {
    super.initState();
    _createCarMarkerIcon();
  }
  
  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
  
  /// Create custom car icon for driver marker using built-in taxi icon
  Future<void> _createCarMarkerIcon() async {
    try {
      final iconBytes = await _getBytesFromIcon(
        Icons.local_taxi,
        color: Colors.green,
        size: 80,
      );
      
      _carIcon = BitmapDescriptor.fromBytes(iconBytes);
      debugPrint('✅ Created car marker from taxi icon');
    } catch (e) {
      // Fallback: Use default green marker
      debugPrint('⚠️ Could not create icon, using default: $e');
      _carIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }
    
    if (mounted) {
      setState(() {});
    }
  }
  
  /// Convert Flutter icon to bytes for map marker
  Future<Uint8List> _getBytesFromIcon(
    IconData iconData, {
    required Color color,
    required double size,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    
    // Draw a white circle background
    final paint = Paint()..color = Colors.white;
    final circlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2,
      circlePaint,
    );
    
    // Draw the icon
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: size * 0.7,
        fontFamily: iconData.fontFamily,
        color: color,
      ),
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2,
      ),
    );
    
    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    
    return bytes!.buffer.asUint8List();
  }

  void _updateMap(GeoPoint? driverLocation) {
    if (_mapController == null) return;
    
    final markers = <Marker>{};
    
    // Add pickup marker
    markers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(
          widget.ride.pickupLocation.latitude,
          widget.ride.pickupLocation.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
          title: 'Your Location',
          snippet: widget.ride.pickupAddress,
        ),
      ),
    );
    
    // Add driver marker if location available
    if (driverLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(
            driverLocation.latitude,
            driverLocation.longitude,
          ),
          icon: _carIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: '🚗 Your Driver',
            snippet: 'On the way to pick you up',
          ),
          anchor: const Offset(0.5, 0.5), // Center the icon
          rotation: 0, // TODO: Calculate bearing for direction
        ),
      );
      
      // Calculate distance
      final distance = _calculateDistance(
        widget.ride.pickupLocation.latitude,
        widget.ride.pickupLocation.longitude,
        driverLocation.latitude,
        driverLocation.longitude,
      );
      
      debugPrint('📍 Driver distance from you: ${distance.toStringAsFixed(2)} km');
    }
    
    setState(() {
      _markers.clear();
      _markers.addAll(markers);
    });
    
    // Auto-zoom to show both markers
    if (driverLocation != null) {
      _fitBounds(
        LatLng(widget.ride.pickupLocation.latitude, widget.ride.pickupLocation.longitude),
        LatLng(driverLocation.latitude, driverLocation.longitude),
      );
    }
  }

  void _fitBounds(LatLng point1, LatLng point2) {
    if (_mapController == null) return;
    
    final bounds = LatLngBounds(
      southwest: LatLng(
        point1.latitude < point2.latitude ? point1.latitude : point2.latitude,
        point1.longitude < point2.longitude ? point1.longitude : point2.longitude,
      ),
      northeast: LatLng(
        point1.latitude > point2.latitude ? point1.latitude : point2.latitude,
        point1.longitude > point2.longitude ? point1.longitude : point2.longitude,
      ),
    );
    
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Haversine formula
    const double earthRadius = 6371; // km
    
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final c = 2 * math.asin(math.sqrt(a));
    
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }

  @override
  Widget build(BuildContext context) {
    final driverId = widget.ride.driverId;
    
    if (driverId == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'Waiting for driver assignment...',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
    
    final driverLocationStream = ref.watch(driverLocationStreamProvider(driverId));
    
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  widget.ride.pickupLocation.latitude,
                  widget.ride.pickupLocation.longitude,
                ),
                zoom: 14,
              ),
              markers: _markers,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
                SetBlackMap().setBlackMapTheme(controller);
              },
            ),
            
            // Driver location status overlay
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: driverLocationStream.when(
                data: (driverLocation) {
                  // Update map when location changes
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _updateMap(driverLocation);
                  });
                  
                  if (driverLocation == null) {
                    return _StatusCard(
                      icon: Icons.gps_off,
                      text: 'Driver location unavailable',
                      color: Colors.grey,
                    );
                  }
                  
                  final distance = _calculateDistance(
                    widget.ride.pickupLocation.latitude,
                    widget.ride.pickupLocation.longitude,
                    driverLocation.latitude,
                    driverLocation.longitude,
                  );
                  
                  // Estimate time (assume 30 km/h average in city)
                  final eta = (distance / 30 * 60).round(); // minutes
                  
                  return _StatusCard(
                    icon: Icons.navigation,
                    text: distance < 0.1 
                        ? 'Driver nearby!'
                        : '${distance.toStringAsFixed(1)} km away • ETA: $eta min',
                    color: Colors.green,
                  );
                },
                loading: () => const _StatusCard(
                  icon: Icons.gps_not_fixed,
                  text: 'Locating driver...',
                  color: Colors.orange,
                ),
                error: (_, __) => const _StatusCard(
                  icon: Icons.gps_off,
                  text: 'Unable to track driver',
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Status card showing driver tracking info
class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  
  const _StatusCard({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

