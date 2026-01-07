import 'package:better_together/services/slot_loader.dart';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:better_together/widgets/idea_modal.dart';
import 'package:better_together/widgets/timezone_modal.dart';
import 'package:better_together/widgets/share_preview_sheet.dart';
import 'package:better_together/widgets/supporter_modal.dart';
import 'package:better_together/services/analytics_service.dart';

import 'package:better_together/screens/settings_screen.dart';
import 'package:better_together/helpers/nickname_helper.dart';

class SlotScreen extends StatefulWidget {
  const SlotScreen({super.key});

  @override
  State<SlotScreen> createState() => _SlotScreenState();
}

class _SlotScreenState extends State<SlotScreen> with TickerProviderStateMixin {
  // ================================================================
  // STATE
  // ================================================================
  final SlotLoader _slotLoader = SlotLoader();
  final AnalyticsService _analytics = AnalyticsService();

  String _headline = "";

  String _text = "";
  String _submittedBy = "";
  String _sponsoredBy = "";
  String _sponsorUrl = "";
  String _location = "";
  int _counter = 0;
  List<String> _nicknames = [];

  String _slot = "";
  String _nickname = "";
  String _taskId = "";

  bool _isDone = false;
  bool _showPlusOne = false;
  bool _isLoading = true;
  bool _isOffline = false;

  final TextEditingController _ideaController = TextEditingController();

  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  StreamSubscription<Map<String, dynamic>>? _counterSubscription;
  Timer? _screenSaverTimer;
  bool _isScreenSaverActive = false;

  // ================================================================
  // ANIMATION (unverändert)
  // ================================================================
  late AnimationController _boltWiggle;
  late AnimationController _boltCelebration;
  late Animation<double> _boltRotation;
  late Animation<double> _boltSpin;
  late Animation<double> _boltJump;
  late AnimationController _doneAnimation;
  late Animation<double> _doneScale;
  late AnimationController _fadeInController;
  late Animation<double> _fadeInAnimation;
  late AnimationController _boltTransitionController;
  late Animation<double> _boltTilt;
  late Animation<double> _boltScale;
  late Animation<double> _boltMoveToCenter;
  late Animation<double> _textFadeOut;

  List<Color> _gradientColors = [];

  @override
  void initState() {
    super.initState();

    _setupAnimations();
    _loadSlotAndTask();
  }

