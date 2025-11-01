import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/route_constants.dart';
import '../../../../../core/constants/firebase_constants.dart';
import '../../../../../data/providers/auth_providers.dart';
import '../../../../../data/providers/user_providers.dart';
import '../../../../../Container/utils/error_notification.dart';
import '../../../../../View/Components/all_components.dart';

/// Providers for driver configuration screen
final driverConfigDropDownProvider = StateProvider.autoDispose<String?>((ref) => FirebaseConstants.vehicleTypeSedan);
final driverConfigIsLoadingProvider = StateProvider.autoDispose<bool>((ref) => false);

/// Screen for driver to configure their vehicle information
class DriverConfigScreen extends ConsumerStatefulWidget {
  const DriverConfigScreen({super.key});

  @override
  ConsumerState<DriverConfigScreen> createState() => _DriverConfigScreenState();
}

class _DriverConfigScreenState extends ConsumerState<DriverConfigScreen> {
  final TextEditingController carNameController = TextEditingController();
  final TextEditingController plateNumController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  /// Load existing driver data if available (for editing)
  Future<void> _loadExistingData() async {
    try {
      final currentUser = await ref.read(currentUserProvider.future);
      if (currentUser == null) return;

      final driverRepo = ref.read(driverRepositoryProvider);
      final driverData = await driverRepo.getDriverById(currentUser.uid);

      if (driverData != null && driverData.hasCompletedConfiguration) {
        // Load existing data
        if (mounted) {
          carNameController.text = driverData.carName;
          plateNumController.text = driverData.carPlateNum;
          ref.read(driverConfigDropDownProvider.notifier).state = driverData.carType;
        }
      }
    } catch (e) {
      debugPrint('Error loading driver data: $e');
    }
  }

  @override
  void dispose() {
    carNameController.dispose();
    plateNumController.dispose();
    super.dispose();
  }

  /// Submit driver configuration to Firestore
  Future<void> _submitConfiguration() async {
    try {
      if (carNameController.text.isEmpty || plateNumController.text.isEmpty) {
        ErrorNotification().showError(
          context,
          "Please enter car name and plate number",
        );
        return;
      }

      final selectedCarType = ref.read(driverConfigDropDownProvider);
      if (selectedCarType == null) {
        ErrorNotification().showError(context, "Please select a vehicle type");
        return;
      }

      ref.read(driverConfigIsLoadingProvider.notifier).update((state) => true);

      // Get current user
      final currentUser = await ref.read(currentUserProvider.future);
      if (currentUser == null) {
        throw Exception('User not found');
      }

      // Update driver configuration
      final driverRepo = ref.read(driverRepositoryProvider);
      await driverRepo.updateDriverConfiguration(
        driverId: currentUser.uid,
        carName: carNameController.text.trim(),
        carPlateNum: plateNumController.text.trim(),
        carType: selectedCarType,
      );

      ref.read(driverConfigIsLoadingProvider.notifier).update((state) => false);

      if (mounted && context.mounted) {
        // Navigate to driver main after configuration
        context.goNamed(RouteNames.driverMain);
      }
    } catch (e) {
      ref.read(driverConfigIsLoadingProvider.notifier).update((state) => false);
      if (mounted) {
        ErrorNotification().showError(
          context,
          "Configuration failed: ${e.toString()}",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Column(
              children: [
                // Title
                Text(
                  "Vehicle Information",
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        fontFamily: "bold",
                        fontSize: 20,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Update your vehicle details including license plate",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                
                // Form
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20.0, left: 20, right: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Car Name Field
                        Components().returnTextField(
                          carNameController,
                          context,
                          false,
                          "Please Enter Car Name",
                        ),
                        
                        // Plate Number Field
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Components().returnTextField(
                            plateNumController,
                            context,
                            false,
                            "Please Enter Car Plate Number",
                          ),
                        ),
                        
                        // Vehicle Type Dropdown
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: SizedBox(
                            width: size.width * 0.9,
                            child: DropdownButton<String>(
                              value: ref.watch(driverConfigDropDownProvider),
                              onChanged: (val) {
                                ref
                                    .read(driverConfigDropDownProvider.notifier)
                                    .update((state) => val);
                              },
                              dropdownColor: Colors.black45,
                              isExpanded: true,
                              underline: Container(),
                              hint: Text(
                                "Select Vehicle Type",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(fontFamily: "medium", fontSize: 14),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: FirebaseConstants.vehicleTypeSedan,
                                  child: Text(
                                    "Sedan",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall!
                                        .copyWith(
                                          fontFamily: "medium",
                                          fontSize: 14,
                                        ),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: FirebaseConstants.vehicleTypeSUV,
                                  child: Text(
                                    "SUV",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall!
                                        .copyWith(
                                          fontFamily: "medium",
                                          fontSize: 14,
                                        ),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: FirebaseConstants.vehicleTypeLuxurySUV,
                                  child: Text(
                                    "Luxury SUV",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall!
                                        .copyWith(
                                          fontFamily: "medium",
                                          fontSize: 14,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Submit Button
                        Padding(
                          padding: const EdgeInsets.only(top: 30.0),
                          child: InkWell(
                            onTap: ref.watch(driverConfigIsLoadingProvider)
                                ? null
                                : _submitConfiguration,
                            child: Components().mainButton(
                              size,
                              ref.watch(driverConfigIsLoadingProvider)
                                  ? "Loading ..."
                                  : "Submit Configuration",
                              context,
                              ref.watch(driverConfigIsLoadingProvider)
                                  ? Colors.grey
                                  : Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

