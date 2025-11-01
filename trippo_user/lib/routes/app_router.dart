import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/route_constants.dart';
import '../data/providers/auth_providers.dart';
import '../data/providers/user_providers.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/role_selection_screen.dart';
import '../features/driver/config/presentation/screens/driver_config_screen.dart';
import '../features/driver/navigation/driver_main_navigation.dart';
import '../features/shared/presentation/screens/rating_screen.dart';

// Import existing screens (will be migrated later)
import '../View/Screens/Auth_Screens/Login_Screen/login_screen.dart';
import '../View/Screens/Auth_Screens/Register_Screen/register_screen.dart';
import '../features/shared/presentation/screens/unified_main_screen.dart';

/// Global key for accessing navigator state
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Provider for GoRouter instance
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    
    // Redirect logic for role-based navigation
    redirect: (BuildContext context, GoRouterState state) async {
      // Get the container to access providers
      final container = ProviderScope.containerOf(context);
      
      return await _handleRedirect(container, state);
    },
    
    routes: [
      // Splash Screen
      GoRoute(
        path: RouteNames.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Authentication Routes
      GoRoute(
        path: RouteNames.roleSelection,
        name: RouteNames.roleSelection,
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      
      GoRoute(
        path: RouteNames.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      
      GoRoute(
        path: RouteNames.register,
        name: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      
      // Unified Main Route - Shows different UI based on user role
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const UnifiedMainScreen(),
      ),
      
      // Driver-specific setup (one-time config)
      GoRoute(
        path: RouteNames.driverConfig,
        name: RouteNames.driverConfig,
        builder: (context, state) => const DriverConfigScreen(),
      ),
      
      // Shared Routes
      GoRoute(
        path: RouteNames.ratingScreen,
        name: RouteNames.ratingScreen,
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>?;
          final rideId = extras?['rideId'] as String? ?? '';
          final isDriver = extras?['isDriver'] as bool? ?? false;
          
          return RatingScreen(
            rideId: rideId,
            isDriver: isDriver,
          );
        },
      ),
    ],
    
    // Error page
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              '404 - Page Not Found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.goNamed(RouteNames.splash),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

/// Handle redirect logic based on auth state and user role
Future<String?> _handleRedirect(
  ProviderContainer container,
  GoRouterState state,
) async {
  final location = state.matchedLocation;
  
  // Public routes that don't require auth
  final publicRoutes = [
    RouteNames.splash,
    RouteNames.login,
    RouteNames.register,
    RouteNames.roleSelection,
  ];
  
  try {
    // Check if user is authenticated with timeout
    final authUser = await container
        .read(firebaseAuthUserProvider.future)
        .timeout(const Duration(seconds: 5));
    final isAuthenticated = authUser != null;
    
    // If not authenticated and trying to access protected route
    if (!isAuthenticated && !publicRoutes.contains(location)) {
      return RouteNames.login;
    }
    
    // If authenticated and on auth pages, redirect to home
    if (isAuthenticated && publicRoutes.contains(location)) {
      // Don't redirect from splash (it handles its own navigation)
      if (location == RouteNames.splash) {
        return null;
      }
      
      // Check if driver needs to complete config
      final user = await container
          .read(currentUserProvider.future)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => null,
          );
      
      if (user == null) {
        // User authenticated but no data - logout
        final authRepo = container.read(authRepositoryProvider);
        await authRepo.logout();
        return RouteNames.login;
      }
      
      // If driver without config, go to driver config
      if (user.isDriver) {
        final hasConfig =
            await container.read(hasCompletedDriverConfigProvider.future);
        if (!hasConfig) {
          debugPrint('🔀 Driver needs config, redirecting to driver-config');
          return RouteNames.driverConfig;
        }
      }
      
      // Otherwise, go to unified home (shows role-appropriate UI)
      debugPrint('🔀 Router redirecting to unified home');
      return '/home';
    }
    
    // Allow navigation
    return null;
  } catch (e) {
    // On error, redirect to splash
    debugPrint('Redirect error: $e');
    return RouteNames.splash;
  }
}

