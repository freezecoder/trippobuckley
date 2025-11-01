import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/firebase_options.dart';

/// Script to add 4 sample drivers to Firestore
/// Run with: flutter run -d chrome scripts/add_drivers.dart
/// Or use: dart run scripts/add_drivers.dart

void main() async {
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final db = FirebaseFirestore.instance;
  final geo = GeoFlutterFire();

  // Sample drivers data - Located near major airports in the area
  final drivers = [
    {
      "Car Name": "Toyota Camry",
      "Car Plate Num": "ABC-1234",
      "Car Type": "Car",
      "name": "Ahmed Khan",
      "email": "ahmed.khan@driver.com",
      "driverStatus": "Idle",
      "driverLoc": {
        "geopoint": GeoPoint(40.6895, -74.1745), // Near Newark Airport
      },
    },
    {
      "Car Name": "Honda Civic",
      "Car Plate Num": "XYZ-5678",
      "Car Type": "Car",
      "name": "Sara Ali",
      "email": "sara.ali@driver.com",
      "driverStatus": "Idle",
      "driverLoc": {
        "geopoint": GeoPoint(40.6413, -73.7781), // Near JFK Airport
      },
    },
    {
      "Car Name": "Toyota RAV4",
      "Car Plate Num": "SUV-9012",
      "Car Type": "SUV",
      "name": "Mohammed Hassan",
      "email": "mohammed.hassan@driver.com",
      "driverStatus": "Idle",
      "driverLoc": {
        "geopoint": GeoPoint(40.7769, -73.8740), // Near La Guardia Airport
      },
    },
    {
      "Car Name": "Yamaha R15",
      "Car Plate Num": "MOT-3456",
      "Car Type": "MotorCycle",
      "name": "Fatima Ahmed",
      "email": "fatima.ahmed@driver.com",
      "driverStatus": "Idle",
      "driverLoc": {
        "geopoint": GeoPoint(39.8719, -75.2411), // Near Philadelphia Airport
      },
    },
  ];

  print("Adding ${drivers.length} drivers to Firestore...\n");

  for (var driverData in drivers) {
    try {
      // Use email as document ID for easier lookup
      final docRef = db.collection("Drivers").doc(driverData["email"] as String);
      
      // Check if driver already exists
      final doc = await docRef.get();
      if (doc.exists) {
        print("⚠️  Driver ${driverData["email"]} already exists. Updating...");
        await docRef.update(driverData);
        print("✅ Updated: ${driverData["name"]} (${driverData["Car Name"]})");
      } else {
        await docRef.set(driverData);
        print("✅ Added: ${driverData["name"]} (${driverData["Car Name"]})");
      }
      
      print("   Email: ${driverData["email"]}");
      print("   Location: ${driverData["driverLoc"]?["geopoint"] ?? 'Unknown'}");
      print("   Status: ${driverData["driverStatus"]}\n");
    } catch (e) {
      print("❌ Error adding driver ${driverData["email"]}: $e\n");
    }
  }

  print("Done! ${drivers.length} drivers added/updated to Firestore.");
  print("\nNote: Make sure Firestore security rules allow write access for testing.");
}
