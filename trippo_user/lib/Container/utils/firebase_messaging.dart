import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:btrips_unified/Container/Repositories/firestore_repo.dart';
import 'package:btrips_unified/Container/utils/error_notification.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class MessagingService {
  static String? fcmToken; // Variable to store the FCM token

  static final MessagingService _instance = MessagingService._internal();

  factory MessagingService() => _instance;

  MessagingService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> init(BuildContext context, WidgetRef ref) async {
    // Skip Firebase Messaging initialization on web
    // Web requires service worker setup which is not configured
    if (kIsWeb) {
      debugPrint('ℹ️ Firebase Messaging not available on web platform');
      return;
    }
    
    try {
      // Initialize local notifications
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();

      // Android initialization
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );

      // Requesting permission for notifications
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint(
          'User granted notifications permission: ${settings.authorizationStatus}');

      // Retrieving the FCM token
      fcmToken = await _fcm.getToken();
      debugPrint('FCM Token: $fcmToken');

      // Listen for token refresh
      _fcm.onTokenRefresh.listen((newToken) {
        fcmToken = newToken;
        debugPrint('FCM Token refreshed: $fcmToken');
        // TODO: Save token to Firestore when user is authenticated
      });

      // Android notification channel
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel', // id
        'Buckley Transport Notifications', // title
        description: 'Notifications for Buckley Transport ride updates',
        importance: Importance.max,
        showBadge: true,
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // Listening for incoming messages while the app is in the foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        debugPrint('Foreground message received: ${message.notification?.title}');
        
        if (message.notification != null) {
          // Show local notification for foreground messages
          final notification = message.notification!;
          
          await flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'high_importance_channel',
                'Buckley Transport Notifications',
                channelDescription: 'Notifications for Buckley Transport ride updates',
                importance: Importance.max,
                priority: Priority.high,
                showWhen: true,
              ),
              iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
            payload: message.data.toString(),
          );

          // Check if ride was denied
          if (message.data.containsKey('status') && 
              message.data['status'] == 'denied') {
            if (context.mounted) {
              ref.read(globalFirestoreRepoProvider).nullifyUserRides(context);
            }
          }

          // Show dialog if app is in foreground
          if (context.mounted && message.notification!.title != null &&
              message.notification!.body != null) {
            final notificationData = message.data;
            final screen = notificationData['screen'];

            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return PopScope(
                  canPop: false,
                  child: AlertDialog(
                    title: Text(message.notification!.title!),
                    content: Text(
                      message.notification!.body!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall!
                          .copyWith(color: Colors.black54),
                    ),
                    actions: [
                      if (screen != null)
                        TextButton(
                          onPressed: () {
                            context.pop();
                            context.goNamed(screen);
                          },
                          child: const Text('Open Screen'),
                        ),
                      TextButton(
                        onPressed: () => context.pop(),
                        child: const Text('Dismiss'),
                      ),
                    ],
                  ),
                );
              },
            );
          }
        }
      });

      // Handling the initial message received when the app is launched from dead (killed state)
      FirebaseMessaging.instance.getInitialMessage().then((message) {
        if (message != null && context.mounted) {
          final notificationData = message.data;
          if (notificationData.containsKey('screen')) {
            final screen = notificationData['screen'];
            context.goNamed(screen);
          }
        }
      });

      // Handling a notification click event when the app is in the background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('Notification opened app: ${message.notification?.title}');
        if (context.mounted) {
          final notificationData = message.data;
          if (notificationData.containsKey('screen')) {
            final screen = notificationData['screen'];
            context.goNamed(screen);
          }
        }
      });
    } catch (e) {
      await Future.delayed(const Duration(seconds: 2));
      SystemChannels.platform.invokeMethod("SystemNavigator.pop");

      if (context.mounted) {
        ErrorNotification().showError(context, e.toString());
      }
    }
  }
}

