import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:better_together/services/profanity_service.dart';
import 'package:better_together/services/analytics_service.dart';

class IdeaModal extends StatefulWidget {
  final String nickname;
  final VoidCallback onSubmitted;
  const IdeaModal({
    super.key,
    required this.nickname,
    required this.onSubmitted,
  });

  @override
  State<IdeaModal> createState() => _IdeaModalState();
}

class _IdeaModalState extends State<IdeaModal> {
  final TextEditingController _ideaController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  bool _isSubmitted = false;
  String _nickname = '';
  late final String _initialNickname;
  String _initialLocation = '';
  bool _isLoadingPrefs = true;

  @override
  void initState() {
    super.initState();
    _nickname = widget.nickname;
    _initialNickname = widget.nickname;
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _initialLocation = prefs.getString('location') ?? '';
      _isLoadingPrefs = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget _buildBody() {
      if (_isSubmitted) {
        return SizedBox(
          width: double.infinity,
          height: 250,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Thanks!',
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
              const Text(
                'You are awesome!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black54,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        );
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Got a micro-action\nothers might love?',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ideas you submit may be gently edited to match the NOW.style.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.black.withOpacity(0.4),
            ),
            //textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _ideaController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Share your idea!',
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 16),
          if (_initialNickname == 'tom' || _initialNickname.isEmpty) ...[
            TextField(
              controller: _nicknameController,
              decoration: InputDecoration(
                hintText: 'Nickname',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (val) {
                _nickname = val.trim();
              },
            ),
            const SizedBox(height: 8),
          ],
          if (_isLoadingPrefs || _initialLocation.isEmpty) ...[
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: 'Location',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),
          ],
          ElevatedButton(
            onPressed: () async {
              final text = _ideaController.text.trim();
              if (text.isEmpty) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter your idea'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
                return;
              }
              HapticFeedback.mediumImpact();
              try {
                final prefs = await SharedPreferences.getInstance();
                final nickname = _nickname.isNotEmpty
                    ? _nickname
                    : (prefs.getString('nickname') ?? 'tom');

                // Save location if provided
                final locationText = _locationController.text.trim();
                if (locationText.isNotEmpty) {
                  await prefs.setString('location', locationText);
                }
                final location = locationText.isNotEmpty
                    ? locationText
                    : (prefs.getString('location') ?? '');

                // Profanity check
                final profanityService = ProfanityService();
                final hasProfanity =
                    profanityService.containsProfanity(text) ||
                    profanityService.containsProfanity(nickname);

                if (hasProfanity) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: const Text(
                        'Hey there! 👋\nLet\'s keep our ideas and nicknames friendly and respectful.',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      backgroundColor: Colors.orange[700],
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  return;
                }

                final db = FirebaseFirestore.instanceFor(
                  app: Firebase.app(),
                  databaseId: 'nowdb',
                );
                await db.collection('ideas').add({
                  'idea': text,
                  'nickname': nickname,
                  'location': location,
                  'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                  'timestamp': FieldValue.serverTimestamp(),
                });

                // Log analytics
                await AnalyticsService().logIdeaSubmitted(
                  nickname: nickname,
                  location: location,
                );

                setState(() {
                  _isSubmitted = true;
                });
                Future.delayed(const Duration(seconds: 3), () {
                  Navigator.pop(context);
                  widget.onSubmitted();
                });
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to save: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Send',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );
    }

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              _buildBody(),
            ],
          ),
        ),
      ),
    );
  }
}
