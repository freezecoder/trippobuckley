import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:btrips_unified/Container/Repositories/address_parser_repo.dart';
import 'package:btrips_unified/Container/Repositories/direction_polylines_repo.dart';
import 'package:btrips_unified/Container/utils/firebase_messaging.dart';
import 'package:btrips_unified/Container/utils/set_blackmap.dart';
import 'package:btrips_unified/data/models/ride_request_model.dart';
import 'package:btrips_unified/data/providers/auth_providers.dart';
import 'package:btrips_unified/data/providers/ride_providers.dart';
import 'package:btrips_unified/View/Screens/Main_Screens/Home_Screen/home_providers.dart';
import 'package:btrips_unified/View/Screens/Main_Screens/Home_Screen/home_logics.dart';
import 'package:btrips_unified/View/Screens/Main_Screens/Home_Screen/modern_home_providers.dart';
import 'package:btrips_unified/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_screen.dart';
import 'package:btrips_unified/View/Screens/Main_Screens/Profile_Screen/Ride_History_Screen/ride_history_screen.dart';
import 'package:btrips_unified/View/Screens/Main_Screens/Profile_Screen/Payment_Methods_Screen/payment_methods_screen.dart';
import 'package:btrips_unified/View/Screens/Main_Screens/Home_Screen/nearby_airports_screen.dart';
import 'package:btrips_unified/View/Screens/Main_Screens/Delivery_Request_Screen/delivery_request_screen.dart';
import 'package:btrips_unified/Model/direction_model.dart';
import 'package:intl/intl.dart';

/// Modern Home Screen for Rider/User Role
/// Features:
/// - "Where to?" search bar with Now/Later scheduling
/// - 3 most recent trips
/// - Suggestion tiles for quick actions
/// - Clean, modern UI design
class ModernHomeScreen extends ConsumerStatefulWidget {
  const ModernHomeScreen({super.key});

  @override
  ConsumerState<ModernHomeScreen> createState() => _ModernHomeScreenState();
}

