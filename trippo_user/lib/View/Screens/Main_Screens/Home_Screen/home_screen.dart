import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:btrips_unified/Container/utils/firebase_messaging.dart';
import 'package:btrips_unified/Container/utils/set_blackmap.dart';
import 'package:btrips_unified/Model/preset_location_model.dart';
import 'package:btrips_unified/View/Routes/routes.dart';
import 'package:btrips_unified/View/Screens/Main_Screens/Home_Screen/home_logics.dart';
import 'package:btrips_unified/View/Screens/Main_Screens/Home_Screen/home_providers.dart';
import 'package:btrips_unified/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_screen.dart';
import 'package:btrips_unified/data/providers/preset_location_providers.dart';
import 'package:btrips_unified/data/providers/stripe_providers.dart';
import 'package:btrips_unified/View/Screens/Main_Screens/Profile_Screen/Payment_Methods_Screen/payment_methods_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController whereToController = TextEditingController();
  CameraPosition initpos =
      const CameraPosition(target: LatLng(0.0, 0.0), zoom: 14);

  final Completer<GoogleMapController> completer = Completer();
  GoogleMapController? controller;
  bool _hasShownPaymentDialog = false;

  @override
  void initState() {
    super.initState();
    // Initialize messaging after the first frame to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        MessagingService().init(context, ref);
        _checkPaymentMethods();
      }
    });
  }

  void _checkPaymentMethods() async {
    // Wait a bit for the screen to fully load
    await Future.delayed(const Duration(seconds: 1));
    
    if (!mounted || _hasShownPaymentDialog) return;
    
    final hasPaymentMethods = await ref.read(hasPaymentMethodsProvider.future);
    
    if (!hasPaymentMethods && mounted && !_hasShownPaymentDialog) {
      _hasShownPaymentDialog = true;
      _showPaymentMethodReminder();
    }
  }

  void _showPaymentMethodReminder() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue, width: 2),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.payment,
                    size: 48,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Title
                const Text(
                  'Add a Payment Method',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                
                // Message
                Text(
                  'To book rides, you\'ll need to add a payment method. It\'s quick and secure!',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 16,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Benefits
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      _buildBenefitRow(Icons.check_circle, 'Secure payments via Stripe'),
                      const SizedBox(height: 8),
                      _buildBenefitRow(Icons.speed, 'Faster booking process'),
                      const SizedBox(height: 8),
                      _buildBenefitRow(Icons.lock, 'PCI-compliant encryption'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey[600]!),
                          ),
                        ),
                        child: const Text(
                          'Later',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PaymentMethodsScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Add Payment Method',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBenefitRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
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
                      HomeScreenLogics().getUserLoc(context, ref, controller!);
                    },
                    onCameraMove: (CameraPosition pos) {
                      if (ref.watch(homeScreenDropOffLocationProvider) !=
                          null) {
                        return;
                      }
                      if (ref.watch(homeScreenCameraMovementProvider) !=
                          pos.target) {
                        ref
                            .watch(homeScreenCameraMovementProvider.notifier)
                            .update((state) => pos.target);
                      }
                    },
                    onCameraIdle: () {
                      if (ref.watch(homeScreenDropOffLocationProvider) !=
                          null) {
                        return;
                      }
                      HomeScreenLogics().getAddressfromCordinates(context, ref);
                    },
                  ),
                  ref.watch(homeScreenDropOffLocationProvider) != null
                      ? Container()
                      : const Align(
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.location_on,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                  Positioned(
                    bottom: 0,
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: size.height * 0.5,
                        minHeight: 320,
                      ),
                      width: size.width,
                      decoration: const BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20))),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10.0),
                                child: Text(
                                  "From",
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: Container(
                                  width: size.width * 0.9,
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                      border: Border(
                                          bottom:
                                              BorderSide(color: Colors.blue))),
                                  child: Row(
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(right: 10.0),
                                        child: Icon(
                                          Icons.start_outlined,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      SizedBox(
                                        width: size.width * 0.7,
                                        child: Text(
                                          ref
                                                  .watch(
                                                      homeScreenPickUpLocationProvider)
                                                  ?.humanReadableAddress ??
                                              "Loading ...",
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                          maxLines: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "To",
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    // Toggle between Search and Preset Locations
                                    Row(
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            ref.read(homeScreenPresetLocationsModeProvider.notifier)
                                                .update((state) => false);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: !ref.watch(homeScreenPresetLocationsModeProvider)
                                                  ? Colors.blue
                                                  : Colors.transparent,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: !ref.watch(homeScreenPresetLocationsModeProvider)
                                                    ? Colors.blue
                                                    : Colors.grey,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.search,
                                                  size: 16,
                                                  color: !ref.watch(homeScreenPresetLocationsModeProvider)
                                                      ? Colors.white
                                                      : Colors.grey,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  "Search",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall!
                                                      .copyWith(
                                                        color: !ref.watch(homeScreenPresetLocationsModeProvider)
                                                            ? Colors.white
                                                            : Colors.grey,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        InkWell(
                                          onTap: () {
                                            ref.read(homeScreenPresetLocationsModeProvider.notifier)
                                                .update((state) => true);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: ref.watch(homeScreenPresetLocationsModeProvider)
                                                  ? Colors.blue
                                                  : Colors.transparent,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: ref.watch(homeScreenPresetLocationsModeProvider)
                                                    ? Colors.blue
                                                    : Colors.grey,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.flight_takeoff,
                                                  size: 16,
                                                  color: ref.watch(homeScreenPresetLocationsModeProvider)
                                                      ? Colors.white
                                                      : Colors.grey,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  "Airports",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall!
                                                      .copyWith(
                                                        color: ref.watch(homeScreenPresetLocationsModeProvider)
                                                            ? Colors.white
                                                            : Colors.grey,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Show preset locations or search option based on mode
                              ref.watch(homeScreenPresetLocationsModeProvider)
                                  ? Container(
                                      width: size.width * 0.9,
                                      constraints: BoxConstraints(
                                        maxHeight: size.height * 0.3,
                                        minHeight: 200,
                                      ),
                                      margin: const EdgeInsets.only(top: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[900],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.blue),
                                      ),
                                      child: ref.watch(airportPresetLocationsProvider).when(
                                        data: (presetLocations) {
                                          if (presetLocations.isEmpty) {
                                            return Center(
                                              child: Padding(
                                                padding: const EdgeInsets.all(20.0),
                                                child: Text(
                                                  'No preset locations available',
                                                  style: TextStyle(color: Colors.grey[400]),
                                                ),
                                              ),
                                            );
                                          }
                                          return ListView.builder(
                                            shrinkWrap: true,
                                            itemCount: presetLocations.length,
                                            itemBuilder: (context, index) {
                                              final preset = presetLocations[index];
                                              return InkWell(
                                                onTap: () {
                                                  HomeScreenLogics().selectPresetLocation(
                                                      context, ref, controller!, preset);
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.all(15),
                                                  decoration: BoxDecoration(
                                                    border: Border(
                                                      bottom: BorderSide(
                                                        color: Colors.grey[800]!,
                                                        width: index < presetLocations.length - 1 ? 0.5 : 0,
                                                      ),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        preset.category == 'airport'
                                                            ? Icons.flight_takeoff
                                                            : preset.category == 'station'
                                                                ? Icons.train
                                                                : Icons.place,
                                                        color: Colors.blue,
                                                        size: 24,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      preset.name,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall,
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
                                          );
                                        },
                                      );
                                    },
                                    loading: () => const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(20.0),
                                        child: CircularProgressIndicator(color: Colors.blue),
                                      ),
                                    ),
                                    error: (error, stack) => Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(20.0),
                                        child: Text(
                                          'Error loading locations',
                                          style: TextStyle(color: Colors.red[400]),
                                        ),
                                      ),
                                    ),
                                  ),
                                    )
                                  : MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                        onTap: () async {
                                          debugPrint('🔍 Where To clicked - opening search screen');
                                          final mapController = controller;
                                          if (mapController != null) {
                                            await Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) => WhereToScreen(controller: mapController),
                                              ),
                                            );
                                            if (context.mounted) {
                                              HomeScreenLogics().openWhereToScreen(
                                                  context, ref, mapController);
                                            }
                                          } else {
                                            debugPrint('❌ Map controller is null');
                                          }
                                        },
                                        child: Container(
                                          width: size.width * 0.9,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 15,
                                            horizontal: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.blue,
                                              width: 1.5,
                                            ),
                                            borderRadius: BorderRadius.circular(8),
                                            color: Colors.grey[850],
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.search,
                                                color: Colors.blue,
                                                size: 24,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  ref
                                                          .watch(
                                                              homeScreenDropOffLocationProvider)
                                                          ?.locationName ??
                                                      "Click to search destination...",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall!
                                                      .copyWith(
                                                        fontSize: 15,
                                                        color: ref.watch(
                                                                    homeScreenDropOffLocationProvider) ==
                                                                null
                                                            ? Colors.grey[400]
                                                            : Colors.white,
                                                      ),
                                                  maxLines: 2,
                                                ),
                                              ),
                                              Icon(
                                                Icons.arrow_forward_ios,
                                                size: 16,
                                                color: Colors.grey[500],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                              // Request a Ride Button (Primary Action)
                              Padding(
                                padding: const EdgeInsets.only(top: 20.0),
                                child: InkWell(
                                  onTap: () {
                                    HomeScreenLogics().requestARide(
                                        size, context, ref, controller!);
                                  },
                                  child: Container(
                                    alignment: Alignment.center,
                                    width: size.width * 0.9,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14.0),
                                      color: Colors.orange,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.orange.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      "Request a Ride",
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium!
                                          .copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                              
                              // Time Selection Section (Secondary Options)
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0, bottom: 10.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "When",
                                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                        fontSize: 12,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        // "Now" button (smaller)
                                        Expanded(
                                          child: InkWell(
                                            onTap: () {
                                              ref.read(homeScreenIsSchedulingProvider.notifier)
                                                  .update((state) => false);
                                              ref.read(homeScreenScheduledTimeProvider.notifier)
                                                  .update((state) => null);
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                vertical: 8,
                                                horizontal: 12,
                                              ),
                                              decoration: BoxDecoration(
                                                color: !ref.watch(homeScreenIsSchedulingProvider)
                                                    ? Colors.blue
                                                    : Colors.grey[800],
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: !ref.watch(homeScreenIsSchedulingProvider)
                                                      ? Colors.blue
                                                      : Colors.grey[700]!,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.schedule,
                                                    size: 18,
                                                    color: !ref.watch(homeScreenIsSchedulingProvider)
                                                        ? Colors.white
                                                        : Colors.grey,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    "Now",
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall!
                                                        .copyWith(
                                                          fontSize: 13,
                                                          color: !ref.watch(homeScreenIsSchedulingProvider)
                                                              ? Colors.white
                                                              : Colors.grey,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // "Schedule" button
                                        Expanded(
                                          child: InkWell(
                                            onTap: () async {
                                              final DateTime now = DateTime.now();
                                              final DateTime? pickedDate = await showDatePicker(
                                                context: context,
                                                initialDate: now,
                                                firstDate: now,
                                                lastDate: now.add(const Duration(days: 30)),
                                                builder: (context, child) {
                                                  return Theme(
                                                    data: Theme.of(context).copyWith(
                                                      colorScheme: const ColorScheme.dark(
                                                        primary: Colors.blue,
                                                        onPrimary: Colors.white,
                                                        surface: Colors.black87,
                                                        onSurface: Colors.white,
                                                      ),
                                                    ),
                                                    child: child!,
                                                  );
                                                },
                                              );
                                              
                                              if (pickedDate != null && context.mounted) {
                                                final TimeOfDay? pickedTime = await showTimePicker(
                                                  context: context,
                                                  initialTime: TimeOfDay.now(),
                                                  builder: (context, child) {
                                                    return Theme(
                                                      data: Theme.of(context).copyWith(
                                                        colorScheme: const ColorScheme.dark(
                                                          primary: Colors.blue,
                                                          onPrimary: Colors.white,
                                                          surface: Colors.black87,
                                                          onSurface: Colors.white,
                                                        ),
                                                      ),
                                                      child: child!,
                                                    );
                                                  },
                                                );
                                                
                                                if (pickedTime != null) {
                                                  final scheduledDateTime = DateTime(
                                                    pickedDate.year,
                                                    pickedDate.month,
                                                    pickedDate.day,
                                                    pickedTime.hour,
                                                    pickedTime.minute,
                                                  );
                                                  
                                                  // Check if scheduled time is in the future
                                                  if (scheduledDateTime.isAfter(now)) {
                                                    ref.read(homeScreenIsSchedulingProvider.notifier)
                                                        .update((state) => true);
                                                    ref.read(homeScreenScheduledTimeProvider.notifier)
                                                        .update((state) => scheduledDateTime);
                                                  }
                                                }
                                              }
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                vertical: 8,
                                                horizontal: 12,
                                              ),
                                              decoration: BoxDecoration(
                                                color: ref.watch(homeScreenIsSchedulingProvider)
                                                    ? Colors.blue
                                                    : Colors.grey[800],
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: ref.watch(homeScreenIsSchedulingProvider)
                                                      ? Colors.blue
                                                      : Colors.grey[700]!,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.calendar_today,
                                                    size: 18,
                                                    color: ref.watch(homeScreenIsSchedulingProvider)
                                                        ? Colors.white
                                                        : Colors.grey,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    "Schedule",
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall!
                                                        .copyWith(
                                                          fontSize: 13,
                                                          color: ref.watch(homeScreenIsSchedulingProvider)
                                                              ? Colors.white
                                                              : Colors.grey,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Show scheduled time if set
                                    if (ref.watch(homeScreenScheduledTimeProvider) != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.blue),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(Icons.access_time, 
                                                    color: Colors.blue, size: 20),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    HomeScreenLogics().formatScheduledTime(
                                                      ref.watch(homeScreenScheduledTimeProvider)!,
                                                    ),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall!
                                                        .copyWith(color: Colors.blue),
                                                  ),
                                                ],
                                              ),
                                              InkWell(
                                                onTap: () {
                                                  ref.read(homeScreenIsSchedulingProvider.notifier)
                                                      .update((state) => false);
                                                  ref.read(homeScreenScheduledTimeProvider.notifier)
                                                      .update((state) => null);
                                                },
                                                child: const Icon(
                                                  Icons.close,
                                                  color: Colors.blue,
                                                  size: 20,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // Optional: Change Pickup button (smaller, secondary action)
                              Padding(
                                padding: const EdgeInsets.only(top: 12.0),
                                child: InkWell(
                                  onTap: () => HomeScreenLogics()
                                      .changePickUpLoc(context, ref, controller!),
                                  child: Container(
                                    alignment: Alignment.center,
                                    width: size.width * 0.9,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8.0),
                                      color: Colors.transparent,
                                      border: Border.all(color: Colors.blue, width: 1),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.edit_location_alt,
                                          color: Colors.blue,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Change Pickup Location",
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall!
                                              .copyWith(
                                                color: Colors.blue,
                                                fontSize: 13,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ))),
    );
  }


}
