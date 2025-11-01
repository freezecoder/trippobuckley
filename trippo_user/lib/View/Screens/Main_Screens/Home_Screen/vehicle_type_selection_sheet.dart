import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../Container/utils/currency_config.dart';
import 'home_providers.dart';

/// Bottom sheet for selecting vehicle type (Sedan, SUV, Luxury SUV)
class VehicleTypeSelectionSheet extends ConsumerWidget {
  final VoidCallback onVehicleSelected;

  const VehicleTypeSelectionSheet({
    super.key,
    required this.onVehicleSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final selectedVehicleType = ref.watch(homeScreenSelectedVehicleTypeProvider);
    
    // ✅ Watch providers directly for real-time updates
    final baseRate = ref.watch(homeScreenRateProvider);
    final routeDistance = ref.watch(homeScreenRouteDistanceProvider);

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
          topRight: Radius.circular(16.0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Select Vehicle Type",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (routeDistance != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    "Distance: ${(routeDistance! / 1609.34).toStringAsFixed(1)} mi",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                ],
                const SizedBox(height: 4),
                // Show loading state if fare is still being calculated
                if (baseRate == null)
                  Row(
                    children: [
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Calculating fares...",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.blue,
                              fontSize: 12,
                            ),
                      ),
                    ],
                  )
                else
                  Text(
                    "Choose your preferred vehicle",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
              ],
            ),
          ),

          // Vehicle Type Options
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  _buildVehicleTypeCard(
                    context,
                    ref,
                    vehicleType: FirebaseConstants.vehicleTypeSedan,
                    displayName: "Sedan",
                    description: "Affordable, comfortable rides",
                    icon: Icons.directions_car,
                    multiplier: AppConstants.sedanMultiplier,
                    baseRate: baseRate,
                    isSelected:
                        selectedVehicleType == FirebaseConstants.vehicleTypeSedan,
                  ),
                  const SizedBox(height: 12),
                  _buildVehicleTypeCard(
                    context,
                    ref,
                    vehicleType: FirebaseConstants.vehicleTypeSUV,
                    displayName: "SUV",
                    description: "Extra space for passengers",
                    icon: Icons.airport_shuttle,
                    multiplier: AppConstants.suvMultiplier,
                    baseRate: baseRate,
                    isSelected:
                        selectedVehicleType == FirebaseConstants.vehicleTypeSUV,
                  ),
                  const SizedBox(height: 12),
                  _buildVehicleTypeCard(
                    context,
                    ref,
                    vehicleType: FirebaseConstants.vehicleTypeLuxurySUV,
                    displayName: "Luxury SUV",
                    description: "Premium comfort & style",
                    icon: Icons.local_taxi,
                    multiplier: AppConstants.luxurySuvMultiplier,
                    baseRate: baseRate,
                    isSelected: selectedVehicleType ==
                        FirebaseConstants.vehicleTypeLuxurySUV,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Submit Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedVehicleType == null ? null : onVehicleSelected,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      selectedVehicleType == null ? Colors.grey : Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  selectedVehicleType == null
                      ? "Select a vehicle type"
                      : "Request Ride",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleTypeCard(
    BuildContext context,
    WidgetRef ref, {
    required String vehicleType,
    required String displayName,
    required String description,
    required IconData icon,
    required double multiplier,
    required double? baseRate,
    required bool isSelected,
  }) {
    // Calculate fare with multiplier
    // Formula: baseRate * multiplier * service multiplier (5x) 
    // Same calculation as old driver selection
    double? fare;
    String fareText;
    
    if (baseRate != null && baseRate > 0) {
      // Apply vehicle type multiplier and service multiplier
      fare = baseRate * multiplier * 5;
      fareText = CurrencyConfig.formatAmount(fare);
    } else {
      fareText = "${CurrencyConfig.code} ...";
    }
    
    debugPrint('💰 Fare for $vehicleType: baseRate=$baseRate, multiplier=$multiplier, fare=$fare');

    return InkWell(
      onTap: () {
        ref.read(homeScreenSelectedVehicleTypeProvider.notifier).state =
            vehicleType;
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue[300]! : Colors.grey[700]!,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue[900] : Colors.grey[700],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 32,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                  ),
                  if (multiplier != 1.0) ...[
                    const SizedBox(height: 4),
                    Text(
                      "${multiplier}x pricing",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange[300],
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  fareText,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  "one way",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

