import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'driver_pending_rides_screen.dart';
import 'driver_active_rides_screen.dart';
import '../../../history/presentation/screens/driver_history_screen.dart';
import '../../../../../data/providers/ride_providers.dart';

/// Main rides screen with 3 tabs: Pending, Active, History
class DriverRidesMainScreen extends ConsumerWidget {
  const DriverRidesMainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch pending and active rides counts
    final pendingRides = ref.watch(pendingRideRequestsProvider);
    final activeRides = ref.watch(driverActiveRidesProvider);
    
    final pendingCount = pendingRides.maybeWhen(
      data: (rides) => rides.length,
      orElse: () => 0,
    );
    
    final activeCount = activeRides.maybeWhen(
      data: (rides) => rides.length,
      orElse: () => 0,
    );

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Rides'),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          bottom: TabBar(
            indicatorColor: Colors.blue,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(
                icon: Badge(
                  label: Text(pendingCount.toString()),
                  isLabelVisible: pendingCount > 0,
                  backgroundColor: Colors.orange,
                  child: const Icon(Icons.pending_actions),
                ),
                text: 'Pending',
              ),
              Tab(
                icon: Badge(
                  label: Text(activeCount.toString()),
                  isLabelVisible: activeCount > 0,
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.local_taxi),
                ),
                text: 'Active',
              ),
              const Tab(
                icon: Icon(Icons.history),
                text: 'History',
              ),
            ],
          ),
        ),
        backgroundColor: Colors.black,
        body: const TabBarView(
          children: [
            DriverPendingRidesScreen(),
            DriverActiveRidesScreen(),
            DriverHistoryScreen(),
          ],
        ),
      ),
    );
  }
}

