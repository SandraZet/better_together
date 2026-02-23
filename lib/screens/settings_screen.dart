import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:better_together/services/profanity_service.dart';
import 'package:better_together/services/tour_service.dart';

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
          backgroundColor: Colors.pink,
          duration: const Duration(seconds: 3),
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

  Widget _buildSlotTimeRow(String slotName, String time) {
    final double scale = (MediaQuery.of(context).size.width / 390.0).clamp(
      1.0,
      1.4,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          slotName,
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 15 * scale,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          time,
          style: GoogleFonts.poppins(
            color: Colors.black54,
            fontSize: 15 * scale,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    final double scale = (w / 390.0).clamp(1.0, 1.4);
    final double hPad = w > 640 ? (w - 600) / 2.0 : 20.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 32 * scale,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 24 * scale),

              // Nickname field
              TextField(
                controller: _nicknameController,
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 15 * scale,
                ),
                decoration: InputDecoration(
                  labelText: 'Nickname',
                  labelStyle: GoogleFonts.poppins(
                    color: Colors.black54,
                    fontSize: 14 * scale,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              SizedBox(height: 12 * scale),

              // Location field
              TextField(
                controller: _locationController,
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 15 * scale,
                ),
                decoration: InputDecoration(
                  labelText: 'Location',
                  labelStyle: GoogleFonts.poppins(
                    color: Colors.black54,
                    fontSize: 14 * scale,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              SizedBox(height: 20 * scale),

              // Save button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.pink[400]!, Colors.purple[400]!],
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
                      color: Colors.white,
                      fontSize: 16 * scale,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12 * scale),

              // Replay Tour button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    await TourService.resetTour();
                    if (mounted) {
                      Navigator.pop(context, 'replay_tour');
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.grey[100],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.replay, size: 18 * scale, color: Colors.black),
                      const SizedBox(width: 8),
                      Text(
                        'Replay Tour',
                        style: GoogleFonts.poppins(
                          fontSize: 15 * scale,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 40 * scale),
              Divider(color: Colors.grey[200], thickness: 1),
              SizedBox(height: 24 * scale),

              // Slot times section
              Text(
                'Actions refresh daily at:',
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 18 * scale,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 12 * scale),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildSlotTimeRow('Morning', '05:00'),
                    const SizedBox(height: 12),
                    _buildSlotTimeRow('Noon', '12:00'),
                    const SizedBox(height: 12),
                    _buildSlotTimeRow('Afternoon', '17:00'),
                    const SizedBox(height: 12),
                    _buildSlotTimeRow('Night', '22:00'),
                  ],
                ),
              ),

              SizedBox(height: 40 * scale),
              Divider(color: Colors.grey[200], thickness: 1),
              SizedBox(height: 24 * scale),

              // Privacy policy section
              Text(
                'Imprint & Privacy Policy',
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 18 * scale,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4 * scale),
              Text(
                'Last updated: February 2026',
                style: GoogleFonts.poppins(
                  color: Colors.black45,
                  fontSize: 12 * scale,
                ),
              ),
              SizedBox(height: 16 * scale),
              Text(
                '1. Responsible Party\n\n'
                'S.Zet Studios\n'
                'Felsenweg 9\n'
                '2840 Grimmenstein\n'
                'Austria\n'
                'Email: sandrazaenglein@gmail.com\n\n'
                '2. General Information\n\n'
                'The NOW app can be used without registration.\n'
                'No personal data such as name, email, or phone number is collected.\n'
                'All stored data is non-personal and serves exclusively for the app\'s functionality.\n\n'
                '3. What Data We Store\n\n'
                'a) Nickname\n'
                'When first starting the app, users choose a freely invented nickname.\n'
                'This nickname is used exclusively for display within the app and is not personal data.\n\n'
                'b) Location (freely entered)\n'
                'Users can voluntarily enter an approximate location (e.g., city, country, or any freely chosen term).\n'
                'This information is not precise and does not allow identification of a person.\n\n'
                'c) Ideas / Micro-Action Suggestions & Push Notifications\n'
                'When users submit an idea, we store:\n'
                '• Nickname\n'
                '• Voluntary location\n'
                '• Idea text\n'
                '• Device push notification token (only if you explicitly opt-in during submission)\n\n'
                'If you opt-in for notifications, your device token is stored securely and used solely to notify you when your idea gets scheduled. No other messages are sent.\n'
                'You can opt-out at any time in your profile settings.\n\n'
                'd) Slot Data\n'
                'For the micro-action slots to function, we store:\n'
                '• Which slot was used\n'
                '• Which micro action was displayed\n'
                '• Nickname and location for display on share cards or community notices\n\n'
                '4. Firebase Firestore (Data Storage)\n\n'
                'We use Firebase Firestore to store the above-mentioned data.\n'
                'This data is not linked to personal information.\n'
                'Service provider: Google Ireland Limited, Gordon House, Barrow Street, Dublin 4, Ireland\n'
                'Privacy Policy: https://policies.google.com/privacy\n\n'
                '5. Firebase Analytics (Anonymous Usage Statistics)\n\n'
                'NOW uses Firebase Analytics to collect anonymous usage data.\n'
                'Firebase Analytics does not collect personal data, does not use advertising IDs, and does not create user profiles.\n\n'
                '6. Push Notifications (Firebase Cloud Messaging)\n\n'
                'If you opt-in when submitting an idea, NOW uses Firebase Cloud Messaging (FCM) to notify you when your idea is scheduled.\n'
                '• Notifications are only sent to users who explicitly opted-in.\n'
                '• We do not send marketing or unsolicited push notifications.\n'
                '• Your device token is not shared with any third party outside of Google/Firebase.\n'
                '• You can withdraw consent at any time in your profile settings or by contacting us.\n\n'
                '7. No Sharing with Third Parties\n\n'
                'No stored data is shared with third parties outside of Firebase/Google.\n'
                'We do not operate advertising, tracking, or sell any data.\n\n'
                '8. No Location Tracking / No Sensitive Data\n\n'
                'NOW does not collect GPS location data, does not use tracking tools, does not integrate social media SDKs, and does not use cookies.\n\n'
                '9. User Rights\n\n'
                'Users can request deletion of the following data at any time:\n'
                '• Nickname\n'
                '• Location\n'
                '• Submitted ideas\n'
                '• Slot data\n'
                '• Push notification token\n\n'
                'Contact: sandrazaenglein@gmail.com\n'
                'We will delete the data within 14 days.\n\n'
                '10. Data Retention\n\n'
                'Data remains stored as long as necessary for the app\'s functionality.\n'
                'No profiling or identity tracking takes place.\n\n'
                '11. Changes to Privacy Policy\n\n'
                'We may update this policy as needed.\n'
                'The current version is always displayed in the app.',
                style: GoogleFonts.poppins(
                  color: Colors.black54,
                  fontSize: 13 * scale,
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
