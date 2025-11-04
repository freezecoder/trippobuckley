import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/admin_theme.dart';
import '../../../../data/providers/auth_providers.dart';
import 'admin_drivers_screen.dart';
import 'admin_users_screen.dart';
import 'admin_trips_screen.dart';
import 'admin_accounts_screen.dart';
import 'admin_costs_screen.dart';

/// Provider for admin navigation state
final adminNavigationStateProvider = StateProvider<int>((ref) => 0);

/// Main admin screen with bottom navigation (5 sections)
class AdminMainScreen extends ConsumerWidget {
  const AdminMainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(adminNavigationStateProvider);
    final userAsync = ref.watch(currentUserProvider);

    final List<Widget> screens = const [
      AdminDriversScreen(),
      AdminUsersScreen(),
      AdminTripsScreen(),
      AdminAccountsScreen(),
      AdminCostsScreen(),
    ];

    return Theme(
      data: AdminTheme.theme,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Icon(Icons.admin_panel_settings, size: 28),
              const SizedBox(width: 12),
              const Text('BTrips Admin'),
              const Spacer(),
              // Show admin email
              userAsync.when(
                data: (user) => user != null
                    ? Chip(
                        avatar: const Icon(
                          Icons.shield,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: Text(
                          user.email,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: AdminTheme.primaryColor.withValues(alpha: 0.8),
                      )
                    : const SizedBox(),
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(width: 8),
              // Logout button
              IconButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AdminTheme.dangerColor,
                          ),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && context.mounted) {
                    await ref.read(authRepositoryProvider).logout();
                  }
                },
                icon: const Icon(Icons.logout),
                tooltip: 'Logout',
              ),
            ],
          ),
        ),
        body: IndexedStack(
          index: currentIndex,
          children: screens,
        ),
        bottomNavigationBar: NavigationBar(
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.local_taxi_outlined),
              label: 'Drivers',
              selectedIcon: Icon(Icons.local_taxi),
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              label: 'Users',
              selectedIcon: Icon(Icons.people),
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              label: 'Trips',
              selectedIcon: Icon(Icons.map),
            ),
            NavigationDestination(
              icon: Icon(Icons.account_circle_outlined),
              label: 'Accounts',
              selectedIcon: Icon(Icons.account_circle),
            ),
            NavigationDestination(
              icon: Icon(Icons.attach_money_outlined),
              label: 'Costs',
              selectedIcon: Icon(Icons.attach_money),
            ),
          ],
          onDestinationSelected: (int selection) {
            ref.read(adminNavigationStateProvider.notifier).state = selection;
          },
          backgroundColor: AdminTheme.primaryColor,
          indicatorColor: Colors.white.withValues(alpha: 0.2),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          selectedIndex: currentIndex,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.black26,
          elevation: 8,
        ),
      ),
    );
  }
}

