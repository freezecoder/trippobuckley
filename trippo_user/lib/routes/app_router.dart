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
import '../View/Screens/Main_Screens/main_navigation.dart';

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
      
      // Driver Routes
      GoRoute(
        path: RouteNames.driverConfig,
        name: RouteNames.driverConfig,
        builder: (context, state) => const DriverConfigScreen(),
      ),
      
      GoRoute(
        path: RouteNames.driverMain,
        name: RouteNames.driverMain,
        builder: (context, state) => const DriverMainNavigation(),
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
      
      // User Routes
      GoRoute(
        path: RouteNames.userMain,
        name: RouteNames.userMain,
        builder: (context, state) => const MainNavigation(),
        routes: [
          // Nested user routes (like where-to)
          GoRoute(
            path: 'where-to',
            name: RouteNames.whereTo,
            builder: (context, state) {
              // final controller = state.extra; // Will be used when screen is migrated
              return const Scaffold(
                body: Center(
                  child: Text('Where To Screen - To be migrated'),
                ),
              );
            },
          ),
        ],
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
    
    // If authenticated and on auth pages, redirect to appropriate home
    if (isAuthenticated && publicRoutes.contains(location)) {
      // Don't redirect from splash (it handles its own navigation)
      if (location == RouteNames.splash) {
        return null;
      }
      
      // Get user data to determine role with timeout
      final user = await container
          .read(currentUserProvider.future)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('⚠️ User data fetch timeout, redirecting to login');
              return null;
            },
          );
      
      if (user == null) {
        // User authenticated but no data - logout
        final authRepo = container.read(authRepositoryProvider);
        await authRepo.logout();
        return RouteNames.login;
      }
      
      // Redirect based on role
      if (user.isDriver) {
        final hasConfig =
            await container.read(hasCompletedDriverConfigProvider.future);
        return hasConfig ? RouteNames.driverMain : RouteNames.driverConfig;
      } else {
        return RouteNames.userMain;
      }
    }
    
    // Check role-based route protection
    if (isAuthenticated) {
      final user = await container
          .read(currentUserProvider.future)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => null,
          );
      
      if (user != null) {
        // Prevent users from accessing driver routes
        if (!user.isDriver && location.startsWith('/driver')) {
          return RouteNames.userMain;
        }
        
        // Prevent drivers from accessing user routes
        if (user.isDriver && location.startsWith('/user')) {
          // Check if driver completed config
          final hasConfig =
              await container.read(hasCompletedDriverConfigProvider.future);
          return hasConfig ? RouteNames.driverMain : RouteNames.driverConfig;
        }
      }
    }
    
    // Allow navigation
    return null;
  } catch (e) {
    // On error, redirect to splash
    debugPrint('Redirect error: $e');
    return RouteNames.splash;
  }
}

