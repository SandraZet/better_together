import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:better_together/services/profanity_service.dart';

class SettingsScreen extends StatefulWidget {
  final String currentNickname;
  final String currentLocation;
  final Function(String nickname, String location) onSaved;

  const SettingsScreen({
    super.key,
    required this.currentNickname,
    required this.currentLocation,
    required this.onSaved,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nicknameController;
  late TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: widget.currentNickname);
    _locationController = TextEditingController(text: widget.currentLocation);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final nickname = _nicknameController.text.trim().isEmpty
        ? 'tom'
        : _nicknameController.text.trim();
    final location = _locationController.text.trim().isEmpty
        ? 'now.space'
        : _locationController.text.trim();

    // Profanity check
    final profanityService = ProfanityService();
    final hasProfanity =
        profanityService.containsProfanity(nickname) ||
        profanityService.containsProfanity(location);

    if (hasProfanity) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            "Not in this universe ;) \n Try another one!",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: Colors.pink, // cosmic & friendly
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nickname', nickname);
    await prefs.setString('location', location);

    if (mounted) {
      widget.onSaved(nickname, location);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Saved!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          backgroundColor: Colors.white,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nicknameController,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Nickname',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _locationController,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Location',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9A56), Color(0xFF4FC3F7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Save',
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              Divider(color: Colors.grey[600], thickness: 1),
              const SizedBox(height: 24),
              Text(
                'Imprint & Privacy Policy',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '(Last updated: 2025)',
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '1. Responsible Party\n\n'
                'S.Zet Studios\n'
                'Felsenweg 9\n'
                '2840 Grimmenstein\n'
                'Austria\n'
                'Email: sandra@szetstudios.com\n\n'
                '2. General Information\n\n'
                'The NOW app can be used without registration.\n'
                'No personal data such as name, email, or phone number is collected.\n\n'
                'All stored data is non-personal and serves exclusively for the app\'s functionality.\n\n'
                '3. What Data We Store\n\n'
                'a) Nickname\n'
                'When first starting the app, users choose a freely invented nickname.\n'
                'This nickname is used exclusively for display within the app and is not personal data.\n\n'
                'b) Location (freely entered)\n'
                'Users can voluntarily enter an approximate location (e.g., city, country, or any freely chosen term).\n'
                'This information is not precise and does not allow identification of a person.\n\n'
                'c) Ideas / Micro-Action Suggestions\n'
                'When users submit an idea, we store:\n'
                '• Nickname\n'
                '• voluntary location\n'
                '• idea text\n\n'
                'This data is used to review, display, or editorially process the idea within the app.\n\n'
                'd) Slot Data\n'
                'For the micro-action slots to function, we store:\n'
                '• which slot was used\n'
                '• which micro action was displayed\n'
                '• nickname and location for display on share cards or community notices\n\n'
                '4. Firebase Firestore (Data Storage)\n\n'
                'We use Firebase Firestore to store the above-mentioned data.\n'
                'This data is not linked to personal information.\n\n'
                'Service provider:\n'
                'Google Ireland Limited\n'
                'Gordon House, Barrow Street, Dublin 4, Ireland\n'
                'Privacy Policy: https://policies.google.com/privacy\n\n'
                '5. Firebase Analytics (Anonymous Usage Statistics)\n\n'
                'NOW uses Firebase Analytics to collect anonymous usage data, e.g.:\n'
                '• App opened\n'
                '• Slot completed\n'
                '• Certain screens accessed\n\n'
                'This data helps us improve the app.\n\n'
                'Firebase Analytics:\n'
                '• does not collect personal data\n'
                '• does not use advertising IDs (IDFA/AAID)\n'
                '• does not create user profiles\n'
                '• does not perform cross-app tracking\n'
                '• serves exclusively for anonymous usage analysis\n\n'
                'An opt-out option in the app is currently not provided, as no personal or advertising-related data is collected.\n\n'
                '6. No Sharing with Third Parties\n\n'
                'No stored data is shared with third parties outside of Firebase/Google.\n'
                'We do not operate advertising, tracking, or sell any data.\n\n'
                '7. No Location Tracking / No Sensitive Data\n\n'
                'NOW:\n'
                '• does not collect GPS location data\n'
                '• does not use tracking tools\n'
                '• does not integrate social media SDKs\n'
                '• does not use cookies\n\n'
                'The entered location is a freely entered text and not an actual location.\n\n'
                '8. User Rights\n\n'
                'Users can request deletion of the following data at any time:\n'
                '• Nickname\n'
                '• Location\n'
                '• submitted ideas\n'
                '• slot data\n\n'
                'Contact: sandra@szetstudios.com\n\n'
                'We will delete the data within 14 days.\n\n'
                '9. Data Retention\n\n'
                'Data remains stored as long as necessary for the app\'s functionality.\n'
                'No profiling or identity tracking takes place.\n\n'
                '10. Changes to Privacy Policy\n\n'
                'We may update this policy as needed.\n'
                'The current version is always displayed in the app.',
                style: GoogleFonts.poppins(
                  color: Colors.grey[300],
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
