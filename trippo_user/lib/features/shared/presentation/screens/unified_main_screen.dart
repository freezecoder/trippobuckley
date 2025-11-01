import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/providers/auth_providers.dart';
import '../../../driver/navigation/driver_main_navigation.dart';
import '../../../../View/Screens/Main_Screens/main_navigation.dart';

/// Unified main screen that shows different UI based on user role
/// This is the single entry point for both users and drivers
class UnifiedMainScreen extends ConsumerWidget {
  const UnifiedMainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          // User not found - should not happen here
          return const Scaffold(
            body: Center(
              child: Text('User data not found'),
            ),
          );
        }

        debugPrint('🎯 UnifiedMainScreen - Showing UI for: ${user.email}');
        debugPrint('   Role: ${user.userType}');
        debugPrint('   isDriver: ${user.isDriver}');

        // Show different UI based on role
        if (user.isDriver) {
          debugPrint('   → Showing Driver UI (4 tabs)');
          return const DriverMainNavigation();
        } else {
          debugPrint('   → Showing User UI (2 tabs)');
          return const MainNavigation();
        }
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading user data: $error'),
            ],
          ),
        ),
      ),
    );
  }
}