  // ================================================================
  // LOADING
  // ================================================================
  Future<void> _loadSlotAndTask() async {
    try {
      final data = await _slotLoader.loadCurrentSlotTask();
      print(
        'DEBUG: date=${data['date']}, slot=${data['slot']}, taskId=${data['taskId']}, location=${data['location']}',
      );

      // load nickname
      final prefs = await SharedPreferences.getInstance();
      final nickname = prefs.getString('nickname') ?? 'tom';

      // check if done
      final isDone = await _slotLoader.isCurrentSlotDone();

      setState(() {
        _slot = data['slot'];
        _taskId = data['taskId'] ?? '';
        _headline = data['headline'];

        _text = data['text'];
        _submittedBy = data['submittedBy'];
        _sponsoredBy = data['sponsoredBy'];
        _sponsorUrl = data['sponsorUrl'] ?? '';
        _location = data['location'];
        _counter = data['completions'];
        _nicknames = List<String>.from(
          (data['nicknames'] as List?) ?? <String>[],
        );
        _isLoading = false;
        _nickname = nickname;
        _isDone = isDone;
        _isOffline = false;

        // Gradient-Farben einmalig berechnen
        _gradientColors = _calculateGradientColors(_slot);
      });
    } catch (e) {
      print('❌ Error loading task: $e');
      setState(() {
        _isLoading = false;
        _isOffline = true;
        _slot = 'morning'; // default for gradient colors
        _gradientColors = _calculateGradientColors('morning');
      });
      return;
    }

    // Start fade-in animation
    _fadeInController.forward();

    // gently wiggle on start if not done
    if (!_isDone) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _boltWiggle.forward();
      });
    }

    _setupRemainingSeconds();
    _listenToCompletions();

    // Start countdown AFTER slot is loaded
    _startCountdown();
  }

  // ================================================================
  // LISTEN TO COMPLETIONS (LIVE)
  // ================================================================
  void _listenToCompletions() {
    _counterSubscription?.cancel();
    _counterSubscription = _slotLoader.getSlotLiveStream().listen((data) {
      if (!mounted) return;

      final liveNicknames = List<String>.from(
        (data['nicknames'] as List?) ?? <String>[],
      );
      final liveCounter = data['completions'] as int? ?? 0;

      final hasNicknamesChanged = !listEquals(_nicknames, liveNicknames);
      final hasCounterChanged = _counter != liveCounter;

      if (!hasNicknamesChanged && !hasCounterChanged) return;

      setState(() {
        if (hasCounterChanged) _counter = liveCounter;
        if (hasNicknamesChanged) _nicknames = liveNicknames;
      });
    });
  }

  // ================================================================
  // SETUP COUNTDOWN
  // ================================================================
  void _setupRemainingSeconds() {
    final now = DateTime.now();
    late DateTime next;

    if (_slot == "morning") {
      next = DateTime(now.year, now.month, now.day, 12, 0, 0);
    } else if (_slot == "noon") {
      next = DateTime(now.year, now.month, now.day, 17, 0, 0);
    } else if (_slot == "afternoon") {
      next = DateTime(now.year, now.month, now.day, 22, 0, 0);
    } else {
      // night → next morning @ 05:00
      // If it's already past midnight but before 5am, 5am is TODAY
      if (now.hour < 5) {
        next = DateTime(now.year, now.month, now.day, 5, 0, 0);
      } else {
        // Otherwise it's tomorrow at 5am
        final tomorrow = now.add(const Duration(days: 1));
        next = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 5, 0, 0);
      }
    }

    _remainingSeconds = next.difference(now).inSeconds;
  }

  void _startCountdown() {
    // Cancel existing timer before starting new one
    _countdownTimer?.cancel();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_remainingSeconds <= 1) {
        // slot is about to change or has changed
        final currentSlot = _slot; // Remember current slot

        setState(() => _remainingSeconds--);

        // Wait a moment, then check if slot actually changed
        await Future.delayed(const Duration(milliseconds: 100));

        final newData = await _slotLoader.loadCurrentSlotTask();
        final newSlot = newData['slot'];

        if (newSlot != currentSlot) {
          // Slot actually changed - clear old done flag
          print('🔄 Slot changed from $currentSlot to $newSlot');
          final oldSlotTime = DateTime.now().subtract(
            const Duration(seconds: 2),
          );
          await _slotLoader.clearCurrentSlotDoneFlag(when: oldSlotTime);
          _isDone = false;
          _loadSlotAndTask();
        }
        return;
      }

      setState(() => _remainingSeconds--);
    });
  }

  // ================================================================
  // DEBUG: Bot Auto-Complete (REMOVE BEFORE RELEASE)
  // ================================================================
  Future<void> _botAutoComplete() async {
    // Generate random nickname
    final randomNames = [
      'alex',
      'sam',
      'jordan',
      'taylor',
      'casey',
      'riley',
      'morgan',
      'avery',
      'quinn',
      'charlie',
      'drew',
      'jamie',
      'kai',
      'skyler',
      'phoenix',
      'river',
      'sage',
      'rowan',
      'finley',
      'Dakota',
      'emerson',
      'hayden',
      'justice',
      'lennon',
      'marley',
      'navy',
      'oakley',
      'parker',
      'rebel',
      'scout',
      'tatum',
      'winter',
      'zion',
      'ash',
      'blue',
      'cloud',
      'max_99',
      'anna_22',
      'leo_7',
      'mia_11',
      'tim_42',
      'lisa_88',
      'ben_5',
      'nina_13',
      'tom_777',
      'emma_1',
      'paul_21',
      'lara_55',
    ];
    final randomNickname = (randomNames..shuffle()).first;

    // Generate random location
    final randomLocations = [
      'vienna',
      'austria',
      'tokyo',
      'bgld',
      'grimmenstein',
      'salzburg',
      'tulln',
      'linz',
      'graz',
      'innsbruck',
      'klagenfurt',
      'berlin',
      'paris',
      'london',
      'madrid',
      'rome',
      'bangkok',
      'vienna',
      'mumbai',
      'sydney',
    ];
    final randomLocation = (randomLocations..shuffle()).first;

    // Clear preferences BUT keep hasSeenOnboarding and done flags
    final prefs = await SharedPreferences.getInstance();
    final hadSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    // Save all done flags (format: YYYY-MM-DD_slot_done)
    final allKeys = prefs.getKeys();
    final doneFlags = <String, bool>{};
    for (final key in allKeys) {
      if (key.endsWith('_done')) {
        doneFlags[key] = prefs.getBool(key) ?? false;
      }
    }

    await prefs.clear();

    // Restore flags
    if (hadSeenOnboarding) {
      await prefs.setBool('hasSeenOnboarding', true);
    }
    for (final entry in doneFlags.entries) {
      await prefs.setBool(entry.key, entry.value);
    }

    await prefs.setString('nickname', randomNickname);
    await prefs.setString('location', randomLocation);

    // Complete task with nickname|location format
    final displayName = '$randomNickname|$randomLocation';
    await _slotLoader.addCompletion(nickname: displayName);

    // Show toast
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🤖 Bot completed as "$randomNickname"'),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.purple,
      ),
    );

    // Reload
    await Future.delayed(const Duration(milliseconds: 500));
    _loadSlotAndTask();
  }

  // ================================================================
  // ON DID IT
  // ================================================================
  Future<void> _handleDidIt() async {
    HapticFeedback.mediumImpact();

    final prefs = await SharedPreferences.getInstance();
    final userLocation = prefs.getString('location') ?? 'now.space';
    final displayName = '$_nickname|$userLocation';

    await _slotLoader.addCompletion(nickname: displayName);

    // Log analytics
    await _analytics.logTaskCompleted(
      taskId: _taskId,
      slot: _slot,
      nickname: _nickname,
    );

    setState(() {
      _isDone = true;
      _showPlusOne = true;
    });

    // bolt party
    _boltCelebration.forward(from: 0);
    _doneAnimation.repeat(reverse: true);

    // After celebration, start bolt transition
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        _boltTransitionController.forward();
      }
    });

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) setState(() => _showPlusOne = false);
    });

    // Start screen saver after 2 minutes
    _startScreenSaver();
  }

  String _getNextSlotTime(String currentSlot) {
    switch (currentSlot.toLowerCase()) {
      case 'morning':
        return '12pm';
      case 'noon':
        return '5pm';
      case 'afternoon':
        return '10pm';
      case 'night':
        return '5am';
      default:
        return 'soon';
    }
  }

  void _showShareModal() async {
    HapticFeedback.selectionClick();

    final prefs = await SharedPreferences.getInstance();
    final displayLocation = prefs.getString('location') ?? 'now.space';

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SharePreviewSheet(
          location: displayLocation,
          text: _text,
          nickname: _nickname,
          headline: _headline,
          slot: _slot,
          counter: _counter,
          gradientColors: _gradientColors,
          onSubmitted: () {
            Navigator.of(sheetContext).pop();
          },
        );
      },
    );
  }

  void _showLegalInfo() async {
    HapticFeedback.selectionClick();

    final prefs = await SharedPreferences.getInstance();
    final currentNickname = prefs.getString('nickname') ?? 'tom';
    final currentLocation = prefs.getString('location') ?? 'now.space';

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          currentNickname: currentNickname,
          currentLocation: currentLocation,
          onSaved: (nickname, location) {
            setState(() {
              _nickname = nickname;
            });
          },
        ),
      ),
    );
  }

  void _showSupporterModal() {
    HapticFeedback.selectionClick();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SupporterModal(),
    );
  }

  void _startScreenSaver() {
    _screenSaverTimer?.cancel();
    _screenSaverTimer = Timer(const Duration(minutes: 2), () {
      if (mounted && _isDone) {
        setState(() => _isScreenSaverActive = true);
      }
    });
  }

  void _wakeUpScreen() {
    if (_isScreenSaverActive) {
      setState(() => _isScreenSaverActive = false);
      _startScreenSaver(); // Restart timer
    }
  }

  // ================================================================
  // UI + ANIMATIONS (DEIN CODE UNVERÄNDERT)
  // ================================================================

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _counterSubscription?.cancel();
    _screenSaverTimer?.cancel();
    _boltWiggle.dispose();
    _boltCelebration.dispose();
    _doneAnimation.dispose();
    _fadeInController.dispose();
    _boltTransitionController.dispose();
    _ideaController.dispose();
    super.dispose();
  }

  String _fmt(int s) =>
      "${(s ~/ 3600).toString().padLeft(2, '0')}:${((s % 3600) ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}";

  // ================================================================
  // BUILD UI
  // ================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leadingWidth: 80,
        leading: FadeTransition(
          opacity: _fadeInAnimation,
          child: GestureDetector(
            onTap: _showLegalInfo,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.only(left: 16),
              alignment: Alignment.centerLeft,
              child: Text(
                'Now.',
                style: GoogleFonts.poppins(
                  color: _slot == 'night'
                      ? Colors.white.withOpacity(0.35)
                      : Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ),
        title: _isDone
            ? null
            : FadeTransition(
                opacity: _fadeInAnimation,
                child: Text(
                  _fmt(_remainingSeconds),
                  style: GoogleFonts.poppins(
                    color: _slot == 'night' ? Colors.black87 : Colors.black87,
                    fontSize: 17,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
        actions: [
          FadeTransition(
            opacity: _fadeInAnimation,
            child: InkWell(
              onTap: () {
                showGeneralDialog(
                  context: context,
                  barrierDismissible: true,
                  barrierLabel: MaterialLocalizations.of(
                    context,
                  ).modalBarrierDismissLabel,
                  barrierColor: Colors.black54,
                  transitionDuration: const Duration(milliseconds: 300),
                  pageBuilder: (context, animation, secondaryAnimation) {
                    return Align(
                      alignment: Alignment.centerRight,
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.6,
                          height: MediaQuery.of(context).size.height,
                          child: TimezoneModal(
                            counter: _counter,
                            nicknames: _nicknames,
                            currentSlot: _slot,
                          ),
                        ),
                      ),
                    );
                  },
                  transitionBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(1.0, 0.0),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic,
                                ),
                              ),
                          child: child,
                        );
                      },
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.public,
                      color: _slot == 'night'
                          ? Colors.white.withOpacity(0.35)
                          : Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        '$_counter',
                        key: ValueKey(_counter),
                        style: GoogleFonts.poppins(
                          color: _slot == 'night'
                              ? Colors.white.withOpacity(0.35)
                              : Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // IconButton(
          //   icon: Icon(
          //     Icons.bug_report,
          //     color: _slot == 'night' ? const Color(0xFFE5E0EA) : Colors.white,
          //     size: 20,
          //   ),
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (_) => const DebugPrefsScreen()),
          //     );
          //   },
          // ),
          // const SizedBox(width: 8),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _isLoading = true);
          await _loadSlotAndTask();
        },
        color: Colors.white,
        backgroundColor: Colors.black87,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: GestureDetector(
              onTap: _wakeUpScreen,
              behavior: HitTestBehavior.translucent,
              child: Stack(
                children: [
                  _buildGradientBackground(child: _buildActiveView()),

                  if (_isDone)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(color: Colors.black.withOpacity(0.2)),
                      ),
                    ),
                  if (_isScreenSaverActive)
                    Positioned.fill(
                      child: AnimatedOpacity(
                        opacity: _isScreenSaverActive ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 800),
                        child: Container(
                          color: Colors.black.withOpacity(0.92),
                          child: Center(
                            child: Icon(
                              Icons.bolt,
                              size: 80,
                              color: Colors.white.withOpacity(0.15),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: -16,
                    right: -16,
                    bottom: -4,
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        opacity: _nicknames.isNotEmpty ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 600),
                        child: Container(
                          padding: const EdgeInsets.only(top: 32, bottom: 0),
                          child: SafeArea(
                            minimum: const EdgeInsets.only(bottom: 6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 0,
                              ),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: AnimatedOpacity(
                                  opacity: _nicknames.isNotEmpty ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 800),
                                  child: _NicknamesBanner(
                                    nicknames: _nicknames,
                                    isDone: _isDone,
                                    slot: _slot,
                                    nextSlotTime: _getNextSlotTime(_slot),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      // ================================================================
      // DEBUG: Bot Auto-Complete Button (COMMENT OUT BEFORE RELEASE)
      // ================================================================
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _botAutoComplete,
      //   backgroundColor: Colors.purple.withOpacity(0.8),
      //   child: const Text('🤖', style: TextStyle(fontSize: 24)),
      // ),
    );
  }

  // ================================================================
  // GRADIENT CONTAINER (unchanged)
  // ================================================================
  List<Color> _calculateGradientColors(String slot) {
    switch (slot) {
      case 'morning':
        final allMorningColors = [
          const Color(0xFFFFE5B4),
          const Color(0xFFFFB6C1),
          const Color(0xFF87CEEB),
          const Color(0xFFFFDAB9),
          const Color(0xFFFFE4E1),
          const Color(0xFFB0E0E6),
          const Color(0xFFFFF5E1),
          const Color(0xFFFFE4B5),
          const Color(0xFFADD8E6),
        ];
        final shuffled = List<Color>.from(allMorningColors)..shuffle();
        return shuffled.take(3).toList();
      case 'noon':
        final allNoonColors = [
          const Color(0xFFFFD700),
          const Color(0xFFFFA500),
          const Color(0xFF00CED1),
          const Color(0xFFFFB347),
          const Color(0xFFFFCC33),
          const Color(0xFF4FC3F7),
          const Color(0xFFFDB813),
          const Color(0xFFFF9800),
          const Color(0xFF26C6DA),
        ];
        final shuffledNoon = List<Color>.from(allNoonColors)..shuffle();
        return shuffledNoon.take(3).toList();
      case 'afternoon':
        final allAfternoonColors = [
          const Color(0xFFFFA53E),
          const Color(0xFF667EEA),
          const Color(0xFF64B5F6),
          const Color(0xFFFF7E5F),
          const Color(0xFFFEB47B),
          const Color(0xFF86A8E7),
          const Color(0xFFFFAA85),
          const Color(0xFFB993D6),
          const Color(0xFF8CA6DB),
        ];
        final shuffledAfternoon = List<Color>.from(allAfternoonColors)
          ..shuffle();
        return shuffledAfternoon.take(3).toList();
      case 'night':
        final allNightColors = [
          const Color(0xFF1E3A5F),
          const Color(0xFF2D1B4E),
          const Color(0xFF0F1419),
          const Color(0xFF0F2027),
          const Color(0xFF203A43),
          const Color(0xFF2C5364),
          const Color(0xFF141E30),
          const Color(0xFF243B55),
        ];
        final shuffledNight = List<Color>.from(allNightColors)..shuffle();
        return shuffledNight.take(3).toList();
      default:
        return [
          const Color(0xFFFFA53E),
          const Color(0xFF667EEA),
          const Color(0xFF64B5F6),
        ];
    }
  }

  Widget _buildGradientBackground({required Widget child}) {
    return FadeTransition(
      opacity: _fadeInAnimation,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 80, 24, 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _gradientColors.isEmpty
                    ? [Colors.black, Colors.black, Colors.black]
                    : _gradientColors,
              ),
            ),
            child: child,
          ),
          // Warm reddish overlay for subtle warmth
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.0,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.15),
                    ],
                    stops: const [0.7, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // SLOT VIEW (headline, text, bolt…)
  // ================================================================
  Widget _buildActiveView() {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    // Show friendly offline message
    if (_isOffline) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 80,
              color: Colors.white.withOpacity(0.6),
            ),
            const SizedBox(height: 24),
            Text(
              'No internet connection',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Please check your internet\nand try again',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withOpacity(0.7),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                setState(() => _isLoading = true);
                _loadSlotAndTask();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeInAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 2),

          Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: FadeTransition(
                      opacity: _textFadeOut,
                      child: AutoSizeText(
                        _headline,
                        style: GoogleFonts.poppins(
                          fontSize: _slot == 'night' ? 50 : 58,
                          fontWeight: FontWeight.w900,
                          color: _slot == 'night'
                              ? const Color(0xFFE5E0EA)
                              : Colors.white,
                          height: 1.1,
                        ),
                        maxLines: 3,
                        minFontSize: 24,
                        overflow: TextOverflow.visible,
                        wrapWords: false,
                      ),
                    ),
                  ),
                  _buildBolt(),
                ],
              ),
              // +1 Animation
              if (_showPlusOne)
                Positioned(
                  top: -10,
                  right: 40,
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 2500),
                    tween: Tween(begin: 0.0, end: 1.0),
                    onEnd: () {
                      setState(() {
                        _showPlusOne = false;
                      });
                    },
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, -value * 60),
                        child: Opacity(
                          opacity: (1 - value).clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: 1 + (value * 0.5),
                            child: Text(
                              '+1',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                shadows: [
                                  Shadow(
                                    blurRadius: 8,
                                    color: Colors.black.withOpacity(0.3),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          FadeTransition(
            opacity: _textFadeOut,
            child: Text(
              _text,
              style: GoogleFonts.poppins(
                color: _slot == 'night'
                    ? const Color(0xFFE5E0EA).withOpacity(0.5)
                    : Colors.black.withOpacity(0.6),
                fontSize: 22,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 44),

          FadeTransition(opacity: _textFadeOut, child: _buildSubmittedBy()),

          const Spacer(flex: 1),

          // AnimatedCrossFade: Button → Done Message
          Center(
            child: AnimatedCrossFade(
              firstChild: _slot == 'night'
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glow layers - multiple for softer effect
                        Positioned(
                          child: Container(
                            width: 200,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(40),
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFFE5E0EA).withOpacity(0.15),
                                  const Color(0xFFE5E0EA).withOpacity(0.05),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Button
                        ElevatedButton(
                          onPressed: _handleDidIt,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black.withOpacity(0.75),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            _getButtonText(),
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ElevatedButton(
                      onPressed: _handleDidIt,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _getButtonText(),
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),
              secondChild: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 0),
                  ScaleTransition(
                    scale: _doneScale,
                    child: Text(
                      _getDoneTitle(),
                      style: GoogleFonts.poppins(
                        fontSize: _slot == 'night' ? 36 : 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: _slot == 'night'
                            ? Colors.white.withOpacity(0.5)
                            : Colors.white,
                      ),
                    ),
                  ),

                  Text(
                    _getDoneSubtitle(),
                    style: GoogleFonts.poppins(
                      color: _slot == 'night'
                          ? Colors.white.withOpacity(0.4)
                          : Colors.white,
                      fontSize: _slot == 'night' ? 14 : 20,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 56),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: _showShareModal,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(
                              _slot == 'night' ? 0.08 : 0.2,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.share_rounded,
                            color: Colors.white.withOpacity(
                              _slot == 'night' ? 0.35 : 0.8,
                            ),
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 28),
                      GestureDetector(
                        onTap: () => _showSubmitModal(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(
                              _slot == 'night' ? 0.08 : 0.2,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.lightbulb_rounded,
                            color: Colors.white.withOpacity(
                              _slot == 'night' ? 0.35 : 0.8,
                            ),
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 28),
                      GestureDetector(
                        onTap: _showSupporterModal,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(
                              _slot == 'night' ? 0.08 : 0.2,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.star_rounded,
                            color: Colors.white.withOpacity(
                              _slot == 'night' ? 0.35 : 0.8,
                            ),
                            size: 26,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (_sponsoredBy.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    GestureDetector(
                      onTap: _sponsorUrl.isNotEmpty
                          ? () async {
                              try {
                                final uri = Uri.parse(_sponsorUrl);
                                await launchUrl(uri);
                              } catch (e) {
                                print('Could not launch URL: $e');
                              }
                            }
                          : null,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Supported with kindness by\n',
                              style: GoogleFonts.poppins(
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w400,
                                color: _slot == 'night'
                                    ? Colors.white.withOpacity(0.3)
                                    : Colors.black54,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                            TextSpan(
                              text: _sponsoredBy,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: _slot == 'night'
                                    ? Colors.white.withOpacity(0.3)
                                    : Colors.black54,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
              crossFadeState: _isDone
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 400),
            ),
          ),
          SizedBox(height: 40),
        ],
      ),
    );
  }

  // ================================================================
  // SUBMITTED BY
  // =======================================================
  String _getButtonText() {
    switch (_slot) {
      case 'morning':
        return 'Did it!';
      case 'noon':
        return 'Did it!';
      case 'afternoon':
        return 'Did it!';
      case 'night':
        return "I'm here.";
      default:
        return 'Did it!';
    }
  }

  String _getDoneTitle() {
    switch (_slot) {
      case 'morning':
        return 'Done.';
      case 'noon':
        return 'Done.';
      case 'afternoon':
        return 'Done.';
      case 'night':
        return 'Sleep well.';
      default:
        return 'Done.';
    }
  }

  String _getDoneSubtitle() {
    switch (_slot) {
      case 'morning':
        return 'That\'s enough for now.';
      case 'noon':
        return 'You did it. Nice.';
      case 'afternoon':
        return 'See u in a bit!';
      case 'night':
        return '';
      default:
        return 'That\'s enough for now';
    }
  }

  // ================================================================
  // SUBMITTED BY
  // =======================================================
  Widget _buildSubmittedBy() {
    if (_submittedBy.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _slot == 'night' ? Colors.white12 : Colors.white60,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Idea: ⭐ $_submittedBy | $_location',
        style: GoogleFonts.poppins(
          color: _slot == 'night' ? Colors.white38 : Colors.black38,
          fontSize: 13,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  // ================================================================
  // BOLT WIDGET + ANIMATION
  // ================================================================
  void _showSubmitModal(BuildContext context) {
    setState(() {
      _ideaController.clear();
    });
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: IdeaModal(
          nickname: _nickname,
          onSubmitted: () {
            setState(() {
              _ideaController.clear();
            });
          },
        ),
      ),
    );
  }

  // ================================================================
  // BOLT WIDGET + ANIMATION
  // ================================================================
  Widget _buildBolt() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate offset to center: bolt is at right edge, move it to center
        final screenWidth = MediaQuery.of(context).size.width;
        final padding =
            24.0; // horizontal padding from _buildGradientBackground
        final availableWidth = screenWidth - (padding * 2);
        final boltSize = 120.0;

        // Bolt starts at right (availableWidth - boltSize), move to center
        final startX = availableWidth - boltSize;
        final centerX = (availableWidth - boltSize) / 2;
        final moveDistance = -(startX - centerX);

        return AnimatedBuilder(
          animation: Listenable.merge([
            _boltRotation,
            _boltSpin,
            _boltJump,
            _boltTilt,
            _boltScale,
            _boltMoveToCenter,
          ]),
          builder: (_, child) {
            final currentRotation = _isDone
                ? _boltSpin.value
                : _boltRotation.value;
            final transitionRotation = _boltTilt.value;
            final totalRotation = currentRotation + transitionRotation;

            final moveX = moveDistance * _boltMoveToCenter.value;

            return Transform.translate(
              offset: Offset(moveX, _boltJump.value),
              child: Transform.scale(
                scale: _boltScale.value,
                child: Transform.rotate(angle: totalRotation, child: child),
              ),
            );
          },
          child: Icon(
            Icons.bolt,
            color: Colors.black.withOpacity(0.85),
            size: 120,
            shadows: _slot == 'night'
                ? [
                    Shadow(
                      color: Color(0xFFE5E0EA).withOpacity(0.15),
                      blurRadius: 6,
                    ),
                    Shadow(
                      color: Color(0xFFE5E0EA).withOpacity(0.08),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
        );
      },
    );
  }

  // ================================================================
  // SETUP ANIMATIONS (unchanged from your version)
  // ================================================================
  void _setupAnimations() {
    _boltWiggle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _boltRotation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 0.2,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.2,
          end: -0.2,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: -0.2,
          end: 0.15,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.15,
          end: 0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
    ]).animate(_boltWiggle);

    _boltCelebration = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _boltSpin = Tween<double>(begin: 0.0, end: 6.28319).animate(
      CurvedAnimation(parent: _boltCelebration, curve: const Interval(0, 0.6)),
    );

    _boltJump =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(
              begin: 0.0,
              end: -40.0,
            ).chain(CurveTween(curve: Curves.easeOut)),
            weight: 15,
          ),
          TweenSequenceItem(
            tween: Tween<double>(
              begin: -40.0,
              end: 0.0,
            ).chain(CurveTween(curve: Curves.easeIn)),
            weight: 15,
          ),
          TweenSequenceItem(
            tween: Tween<double>(
              begin: 0.0,
              end: -25.0,
            ).chain(CurveTween(curve: Curves.easeOut)),
            weight: 13,
          ),
          TweenSequenceItem(
            tween: Tween<double>(
              begin: -25.0,
              end: 0.0,
            ).chain(CurveTween(curve: Curves.easeIn)),
            weight: 13,
          ),
          TweenSequenceItem(
            tween: Tween<double>(
              begin: 0.0,
              end: -12.0,
            ).chain(CurveTween(curve: Curves.easeOut)),
            weight: 11,
          ),
          TweenSequenceItem(
            tween: Tween<double>(
              begin: -12.0,
              end: 0.0,
            ).chain(CurveTween(curve: Curves.easeInOut)),
            weight: 13,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _boltCelebration,
            curve: const Interval(0.3, 1.0),
          ),
        );

    _doneAnimation = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _doneScale = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _doneAnimation, curve: Curves.easeInOut));

    _fadeInController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeInAnimation = CurvedAnimation(
      parent: _fadeInController,
      curve: Curves.easeIn,
    );

    // Bolt transition mit exakter Timing-Sequenz
    _boltTransitionController = AnimationController(
      duration: const Duration(milliseconds: 4500),
      vsync: this,
    );

    // 0-20%: Text verschwindet
    _textFadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _boltTransitionController,
        curve: const Interval(0.0, 0.20, curve: Curves.easeOut),
      ),
    );

    // 20-32%: Sanft kippen (-20°), 32-45%: Stärker kippen (-35°)
    // 45-70%: Gekippt halten, 70-82%: Aufrichten mit Wackler, 82-100%: Gerade
    _boltTilt = TweenSequence<double>([
      // 0-20%: Gerade bleiben
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 20),

      // 20-45%: Stärker kippen zu -35° (13%)
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: -0.611,
        ).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 13,
      ),
      // 45-70%: Gekippt halten bei -35° (25%)
      TweenSequenceItem(tween: ConstantTween<double>(-0.611), weight: 25),
      // 70-82%: Aufrichten mit Wackler (12%)
      TweenSequenceItem(
        tween: Tween<double>(
          begin: -0.611,
          end: 0.08,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 8,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.08,
          end: -0.03,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 4,
      ),
      // 82-100%: Gerade bleiben (18%)
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 18),
    ]).animate(_boltTransitionController);

    // 45-70%: Zur Mitte wandern (während er gekippt bleibt)
    _boltMoveToCenter = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _boltTransitionController,
        curve: const Interval(0.45, 0.70, curve: Curves.easeInOutCubic),
      ),
    );

    // 82-100%: Größer werden
    _boltScale = TweenSequence<double>([
      // 0-82%: Normal
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 82),
      // 82-93%: Wachsen zu 1.65x (11%)
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.65,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 11,
      ),
      // 93-100%: Zurück zu 1.5x (7%)
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.65,
          end: 1.5,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 7,
      ),
    ]).animate(_boltTransitionController);
  }
}

