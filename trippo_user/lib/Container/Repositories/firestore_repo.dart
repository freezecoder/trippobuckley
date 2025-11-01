import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:btrips_unified/Model/driver_model.dart';
import 'package:btrips_unified/View/Screens/Main_Screens/Home_Screen/home_providers.dart';

import '../utils/error_notification.dart';

final globalFirestoreRepoProvider = Provider<FirestoreRepo>((ref) {
  return FirestoreRepo();
});

class FirestoreRepo {
  final geo = GeoFlutterFire();
  FirebaseFirestore db = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;
  
  // Stream subscriptions to manage and cancel
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _driversSubscription;
  StreamSubscription<List<DocumentSnapshot<Object?>>>? _geoDriversSubscription;

  /// Dispose method to cancel all active streams
  void dispose() {
    _driversSubscription?.cancel();
    _geoDriversSubscription?.cancel();
    _driversSubscription = null;
    _geoDriversSubscription = null;
  }

  void getDriverData(
      BuildContext context, WidgetRef ref, LatLng userPos) async {
    try {
      // Cancel existing subscriptions if any
      await _driversSubscription?.cancel();
      await _geoDriversSubscription?.cancel();
      
      // Check authentication before accessing Firestore
      if (auth.currentUser == null) {
        debugPrint('❌ User not authenticated - cannot load drivers');
        if (context.mounted) {
          ErrorNotification().showError(context, "Please sign in to view available drivers");
        }
        return;
      }
      
      debugPrint('✅ User authenticated: ${auth.currentUser!.email}');
      debugPrint('📍 Loading drivers near: ${userPos.latitude}, ${userPos.longitude}');

      /// getting [DriverData] from [FirebaseFirestore]
      // Clear existing drivers before adding new ones
      ref.read(homeScreenAvailableDriversProvider.notifier).update((state) => []);

      Stream<QuerySnapshot<Map<String, dynamic>>> drivers =
          db.collection("Drivers").snapshots();

      _driversSubscription = drivers.listen((event) {
        debugPrint('📦 Firestore snapshot received: ${event.docs.length} documents');
        
        if (event.docs.isEmpty) {
          debugPrint('⚠️  No driver documents found in Firestore');
          return;
        }
        
        List<DriverModel> newDrivers = [];
        
        for (var driver in event.docs) {
          try {
            final driverData = driver.data();
            debugPrint('🔍 Processing driver: ${driver.id}');
            debugPrint('   Data keys: ${driverData.keys.join(", ")}');
            
            // Validate required fields exist
            if (driverData["Car Name"] == null) {
              debugPrint('   ❌ Missing "Car Name"');
              continue;
            }
            if (driverData["driverLoc"] == null) {
              debugPrint('   ❌ Missing "driverLoc"');
              continue;
            }
            if (driverData["driverLoc"]["geopoint"] == null) {
              debugPrint('   ❌ Missing "driverLoc.geopoint"');
              continue;
            }

            // Check driver status
            final status = driverData["driverStatus"]?.toString().toLowerCase();
            debugPrint('   Status: ${driverData["driverStatus"]}');
            
            // Skip offline drivers (case-insensitive check)
            if (status == "offline") {
              debugPrint('   ⏭️  Skipping offline driver');
              continue;
            }

            // Get rate from Firestore, default to 3.0 if not present
            double driverRate = (driverData["rate"] ?? 3.0).toDouble();
            
            DriverModel model = DriverModel(
                driverData["Car Name"] ?? "",
                driverData["Car Plate Num"] ?? "",
                driverData["Car Type"] ?? "",
                geo.point(
                    latitude: driverData["driverLoc"]["geopoint"].latitude ?? 0.0,
                    longitude: driverData["driverLoc"]["geopoint"].longitude ?? 0.0),
                driverData["driverStatus"] ?? "",
                driverData["email"] ?? "",
                driverData["name"] ?? "",
                driverRate);

            newDrivers.add(model);
            debugPrint('   ✅ Added driver: ${driverData["name"]}');
          } catch (e) {
            debugPrint("❌ Error parsing driver data for ${driver.id}: $e");
            debugPrint('   Stack trace: ${StackTrace.current}');
            continue;
          }
        }
        
        debugPrint('📊 Total valid drivers found: ${newDrivers.length}');
        // Update state with all drivers at once
        ref.read(homeScreenAvailableDriversProvider.notifier).update((state) => newDrivers);
        
        if (newDrivers.isEmpty && context.mounted) {
          debugPrint('⚠️  No valid drivers after filtering. Possible issues:');
          debugPrint('   - All drivers have status "offline"');
          debugPrint('   - Missing required fields (Car Name, driverLoc, etc.)');
          debugPrint('   - Check Firestore console to verify driver data format');
        }
      }, onError: (error) {
        if (context.mounted) {
          String errorMessage = "Error loading drivers";
          if (error.toString().contains("permission-denied")) {
            errorMessage = "Permission denied. Please check Firestore security rules.";
          }
          ErrorNotification().showError(context, "$errorMessage: $error");
        }
      });

      GeoFirePoint center =
          geo.point(latitude: userPos.latitude, longitude: userPos.longitude);

      Stream<List<DocumentSnapshot<Object?>>> allDriversStream = geo
          .collection(collectionRef: db.collection("Drivers"))
          .within(
              center: center, radius: 50, field: "driverLoc", strictMode: true);

      _geoDriversSubscription = allDriversStream.listen((event) async {
        if (event.isEmpty) {
          return;
        }
        
        Set<Marker> newMarkers = {};
        
        for (var driver in event) {
          try {
            if (driver["driverStatus"] == "Idle" && 
                driver["driverLoc"] != null &&
                driver["driverLoc"]["geopoint"] != null &&
                driver["Car Name"] != null) {
              
              Marker marker = Marker(
                  markerId: MarkerId(driver["Car Name"] ?? "driver_${driver.id}"),
                  infoWindow: InfoWindow(
                    title: driver["Car Name"] ?? "Driver",
                  ),
                  position: LatLng(
                      driver["driverLoc"]["geopoint"].latitude ?? 0.0,
                      driver["driverLoc"]["geopoint"].longitude ?? 0.0),
                  icon: await BitmapDescriptor.asset(
                      const ImageConfiguration(),
                      driver["Car Type"] == "Sedan" || driver["carType"] == "Sedan"
                          ? "assets/imgs/sedan.png"
                          : driver["Car Type"] == "Luxury SUV" || driver["carType"] == "Luxury SUV"
                              ? "assets/imgs/suv.png"
                              : "assets/imgs/suv.png")); // Default to SUV for SUV and Luxury SUV

              newMarkers.add(marker);
            }
          } catch (e) {
            debugPrint("Error creating driver marker: $e");
            continue;
          }
        }
        
        // Update markers set
        ref.read(homeScreenMainMarkersProvider.notifier).update((state) => newMarkers);
      }, onError: (error) {
        if (context.mounted) {
          String errorMessage = "Error loading driver locations";
          if (error.toString().contains("permission-denied")) {
            errorMessage = "Permission denied. Please check Firestore security rules.";
          }
          ErrorNotification().showError(context, "$errorMessage: $error");
        }
      });
    } catch (e) {
      if (context.mounted) {
        String errorMessage = "An error occurred while loading driver data";
        if (e.toString().contains("permission-denied")) {
          errorMessage = "Permission denied. Please sign in and check Firestore security rules.";
        }
        ErrorNotification().showError(context, "$errorMessage: $e");
      }
    }
  }

