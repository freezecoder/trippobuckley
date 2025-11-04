import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../data/providers/auth_providers.dart';
import '../../../../data/providers/user_providers.dart';

/// Splash screen with role-based routing logic
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: AppConstants.mediumAnimationDuration,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _animationController.forward();

    // Navigate after splash duration
    _navigateBasedOnAuthState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Navigate based on authentication state and user role
  Future<void> _navigateBasedOnAuthState() async {
    // Wait for splash duration
    await Future.delayed(
      Duration(seconds: AppConstants.splashScreenDurationSeconds),
    );

    if (!mounted) return;

    try {
      // Check if user is authenticated
      final authUser = await ref.read(firebaseAuthUserProvider.future);

      if (authUser == null) {
        // Not authenticated - go to role selection
        if (mounted) context.goNamed(RouteNames.roleSelection);
        return;
      }

      // User is authenticated - get full user data with role
      final user = await ref.read(currentUserProvider.future);

      if (user == null) {
        // Error: User authenticated but no data
        // Sign out and go to login
        debugPrint('❌ No user data found for authenticated user');
        final authRepo = ref.read(authRepositoryProvider);
        await authRepo.logout();
        if (mounted) context.goNamed(RouteNames.login);
        return;
      }

      // Log user data for debugging
      debugPrint('✅ User data loaded:');
      debugPrint('   Email: ${user.email}');
      debugPrint('   Name: ${user.name}');
      debugPrint('   UserType: ${user.userType}');
      debugPrint('   isDriver: ${user.isDriver}');
      debugPrint('   isRegularUser: ${user.isRegularUser}');
      debugPrint('   isAdmin: ${user.isAdmin}');

      // Route based on user role
      if (user.isAdmin) {
        // Admin user - go to admin dashboard
        debugPrint('🔐 User is an ADMIN, navigating to admin dashboard');
        if (mounted) context.go('/admin');
      } else if (user.isDriver) {
        debugPrint('🚗 User is a DRIVER, checking config...');
        // Check if driver has completed vehicle configuration
        final hasConfig =
            await ref.read(hasCompletedDriverConfigProvider.future);

        if (hasConfig) {
          // Driver configured - go to unified home (will show driver UI)
          debugPrint('✅ Driver configured, navigating to unified home');
          if (mounted) context.go('/home');
        } else {
          // Driver not configured - go to config screen
          debugPrint('⚠️  Driver not configured, navigating to: ${RouteNames.driverConfig}');
          if (mounted) context.goNamed(RouteNames.driverConfig);
        }
      } else {
        // Regular user - go to unified home (will show user UI)
        debugPrint('👤 User is a PASSENGER, navigating to unified home');
        if (mounted) context.go('/home');
      }
    } catch (e) {
      // Error during navigation - go to login
      debugPrint('Splash navigation error: $e');
      if (mounted) context.goNamed(RouteNames.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Icon/Logo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_taxi,
                    size: 100,
                    color: Colors.blue,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // App Name
                Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 48,
                        letterSpacing: 2,
                      ),
                ),
                
                const SizedBox(height: 8),
                
                // Tagline
                Text(
                  AppConstants.appDescription,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                ),
                
                const SizedBox(height: 48),
                
                // Loading indicator
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    strokeWidth: 3,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Loading text
                Text(
                  'Loading...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

