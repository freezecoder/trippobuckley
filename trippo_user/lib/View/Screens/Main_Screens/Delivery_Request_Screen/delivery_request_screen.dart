import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:btrips_unified/View/Screens/Main_Screens/Delivery_Request_Screen/delivery_providers.dart';
import 'package:btrips_unified/View/Screens/Main_Screens/Delivery_Request_Screen/Components/category_selection_widget.dart';
import 'package:btrips_unified/View/Screens/Main_Screens/Delivery_Request_Screen/Components/verification_code_display.dart';
import 'package:btrips_unified/View/Screens/Main_Screens/Delivery_Request_Screen/Components/delivery_summary_card.dart';
import 'package:btrips_unified/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_screen.dart';
import 'package:btrips_unified/View/Screens/Main_Screens/Home_Screen/home_providers.dart';
import 'package:btrips_unified/features/shared/presentation/screens/ride_delivery_details_screen.dart';
import 'package:btrips_unified/core/utils/delivery_helpers.dart';
import 'package:btrips_unified/Container/Repositories/firestore_repo.dart';
import 'package:btrips_unified/Model/direction_model.dart';
import 'package:geolocator/geolocator.dart';

/// Main screen for creating a delivery request
class DeliveryRequestScreen extends ConsumerStatefulWidget {
  const DeliveryRequestScreen({super.key});

  @override
  ConsumerState<DeliveryRequestScreen> createState() =>
      _DeliveryRequestScreenState();
}

