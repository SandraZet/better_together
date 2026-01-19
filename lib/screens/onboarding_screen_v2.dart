import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:better_together/screens/onboarding_screen.dart';

class OnboardingScreenV2 extends StatefulWidget {
  final Widget nextScreen;

  const OnboardingScreenV2({super.key, required this.nextScreen});

  @override
  State<OnboardingScreenV2> createState() => _OnboardingScreenV2State();
}

class _OnboardingScreenV2State extends State<OnboardingScreenV2>
    with TickerProviderStateMixin {
  // Animation controllers für jeden Text
  late AnimationController _text1Controller;
  late AnimationController _text2Controller;
  late AnimationController _text3Controller;
  late AnimationController _buttonController;

  late Animation<double> _text1Opacity;
  late Animation<double> _text2Opacity;
  late Animation<double> _text3Opacity;
  late Animation<double> _buttonOpacity;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSequence();
  }

  void _setupAnimations() {
    // Text 1: "It's a"
    _text1Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _text1Opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _text1Controller, curve: Curves.easeIn));

    // Text 2: "Radio."
    _text2Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _text2Opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _text2Controller, curve: Curves.easeIn));

    // Text 3: "Ok... kind of." (pink graffiti - the twist!)
    _text3Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _text3Opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _text3Controller, curve: Curves.easeIn));

    // Button
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _buttonOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _buttonController, curve: Curves.easeIn));
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 500));

    // 1. "It's a" - fade in, stay, fade out
    await _text1Controller.forward();
    await Future.delayed(const Duration(milliseconds: 800));
    await _text1Controller.reverse();
    await Future.delayed(const Duration(milliseconds: 300));

    // 2. "Radio." - fade in, stay, fade out
    await _text2Controller.forward();
    await Future.delayed(const Duration(milliseconds: 1200));
    await _text2Controller.reverse();
    await Future.delayed(const Duration(milliseconds: 300));

    // 3. "Ok... kind of." - fade in, stay longer (the twist!), fade out
    await _text3Controller.forward();
    await Future.delayed(const Duration(milliseconds: 1200));
    await _text3Controller.reverse();
    await Future.delayed(const Duration(milliseconds: 500));

    // Button - fade in
    await _buttonController.forward();
  }

  @override
  void dispose() {
    _text1Controller.dispose();
    _text2Controller.dispose();
    _text3Controller.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  Future<void> _onTuneIn() async {
    if (!mounted) return;

    // Navigate to old onboarding screens (starting from page 2)
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => OnboardingScreen(nextScreen: widget.nextScreen),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Film-Texte in der Mitte - alle an derselben Position
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
              child: SizedBox(
                height: 100 * screenWidth / 400,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Text 1: "It's a"
                    FadeTransition(
                      opacity: _text1Opacity,
                      child: Text(
                        "It's a",
                        style: GoogleFonts.poppins(
                          fontSize: 48 * screenWidth / 400,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),

                    // Text 2: "Radio."
                    FadeTransition(
                      opacity: _text2Opacity,
                      child: Text(
                        "Radio.",
                        style: GoogleFonts.poppins(
                          fontSize: 72 * screenWidth / 400,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -1.5,
                        ),
                      ),
                    ),

                    // Text 3: "Ok... kind of." (pink graffiti - the twist!)
                    FadeTransition(
                      opacity: _text3Opacity,
                      child: Text(
                        "Ok... kind of.",
                        style: GoogleFonts.permanentMarker(
                          fontSize: 52 * screenWidth / 400,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFFFF1493), // Hot pink
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Button centered
          Center(
            child: FadeTransition(
              opacity: _buttonOpacity,
              child: GestureDetector(
                onTap: _onTuneIn,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF1493), Color(0xFFFF69B4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
