import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../Container/utils/currency_config.dart';
import '../../../../data/providers/stripe_providers.dart';
import '../../../../data/models/payment_method_model.dart';
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
    final selectedPaymentMethod = ref.watch(homeScreenSelectedPaymentMethodProvider);
    final payCash = ref.watch(homeScreenPayCashProvider);
    final paymentMethodsAsync = ref.watch(paymentMethodsProvider);
    
    // ✅ Watch providers directly for real-time updates
    final baseRate = ref.watch(homeScreenRateProvider);
    final routeDistance = ref.watch(homeScreenRouteDistanceProvider);

    // Determine if payment is selected
    final hasPaymentSelection = payCash || selectedPaymentMethod != null;

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

          // Vehicle Type Options OR Payment Selection
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  // Show vehicle selection if no vehicle selected yet
                  if (selectedVehicleType == null) ...[
                    _buildVehicleTypeCard(
                      context,
                      ref,
                      vehicleType: FirebaseConstants.vehicleTypeSedan,
                      displayName: "Sedan",
                      description: "Affordable, comfortable rides",
                      icon: Icons.directions_car,
                      multiplier: AppConstants.sedanMultiplier,
                      baseRate: baseRate,
                      isSelected: false,
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
                      isSelected: false,
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
                      isSelected: false,
                    ),
                  ]
                  // Show payment selection after vehicle is selected
                  else ...[
                    // Selected vehicle summary
                    _buildSelectedVehicleSummary(context, ref, selectedVehicleType, baseRate),
                    const SizedBox(height: 20),
                    
                    // Payment method section header
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Select Payment Method",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Payment methods list
                    paymentMethodsAsync.when(
                      data: (paymentMethods) {
                        return Column(
                          children: [
                            // Saved cards
                            ...paymentMethods.map((pm) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildPaymentMethodCard(context, ref, pm, 
                                selectedPaymentMethod?.id == pm.id),
                            )),
                            
                            // Cash option
                            _buildCashPaymentCard(context, ref, payCash),
                          ],
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(color: Colors.blue),
                        ),
                      ),
                      error: (error, stack) => Column(
                        children: [
                          _buildCashPaymentCard(context, ref, payCash),
                          const SizedBox(height: 12),
                          Text(
                            'Could not load payment methods',
                            style: TextStyle(color: Colors.red[400], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Submit Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Back button when in payment selection
                if (selectedVehicleType != null && !hasPaymentSelection) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        // Reset to vehicle selection
                        ref.read(homeScreenSelectedVehicleTypeProvider.notifier).state = null;
                        ref.read(homeScreenSelectedPaymentMethodProvider.notifier).state = null;
                        ref.read(homeScreenPayCashProvider.notifier).state = false;
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "← Change Vehicle",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                // Main action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedVehicleType == null
                        ? null
                        : !hasPaymentSelection
                            ? null
                            : onVehicleSelected,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedVehicleType == null || !hasPaymentSelection
                          ? Colors.grey
                          : Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      selectedVehicleType == null
                          ? "Select a vehicle type"
                          : !hasPaymentSelection
                              ? "Select payment method"
                              : "Request Ride",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
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
                color: isSelected ? Colors.blue[900] : const Color(0xFF2a2a2a),
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
                            color: Colors.orange[400],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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

  /// Build selected vehicle summary card
  Widget _buildSelectedVehicleSummary(
    BuildContext context,
    WidgetRef ref,
    String vehicleType,
    double? baseRate,
  ) {
    String displayName = 'Vehicle';
    double multiplier = 1.0;
    IconData icon = Icons.directions_car;

    if (vehicleType == FirebaseConstants.vehicleTypeSedan) {
      displayName = 'Sedan';
      multiplier = AppConstants.sedanMultiplier;
      icon = Icons.directions_car;
    } else if (vehicleType == FirebaseConstants.vehicleTypeSUV) {
      displayName = 'SUV';
      multiplier = AppConstants.suvMultiplier;
      icon = Icons.airport_shuttle;
    } else if (vehicleType == FirebaseConstants.vehicleTypeLuxurySUV) {
      displayName = 'Luxury SUV';
      multiplier = AppConstants.luxurySuvMultiplier;
      icon = Icons.local_taxi;
    }

    double? fare;
    String fareText;
    if (baseRate != null && baseRate > 0) {
      fare = baseRate * multiplier * 5;
      fareText = CurrencyConfig.formatAmount(fare);
    } else {
      fareText = "${CurrencyConfig.code} ...";
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue, width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 28, color: Colors.white),
          ),
          const SizedBox(width: 16),
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
                  'Selected',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue[200],
                        fontSize: 12,
                      ),
                ),
              ],
            ),
          ),
          Text(
            fareText,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  /// Build payment method card (for saved cards)
  Widget _buildPaymentMethodCard(
    BuildContext context,
    WidgetRef ref,
    PaymentMethodModel paymentMethod,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () {
        ref.read(homeScreenSelectedPaymentMethodProvider.notifier).state = paymentMethod;
        ref.read(homeScreenPayCashProvider.notifier).state = false;
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
            // Card icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue[900] : Colors.grey[700],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.credit_card,
                size: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            // Card details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    paymentMethod.fullDisplayString,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Expires ${paymentMethod.expiryDisplayString}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                  ),
                  if (paymentMethod.isDefault) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.green, width: 1),
                      ),
                      child: Text(
                        'DEFAULT',
                        style: TextStyle(
                          color: Colors.green[300],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Selected indicator
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Colors.blue[300],
                size: 28,
              ),
          ],
        ),
      ),
    );
  }

  /// Build cash payment option card
  Widget _buildCashPaymentCard(
    BuildContext context,
    WidgetRef ref,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () {
        ref.read(homeScreenPayCashProvider.notifier).state = true;
        ref.read(homeScreenSelectedPaymentMethodProvider.notifier).state = null;
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green[300]! : Colors.grey[700]!,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Cash icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.green[900] : Colors.grey[700],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.payments,
                size: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            // Cash details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pay with Cash',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pay driver in cash upon arrival',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                  ),
                ],
              ),
            ),
            // Selected indicator
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Colors.green[300],
                size: 28,
              ),
          ],
        ),
      ),
    );
  }
}

