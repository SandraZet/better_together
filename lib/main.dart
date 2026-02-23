import 'package:better_together/screens/onboarding_screen_v2.dart';
import 'package:better_together/screens/slot_screen.dart';
import 'package:better_together/screens/onboarding_screen.dart';
import 'package:better_together/screens/splash_screen.dart';
import 'package:better_together/screens/user_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:provider/provider.dart';
import 'firebase_options.dart';
// import 'providers/app_state_provider.dart';
import 'services/profanity_service.dart';
import 'services/revenue_cat_service.dart';
import 'services/analytics_service.dart';
import 'services/notification_service.dart';

// Handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('📬 Background message: ${message.notification?.title}');

  // Save scheduled idea notification to local storage
  if (message.data.containsKey('date') || message.data.containsKey('slot')) {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scheduledNotifications =
          prefs.getStringList('scheduled_notifications') ?? [];

      final title = message.notification?.title ?? 'Task scheduled';
      final body = message.notification?.body ?? '';
      final date = message.data['date'] ?? '';
      final slot = message.data['slot'] ?? '';
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      final notificationData = [title, body, date, slot, timestamp].join('|||');
      scheduledNotifications.add(notificationData);

      await prefs.setStringList(
        'scheduled_notifications',
        scheduledNotifications,
      );
      print('💾 Background: Saved scheduled notification');
    } catch (e) {
      print('❌ Error saving background notification: $e');
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable edge-to-edge on Android
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Make system bars transparent for edge-to-edge
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  // Portrait mode only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize Notification Service (for foreground)
  await NotificationService().initialize();

  // Handle notification clicks when app was terminated
  RemoteMessage? initialMessage = await FirebaseMessaging.instance
      .getInitialMessage();
  if (initialMessage != null) {
    print(
      '📬 App opened from notification: ${initialMessage.notification?.title}',
    );
  }

  // Handle notification clicks when app is in background
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('📬 Notification clicked: ${message.notification?.title}');
    // Navigate to profile screen
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const UserProfileScreen()),
    );
  });

  // Load profanity words
  await ProfanityService().loadWords();

  // Initialize RevenueCat
  await RevenueCatService().initialize();

  runApp(const BetterTogetherApp());
}

// Global navigator key for navigation from outside widget tree
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class BetterTogetherApp extends StatelessWidget {
  const BetterTogetherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Now.',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
        useMaterial3: true,
      ),
      navigatorKey: navigatorKey,
      navigatorObservers: [AnalyticsService().observer],
      home: SplashScreen(
        nextScreen: OnboardingScreenV2(nextScreen: const SlotScreen()),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