class _ModernHomeScreenState extends ConsumerState<ModernHomeScreen> {
  final Completer<GoogleMapController> _completer = Completer();
  GoogleMapController? _mapController;
  final CameraPosition _initPos =
      const CameraPosition(target: LatLng(0.0, 0.0), zoom: 14);
  bool _isInitialized = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        MessagingService().init(context, ref);
        _loadRecentTrips();
        _waitForInitialization();
        _listenForRideCreation();
      }
    });
  }
  
  /// Listen for when a ride is successfully created
  void _listenForRideCreation() {
    // Watch for active rides
    ref.listen(userActiveRidesProvider, (previous, next) {
      final previousRides = previous?.value ?? [];
      final currentRides = next.value ?? [];
      
      // If we went from 0 to 1+ rides, a new ride was just created
      if (previousRides.isEmpty && currentRides.isNotEmpty) {
        debugPrint('🎉 New ride created! Switching to Rides tab');
        
        // Clear the booking state
        ref.read(homeScreenDropOffLocationProvider.notifier).state = null;
        ref.read(homeScreenRateProvider.notifier).state = null;
        ref.read(homeScreenSelectedVehicleTypeProvider.notifier).state = null;
        ref.read(homeScreenMainPolylinesProvider.notifier).state = {};
        ref.read(homeScreenMainMarkersProvider.notifier).state = {};
        ref.read(homeScreenMainCirclesProvider.notifier).state = {};
        
        // Switch to Rides tab (index 1)
        ref.read(mainNavigationTabIndexProvider.notifier).state = 1;
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Ride requested! Check the Rides tab for updates.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    });
  }
  
  /// Wait for map and pickup location to be fully initialized
  Future<void> _waitForInitialization() async {
    debugPrint('⏳ Waiting for initialization...');
    
    // Wait for map controller
    try {
      _mapController = await _completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('❌ Map controller timeout');
          throw TimeoutException('Map initialization timeout');
        },
      );
      debugPrint('✅ Map controller ready');
    } catch (e) {
      debugPrint('❌ Map initialization failed: $e');
      // Continue anyway - we can try to get location without map
    }
    
    // Try to get pickup location directly if getUserLoc hasn't set it
    var pickup = ref.read(homeScreenPickUpLocationProvider);
    
    if (pickup == null) {
      debugPrint('📍 Getting current location directly with Geolocator...');
      
      try {
        // Get location directly
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw TimeoutException('Location fetch timeout');
          },
        );
        
        debugPrint('✅ Got GPS location: ${position.latitude}, ${position.longitude}');
        
        // Set basic pickup location with coordinates
        // Address will be fetched in background
        final basicPickup = Direction(
          locationLatitude: position.latitude,
          locationLongitude: position.longitude,
          humanReadableAddress: 'Current Location',
          locationName: 'Current Location',
        );
        
        ref.read(homeScreenPickUpLocationProvider.notifier).state = basicPickup;
        
        // Try to get readable address in background
        _fetchPickupAddress(position);
        
      } catch (e) {
        debugPrint('❌ Could not get location: $e');
        // Allow user to proceed anyway - they can edit pickup location
      }
    }
    
    // Mark as initialized after 3 seconds max, even if location not perfect
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
      debugPrint('✅ Initialization complete');
    }
  }
  
  /// Fetch readable address for pickup location in background
  Future<void> _fetchPickupAddress(Position position) async {
    try {
      await ref.read(globalAddressParserProvider).humanReadableAddress(
        position,
        context,
        ref,
      );
      debugPrint('✅ Pickup address updated');
      if (mounted) {
        setState(() {}); // Refresh to show address
      }
    } catch (e) {
      debugPrint('⚠️ Could not fetch address: $e');
      // Not critical - coordinates are enough for booking
    }
  }

  /// Load user's 2 most recent trips
  Future<void> _loadRecentTrips() async {
    final user = ref.read(firebaseAuthUserProvider).value;
    if (user == null) return;

    ref.read(recentTripsLoadingProvider.notifier).state = true;

    try {
      final rideRepo = ref.read(rideRepositoryProvider);
      final allHistory = await rideRepo.getUserRideHistory(user.uid);
      
      // Get only the 2 most recent trips
      final recentTrips = allHistory.take(2).toList();
      ref.read(recentTripsProvider.notifier).state = recentTrips;
    } catch (e) {
      debugPrint('❌ Error loading recent trips: $e');
      ref.read(recentTripsProvider.notifier).state = [];
    } finally {
      ref.read(recentTripsLoadingProvider.notifier).state = false;
    }
  }

  /// Handle clicking on a recent trip - set destination and trigger workflow
  Future<void> _onRecentTripTap(RideRequestModel trip) async {
    // Wait for map controller if not ready yet
    if (_mapController == null) {
      debugPrint('⏳ Waiting for map controller...');
      try {
        _mapController = await _completer.future.timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw TimeoutException('Map initialization timeout');
          },
        );
        debugPrint('✅ Map controller ready');
      } catch (e) {
        debugPrint('❌ Map controller initialization failed: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Map initialization failed. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    try {
      // Set the destination
      final destination = Direction(
        humanReadableAddress: trip.dropoffAddress,
        locationName: _getLocationName(trip.dropoffAddress),
        locationLatitude: trip.dropoffLocation.latitude,
        locationLongitude: trip.dropoffLocation.longitude,
        locationId: null,
      );

      ref.read(homeScreenDropOffLocationProvider.notifier).state = destination;

      if (!mounted) return;

      // Trigger the shared workflow
      await _handleDestinationSelected();
      
    } catch (e) {
      debugPrint('❌ Error handling recent trip: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading trip: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handle destination selected - trigger fare calculation and vehicle selection
  Future<void> _handleDestinationSelected() async {
    // Don't proceed if not fully initialized
    if (!_isInitialized) {
      debugPrint('⏳ Waiting for initialization to complete...');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loading... Please wait a moment'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      
      // Wait up to 5 more seconds for initialization
      for (int i = 0; i < 25; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (_isInitialized) {
          debugPrint('✅ Initialization completed');
          break;
        }
      }
      
      if (!_isInitialized) {
        throw Exception('App still initializing. Please wait a few more seconds and try again.');
      }
    }
    
    final destination = ref.read(homeScreenDropOffLocationProvider);
    
    if (destination == null) {
      debugPrint('ℹ️ No destination selected');
      return;
    }
    
    debugPrint('✅ Destination selected: ${destination.locationName}');
    
    try {
      // Get pickup location (should already be set from initialization)
      var pickupLocation = ref.read(homeScreenPickUpLocationProvider);
      
      if (pickupLocation == null) {
        debugPrint('⏳ Waiting for pickup location...');
        // Wait for pickup location to be set by getUserLoc
        for (int i = 0; i < 30; i++) {
          await Future.delayed(const Duration(milliseconds: 100));
          pickupLocation = ref.read(homeScreenPickUpLocationProvider);
          if (pickupLocation != null) {
            debugPrint('✅ Pickup location ready: ${pickupLocation.humanReadableAddress}');
            break;
          }
        }
        
        if (pickupLocation == null) {
          throw Exception('Could not get your current location. Please enable location services.');
        }
      } else {
        debugPrint('✅ Pickup location already set: ${pickupLocation.humanReadableAddress}');
      }
      
      // Validate locations have all required data
      debugPrint('📍 Validating location data...');
      debugPrint('   Pickup lat: ${pickupLocation.locationLatitude}');
      debugPrint('   Pickup lng: ${pickupLocation.locationLongitude}');
      debugPrint('   Dropoff lat: ${destination.locationLatitude}');
      debugPrint('   Dropoff lng: ${destination.locationLongitude}');
      
      if (pickupLocation.locationLatitude == null || 
          pickupLocation.locationLongitude == null ||
          destination.locationLatitude == null ||
          destination.locationLongitude == null) {
        throw Exception('Location coordinates are missing. Please try again.');
      }
      
      // Calculate fare directly without map rendering
      debugPrint('🔄 Calculating fare...');
      
      try {
        // Just calculate the fare, don't do map stuff
        await ref.read(globalDirectionPolylinesRepoProvider).calculateRideRate(context, ref);
        
        debugPrint('✅ Fare calculation initiated');
      } catch (fareError) {
        debugPrint('❌ Fare calculation error: $fareError');
        throw Exception('Failed to calculate fare: $fareError');
      }
      
      // Wait for fare to be calculated and check periodically
      debugPrint('⏳ Waiting for fare result...');
      double? calculatedFare;
      
      for (int i = 0; i < 30; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        calculatedFare = ref.read(homeScreenRateProvider);
        
        if (calculatedFare != null && calculatedFare > 0) {
          debugPrint('✅ Base fare: \$${calculatedFare.toStringAsFixed(2)} (after ${(i + 1) * 200}ms)');
          
          // Force UI rebuild to show fare in the card
          if (mounted) {
            setState(() {});
          }
          break;
        }
        
        // Log progress every 2 seconds
        if ((i + 1) % 10 == 0) {
          debugPrint('⏳ Still calculating... ${(i + 1) * 200}ms elapsed');
        }
      }
      
      if (calculatedFare == null || calculatedFare == 0) {
        debugPrint('⚠️ Fare calculation timeout or returned zero');
        throw Exception('Failed to calculate fare. Please try again.');
      }
      
      // Give a moment for everything to settle
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (!mounted) return;
      
      // Show vehicle selection bottom sheet
      final size = MediaQuery.of(context).size;
      debugPrint('🚗 Opening vehicle selection with fare: \$${calculatedFare.toStringAsFixed(2)}');
      
      try {
        HomeScreenLogics().requestARide(size, context, ref, _mapController!);
        debugPrint('✅ Vehicle selection sheet should appear');
      } catch (requestError) {
        debugPrint('❌ Request ride error: $requestError');
        throw Exception('Failed to show vehicle options: $requestError');
      }
      
    } catch (e) {
      debugPrint('❌ Error in booking workflow: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Handle "Where to?" search bar tap
  Future<void> _onWhereToTap() async {
    // Wait for map controller if not ready yet
    if (_mapController == null) {
      debugPrint('⏳ Waiting for map controller...');
      try {
        _mapController = await _completer.future.timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw TimeoutException('Map initialization timeout');
          },
        );
        debugPrint('✅ Map controller ready');
      } catch (e) {
        debugPrint('❌ Map controller initialization failed: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Map initialization failed. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    // Open the destination search screen
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WhereToScreen(controller: _mapController!),
      ),
    );

    // After returning from WhereToScreen, check if a destination was selected
    if (!mounted) return;
    
    final destination = ref.read(homeScreenDropOffLocationProvider);
    if (destination != null) {
      _handleDestinationSelected();
    } else {
      debugPrint('ℹ️ No destination selected');
    }
  }

  /// Toggle between "Now" and "Later" scheduling
  void _onScheduleToggle() {
    final currentlyScheduled = ref.read(homeScreenScheduledTimeProvider) != null;
    
    if (currentlyScheduled) {
      // Clear schedule - set to "Now"
      ref.read(homeScreenScheduledTimeProvider.notifier).state = null;
      ref.read(homeScreenIsSchedulingProvider.notifier).state = false;
    } else {
      // Show time picker for "Later"
      _showScheduleTimePicker();
    }
  }

  /// Show time picker for scheduling ride
  Future<void> _showScheduleTimePicker() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blue,
              surface: Color(0xFF1E1E1E),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blue,
              surface: Color(0xFF1E1E1E),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null || !mounted) return;

    final scheduledDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    // Check if scheduled time is in the future
    if (scheduledDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a future time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ref.read(homeScreenScheduledTimeProvider.notifier).state = scheduledDateTime;
    ref.read(homeScreenIsSchedulingProvider.notifier).state = true;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ride scheduled for ${DateFormat('MMM d, h:mm a').format(scheduledDateTime)}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final recentTrips = ref.watch(recentTripsProvider);
    final isLoadingTrips = ref.watch(recentTripsLoadingProvider);
    final scheduledTime = ref.watch(homeScreenScheduledTimeProvider);
    final pickupLocation = ref.watch(homeScreenPickUpLocationProvider);
    final selectedDestination = ref.watch(homeScreenDropOffLocationProvider);
    final calculatedFare = ref.watch(homeScreenRateProvider);
    final selectedVehicleType = ref.watch(homeScreenSelectedVehicleTypeProvider);
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: Stack(
            children: [
              // Full Google Map (like classic home screen) - but will be covered by content
              GoogleMap(
                mapType: MapType.normal,
                myLocationButtonEnabled: false,
                trafficEnabled: false,
                compassEnabled: false,
                buildingsEnabled: false,
                myLocationEnabled: true,
                zoomControlsEnabled: false,
                zoomGesturesEnabled: false,
                scrollGesturesEnabled: false,
                rotateGesturesEnabled: false,
                tiltGesturesEnabled: false,
                initialCameraPosition: _initPos,
                polylines: ref.watch(homeScreenMainPolylinesProvider),
                markers: ref.watch(homeScreenMainMarkersProvider),
                circles: ref.watch(homeScreenMainCirclesProvider),
                onMapCreated: (map) {
                  _completer.complete(map);
                  _mapController = map;
                  SetBlackMap().setBlackMapTheme(map);
                  debugPrint('✅ Map controller initialized');
                  // Initialize user location - same as classic home screen
                  HomeScreenLogics().getUserLoc(context, ref, map);
                },
              ),
            
            // Main content overlay (covers the map)
            Container(
              color: Colors.black,
              child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // Header
                _buildHeader(),
                
                const SizedBox(height: 24),
                
                // Selected Destination Display (if destination is set)
                if (selectedDestination != null)
                  _buildTripSummaryCard(pickupLocation, selectedDestination, calculatedFare, selectedVehicleType),
                
                if (selectedDestination != null)
                  const SizedBox(height: 24),
                
                // "Where to?" Search Bar with Now/Later toggle
                _buildSearchBar(scheduledTime),
                
                const SizedBox(height: 32),
                
                // Recent Trips Section (hide if destination is selected)
                if (selectedDestination == null && (recentTrips.isNotEmpty || isLoadingTrips))
                  _buildRecentTripsSection(recentTrips, isLoadingTrips),
                
                // Suggestions Section (hide if destination is selected)
                if (selectedDestination == null)
                  const SizedBox(height: 32),
                
                if (selectedDestination == null)
                  _buildSuggestionsSection(),
                
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  /// Handle editing pickup location
  Future<void> _onEditPickupLocation() async {
    if (_mapController == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Map not ready. Please try again.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Open WhereToScreen for pickup location selection
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _PickupLocationScreen(mapController: _mapController!),
      ),
    );

    // After returning, check if pickup changed and recalculate if needed
    if (!mounted) return;
    
    final pickup = ref.read(homeScreenPickUpLocationProvider);
    final dropoff = ref.read(homeScreenDropOffLocationProvider);
    
    if (pickup != null && dropoff != null) {
      debugPrint('🔄 Pickup location changed, recalculating route...');
      
      try {
        // Recalculate route and fare with new pickup location
        await HomeScreenLogics().refreshRouteAndFare(context, ref, _mapController!);
        
        // Wait for calculation
        await Future.delayed(const Duration(milliseconds: 1500));
        
        if (!mounted) return;
        
        // Show vehicle selection again
        final size = MediaQuery.of(context).size;
        HomeScreenLogics().requestARide(size, context, ref, _mapController!);
      } catch (e) {
        debugPrint('❌ Error recalculating: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Build trip summary card showing pickup and dropoff
  Widget _buildTripSummaryCard(Direction? pickup, Direction dropoff, double? fare, String? vehicleType) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Clear button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Trip Summary',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                  letterSpacing: 0.5,
                ),
              ),
              InkWell(
                onTap: () {
                  // Clear all booking data
                  ref.read(homeScreenDropOffLocationProvider.notifier).state = null;
                  ref.read(homeScreenRateProvider.notifier).state = null;
                  ref.read(homeScreenSelectedVehicleTypeProvider.notifier).state = null;
                  ref.read(homeScreenMainPolylinesProvider.notifier).state = {};
                  ref.read(homeScreenMainMarkersProvider.notifier).state = {};
                  ref.read(homeScreenMainCirclesProvider.notifier).state = {};
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.close, size: 14, color: Colors.red),
                      SizedBox(width: 4),
                      Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Pickup Location (editable)
          _buildLocationRow(
            icon: Icons.my_location,
            iconColor: Colors.green,
            label: 'Pickup',
            locationName: pickup?.locationName ?? 'Current Location',
            address: pickup?.humanReadableAddress ?? 'Getting location...',
            isEditable: true,
            onEdit: _onEditPickupLocation,
          ),
          
          const SizedBox(height: 12),
          
          // Dotted line connector
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Container(
              width: 2,
              height: 30,
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Colors.grey[600]!,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
              ),
              child: CustomPaint(
                painter: DashedLinePainter(color: Colors.grey[600]!),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Dropoff Location
          _buildLocationRow(
            icon: Icons.location_on,
            iconColor: Colors.blue,
            label: 'Dropoff',
            locationName: dropoff.locationName ?? 'Destination',
            address: dropoff.humanReadableAddress ?? '',
            isEditable: false,
          ),
          
          // Fare information (if calculated)
          if (fare != null) ...[
            const SizedBox(height: 20),
            const Divider(color: Colors.grey, height: 1),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.attach_money, color: Colors.green, size: 20),
                      const SizedBox(width: 4),
                      const Text(
                        'Base Fare: ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        '\$${fare.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  if (vehicleType != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        vehicleType,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '💡 Vehicle options will appear below',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white60,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Calculating fare...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Build a location row (for pickup or dropoff)
  Widget _buildLocationRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String locationName,
    required String address,
    bool isEditable = false,
    VoidCallback? onEdit,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 22,
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Location info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[400],
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (isEditable) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: onEdit,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.orange, width: 1),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit, size: 10, color: Colors.orange),
                            SizedBox(width: 3),
                            Text(
                              'Edit',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                locationName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build header with title
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            // Show initialization status
            if (!_isInitialized)
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange, width: 1),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Loading...',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.directions_car,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Rides',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        // Toggle button to switch back to classic view
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: Colors.grey[900],
                title: const Text('Switch View', style: TextStyle(color: Colors.white)),
                content: const Text('Switch back to classic home screen?', style: TextStyle(color: Colors.white70)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(useModernHomeScreenProvider.notifier).state = false;
                      Navigator.pop(context);
                    },
                    child: const Text('Switch'),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  /// Build "Where to?" search bar with Now/Later toggle
  Widget _buildSearchBar(DateTime? scheduledTime) {
    final isScheduled = scheduledTime != null;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.grey[700]!, width: 1),
      ),
      child: Row(
        children: [
          // Search icon and text
          Expanded(
            child: InkWell(
              onTap: _onWhereToTap,
              borderRadius: BorderRadius.circular(32),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Where to?',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Now/Later toggle button
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: _onScheduleToggle,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.schedule,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isScheduled 
                          ? DateFormat('h:mm a').format(scheduledTime)
                          : 'Now',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build Recent Trips section
  Widget _buildRecentTripsSection(List<RideRequestModel> trips, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Trips',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        
        if (isLoading)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: CircularProgressIndicator(color: Colors.blue),
            ),
          )
        else if (trips.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: Center(
              child: Text(
                'No recent trips yet',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          ...trips.map((trip) => _buildRecentTripItem(trip)),
      ],
    );
  }

  /// Build individual recent trip item
  Widget _buildRecentTripItem(RideRequestModel trip) {
    return InkWell(
      onTap: () => _onRecentTripTap(trip),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          border: Border.all(color: Colors.grey[700]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Location icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Address info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getLocationName(trip.dropoffAddress),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    trip.dropoffAddress,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[400],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
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

  /// Extract location name from full address
  String _getLocationName(String fullAddress) {
    // Try to extract the main location name (before first comma)
    final parts = fullAddress.split(',');
    if (parts.isNotEmpty) {
      return parts[0].trim();
    }
    return fullAddress;
  }

  /// Build Suggestions section with action tiles
  Widget _buildSuggestionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Suggestions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to more options or all suggestions
              },
              child: Text(
                'See all',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Suggestion tiles
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildSuggestionTile(
                icon: Icons.flight,
                label: 'Airports',
                badge: 'Near',
                badgeColor: Colors.orange,
                onTap: () async {
                  // Wait for map controller if needed
                  if (_mapController == null) {
                    try {
                      _mapController = await _completer.future.timeout(
                        const Duration(seconds: 5),
                      );
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Map not ready. Please try again.'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                      return;
                    }
                  }
                  
                  // Clear any previous destination
                  final previousDestination = ref.read(homeScreenDropOffLocationProvider);
                  
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => NearbyAirportsScreen(
                        mapController: _mapController!,
                      ),
                    ),
                  );
                  
                  // After returning, check if a new airport was selected
                  if (!mounted) return;
                  
                  final newDestination = ref.read(homeScreenDropOffLocationProvider);
                  
                  // If destination changed, trigger workflow
                  if (newDestination != null && newDestination != previousDestination) {
                    debugPrint('✅ Airport selected, triggering workflow');
                    _handleDestinationSelected();
                  }
                },
              ),
              
              const SizedBox(width: 12),
              
              _buildSuggestionTile(
                icon: Icons.delivery_dining,
                label: 'Delivery',
                badge: 'New',
                badgeColor: Colors.orange,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const DeliveryRequestScreen(),
                    ),
                  );
                },
              ),
              
              const SizedBox(width: 12),
              
              _buildSuggestionTile(
                icon: Icons.schedule,
                label: 'Reserve',
                badge: 'Promo',
                badgeColor: Colors.green,
                onTap: () {
                  _onScheduleToggle();
                  Future.delayed(const Duration(milliseconds: 300), _onWhereToTap);
                },
              ),
              
              const SizedBox(width: 12),
              
              _buildSuggestionTile(
                icon: Icons.favorite,
                label: 'Favorites',
                onTap: () {
                  // Open WhereToScreen which has favorites integration
                  _onWhereToTap();
                },
              ),
              
              const SizedBox(width: 12),
              
              _buildSuggestionTile(
                icon: Icons.payment,
                label: 'Payment',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PaymentMethodsScreen(),
                    ),
                  );
                },
              ),
              
              const SizedBox(width: 12),
              
              _buildSuggestionTile(
                icon: Icons.history,
                label: 'History',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const RideHistoryScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build individual suggestion tile
  Widget _buildSuggestionTile({
    required IconData icon,
    required String label,
    String? badge,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 120,
        height: 140,
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[700]!),
        ),
        child: Stack(
          children: [
            // Badge (if provided)
            if (badge != null)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor ?? Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            
            // Icon and label
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Icon(
                      icon,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

/// Custom painter for dashed line
class DashedLinePainter extends CustomPainter {
  final Color color;
  
  DashedLinePainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashWidth),
        paint,
      );
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Screen for selecting a different pickup location
class _PickupLocationScreen extends ConsumerStatefulWidget {
  final GoogleMapController mapController;

  const _PickupLocationScreen({required this.mapController});

  @override
  ConsumerState<_PickupLocationScreen> createState() => _PickupLocationScreenState();
}

class _PickupLocationScreenState extends ConsumerState<_PickupLocationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Select Pickup Location'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info message
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange, width: 1),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Search for a different pickup location if you\'re not at your current location.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Search button
              InkWell(
                onTap: () async {
                  // Open WhereToScreen in special mode to select pickup
                  final currentDropoff = ref.read(homeScreenDropOffLocationProvider);
                  
                  // Temporarily clear dropoff to allow pickup selection
                  ref.read(homeScreenDropOffLocationProvider.notifier).state = null;
                  
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => WhereToScreen(controller: widget.mapController),
                    ),
                  );
                  
                  // Check if a location was selected
                  final newPickup = ref.read(homeScreenDropOffLocationProvider);
                  
                  if (newPickup != null) {
                    // Move the selected location to pickup provider
                    ref.read(homeScreenPickUpLocationProvider.notifier).state = newPickup;
                    
                    // Restore dropoff
                    ref.read(homeScreenDropOffLocationProvider.notifier).state = currentDropoff;
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Pickup location updated'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      
                      // Close this screen
                      Navigator.of(context).pop();
                    }
                  } else {
                    // Restore dropoff if user didn't select anything
                    ref.read(homeScreenDropOffLocationProvider.notifier).state = currentDropoff;
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[700]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Search for pickup location...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[400],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Current location button
              InkWell(
                onTap: () async {
                  try {
                    // Get fresh current location
                    final position = await Geolocator.getCurrentPosition(
                      desiredAccuracy: LocationAccuracy.high,
                    );
                    
                    // Get address for this position
                    await ref.read(globalAddressParserProvider).humanReadableAddress(
                      position,
                      context,
                      ref,
                    );
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Pickup set to current location'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      
                      Navigator.of(context).pop();
                    }
                  } catch (e) {
                    debugPrint('❌ Error getting current location: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green, width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Use Current Location',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Pick me up from where I am now',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

