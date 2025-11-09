import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trippo_driver/View/Screens/Main_Screens/History_Screen/history_screen.dart';
import 'package:trippo_driver/View/Screens/Main_Screens/Home_Screen/home_screen.dart';
import 'package:trippo_driver/View/Screens/Main_Screens/Payment_Screen/payment_screen.dart';
import 'package:trippo_driver/View/Screens/Main_Screens/Profile_Screen/profile_screen.dart';
import 'package:trippo_driver/View/Screens/Main_Screens/Delivery_Screens/pending_deliveries_screen.dart';
import 'package:trippo_driver/View/Screens/Nav_Screens/navigation_providers.dart';



class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  List<Widget> screens = [
    const HomeScreen(),
    const PendingDeliveriesScreen(), // NEW: Deliveries tab
    const PaymentScreen(),
    const HistoryScreen(),
    const ProfileScreen()
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return Scaffold(
          body: screens[ref.watch(navigationStateProvider)],
          bottomNavigationBar: NavigationBar(
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                label: "Home",
                selectedIcon: Icon(Icons.home),
              ),
              // NEW: Deliveries tab with badge
              NavigationDestination(
                icon: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('rideRequests')
                      .where('isDelivery', isEqualTo: true)
                      .where('status', isEqualTo: 'pending')
                      .snapshots(),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.docs.length ?? 0;
                    return Badge(
                      label: Text(count.toString()),
                      isLabelVisible: count > 0,
                      backgroundColor: Colors.red,
                      child: const Icon(Icons.delivery_dining_outlined),
                    );
                  },
                ),
                label: "Deliveries",
                selectedIcon: const Icon(Icons.delivery_dining),
              ),
              const NavigationDestination(
                icon: Icon(Icons.currency_bitcoin_outlined),
                label: "Payment",
                selectedIcon: Icon(Icons.currency_bitcoin),
              ),
              const NavigationDestination(
                icon: Icon(Icons.history_edu_outlined),
                label: "History",
                selectedIcon: Icon(Icons.history_edu),
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_2_outlined),
                label: "Profile",
                selectedIcon: Icon(Icons.person),
              )
            ],
            onDestinationSelected: (int selection) {
              ref
                  .watch(navigationStateProvider.notifier)
                  .update((state) => selection);
            },
            backgroundColor: Colors.black38,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow, // Show labels!
            selectedIndex: ref.watch(navigationStateProvider),
          ),
        );
      },
    );
  }
}