  Future<String?> addUserRideRequestToDB(
      context, WidgetRef ref, String driverEmail, {String? vehicleType}) async {
    try {
      // Check authentication before accessing Firestore
      if (auth.currentUser == null || auth.currentUser!.email == null) {
        if (context.mounted) {
          ErrorNotification().showError(context, "Please sign in to request a ride");
        }
        return null;
      }

      // Get pickup and dropoff locations
      final pickupLocation = ref.read(homeScreenPickUpLocationProvider);
      final dropoffLocation = ref.read(homeScreenDropOffLocationProvider);
      
      if (pickupLocation == null || dropoffLocation == null) {
        if (context.mounted) {
          ErrorNotification().showError(context, "Please select pickup and dropoff locations");
        }
        return null;
      }

      // Get scheduled time or use current time
      final scheduledTime = ref.read(homeScreenScheduledTimeProvider);
      final isScheduled = ref.read(homeScreenIsSchedulingProvider);

      // Calculate fare (you may want to get this from a provider)
      const fare = 25.0; // TODO: Get actual calculated fare
      const distance = 10.0; // TODO: Get actual distance
      const duration = 15; // TODO: Get actual duration in minutes

      // Validate location coordinates
      final pickupLat = pickupLocation.locationLatitude;
      final pickupLng = pickupLocation.locationLongitude;
      final dropoffLat = dropoffLocation.locationLatitude;
      final dropoffLng = dropoffLocation.locationLongitude;

      if (pickupLat == null || pickupLng == null || dropoffLat == null || dropoffLng == null) {
        if (context.mounted) {
          ErrorNotification().showError(context, "Invalid location coordinates");
        }
        return null;
      }

      // Ensure addresses are not empty
      final pickupAddr = pickupLocation.locationName?.trim().isNotEmpty == true
          ? pickupLocation.locationName!
          : pickupLocation.humanReadableAddress ?? 'Pickup Location';
      final dropoffAddr = dropoffLocation.locationName?.trim().isNotEmpty == true
          ? dropoffLocation.locationName!
          : dropoffLocation.humanReadableAddress ?? 'Dropoff Location';
      
      debugPrint('📍 Creating ride with:');
      debugPrint('   Pickup: $pickupAddr');
      debugPrint('   Dropoff: $dropoffAddr');

      // Use the new unified rideRequests collection
      final docRef = await db.collection('rideRequests').add({
        "userId": auth.currentUser!.uid,
        "driverId": null, // Will be assigned when driver accepts
        "userEmail": auth.currentUser!.email,
        "driverEmail": driverEmail.isEmpty ? null : driverEmail,
        "status": "pending",
        "pickupLocation": GeoPoint(pickupLat, pickupLng),
        "pickupAddress": pickupAddr,
        "dropoffLocation": GeoPoint(dropoffLat, dropoffLng),
        "dropoffAddress": dropoffAddr,
        "scheduledTime": isScheduled && scheduledTime != null
            ? Timestamp.fromDate(scheduledTime)
            : null,
        "requestedAt": FieldValue.serverTimestamp(),
        "acceptedAt": null,
        "startedAt": null,
        "completedAt": null,
        "vehicleType": vehicleType ?? "Sedan", // Use provided vehicle type or default to Sedan
        "fare": fare,
        "distance": distance,
        "duration": duration,
        "route": null,
      });

      debugPrint('✅ Ride request created with ID: ${docRef.id}');

      if (context.mounted) {
        // Success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ride requested successfully! Waiting for driver...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
      
      return docRef.id; // Return the ride ID for tracking
    } catch (e) {
      print('❌ Error creating ride request: $e');
      if (context.mounted) {
        ErrorNotification().showError(context, "Failed to request ride: ${e.toString()}");
      }
      return null;
    }
  }

  void nullifyUserRides(context) async {
    try {
      // Check authentication before accessing Firestore
      if (auth.currentUser == null || auth.currentUser!.email == null) {
        return;
      }

      var data = await db.collection(auth.currentUser!.email.toString()).get();

      for (var alldata in data.docs) {
        alldata.reference.delete();
      }
    } catch (e) {
      if (context.mounted) {
        ErrorNotification().showError(context, "An Error Occurred $e");
      }
    }
  }

  void setDriverStatus(context, String driverEmail, String driverStatus) async {
    try {
      QuerySnapshot<Map<String, dynamic>> drivers = await db
          .collection("Drivers")
          .where("email", isEqualTo: driverEmail)
          .get();

      for (var driver in drivers.docs) {
        driver.reference.update({"driverStatus": driverStatus});
      }
    } catch (e) {
      if (context.mounted) {
        ErrorNotification().showError(context, "An Error Occurred $e");
      }
    }
  }
}
