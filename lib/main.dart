import 'package:better_together/screens/onboarding_screen_v2.dart';
import 'package:better_together/screens/slot_screen.dart';
import 'package:better_together/screens/onboarding_screen.dart';
import 'package:better_together/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:provider/provider.dart';
import 'firebase_options.dart';
// import 'providers/app_state_provider.dart';
import 'services/profanity_service.dart';
import 'services/revenue_cat_service.dart';
import 'services/analytics_service.dart';

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

  // Load profanity words
  await ProfanityService().loadWords();

  // Initialize RevenueCat
  await RevenueCatService().initialize();

  runApp(const BetterTogetherApp());
}

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
      navigatorObservers: [AnalyticsService().observer],
      home: SplashScreen(
        nextScreen: OnboardingScreenV2(nextScreen: const SlotScreen()),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
