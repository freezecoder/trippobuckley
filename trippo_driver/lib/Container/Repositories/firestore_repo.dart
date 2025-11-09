import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:trippo_driver/Model/driver_info_model.dart';

import '../utils/error_notification.dart';

final globalFirestoreRepoProvider = Provider<AddFirestoreData>((ref) {
  return AddFirestoreData();
});

class AddFirestoreData {
  FirebaseFirestore db = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;

  void addDriversDataToFirestore(BuildContext context, String carName,
      String carPlateNum, String carType) async {
    try {
      await db
          .collection("Drivers")
          .doc(auth.currentUser!.email.toString())
          .set({
        "name": FirebaseAuth.instance.currentUser!.email!.split("@")[0],
        "email": FirebaseAuth.instance.currentUser!.email,
        "Car Name": carName,
        "Car Plate Num": carPlateNum,
        "Car Type": carType
      });
    } catch (e) {
      if(context.mounted){

      ErrorNotification().showError(context, "An Error Occurred $e");
      }
    }
  }

  void getDriverDetails(BuildContext context) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> data = await db
          .collection("Drivers")
          .doc(auth.currentUser!.email.toString())
          .get();

      DriverInfoModel driver = DriverInfoModel(
          auth.currentUser!.uid,
          data.data()?["name"],
          data.data()?["email"],
          data.data()?["Car Name"],
          data.data()?["Car Plate Num"],
          data.data()?["Car Type"]);

      print("data is ${driver.carType}");
    } catch (e) {
      if(context.mounted){

      ErrorNotification().showError(context, "An Error Occurred $e");
      }
    }
  }

  void setDriverStatus(BuildContext context, String status) async {
    try {
      await db
          .collection("Drivers")
          .doc(auth.currentUser!.email.toString())
          .update({"driverStatus": status});
    } catch (e) {
   if(context.mounted){

      ErrorNotification().showError(context, "An Error Occurred $e");
      }
    }
  }
  void setDriverLocationStatus(BuildContext context, GeoFirePoint? loc) async {
    try {
      await db
          .collection("Drivers")
          .doc(auth.currentUser!.email.toString())
          .update({"driverLoc": loc?.data});
    } catch (e) {
     if(context.mounted){

      ErrorNotification().showError(context, "An Error Occurred $e");
      }
    }
  }

  /// Get delivery request details
  Future<Map<String, dynamic>?> getDeliveryDetails(String rideId) async {
    try {
      final doc = await db.collection('rideRequests').doc(rideId).get();
      if (doc.exists && doc.data()?['isDelivery'] == true) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting delivery details: $e');
      return null;
    }
  }

  /// Verify delivery pickup code
  Future<bool> verifyDeliveryCode(
      BuildContext context, String rideId, String enteredCode) async {
    try {
      final doc = await db.collection('rideRequests').doc(rideId).get();
      
      if (!doc.exists) {
        if (context.mounted) {
          ErrorNotification().showError(context, "Delivery request not found");
        }
        return false;
      }

      final data = doc.data();
      final correctCode = data?['deliveryVerificationCode'] as String?;

      if (correctCode == null) {
        if (context.mounted) {
          ErrorNotification().showError(context, "No verification code found");
        }
        return false;
      }

      if (correctCode == enteredCode) {
        // Code is correct - mark as verified
        await db.collection('rideRequests').doc(rideId).update({
          'deliveryCodeVerified': true,
          'pickupVerifiedAt': FieldValue.serverTimestamp(),
        });

        if (context.mounted) {
          ErrorNotification()
              .showSuccess(context, "✅ Code verified! You can pick up the items.");
        }
        
        debugPrint('✅ Delivery code verified successfully');
        return true;
      } else {
        if (context.mounted) {
          ErrorNotification()
              .showError(context, "❌ Incorrect code. Please try again.");
        }
        debugPrint('❌ Incorrect verification code entered');
        return false;
      }
    } catch (e) {
      if (context.mounted) {
        ErrorNotification().showError(context, "Error verifying code: $e");
      }
      debugPrint('❌ Error verifying delivery code: $e');
      return false;
    }
  }

  /// Mark pickup as complete
  Future<void> markPickupComplete(BuildContext context, String rideId) async {
    try {
      await db.collection('rideRequests').doc(rideId).update({
        'pickupCompletedAt': FieldValue.serverTimestamp(),
        'status': 'enroute_to_customer', // New status for delivery
      });

      if (context.mounted) {
        ErrorNotification().showSuccess(
            context, "✅ Pickup complete! Navigate to customer.");
      }
      
      debugPrint('✅ Pickup marked as complete');
    } catch (e) {
      if (context.mounted) {
        ErrorNotification().showError(context, "Error marking pickup: $e");
      }
      debugPrint('❌ Error marking pickup complete: $e');
    }
  }

  /// Accept delivery request
  Future<void> acceptDeliveryRequest(BuildContext context, String rideId) async {
    try {
      await db.collection('rideRequests').doc(rideId).update({
        'driverId': auth.currentUser!.uid,
        'driverEmail': auth.currentUser!.email,
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ErrorNotification()
            .showSuccess(context, "Delivery accepted! Navigate to pickup location.");
      }
      
      debugPrint('✅ Delivery request accepted');
    } catch (e) {
      if (context.mounted) {
        ErrorNotification().showError(context, "Error accepting delivery: $e");
      }
      debugPrint('❌ Error accepting delivery: $e');
    }
  }
}