class _DeliveryRequestScreenState extends ConsumerState<DeliveryRequestScreen> {
  final TextEditingController _itemsController = TextEditingController();
  final TextEditingController _itemCostController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  GoogleMapController? _mapController;
  bool _isCalculatingFare = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeDeliveryMode();
  }

  Future<void> _initializeDeliveryMode() async {
    // Generate verification code
    final code = DeliveryHelpers.generateVerificationCode();
    ref.read(deliveryVerificationCodeProvider.notifier).state = code;

    // Set delivery mode
    ref.read(isDeliveryModeProvider.notifier).state = true;

    // Get user's current location as dropoff
    await _getCurrentLocationAsDropoff();
  }

  Future<void> _getCurrentLocationAsDropoff() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      
      // Create direction for current location
      final currentLocation = Direction(
        locationName: 'Your Location',
        locationLatitude: position.latitude,
        locationLongitude: position.longitude,
        humanReadableAddress: 'Current Location',
      );

      ref.read(homeScreenPickUpLocationProvider.notifier).state =
          currentLocation;
      
      debugPrint('✅ Current location set as dropoff: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      debugPrint('❌ Error getting current location: $e');
      setState(() {
        _errorMessage = 'Could not get your current location. Please enable location services.';
      });
    }
  }

  Future<void> _selectPickupLocation() async {
    if (!mounted) return;

    // Save the current user location
    final userLocation = ref.read(homeScreenPickUpLocationProvider);
    
    // Temporarily clear dropoff so WhereToScreen can set it
    ref.read(homeScreenDropOffLocationProvider.notifier).state = null;
    
    // Navigate directly to search - no dialog needed
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _PickupLocationSearchScreen(),
      ),
    );

    if (mounted) {
      // Location was selected and stored in homeScreenDropOffLocationProvider
      final selectedLocation = ref.read(homeScreenDropOffLocationProvider);
      if (selectedLocation != null) {
        // Store as delivery pickup location
        ref.read(deliveryPickupLocationProvider.notifier).state = selectedLocation;
        
        // Restore user location to pickup provider and clear dropoff
        ref.read(homeScreenPickUpLocationProvider.notifier).state = userLocation;
        ref.read(homeScreenDropOffLocationProvider.notifier).state = null;
        
        // Calculate fare
        _calculateDeliveryFare();
      }
    }
  }

  void _calculateDeliveryFare() {
    final pickup = ref.read(deliveryPickupLocationProvider);
    final dropoff = ref.read(homeScreenPickUpLocationProvider);

    if (pickup == null || dropoff == null) return;

    setState(() {
      _isCalculatingFare = true;
    });

    // Calculate distance using Haversine formula
    final distance = _calculateDistance(
      pickup.locationLatitude ?? 0,
      pickup.locationLongitude ?? 0,
      dropoff.locationLatitude ?? 0,
      dropoff.locationLongitude ?? 0,
    );

    final itemCost = double.tryParse(_itemCostController.text) ?? 0.0;
    final deliveryFee = DeliveryHelpers.calculateDeliveryFare(
      distanceMiles: distance,
      itemCost: itemCost,
    );

    ref.read(deliveryDistanceProvider.notifier).state = distance;
    ref.read(deliveryFareProvider.notifier).state = deliveryFee;

    setState(() {
      _isCalculatingFare = false;
    });

    debugPrint('📊 Delivery fare calculated: \$${deliveryFee.toStringAsFixed(2)} for ${distance.toStringAsFixed(1)} miles');
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusMiles = 3958.8;
    
    final dLat = (lat2 - lat1) * pi / 180.0;
    final dLon = (lon2 - lon1) * pi / 180.0;
    
    final lat1Rad = lat1 * pi / 180.0;
    final lat2Rad = lat2 * pi / 180.0;
    
    final a = pow(sin(dLat / 2), 2) +
        pow(sin(dLon / 2), 2) * cos(lat1Rad) * cos(lat2Rad);
    
    final c = 2 * asin(sqrt(a));
    
    return earthRadiusMiles * c;
  }

  Future<void> _submitDeliveryRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final category = ref.read(deliveryCategoryProvider);
    final pickupLocation = ref.read(deliveryPickupLocationProvider);
    final dropoffLocation = ref.read(homeScreenPickUpLocationProvider);
    final verificationCode = ref.read(deliveryVerificationCodeProvider);
    final deliveryFee = ref.read(deliveryFareProvider);
    final distance = ref.read(deliveryDistanceProvider);

    // Validate
    final validation = DeliveryHelpers.validateDeliveryRequest(
      pickupAddress: pickupLocation?.humanReadableAddress,
      deliveryCategory: category,
      itemsDescription: _itemsController.text,
      itemCost: double.tryParse(_itemCostController.text) ?? 0.0,
    );

    if (!validation['isValid']) {
      final errors = validation['errors'] as List<String>;
      setState(() {
        _errorMessage = errors.join('\n');
      });
      return;
    }

    if (deliveryFee == null || distance == null) {
      setState(() {
        _errorMessage = 'Please wait while we calculate the delivery fee';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    ref.read(isCreatingDeliveryProvider.notifier).state = true;

    try {
      // Create delivery request
      final itemCost = double.tryParse(_itemCostController.text) ?? 0.0;
      
      final rideId = await ref.read(globalFirestoreRepoProvider).addDeliveryRequestToDB(
        context: context,
        ref: ref,
        pickupLocation: GeoPoint(
          pickupLocation!.locationLatitude!,
          pickupLocation.locationLongitude!,
        ),
        pickupAddress: pickupLocation.locationName ?? pickupLocation.humanReadableAddress ?? 'Unknown',
        dropoffLocation: GeoPoint(
          dropoffLocation!.locationLatitude!,
          dropoffLocation.locationLongitude!,
        ),
        dropoffAddress: dropoffLocation.locationName ?? dropoffLocation.humanReadableAddress ?? 'Your Location',
        deliveryCategory: category!,
        itemsDescription: _itemsController.text,
        itemCost: itemCost,
        verificationCode: verificationCode!,
        fare: deliveryFee + itemCost,
        distance: distance,
      );

      if (rideId != null && mounted) {
        // Success! Navigate to tracking screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Delivery requested! Finding driver...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate to tracking screen
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => RideDeliveryDetailsScreen(
                rideId: rideId,
                isDriver: false,
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error creating delivery request: $e');
      setState(() {
        _errorMessage = 'Failed to create delivery request: $e';
      });
    } finally {
      ref.read(isCreatingDeliveryProvider.notifier).state = false;
    }
  }

  @override
  void dispose() {
    _itemsController.dispose();
    _itemCostController.dispose();
    // Reset delivery mode
    ref.read(isDeliveryModeProvider.notifier).state = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = ref.watch(deliveryCategoryProvider);
    final pickupLocation = ref.watch(deliveryPickupLocationProvider);
    final dropoffLocation = ref.watch(homeScreenPickUpLocationProvider);
    final verificationCode = ref.watch(deliveryVerificationCodeProvider);
    final deliveryFee = ref.watch(deliveryFareProvider);
    final distance = ref.watch(deliveryDistanceProvider);
    final isCreating = ref.watch(isCreatingDeliveryProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Color(0xff1a3646),
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Request Delivery',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.grey[900],
                  title: Text(
                    'How Delivery Works',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: Text(
                    '1. Select where to pick up items\n'
                    '2. Choose delivery category\n'
                    '3. Describe the items\n'
                    '4. Enter item cost (if driver pays)\n'
                    '5. Review and confirm\n'
                    '6. Share code with store staff\n'
                    '7. Driver picks up and delivers to you',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error message
              if (_errorMessage != null)
                Container(
                  padding: EdgeInsets.all(12),
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.white, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              // Pickup Location Selection
              Text(
                'Pickup Location',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              InkWell(
                onTap: _selectPickupLocation,
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: pickupLocation != null ? Colors.orange : Colors.grey[700]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.store,
                        color: pickupLocation != null ? Colors.orange : Colors.grey,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          pickupLocation?.locationName ??
                              pickupLocation?.humanReadableAddress ??
                              'Select pickup location',
                          style: TextStyle(
                            color: pickupLocation != null ? Colors.white : Colors.grey[500],
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Category Selection
              CategorySelectionWidget(
                selectedCategory: selectedCategory,
                onCategorySelected: (category) {
                  ref.read(deliveryCategoryProvider.notifier).state = category;
                },
              ),

              SizedBox(height: 24),

              // Items Description
              Text(
                'Items Description',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _itemsController,
                style: TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'e.g., 2 large pizzas, garlic bread, 2 sodas',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  filled: true,
                  fillColor: Colors.grey[850],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[700]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[700]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.orange, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please describe the items';
                  }
                  if (value.trim().length < 3) {
                    return 'Description must be at least 3 characters';
                  }
                  return null;
                },
              ),

              SizedBox(height: 24),

              // Item Cost
              Text(
                'Item Cost (Optional)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'If driver needs to pay for items, enter the amount here',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _itemCostController,
                style: TextStyle(color: Colors.white, fontSize: 18),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.attach_money, color: Colors.green),
                  hintText: '0.00',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  filled: true,
                  fillColor: Colors.grey[850],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[700]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[700]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.orange, width: 2),
                  ),
                ),
                onChanged: (value) {
                  // Recalculate fare when item cost changes
                  if (pickupLocation != null) {
                    _calculateDeliveryFare();
                  }
                },
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final amount = double.tryParse(value);
                    if (amount == null) {
                      return 'Please enter a valid amount';
                    }
                    if (amount < 0 || amount > 500) {
                      return 'Amount must be between \$0 and \$500';
                    }
                  }
                  return null;
                },
              ),

              SizedBox(height: 24),

              // Verification Code Display
              if (verificationCode != null)
                VerificationCodeDisplay(verificationCode: verificationCode),

              SizedBox(height: 24),

              // Delivery Summary
              if (pickupLocation != null &&
                  dropoffLocation != null &&
                  deliveryFee != null)
                DeliverySummaryCard(
                  pickupLocation: pickupLocation,
                  dropoffLocation: dropoffLocation,
                  category: selectedCategory,
                  itemsDescription: _itemsController.text,
                  itemCost: double.tryParse(_itemCostController.text) ?? 0.0,
                  deliveryFee: deliveryFee,
                  distance: distance,
                ),

              SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isCreating || _isCalculatingFare
                      ? null
                      : _submitDeliveryRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    disabledBackgroundColor: Colors.grey[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isCreating
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Creating Request...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Request Delivery',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple wrapper for pickup location search
class _PickupLocationSearchScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<_PickupLocationSearchScreen> createState() =>
      __PickupLocationSearchScreenState();
}

class __PickupLocationSearchScreenState
    extends ConsumerState<_PickupLocationSearchScreen> {
  final Completer<GoogleMapController> _controller = Completer();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Invisible map (just for controller)
          Positioned(
            left: 0,
            top: 0,
            child: SizedBox(
              width: 1,
              height: 1,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(37.7749, -122.4194), // San Francisco
                  zoom: 12,
                ),
                onMapCreated: (controller) {
                  if (!_controller.isCompleted) {
                    _controller.complete(controller);
                  }
                },
              ),
            ),
          ),
          // Search screen overlay
          FutureBuilder<GoogleMapController>(
            future: _controller.future,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return WhereToScreen(controller: snapshot.data!);
              }
              return Center(
                child: CircularProgressIndicator(color: Colors.orange),
              );
            },
          ),
        ],
      ),
    );
  }
}

