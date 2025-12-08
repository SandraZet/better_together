import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:better_together/services/profanity_service.dart';

class OnboardingScreen extends StatefulWidget {
  final Widget nextScreen;

  const OnboardingScreen({super.key, required this.nextScreen});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  int _currentPage = 0;

  // Animation controllers for Page 1
  late AnimationController _line1Controller;
  late AnimationController _line2Controller;
  late AnimationController _line3Controller;
  late AnimationController _nowController;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _line1Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _line2Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _line3Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _nowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Start animations sequentially
    _startPage1Animations();
  }

  void _startPage1Animations() async {
    // Warte auf ersten Frame, damit das Layout vollständig berechnet ist
    await Future.delayed(const Duration(milliseconds: 300));

    await Future.delayed(const Duration(milliseconds: 500));
    _line1Controller.forward();

    await Future.delayed(const Duration(milliseconds: 1200));
    _line2Controller.forward();

    await Future.delayed(const Duration(milliseconds: 1200));
    _line3Controller.forward();

    await Future.delayed(const Duration(milliseconds: 800));
    _nowController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nicknameController.dispose();
    _locationController.dispose();
    _line1Controller.dispose();
    _line2Controller.dispose();
    _line3Controller.dispose();
    _nowController.dispose();
    super.dispose();
  }

  Future<bool> _saveNickname() async {
    final prefs = await SharedPreferences.getInstance();
    final nickname = _nicknameController.text.trim().isEmpty
        ? 'tom'
        : _nicknameController.text.trim();

    // Profanity check
    final profanityService = ProfanityService();
    if (profanityService.containsProfanity(nickname)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: const Text(
              'Nope. Absolutely not.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: Colors.orange[700],
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return false;
    }

    await prefs.setString('nickname', nickname);
    return true;
  }

  Future<bool> _saveLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final location = _locationController.text.trim().isEmpty
        ? 'now.space'
        : _locationController.text.trim();

    // Profanity check
    final profanityService = ProfanityService();
    if (profanityService.containsProfanity(location)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: const Text(
              'Nope. Absolutely not.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: Colors.orange[700],
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return false;
    }

    await prefs.setString('location', location);
    await prefs.setBool('hasSeenOnboarding', true);
    return true;
  }

  Future<void> _nextPage() async {
    // Check profanity before proceeding
    if (_currentPage == 1) {
      final success = await _saveNickname();
      if (!success) return; // Don't proceed if profanity found
    }
    if (_currentPage == 2) {
      final success = await _saveLocation();
      if (!success) return; // Don't proceed if profanity found
    }

    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => widget.nextScreen));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        children: [_buildPage1(), _buildPage2(), _buildPage3(), _buildPage4()],
      ),
    );
  }

  Widget _buildPage1() {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildAnimatedStrikethroughText(
                    'act',
                    'scroll',
                    _line1Controller,
                  ),
                  const SizedBox(height: 24),
                  _buildAnimatedStrikethroughText(
                    'feel',
                    'follow',
                    _line2Controller,
                  ),
                  const SizedBox(height: 24),
                  _buildAnimatedStrikethroughText(
                    'together',
                    'alone',
                    _line3Controller,
                  ),
                  const SizedBox(height: 24),
                  AnimatedBuilder(
                    animation: _nowController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _nowController.value,
                        child: Text(
                          'now.',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.7,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 60),
            child: GestureDetector(
              onTap: _nextPage,
              child: Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage2() {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Choose your 90s ',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Nickname.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'This is us - a tiny crowd doing the same thing at the same moment. Your ideas shape what we all do.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.7),
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  TextField(
                    controller: _nicknameController,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'sk8tergirl92 • BladeRunner_X',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        foreground: Paint()
                          ..shader = const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Color(0x40FF1493), // Hot pink - 25% opacity
                              Color(0x409D00FF), // Purple - 25% opacity
                              Color(0x4000D4FF), // Cyan - 25% opacity
                            ],
                          ).createShader(const Rect.fromLTWH(0, 0, 300, 50)),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Not feeling creative right now? Leave it empty.\nYou can always change it in settings.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.5),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _nextPage,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage3() {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Where are you  ',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'from?',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Let us know your city or country - so we can see how far this moment reaches.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.7),
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  TextField(
                    controller: _locationController,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Vienna • Tokyo • Chile',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.withOpacity(0.6),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _nextPage,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage4() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'READY?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 32),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Three mini-actions each day.\n',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.7),
                        height: 1.5,
                      ),
                    ),
                    TextSpan(
                      text: "You can't fake it to feel it.",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        foreground: Paint()
                          ..shader = const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Color(0xFFFF1493),
                              Color.fromARGB(255, 209, 144, 249), // Purple

                              Color(0xFF00D4FF),
                            ],
                          ).createShader(const Rect.fromLTWH(0, 0, 300, 50)),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 52),
              GestureDetector(
                onTap: _nextPage,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 46,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, Colors.white70],
                    ),
                  ),
                  child: Text(
                    'Go!',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedStrikethroughText(
    String mainText,
    String crossedText,
    AnimationController controller,
  ) {
    // First half: right text fades in with strikethrough
    // Second half: left text fades in
    final rightAnimation = Interval(0.0, 0.5, curve: Curves.easeInOut);
    final leftAnimation = Interval(0.5, 1.0, curve: Curves.easeInOut);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final rightProgress = rightAnimation.transform(controller.value);
        final leftProgress = leftAnimation.transform(controller.value);

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Left text - fades in AFTER right text (second half)
            SizedBox(
              width: 120,
              child: Opacity(
                opacity: leftProgress,
                child: Transform.translate(
                  offset: Offset(0, 8 * (1 - leftProgress)),
                  child: Text(
                    mainText,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
            // Right text - fades to 50% opacity with strikethrough FIRST
            SizedBox(
              width: 120,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Opacity(
                      opacity: rightProgress * 0.5,
                      child: Text(
                        crossedText,
                        textAlign: TextAlign.left,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // Calculate text width
                            final textPainter = TextPainter(
                              text: TextSpan(
                                text: crossedText,
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              textDirection: TextDirection.ltr,
                            )..layout();

                            return Container(
                              height: 1.4,
                              width: textPainter.width * rightProgress,
                              color: Colors.white.withOpacity(0.7),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