// ================================================================
// NICKNAMES BANNER
// ================================================================
class _NicknamesBanner extends StatefulWidget {
  final List<String> nicknames;
  final bool isDone;
  final String slot;
  final String nextSlotTime;

  const _NicknamesBanner({
    required this.nicknames,
    required this.isDone,
    required this.slot,
    required this.nextSlotTime,
  });

  @override
  State<_NicknamesBanner> createState() => _NicknamesBannerState();
}

class _NicknamesBannerState extends State<_NicknamesBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  List<String> _formattedNicknames = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60), // Langsamer: 60 Sekunden
    )..repeat();
    _formatNicknames();
  }

  Future<void> _formatNicknames() async {
    final formatted = await Future.wait(
      widget.nicknames.map(
        (nickname) => NicknameHelper.formatNickname(nickname),
      ),
    );
    if (mounted) {
      setState(() {
        _formattedNicknames = formatted;
        _isLoading = false;
      });

      // Geschwindigkeit dynamisch anpassen basierend auf Textlänge
      _updateScrollSpeed();
    }
  }

  void _updateScrollSpeed() {
    // Konstante Geschwindigkeit: Zeichen pro Sekunde
    const charsPerSecond = 3.0; // Je kleiner, desto langsamer

    final charCount = _formattedNicknames.join('   •   ').length;

    // Duration = Anzahl Zeichen / Geschwindigkeit
    final durationSeconds = (charCount / charsPerSecond).clamp(20.0, 300.0);

    _controller.duration = Duration(
      milliseconds: (durationSeconds * 1000).toInt(),
    );
    _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _NicknamesBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.nicknames, widget.nicknames)) {
      setState(() => _isLoading = true);
      _formatNicknames();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && !widget.isDone) {
      return const SizedBox.shrink();
    }

    // If done state, show "Next tiny body&mind..." text instead of nicknames
    final text = widget.isDone
        ? 'Next global tiny body&mind reset starting at: ${widget.nextSlotTime}. '
        : _formattedNicknames
              .map((name) => name.trim().isEmpty ? 'tom' : name)
              .join('   •   ');

    final textStyle = GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: Colors.white.withOpacity(0.45),
      letterSpacing: 0.8,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 34,
        width: double.infinity,
        //padding: const EdgeInsets.symmetric(horizontal: 22),
        color: Colors.transparent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final painter = TextPainter(
              text: TextSpan(text: text, style: textStyle),
              maxLines: 1,
              textDirection: ui.TextDirection.ltr,
            )..layout();
            final textWidth = painter.width == 0 ? maxWidth : painter.width;
            final distance = textWidth + maxWidth;

            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                // Use linear interpolation for smooth scrolling
                final progress = Curves.linear.transform(_controller.value);
                final offset = maxWidth - (distance * progress);
                return Transform.translate(
                  offset: Offset(offset, 0),
                  child: SizedBox(width: textWidth, child: child),
                );
              },
              child: Text(
                text,
                style: textStyle,
                maxLines: 1,
                overflow: TextOverflow.visible,
                softWrap: false,
              ),
            );
          },
        ),
      ),
    );
  }
}
