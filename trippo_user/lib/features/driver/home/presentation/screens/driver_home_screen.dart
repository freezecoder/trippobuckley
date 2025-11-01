import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../../../../../core/enums/driver_status.dart';
import '../../../../../data/providers/auth_providers.dart';
import '../../../../../data/providers/user_providers.dart';
import '../../../../../data/providers/ride_providers.dart';
import '../../../../../data/repositories/ride_repository.dart';
import '../../../../../Container/utils/set_blackmap.dart';

/// Providers for driver home screen
final driverIsOnlineProvider = StateProvider<bool>((ref) => false);
final driverCurrentLocationProvider = StateProvider<Position?>((ref) => null);

/// Driver home screen with map and online/offline toggle
class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  final Completer<GoogleMapController> _controllerCompleter = Completer();
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionStreamSubscription;

  final CameraPosition _initialPosition =
      const CameraPosition(target: LatLng(0.0, 0.0), zoom: 14);

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  /// Get current location
  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      ref.read(driverCurrentLocationProvider.notifier).state = position;

      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 14,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  /// Toggle driver online/offline status
  Future<void> _toggleOnlineStatus() async {
    try {
      final currentUser = await ref.read(currentUserProvider.future);
      if (currentUser == null) return;

      final isOnline = ref.read(driverIsOnlineProvider);
      final driverRepo = ref.read(driverRepositoryProvider);

      if (!isOnline) {
        // Going online
        final position = ref.read(driverCurrentLocationProvider);
        if (position == null) {
          await _getCurrentLocation();
          return;
        }

        // Update location in Firestore
        await driverRepo.updateDriverLocation(
          driverId: currentUser.uid,
          latitude: position.latitude,
          longitude: position.longitude,
        );

        // Set status to Idle
        await driverRepo.updateDriverStatus(
          driverId: currentUser.uid,
          status: DriverStatus.idle,
        );

        // Start location stream
        _positionStreamSubscription = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((Position position) {
          ref.read(driverCurrentLocationProvider.notifier).state = position;
          
          // Update location in Firestore
          driverRepo.updateDriverLocation(
            driverId: currentUser.uid,
            latitude: position.latitude,
            longitude: position.longitude,
          );
        });

        ref.read(driverIsOnlineProvider.notifier).state = true;
      } else {
        // Going offline
        _positionStreamSubscription?.cancel();

        await driverRepo.updateDriverStatus(
          driverId: currentUser.uid,
          status: DriverStatus.offline,
        );

        ref.read(driverIsOnlineProvider.notifier).state = false;
      }
    } catch (e) {
      debugPrint('Error toggling status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isOnline = ref.watch(driverIsOnlineProvider);

    return Scaffold(
      body: SafeArea(
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: Stack(
            children: [
              // Google Map
              GoogleMap(
                mapType: MapType.normal,
                myLocationButtonEnabled: true,
                trafficEnabled: true,
                compassEnabled: true,
                buildingsEnabled: true,
                myLocationEnabled: true,
                zoomControlsEnabled: false,
                zoomGesturesEnabled: true,
                initialCameraPosition: _initialPosition,
                onMapCreated: (GoogleMapController controller) {
                  _controllerCompleter.complete(controller);
                  _mapController = controller;
                  SetBlackMap().setBlackMapTheme(controller);
                  _getCurrentLocation();
                },
              ),

              // Dimmed overlay when offline
              if (!isOnline)
                Container(
                  height: size.height,
                  width: size.width,
                  color: Colors.black54,
                ),

              // Online/Offline Toggle Button
              Positioned(
                top: !isOnline ? size.height * 0.45 : 45,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: _toggleOnlineStatus,
                      child: Container(
                        alignment: Alignment.center,
                        height: 50,
                        width: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: isOnline ? Colors.green : Colors.blue,
                        ),
                        child: isOnline
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.phone_in_talk,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Online - Available",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            : const Text(
                                "Go Online",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              // Pending Ride Requests (when online)
              if (isOnline)
                Positioned(
                  bottom: 20,
                  left: 16,
                  right: 16,
                  child: Consumer(
                    builder: (context, ref, child) {
                      final pendingRides = ref.watch(pendingRideRequestsProvider);
                      
                      return pendingRides.when(
                        data: (rides) {
                          if (rides.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          // Show the most recent pending ride
                          final ride = rides.first;
                          
                          return Card(
                            color: Colors.white,
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.notification_important, 
                                        color: Colors.orange, size: 28),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Text(
                                          'New Ride Request!',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '\$${ride.fare.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, 
                                        color: Colors.blue, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          ride.pickupAddress,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.flag, 
                                        color: Colors.red, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          ride.dropoffAddress,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            // ✅ Decline ride - adds driver to declinedBy list
                                            try {
                                              final currentUser = await ref.read(
                                                currentUserProvider.future);
                                              if (currentUser == null) return;

                                              final rideRepo = ref.read(
                                                rideRepositoryProvider);
                                              
                                              await rideRepo.declineRideRequest(
                                                rideId: ride.id,
                                                driverId: currentUser.uid,
                                              );

                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Ride declined. It will not appear again.'),
                                                    backgroundColor: Colors.orange,
                                                    duration: Duration(seconds: 2),
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Error: $e'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.grey[300],
                                            foregroundColor: Colors.black87,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14),
                                          ),
                                          child: const Text('Decline'),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        flex: 2,
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            // TODO: Accept ride
                                            try {
                                              final currentUser = await ref.read(
                                                currentUserProvider.future);
                                              if (currentUser == null) return;

                                              final rideRepo = ref.read(
                                                rideRepositoryProvider);
                                              
                                              await rideRepo.acceptRideRequest(
                                                rideId: ride.id,
                                                driverId: currentUser.uid,
                                                driverEmail: currentUser.email,
                                              );

                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Ride accepted! User has been notified.'),
                                                    backgroundColor: Colors.green,
                                                  ),
                                                );
                                              }
                                            } on AlreadyHasActiveRideException catch (e) {
                                              // Show friendly message for multiple active rides
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        const Row(
                                                          children: [
                                                            Icon(Icons.warning_amber_rounded, 
                                                              color: Colors.white, size: 20),
                                                            SizedBox(width: 8),
                                                            Text(
                                                              'Active Ride in Progress',
                                                              style: TextStyle(
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Text(e.toString()),
                                                      ],
                                                    ),
                                                    backgroundColor: Colors.orange[700],
                                                    duration: const Duration(seconds: 4),
                                                    behavior: SnackBarBehavior.floating,
                                                  ),
                                                );
                                              }
                                            } on RideNoLongerAvailableException catch (e) {
                                              // ✅ Show message when ride was taken by another driver
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        const Row(
                                                          children: [
                                                            Icon(Icons.info_outline, 
                                                              color: Colors.white, size: 20),
                                                            SizedBox(width: 8),
                                                            Text(
                                                              'Ride Already Taken',
                                                              style: TextStyle(
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Text(e.toString()),
                                                      ],
                                                    ),
                                                    backgroundColor: Colors.blue[700],
                                                    duration: const Duration(seconds: 3),
                                                    behavior: SnackBarBehavior.floating,
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                  SnackBar(
                                                    content: Text('Error: $e'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14),
                                          ),
                                          child: const Text(
                                            'Accept Ride',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (rides.length > 1)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        '+ ${rides.length - 1} more request(s)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
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

