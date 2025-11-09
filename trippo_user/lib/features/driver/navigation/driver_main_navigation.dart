import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Placeholder screens - will be migrated
import '../home/presentation/screens/driver_home_screen.dart';
import '../deliveries/presentation/screens/driver_deliveries_main_screen.dart';
import '../payments/presentation/screens/driver_payment_screen.dart';
import '../rides/presentation/screens/driver_rides_main_screen.dart';
import '../profile/presentation/screens/driver_profile_screen.dart';

/// Provider for navigation state
final driverNavigationStateProvider = StateProvider<int>((ref) => 0);

/// Main navigation screen for drivers with 4 tabs
class DriverMainNavigation extends ConsumerWidget {
  const DriverMainNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(driverNavigationStateProvider);

    final List<Widget> screens = [
      const DriverHomeScreen(),
      const DriverDeliveriesMainScreen(), // NEW: Deliveries tab with Pending/Active!
      const DriverRidesMainScreen(),
      const DriverPaymentScreen(),
      const DriverProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: "Home",
            selectedIcon: Icon(Icons.home),
          ),
          // NEW: Deliveries tab with live badge
          const NavigationDestination(
            icon: Icon(Icons.delivery_dining_outlined),
            label: "Deliveries",
            selectedIcon: Icon(Icons.delivery_dining),
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: "Rides",
            selectedIcon: Icon(Icons.receipt_long),
          ),
          const NavigationDestination(
            icon: Icon(Icons.attach_money_outlined),
            label: "Earnings",
            selectedIcon: Icon(Icons.attach_money),
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: "Profile",
            selectedIcon: Icon(Icons.person),
          ),
        ],
        onDestinationSelected: (int selection) {
          ref.read(driverNavigationStateProvider.notifier).update((state) => selection);
        },
        backgroundColor: Colors.black,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        selectedIndex: currentIndex,
      ),
    );
  }
}

