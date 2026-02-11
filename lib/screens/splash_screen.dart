import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:better_together/screens/onboarding_screen.dart';
import 'package:better_together/screens/onboarding_screen_v2.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _lineAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _beamPulse;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 3500),
      vsync: this,
    );

    _beamPulse = Tween(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.9, curve: Curves.easeInOutSine),
      ),
    );
    _scaleAnimation = Tween(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOutExpo),
      ),
    );

    _lineAnimation = Tween<double>(begin: -0.5, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 4000), () async {
      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

      if (kDebugMode) {
        print('🔍 SplashScreen checking hasSeenOnboarding: $hasSeenOnboarding');
        print('🔍 nextScreen type: ${widget.nextScreen.runtimeType}');
      }

      // Bestimme Zielscreen basierend auf Onboarding-Status
      Widget targetScreen = widget.nextScreen;
      if (hasSeenOnboarding && widget.nextScreen is OnboardingScreenV2) {
        // Onboarding überspringen und direkt zum nächsten Screen
        targetScreen = (widget.nextScreen as OnboardingScreenV2).nextScreen;
        if (kDebugMode) {
          print('✅ Skipping onboarding, going to: ${targetScreen.runtimeType}');
        }
      }

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => targetScreen,
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutQuad,
              ),
              child: child,
            );
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              // Hintergrund
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.2,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.45),
                        ],
                        stops: const [0.7, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(child: Container(color: Colors.black)),
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.2,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.45),
                        ],
                        stops: const [0.7, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: ClipPath(
                  clipper: DiagonalSwipeClipper(_lineAnimation.value + 0.2),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.0),
                          const Color(0xFFFFA53E).withOpacity(0.15),
                          Colors.black.withOpacity(0.0),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
              ),
              // Diagonale Gradient-Linie
              Positioned.fill(
                child: ClipPath(
                  clipper: DiagonalSwipeClipper(_lineAnimation.value),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.zero,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFA53E).withOpacity(0.10),
                          blurRadius: 60,
                          spreadRadius: 30,
                        ),
                      ],
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.black.withOpacity(0.0),
                          const Color(0xFFFF5E99).withOpacity(0.6),
                          const Color(
                            0xFFFFA53E,
                          ).withOpacity(0.85 * _beamPulse.value),
                          const Color(0xFF667EEA).withOpacity(0.7),
                          Colors.black.withOpacity(0.0),
                        ],
                        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                      ),
                    ),
                    foregroundDecoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.black.withOpacity(0.35),
                          Colors.transparent,
                          Colors.black.withOpacity(0.35),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              // Text
              Center(
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'Now.',
                      style: GoogleFonts.poppins(
                        fontSize: 72 * MediaQuery.of(context).size.width / 400,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class DiagonalSwipeClipper extends CustomClipper<Path> {
  final double progress;

  DiagonalSwipeClipper(this.progress);

  @override
  Path getClip(Size size) {
    final path = Path();

    final diagonalLength =
        (size.width + size.height); // genug Weg für sauberes Offscreen

    final lineWidth = size.width * 0.3; // Breite der Linie

    final offset = progress * diagonalLength;

    path.moveTo(-lineWidth + offset, 0);
    path.lineTo(lineWidth + offset, 0);
    path.lineTo(0, lineWidth + offset);
    path.lineTo(0, -lineWidth + offset);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(DiagonalSwipeClipper oldClipper) =>
      oldClipper.progress != progress;
}
