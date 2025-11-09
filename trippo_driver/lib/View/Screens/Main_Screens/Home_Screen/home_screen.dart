import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trippo_driver/Container/Repositories/firestore_repo.dart';
import 'package:trippo_driver/Container/utils/firebase_messaging.dart';
import 'package:trippo_driver/View/Screens/Main_Screens/Home_Screen/home_logics.dart';
import 'package:trippo_driver/View/Screens/Main_Screens/Home_Screen/home_providers.dart';
import 'package:trippo_driver/View/Screens/Main_Screens/Delivery_Screens/pending_deliveries_screen.dart';
import '../../../../Container/utils/set_blackmap.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';

final geo = GeoFlutterFire();

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  CameraPosition initpos =
      const CameraPosition(target: LatLng(0.0, 0.0), zoom: 14);

  final Completer<GoogleMapController> completer = Completer();
  GoogleMapController? controller;
  Geolocator geoLocator = Geolocator();

  @override
  void initState() {
    super.initState();
    MessagingService().init(context);
    
    // Start listening for delivery requests when driver is online
    // This will be triggered when driver goes online
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: SafeArea(
          child: SizedBox(
              width: size.width,
              height: size.height,
              child: Stack(
                children: [
                  GoogleMap(
                    mapType: MapType.normal,
                    myLocationButtonEnabled: true,
                    trafficEnabled: true,
                    compassEnabled: true,
                    buildingsEnabled: true,
                    myLocationEnabled: true,
                    zoomControlsEnabled: false,
                    zoomGesturesEnabled: true,
                    initialCameraPosition: initpos,
                    polylines: ref.watch(homeScreenMainPolylinesProvider),
                    markers: ref.watch(homeScreenMainMarkersProvider),
                    circles: ref.watch(homeScreenMainCirclesProvider),
                    onMapCreated: (map) {
                      completer.complete(map);
                      controller = map;
                      SetBlackMap().setBlackMapTheme(map);
                      HomeLogics().getDriverLoc(context, ref, controller!);
                      ref
                          .watch(globalFirestoreRepoProvider)
                          .getDriverDetails(context);
                    },
                  ),
                  ref.watch(homeScreenIsDriverActiveProvider)
                      ? Container()
                      : Container(
                          height: size.height,
                          width: size.width,
                          color: Colors.black54),
                  Positioned(
                      top: !ref.watch(homeScreenIsDriverActiveProvider)
                          ? size.height * 0.45
                          : 45,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          InkWell(
                            onTap: () {
                              if (!ref
                                  .watch(homeScreenIsDriverActiveProvider)) {
                                HomeLogics()
                                    .getDriverOnline(context, ref, controller!);
                              } else {
                                HomeLogics().getDriverOffline(context, ref);
                              }
                            },
                            child: Container(
                              alignment: Alignment.center,
                              height: 45,
                              width: 200,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: Colors.blue),
                              child: !ref
                                      .watch(homeScreenIsDriverActiveProvider)
                                  ? const Text("You are Offline")
                                  : const Icon(Icons.phonelink_ring_outlined,
                                      color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      )),
                  
                  // Floating Action Button for Delivery Requests
                  if (ref.watch(homeScreenIsDriverActiveProvider))
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('rideRequests')
                            .where('isDelivery', isEqualTo: true)
                            .where('status', isEqualTo: 'pending')
                            .snapshots(),
                        builder: (context, snapshot) {
                          final pendingCount = snapshot.data?.docs.length ?? 0;
                          
                          return FloatingActionButton.extended(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const PendingDeliveriesScreen(),
                                ),
                              );
                            },
                            backgroundColor: Colors.orange,
                            icon: Stack(
                              children: [
                                const Icon(Icons.delivery_dining, size: 28),
                                if (pendingCount > 0)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        pendingCount.toString(),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            label: Text(
                              pendingCount > 0 
                                  ? 'Deliveries ($pendingCount)' 
                                  : 'Deliveries',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ))),
    );
  }
}
