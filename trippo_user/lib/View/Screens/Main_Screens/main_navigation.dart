import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:btrips_unified/View/Screens/Main_Screens/Home_Screen/home_screen.dart';
import 'package:btrips_unified/View/Screens/Main_Screens/Home_Screen/modern_home_screen.dart';
import 'package:btrips_unified/View/Screens/Main_Screens/Home_Screen/modern_home_providers.dart';
import 'package:btrips_unified/View/Screens/Main_Screens/Rides_Screen/user_rides_screen.dart';
import 'package:btrips_unified/View/Screens/Main_Screens/Profile_Screen/profile_screen.dart';
import 'package:btrips_unified/data/providers/ride_providers.dart';

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  @override
  Widget build(BuildContext context) {
    // Choose between modern and classic home screen based on provider
    final useModernHome = ref.watch(useModernHomeScreenProvider);
    final currentIndex = ref.watch(mainNavigationTabIndexProvider);
    final activeRides = ref.watch(userActiveRidesProvider).value ?? [];
    final activeRideCount = activeRides.length;
    
    final List<Widget> screens = [
      useModernHome ? const ModernHomeScreen() : const HomeScreen(),
      const UserRidesScreen(),
      const ProfileScreen(),
    ];
    
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            ref.read(mainNavigationTabIndexProvider.notifier).state = index;
          },
          backgroundColor: Colors.black,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: activeRideCount > 0
                  ? Badge(
                      label: Text('$activeRideCount'),
                      backgroundColor: Colors.red,
                      child: const Icon(Icons.receipt_long_outlined),
                    )
                  : const Icon(Icons.receipt_long_outlined),
              activeIcon: activeRideCount > 0
                  ? Badge(
                      label: Text('$activeRideCount'),
                      backgroundColor: Colors.red,
                      child: const Icon(Icons.receipt_long),
                    )
                  : const Icon(Icons.receipt_long),
              label: 'Rides',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

