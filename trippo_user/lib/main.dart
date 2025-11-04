import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'firebase_options.dart';
import 'routes/app_router.dart';
import 'View/Themes/app_theme.dart';
import 'core/constants/stripe_constants.dart';

// Background message handler must be a top-level function
// Only used on mobile platforms (iOS and Android)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not already initialized
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Handling a background message: ${message.notification?.title}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Initialize Stripe BEFORE app starts (REQUIRED for flutter_stripe_web!)
  Stripe.publishableKey = StripeConstants.activePublishableKey;
  debugPrint('✅ Stripe initialized with publishable key');
  
  // Register background message handler only on mobile platforms
  // Web platform requires additional service worker setup which is not configured
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    debugPrint('✅ Firebase Messaging initialized for mobile');
  } else {
    debugPrint('ℹ️ Firebase Messaging skipped on web platform');
  }
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'BTrips - Unified App',
      theme: appTheme,
      routerConfig: router,
    );
  }
}
