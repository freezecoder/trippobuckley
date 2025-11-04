import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoder2/geocoder2.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lottie/lottie.dart' as lottie;
import 'package:btrips_unified/Container/Repositories/address_parser_repo.dart';
import 'package:btrips_unified/Container/Repositories/direction_polylines_repo.dart';
import 'package:btrips_unified/Container/Repositories/firestore_repo.dart';
import 'package:btrips_unified/Container/utils/error_notification.dart';
import 'package:btrips_unified/Container/utils/keys.dart';
import 'package:btrips_unified/Container/utils/distance_calculator.dart';
import 'package:btrips_unified/Container/utils/currency_config.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:btrips_unified/Model/direction_model.dart';
import 'package:btrips_unified/Model/preset_location_model.dart' as OldModel;
import 'package:btrips_unified/data/models/preset_location_model.dart';
import 'package:btrips_unified/View/Components/all_components.dart';
import 'package:btrips_unified/View/Screens/Main_Screens/Home_Screen/home_providers.dart';
import 'package:btrips_unified/View/Screens/Main_Screens/Home_Screen/vehicle_type_selection_sheet.dart';
import 'package:dio/dio.dart';

class HomeScreenLogics {
  void changePickUpLoc(BuildContext context, WidgetRef ref,
      GoogleMapController controller) async {
    try {
      ref
          .watch(homeScreenDropOffLocationProvider.notifier)
          .update((state) => null);

      ref
          .watch(homeScreenMainMarkersProvider)
          .removeWhere((element) => element.markerId.value == "pickUpId");
      ref
          .watch(homeScreenMainMarkersProvider)
          .removeWhere((element) => element.markerId.value == "dropOffId");
      ref
          .watch(homeScreenMainCirclesProvider)
          .removeWhere((ele) => ele.circleId.value == "pickUpCircle");
      ref
          .watch(homeScreenMainCirclesProvider)
          .removeWhere((ele) => ele.circleId.value == "dropOffCircle");
      ref.watch(homeScreenMainPolylinesProvider.notifier).update((state) => {});
      Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
          target: LatLng(pos.latitude, pos.longitude), zoom: 14)));
    } catch (e) {
      if (context.mounted) {
        ElegantNotification.error(
            description: Text(
          "An Error Occurred $e",
          style: const TextStyle(color: Colors.black),
        )).show(context);
      }
    }
  }

  /// [getUserLoc] fetches a the users location as soon as user start the app

  void getUserLoc(BuildContext context, WidgetRef ref,
      GoogleMapController controller) async {
    try {
      Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
          target: LatLng(pos.latitude, pos.longitude), zoom: 14)));

      if (context.mounted) {
        await ref
            .watch(globalAddressParserProvider)
            .humanReadableAddress(pos, context, ref);
      }
      if (context.mounted) {
        ref
            .read(globalFirestoreRepoProvider)
            .getDriverData(context, ref, LatLng(pos.latitude, pos.longitude));
      }
    } catch (e) {
      if (context.mounted) {
        ErrorNotification().showError(context, "An Error Occurred $e");
      }
    }
  }

  /// [getAddressfromCordinates] read data from [cameraMovementProvider] (which is updated whenever the camera moves) and gets the human readable address
  /// from the [cameraMovementProvider] and returns a [Direction] model which is assigned to [pickUpLocationProvider] (which sets the user's pick up Location)

  void getAddressfromCordinates(BuildContext context, WidgetRef ref) async {
    try {
      if (ref.read(homeScreenCameraMovementProvider) == null) {
        return;
      }

      final latitude = ref.read(homeScreenCameraMovementProvider)!.latitude;
      final longitude = ref.read(homeScreenCameraMovementProvider)!.longitude;
      String address = '';

      // Try geocoder2 first (Google Maps API)
      try {
        GeoData data = await Geocoder2.getDataFromCoordinates(
            latitude: latitude,
            longitude: longitude,
            googleMapApiKey: Keys.mapKey);
        address = data.address;
      } catch (geocoder2Error) {
        // Fallback to geocoding package (native platform services, no CORS)
        debugPrint("geocoder2 failed, trying geocoding package: $geocoder2Error");
        try {
          List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
            latitude,
            longitude,
          );
          if (placemarks.isNotEmpty) {
            final placemark = placemarks[0];
            final addressParts = <String>[];
            if (placemark.street != null && placemark.street!.isNotEmpty) {
              addressParts.add(placemark.street!);
            }
            if (placemark.subThoroughfare != null && placemark.subThoroughfare!.isNotEmpty) {
              addressParts.insert(0, placemark.subThoroughfare!);
            }
            if (placemark.locality != null && placemark.locality!.isNotEmpty) {
              addressParts.add(placemark.locality!);
            }
            if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) {
              addressParts.add(placemark.administrativeArea!);
            }
            address = addressParts.isNotEmpty 
                ? addressParts.join(', ')
                : '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
            debugPrint("✅ Address from geocoding package: $address");
          }
        } catch (geocodingError) {
          debugPrint("geocoding package also failed: $geocodingError");
          // Last resort: use coordinates as address
          address = '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
        }
      }

      Direction model = Direction(
          locationLatitude: latitude,
          locationLongitude: longitude,
          humanReadableAddress: address);

      ref
          .read(homeScreenPickUpLocationProvider.notifier)
          .update((state) => model);
    } catch (e) {
      if (context.mounted) {
        ErrorNotification().showError(context, "An Error Occurred $e");
      }
    }
  }

  /// Function for [WhereTo] TextField Button

  void openWhereToScreen(BuildContext context, WidgetRef ref,
      GoogleMapController controller) async {
    try {
      if (ref.watch(homeScreenDropOffLocationProvider) == null) {
        return;
      }

      if (context.mounted) {
        // Recalculate route and fare
        await refreshRouteAndFare(context, ref, controller);
      }
    } catch (e) {
      if (context.mounted) {
        ErrorNotification().showError(context, "An Error Occurred $e");
      }
    }
  }

  /// Refresh route, fare, markers and circles when dropoff location changes
  /// This is called whenever a new dropoff location is selected (search, presets, etc.)
  Future<void> refreshRouteAndFare(BuildContext context, WidgetRef ref,
      GoogleMapController controller) async {
    try {
      // Check both locations are set
      if (ref.read(homeScreenPickUpLocationProvider) == null ||
          ref.read(homeScreenDropOffLocationProvider) == null) {
        return;
      }

      if (!context.mounted) return;

      /// Reset previous data
      ref.read(homeScreenRateProvider.notifier).update((state) => null);
      ref.read(homeScreenRouteDistanceProvider.notifier).update((state) => null);
      ref.read(homeScreenSelectedVehicleTypeProvider.notifier).update((state) => null);
      ref.read(homeScreenMainPolylinesProvider.notifier).update((state) => {});

      /// Making [Markers] for [pickUp] and [dropOff] Places
      Marker pickUpMarker = Marker(
          markerId: const MarkerId("pickUpId"),
          infoWindow: InfoWindow(
            title: ref.read(homeScreenPickUpLocationProvider)!.locationName,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen),
          position: LatLng(
              ref.read(homeScreenPickUpLocationProvider)!.locationLatitude!,
              ref
                  .read(homeScreenPickUpLocationProvider)!
                  .locationLongitude!));
      Marker dropOffMarker = Marker(
          markerId: const MarkerId("dropOffId"),
          infoWindow: InfoWindow(
            title: ref.read(homeScreenDropOffLocationProvider)!.locationName,
          ),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          position: LatLng(
              ref.read(homeScreenDropOffLocationProvider)!.locationLatitude!,
              ref
                  .read(homeScreenDropOffLocationProvider)!
                  .locationLongitude!));

      /// Making [Circle] for [pickUp] and [dropOff] Places

      Circle pickUpCircle = Circle(
          circleId: const CircleId("pickUpCircle"),
          fillColor: Colors.green,
          radius: 500,
          strokeColor: Colors.black,
          center: LatLng(
              ref.read(homeScreenPickUpLocationProvider)!.locationLatitude!,
              ref
                  .read(homeScreenPickUpLocationProvider)!
                  .locationLongitude!));
      Circle dropOffCircle = Circle(
          circleId: const CircleId("dropOffCircle"),
          fillColor: Colors.red,
          radius: 500,
          strokeColor: Colors.black,
          center: LatLng(
              ref.read(homeScreenDropOffLocationProvider)!.locationLatitude!,
              ref
                  .read(homeScreenDropOffLocationProvider)!
                  .locationLongitude!));

      /// Calling function to draw [Polylines] and calculate fare
      debugPrint('🔄 Recalculating route and fare for new dropoff location...');
      ref
          .read(globalDirectionPolylinesRepoProvider)
          .setNewDirectionPolylines(ref, context, controller);

      /// Adding [Markers] to [pickUp] and [dropOff] Places
      ref
          .read(homeScreenMainMarkersProvider.notifier)
          .update((state) => {...state, pickUpMarker, dropOffMarker});

      /// Adding [Circles] to [pickUp] and [dropOff] Places
      ref
          .read(homeScreenMainCirclesProvider.notifier)
          .update((state) => {...state, pickUpCircle, dropOffCircle});

      debugPrint('✅ Route and fare recalculated successfully');
    } catch (e) {
      if (context.mounted) {
        ErrorNotification().showError(context, "Error calculating route: $e");
      }
      debugPrint('❌ Error in refreshRouteAndFare: $e');
    }
  }

  /// Calculate distance between two coordinates using reliable Haversine formula
  /// Uses DistanceCalculator utility which has fallback logic
  double calculateDistance(
    lat1,
    lon1,
    lat2,
    lon2,
  ) {
    try {
      // Use DistanceCalculator for consistent, reliable distance calculation
      return DistanceCalculator.calculateStraightLineDistance(
        lat1,
        lon1,
        lat2,
        lon2,
      );
    } catch (e) {
      // Fallback to Geolocator if DistanceCalculator fails
      try {
        return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
      } catch (geoError) {
        debugPrint('Error calculating distance: $geoError');
        return 0.0; // Return 0 if all methods fail
      }
    }
  }

  dynamic requestARide(size, BuildContext context, WidgetRef ref,
      GoogleMapController controller) {
    if (ref.watch(homeScreenDropOffLocationProvider) == null) {
      ErrorNotification().showError(context, "Please add destination first");
      return;
    }
    
    // Ensure pickup location is set
    if (ref.watch(homeScreenPickUpLocationProvider) == null) {
      ErrorNotification().showError(context, "Please set your pickup location first");
      return;
    }
    
    // Reset vehicle type selection
    ref.read(homeScreenSelectedVehicleTypeProvider.notifier).state = null;
    
    // Show vehicle type selection sheet (NEW UI)
    return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return VehicleTypeSelectionSheet(
            onVehicleSelected: () async {
              // Get selected vehicle type
              final selectedVehicleType = ref.read(homeScreenSelectedVehicleTypeProvider);
              if (selectedVehicleType == null) {
                ErrorNotification().showError(context, "Please select a vehicle type");
                return;
              }
              
              debugPrint('🚗 Creating ride request with vehicle type: $selectedVehicleType');
              
              // Create ride request with selected vehicle type
              final rideId = await ref
                  .read(globalFirestoreRepoProvider)
                  .addUserRideRequestToDB(
                    context,
                    ref,
                    "", // No specific driver email - any matching driver can accept
                    vehicleType: selectedVehicleType,
                  );
              
              if (rideId != null) {
                // Store ride ID for tracking
                ref.read(currentRideRequestIdProvider.notifier).state = rideId;
                
                // Close modal
                if (context.mounted) {
                  Navigator.pop(context);
                }
                
                // Show success message
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Ride requested! Waiting for $selectedVehicleType driver to accept...',
                      ),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
                
                // Listen for driver acceptance
                _listenForDriverAcceptance(context, ref, rideId);
              }
            },
          );
        },
    );
  }

  /// Listen for driver acceptance of ride request
  void _listenForDriverAcceptance(BuildContext context, WidgetRef ref, String rideId) {
    FirebaseFirestore.instance
        .collection('rideRequests')
        .doc(rideId)
        .snapshots()
        .listen((doc) {
      if (!doc.exists) return;
      
      final data = doc.data();
      if (data == null) return;
      
      final status = data['status'];
      final driverEmail = data['driverEmail'];
      
      // Check if driver accepted
      if (status == 'accepted' && driverEmail != null) {
        debugPrint('✅ Driver accepted ride: $driverEmail');
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Driver accepted your ride! Driver: $driverEmail'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    });
  }

  // Remove old complex implementation below this line
  dynamic _oldRequestARideImplementation(size, BuildContext context, WidgetRef ref,
      GoogleMapController controller) {
    // This is the old implementation - kept for reference but not used
    if (ref.watch(homeScreenDropOffLocationProvider) == null) {
      ErrorNotification().showError(context, "Please add destination first");
      return;
    }
    
    // Ensure pickup location is set
    if (ref.watch(homeScreenPickUpLocationProvider) == null) {
      ErrorNotification().showError(context, "Please set your pickup location first");
      return;
    }
    
    // Try to load drivers if not already loaded
    if (ref.read(homeScreenAvailableDriversProvider).isEmpty && 
        ref.read(homeScreenPickUpLocationProvider) != null) {
      debugPrint('🔄 Requesting ride - Loading drivers...');
      ref.read(globalFirestoreRepoProvider).getDriverData(
        context, 
        ref, 
        LatLng(
          ref.read(homeScreenPickUpLocationProvider)!.locationLatitude!,
          ref.read(homeScreenPickUpLocationProvider)!.locationLongitude!,
        ),
      );
    } else {
      debugPrint('🔍 Drivers already loaded: ${ref.read(homeScreenAvailableDriversProvider).length}');
    }
    
    return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return Consumer(
            builder: (context, ref, child) {
              // Debug: Log driver count
              final driverCount = ref.watch(homeScreenAvailableDriversProvider).length;
              debugPrint('🔍 Modal opened - Driver count: $driverCount');
              
              return Container(
                  width: size.width,
                  constraints: BoxConstraints(
                    maxHeight: size.height * 0.7,
                    minHeight: 400,
                  ),
                  decoration: const BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16.0),
                          topRight: Radius.circular(16.0))),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    switchInCurve: Curves.easeInOut,
                    switchOutCurve: Curves.easeInOut,
                    child: ref.watch(homeScreenStartDriverSearch)
                        ? Column(
                            key: const Key("sec"),
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              lottie.Lottie.asset(
                                "assets/jsons/dribbble.json",
                                height: 200,
                                width: 200,
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 15.0),
                                child: Text(
                                    "Waiting For Driver's Response. You will be notified about your ride's status."),
                              )
                            ],
                          )
                        : SingleChildScrollView(
                            key: const Key("first"),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Header with trip info
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Select a Driver",
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (ref.watch(homeScreenRouteDistanceProvider) != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Distance to Destination: ${DistanceCalculator.formatDistance(ref.watch(homeScreenRouteDistanceProvider)!)}",
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: Colors.white,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              if (ref.watch(homeScreenRateProvider) != null)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 4.0),
                                                  child: Text(
                                                    "Base Fare: ${CurrencyConfig.formatAmount(ref.watch(homeScreenRateProvider)!)} (${DistanceCalculator.formatDistance(ref.watch(homeScreenRouteDistanceProvider)!)} × driver rate)",
                                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      color: Colors.white70,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                // Driver list or empty state
                                Container(
                                  constraints: const BoxConstraints(
                                    minHeight: 200,
                                    maxHeight: 400,
                                  ),
                                  child: ref.watch(homeScreenAvailableDriversProvider).isEmpty
                                    ? Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(20.0),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.directions_car_outlined, 
                                                size: 64, color: Colors.grey),
                                              const SizedBox(height: 16),
                                              const Text(
                                                "No drivers available",
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              const Text(
                                                "Please try again later",
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              ElevatedButton.icon(
                                                onPressed: () {
                                                  // Refresh drivers
                                                  if (ref.read(homeScreenPickUpLocationProvider) != null) {
                                                    ref.read(globalFirestoreRepoProvider).getDriverData(
                                                      context,
                                                      ref,
                                                      LatLng(
                                                        ref.read(homeScreenPickUpLocationProvider)!.locationLatitude!,
                                                        ref.read(homeScreenPickUpLocationProvider)!.locationLongitude!,
                                                      ),
                                                    );
                                                  }
                                                },
                                                icon: const Icon(Icons.refresh, size: 18),
                                                label: const Text("Refresh"),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.grey[800],
                                                  foregroundColor: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                    shrinkWrap: true,
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    itemCount: driverCount,
                                    itemBuilder: (context, index) {
                                      double distanceToDriver = calculateDistance(
                                          ref
                                              .read(
                                                  homeScreenPickUpLocationProvider)!
                                              .locationLatitude,
                                          ref
                                              .read(
                                                  homeScreenPickUpLocationProvider)!
                                              .locationLongitude,
                                          ref
                                              .watch(homeScreenAvailableDriversProvider)[
                                                  index]
                                              .driverLoc
                                              .latitude,
                                          ref
                                              .watch(homeScreenAvailableDriversProvider)[
                                                  index]
                                              .driverLoc
                                              .longitude);
                                      debugPrint(
                                          "The updated distance is ${(distanceToDriver / 1609.34).toStringAsFixed(2)} miles (${distanceToDriver.toStringAsFixed(0)} meters)");

                                      if (distanceToDriver < 50 && index == ref.watch(homeScreenSelectedRideProvider) && ref.watch(homeScreenStartDriverSearch) ) {
                                        context.pop();
                                        sendNotificationToUserAboutDriverArrival(
                                            context);
                                      }

                                      // Get rate from driver's Firestore data (defaults to 3.0)
                                      double driverRate = ref
                                          .read(homeScreenAvailableDriversProvider)[index].rate;
                                      
                                      double? baseRate = ref.read(homeScreenRateProvider);
                                      
                                      // Calculate fares
                                      // Base fare multiplied by driver rate (from Firestore) and service multiplier (5x)
                                      double oneWayFare = baseRate != null
                                          ? (baseRate * driverRate * 5)
                                          : 0.0;
                                      double returnFare = oneWayFare * 2; // Return is double one-way
                                      
                                      String oneWayFareText = baseRate != null
                                          ? CurrencyConfig.formatAmount(oneWayFare)
                                          : "${CurrencyConfig.code} Loading...";
                                      String returnFareText = baseRate != null
                                          ? CurrencyConfig.formatAmount(returnFare)
                                          : "${CurrencyConfig.code} Loading...";

                                      return Container(
                                        margin: const EdgeInsets.only(
                                            top: 20, right: 20, left: 20),
                                        decoration: BoxDecoration(
                                            color: ref.watch(
                                                        homeScreenSelectedRideProvider) ==
                                                    index
                                                ? Colors.blue
                                                : Colors.grey,
                                            borderRadius:
                                                BorderRadius.circular(14.0)),
                                        child: InkWell(
                                          onTap: () {
                                            ref
                                                .read(
                                                    homeScreenSelectedRideProvider
                                                        .notifier)
                                                .update((state) => index);


                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(15.0),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              right: 12.0),
                                                      child: Image.asset(
                                                        ref
                                                                    .read(homeScreenAvailableDriversProvider)[
                                                                        index]
                                                                    .carType ==
                                                                "Sedan"
                                                            ? "assets/imgs/car.png"
                                                            : ref
                                                                        .read(homeScreenAvailableDriversProvider)[
                                                                            index]
                                                                        .carType ==
                                                                    "Luxury SUV"
                                                                ? "assets/imgs/suv.png"
                                                                : "assets/imgs/suv.png", // Default SUV for both SUV types
                                                        width: 60,
                                                        height: 60,
                                                      ),
                                                    ),
                                                    Column(
                                                      children: [
                                                        Text(ref
                                                            .read(homeScreenAvailableDriversProvider)[
                                                                index]
                                                            .carName),
                                                        Text(
                                                          "${(distanceToDriver / 1609.34).toStringAsFixed(1)} mi away.",
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodySmall!
                                                                  .copyWith(
                                                                    fontSize:
                                                                        10,
                                                                  ),
                                                        ),
                                                        Text(
                                                          ref
                                                              .read(homeScreenAvailableDriversProvider)[
                                                                  index]
                                                              .name,
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodySmall!
                                                                  .copyWith(
                                                                    fontSize:
                                                                        10,
                                                                  ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    // Show route distance for this trip
                                                    if (ref.watch(homeScreenRouteDistanceProvider) != null)
                                                      Padding(
                                                        padding: const EdgeInsets.only(bottom: 4.0),
                                                        child: Text(
                                                          "${DistanceCalculator.formatDistance(ref.watch(homeScreenRouteDistanceProvider)!)}",
                                                          style: Theme.of(context)
                                                              .textTheme
                                                              .bodySmall!
                                                              .copyWith(
                                                                fontSize: 11,
                                                                color: Colors.white60,
                                                              ),
                                                        ),
                                                      ),
                                                    Text(
                                                      oneWayFareText,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium!
                                                          .copyWith(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 16,
                                                          ),
                                                    ),
                                                    if (baseRate != null)
                                                      Padding(
                                                        padding: const EdgeInsets.only(top: 4.0),
                                                        child: Text(
                                                          "Return: $returnFareText",
                                                          style: Theme.of(context)
                                                              .textTheme
                                                              .bodySmall!
                                                              .copyWith(
                                                                fontSize: 12,
                                                                color: Colors.white70,
                                                              ),
                                                        ),
                                                      ),
                                                  ],
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                ),
                                // Submit button
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: InkWell(
                                    onTap: ref.watch(
                                                homeScreenSelectedRideProvider) ==
                                            null
                                        ? null
                                        : () async {
                                      int seletectedDriver = int.parse(ref.read(
                                            homeScreenSelectedRideProvider).toString());
                                        ref
                                            .read(homeScreenStartDriverSearch
                                                .notifier)
                                            .update((state) => true);

                                             // Create ride request and get the ride ID
                                             final rideId = await ref
                                                .read(
                                                    globalFirestoreRepoProvider)
                                                .addUserRideRequestToDB(
                                                    context, ref, ref.read(homeScreenAvailableDriversProvider)[seletectedDriver].email);

                                        // Store ride ID and start listening for driver acceptance
                                        if (rideId != null) {
                                          ref.read(currentRideRequestIdProvider.notifier).state = rideId;
                                          _listenForDriverAcceptance(context, ref, rideId);
                                        }

                                        sendNotificationToDriver(context, ref);
                                      },
                                child: Components().mainButton(
                                    size,
                                    "Submit",
                                    context,
                                    ref.watch(homeScreenSelectedRideProvider) ==
                                            null
                                        ? Colors.grey
                                        : Colors.blue),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  );
            },
          );
          },
        ).whenComplete(() {
      ref
          .watch(homeScreenSelectedRideProvider.notifier)
          .update((state) => null);
      ref.read(homeScreenStartDriverSearch.notifier).update((state) => false);
    });
  }

  Future<dynamic> sendNotificationToDriver(
      BuildContext context, WidgetRef ref) async {
    // TODO: Implement FCM notifications via Cloud Functions
    // Direct FCM API calls from client-side are blocked by CORS policy
    // See: FCM_CLOUD_FUNCTIONS_GUIDE.md for implementation
    
    print('ℹ️ Notification to driver skipped (requires Cloud Functions implementation)');
    
    /* DISABLED: Direct FCM calls don't work from browser (CORS)
    try {
      // Get scheduled time info
      final scheduledTime = ref.read(homeScreenScheduledTimeProvider);
      final isScheduled = ref.read(homeScreenIsSchedulingProvider);
      
      String timeInfo = isScheduled && scheduledTime != null
          ? " for ${formatScheduledTime(scheduledTime)}"
          : " now";
      
      await Dio().post("https://fcm.googleapis.com/fcm/send",
          options: Options(headers: {
            HttpHeaders.contentTypeHeader: "application/json",
            HttpHeaders.authorizationHeader:
                "Bearer AAAA7vDmw2Y:APA91bH44PYH1e9Idr_iOA76pQmowxa5nFZsEJ3CoxjUeAi4B9L-3GAezzskpynDU-wHYo144fCpbglxLdP6jJZUIHjKA-Q3gDiffy3OK-bWrDw7mQh2FeEwAWxEX1G4Ey_7MEkDanXs"
          }),
          data: {
            "data": {"screen": "/navigationScreen"},
            "notification": {
              "title": "Customer Alert",
              "body":
                  "A Customer is requesting driver at ${ref.read(homeScreenPickUpLocationProvider)!.locationName.toString()} heading towards ${ref.read(homeScreenDropOffLocationProvider)!.locationName.toString()}$timeInfo"
            },
            "to":
                "dfPljtkfTo-uhP_KKpTKtR:APA91bGymnaMAIedOXIhSAD4gnPRU5EOfp_4pdpoM6HIbz_8L4MMCXQVpc6sfMoAPv44sLRaAjsOmqm8t7x9pk0wV27V1GhlUwDm_OP7kEIqq_VhyRKqWPaVgIOzhHsGhSkiJAsh5pC7"
          });
    } catch (e) {
      if (context.mounted) {
        ErrorNotification().showError(context, "$e");
      }
    }
    */
  }

  Future<dynamic> sendNotificationToUserAboutDriverArrival(
      BuildContext context) async {
    // TODO: Implement FCM notifications via Cloud Functions
    // Direct FCM API calls from client-side are blocked by CORS policy
    
    print('ℹ️ Notification about driver arrival skipped (requires Cloud Functions)');
    
    /* DISABLED: Direct FCM calls don't work from browser (CORS)
    try {
      await Dio().post("https://fcm.googleapis.com/fcm/send",
          options: Options(headers: {
            HttpHeaders.contentTypeHeader: "application/json",
            HttpHeaders.authorizationHeader:
                "Bearer AAAA7vDmw2Y:APA91bH44PYH1e9Idr_iOA76pQmowxa5nFZsEJ3CoxjUeAi4B9L-3GAezzskpynDU-wHYo144fCpbglxLdP6jJZUIHjKA-Q3gDiffy3OK-bWrDw7mQh2FeEwAWxEX1G4Ey_7MEkDanXs"
          }),
          data: {
            "data": {"screen": "/home"},
            "notification": {
              "title": "Driver is here",
              "body": "Be ready the Driver is just arround the corner"
            },
            "to":
                "eHeH0bV9QbSMvINPFDoo9k:APA91bHrFlYWx5cnoV4cvzwLDrzG_1EYKFAzU0M0CPQyw983SubqiWALhiAVxHntXnaAiUKNPCTfXdK_Ws9LDgc9aJUT_5jvOe9CznTUMxDVFbX4YE7Iu75OMcIj4PTHLiQP0iRgCcm4"
          });
    } catch (e) {
      if (context.mounted) {
        ErrorNotification().showError(context, "$e");
      }
    }
    */
  }

  /// Format scheduled time for display
  String formatScheduledTime(DateTime scheduledTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final scheduledDate = DateTime(scheduledTime.year, scheduledTime.month, scheduledTime.day);
    
    String dateStr;
    if (scheduledDate == today) {
      dateStr = "Today";
    } else if (scheduledDate == tomorrow) {
      dateStr = "Tomorrow";
    } else {
      dateStr = "${scheduledTime.month}/${scheduledTime.day}/${scheduledTime.year}";
    }
    
    final hour = scheduledTime.hour > 12 ? scheduledTime.hour - 12 : (scheduledTime.hour == 0 ? 12 : scheduledTime.hour);
    final minute = scheduledTime.minute.toString().padLeft(2, '0');
    final period = scheduledTime.hour >= 12 ? "PM" : "AM";
    
    return "$dateStr at $hour:$minute $period";
  }

  /// Select a preset location and set it as the drop-off location
  Future<void> selectPresetLocation(
      BuildContext context,
      WidgetRef ref,
      GoogleMapController controller,
      PresetLocationModel preset) async {
    try {
      // If we have coordinates, use them directly
      if (preset.latitude != null && preset.longitude != null) {
        // Get the full address using reverse geocoding (without updating pickup location)
        String addressString = preset.name;
        try {
          // Try geocoder2 first (Google Maps API)
          try {
            final geoData = await Geocoder2.getDataFromCoordinates(
              latitude: preset.latitude!,
              longitude: preset.longitude!,
              googleMapApiKey: Keys.mapKey,
            );
            addressString = geoData.address;
          } catch (geocoder2Error) {
            // Fallback to geocoding package (native platform services)
            debugPrint("geocoder2 failed, trying geocoding package: $geocoder2Error");
            try {
              List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
                preset.latitude!,
                preset.longitude!,
              );
              if (placemarks.isNotEmpty) {
                final placemark = placemarks[0];
                final addressParts = <String>[];
                if (placemark.street != null && placemark.street!.isNotEmpty) {
                  addressParts.add(placemark.street!);
                }
                if (placemark.locality != null && placemark.locality!.isNotEmpty) {
                  addressParts.add(placemark.locality!);
                }
                if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) {
                  addressParts.add(placemark.administrativeArea!);
                }
                addressString = addressParts.isNotEmpty 
                    ? addressParts.join(', ')
                    : preset.name;
                debugPrint("✅ Address from geocoding package: $addressString");
              }
            } catch (geocodingError) {
              debugPrint("geocoding package also failed: $geocodingError");
              // Keep preset name as fallback
            }
          }
        } catch (e) {
          // If all reverse geocoding fails, use preset name directly
          debugPrint("All reverse geocoding methods failed, using preset name: $e");
        }

        // Create direction model with preset location
        final direction = Direction(
          locationName: preset.name,
          locationLatitude: preset.latitude,
          locationLongitude: preset.longitude,
          humanReadableAddress: addressString,
        );

        // Update the drop-off location provider
        ref.read(homeScreenDropOffLocationProvider.notifier).update((state) => direction);

        // Animate camera to the selected location
        controller.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(preset.latitude!, preset.longitude!),
            15,
          ),
        );

        // Recalculate route and fare if pickup location is set
        if (ref.read(homeScreenPickUpLocationProvider) != null && context.mounted) {
          debugPrint('🔄 Preset location selected: ${preset.name}');
          await refreshRouteAndFare(context, ref, controller);
        }

        // Switch back to search mode after selection
        ref.read(homeScreenPresetLocationsModeProvider.notifier).update((state) => false);
      } else {
        // If no coordinates, show error
        if (context.mounted) {
          ErrorNotification().showError(context, "Location coordinates not available for ${preset.name}");
        }
      }
    } catch (e) {
      if (context.mounted) {
        ErrorNotification().showError(context, "Error selecting preset location: $e");
      }
    }
  }
}

/// Listen for driver acceptance of ride request
void _listenForDriverAcceptance(BuildContext context, WidgetRef ref, String rideId) {
  final db = FirebaseFirestore.instance;
  
  // Listen to the ride request document
  db.collection('rideRequests').doc(rideId).snapshots().listen((snapshot) {
    if (!snapshot.exists) return;
    
    final data = snapshot.data();
    if (data == null) return;
    
    final status = data['status'] as String?;
    final driverEmail = data['driverEmail'] as String?;
    
    // Check if driver accepted (status changed from "pending" to "accepted")
    if (status == 'accepted' && driverEmail != null) {
      // Stop showing "waiting for driver" indicator
      ref.read(homeScreenStartDriverSearch.notifier).state = false;
      
      // Show notification to passenger
      if (context.mounted) {
        // Show dialog for more visibility
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
                SizedBox(width: 12),
                Text('Driver Accepted!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Great news! A driver has accepted your ride request.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                Text(
                  'Driver: $driverEmail',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your driver is on the way to pick you up.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Go to the Rides tab to track your driver.',
                  style: TextStyle(fontSize: 13, color: Colors.blue),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to Rides tab (index 1 in main navigation)
                  // Close any open bottom sheets first
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
                child: const Text('View Ride'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  });
}
