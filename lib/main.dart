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
        nextScreen: OnboardingScreen(nextScreen: const SlotScreen()),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

/* class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  @override
  void initState() {
    super.initState();
    _setupUser();
  }

  void _setupUser() async {
    final provider = Provider.of<AppStateProvider>(context, listen: false);

    // For now, we'll use a simple nickname setup
    // In a real app, you might want proper user authentication
    if (!provider.isUserSetup) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showNicknameDialog();
      });
    }
  }

  void _showNicknameDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Willkommen!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Wähle einen Nickname um loszulegen:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Nickname',
                hintText: 'z.B. SuperUser123',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              final nickname = controller.text.trim();
              if (nickname.isNotEmpty) {
                Provider.of<AppStateProvider>(
                  context,
                  listen: false,
                ).setUserNickname(nickname);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Los geht\'s!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, provider, child) {
        if (!provider.isUserSetup) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return const HomeScreen();
      },
    );
  }
}
 */
