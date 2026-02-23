import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:better_together/services/notification_service.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isLoading = true;
  String _nickname = '';
  bool _notificationsOptedIn = false;
  List<Map<String, String>> _submittedIdeas = [];
  List<Map<String, String>> _scheduledNotifications = [];
  Map<String, int> _achievements = {
    'tasksCompleted': 0,
    'ideasSubmitted': 0,
    'streakDays': 0,
  };
  DateTime? _lastFetchTime;
  bool _hasCachedData = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadNotificationPref();
  }

  Future<void> _loadNotificationPref() async {
    final optedIn = await NotificationService()
        .hasOptedInForIdeaNotifications();
    if (mounted) setState(() => _notificationsOptedIn = optedIn);
  }

  Future<void> _setNotificationOptIn(bool value) async {
    await NotificationService().setIdeaNotificationsOptIn(value);
    setState(() => _notificationsOptedIn = value);
  }

  Future<void> _loadUserData({bool forceRefresh = false}) async {
    // Check if we have cached data that's less than 5 minutes old
    if (!forceRefresh &&
        _hasCachedData &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) <
            const Duration(minutes: 5)) {
      print('📦 Using cached profile data');
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      _nickname = prefs.getString('nickname') ?? 'tom';

      // Calculate completed tasks count from SharedPreferences
      int completedCount = 0;
      print('🔍 Checking SharedPreferences for completed tasks...');
      final allKeys = prefs.getKeys();
      print('📋 Total keys in prefs: ${allKeys.length}');

      for (final key in allKeys) {
        if (key.endsWith('_done')) {
          final value = prefs.getBool(key);
          print('  Key: $key = $value');
          if (value == true) {
            completedCount++;
          }
        }
      }
      print('✅ Total completed tasks: $completedCount');

      // Load submitted ideas from SharedPreferences
      final submittedIdeasRaw = prefs.getStringList('submitted_ideas') ?? [];
      _submittedIdeas = submittedIdeasRaw.map((ideaStr) {
        final parts = ideaStr.split('|||');
        return {
          'idea': parts[0],
          'date': parts.length > 1 ? parts[1] : '',
          'location': parts.length > 2 ? parts[2] : '',
          'timestamp': parts.length > 3 ? parts[3] : '0',
        };
      }).toList();
      // Sort by timestamp (newest first)
      _submittedIdeas.sort(
        (a, b) =>
            int.parse(b['timestamp']!).compareTo(int.parse(a['timestamp']!)),
      );
      print('💡 Loaded ${_submittedIdeas.length} submitted ideas');

      // Load scheduled notifications from SharedPreferences
      final scheduledNotificationsRaw =
          prefs.getStringList('scheduled_notifications') ?? [];
      _scheduledNotifications = scheduledNotificationsRaw.map((notifStr) {
        final parts = notifStr.split('|||');
        return {
          'title': parts.length > 0 ? parts[0] : '',
          'body': parts.length > 1 ? parts[1] : '',
          'date': parts.length > 2 ? parts[2] : '',
          'slot': parts.length > 3 ? parts[3] : '',
          'timestamp': parts.length > 4 ? parts[4] : '0',
        };
      }).toList();
      // Sort by scheduled date & slot (newest first)
      const slotOrder = {'morning': 0, 'noon': 1, 'afternoon': 2, 'night': 3};
      _scheduledNotifications.sort((a, b) {
        final dateCompare = b['date']!.compareTo(a['date']!);
        if (dateCompare != 0) return dateCompare;
        return (slotOrder[b['slot']] ?? 0).compareTo(slotOrder[a['slot']] ?? 0);
      });
      print(
        '🎉 Loaded ${_scheduledNotifications.length} scheduled notifications',
      );

      // Fetch completion data from Firestore for scheduled notifications
      if (_scheduledNotifications.isNotEmpty) {
        await _fetchCompletionData();
      }

      // Calculate streak from SharedPreferences
      int streak = 0;
      final now = DateTime.now();
      for (int i = 0; i < 365; i++) {
        final date = now.subtract(Duration(days: i));
        final dateStr = DateFormat('yyyy-MM-dd').format(date);

        bool completedAny = false;
        for (final slot in ['morning', 'noon', 'afternoon', 'night']) {
          if (prefs.getBool('${dateStr}_${slot}_done') == true) {
            completedAny = true;
            break;
          }
        }

        if (completedAny) {
          streak++;
        } else if (i > 0) {
          // If we miss a day (but not today), break the streak
          break;
        }
      }

      setState(() {
        _achievements = {
          'tasksCompleted': completedCount,
          'ideasSubmitted': _scheduledNotifications.length,
          'streakDays': streak,
        };
        _isLoading = false;
        _hasCachedData = true;
        _lastFetchTime = DateTime.now();
      });
      print('✅ Profile data loaded and cached');
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchCompletionData() async {
    try {
      final db = FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'nowdb',
      );

      // Fetch completion data for each scheduled notification
      for (var notification in _scheduledNotifications) {
        final date = notification['date'];
        final slot = notification['slot'];

        if (date == null || slot == null || date.isEmpty || slot.isEmpty) {
          continue;
        }

        // Build document ID: date_slot (e.g., "2026-02-22_afternoon")
        final docId = '${date}_$slot';

        try {
          final slotDoc = await db.collection('slots').doc(docId).get();

          if (slotDoc.exists) {
            final data = slotDoc.data();
            final counter = data?['counter'] ?? 0;
            final nicknames = data?['nicknames'] as List? ?? [];

            // Extract unique timezones from nicknames (format: "nickname|location|timezone#timestamp")
            final uniqueTimezones = <String>{};
            for (final nicknameEntry in nicknames) {
              if (nicknameEntry is String) {
                // Remove timestamp suffix first (e.g., "name|location|UTC+1#12345" -> "name|location|UTC+1")
                final withoutTimestamp = nicknameEntry.split('#').first;
                final parts = withoutTimestamp.split('|');
                if (parts.length >= 3) {
                  uniqueTimezones.add(parts[2]); // timezone is the 3rd part
                }
              }
            }

            // The counter represents total completions (can be more than unique users)
            // nicknames.length represents unique users who completed
            // uniqueTimezones.length represents unique timezones
            notification['counter'] = nicknames.length
                .toString(); // Unique completions (users)
            notification['timezones'] = uniqueTimezones.length.toString();

            print(
              '📊 Fetched data for $docId: ${nicknames.length} completions, ${uniqueTimezones.length} unique timezones',
            );
          } else {
            notification['counter'] = '0';
            notification['timezones'] = '0';
          }
        } catch (e) {
          print('⚠️ Error fetching slot $docId: $e');
          notification['counter'] = '0';
          notification['timezones'] = '0';
        }
      }
    } catch (e) {
      print('Error fetching completion data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    final double hPad = w > 640 ? (w - 600) / 2.0 : 20.0;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Your Impact',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadUserData(forceRefresh: true),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 60),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User info
                    _buildUserHeader(),
                    const SizedBox(height: 20),

                    // Notification opt-out toggle
                    _buildNotificationToggle(),
                    const SizedBox(height: 32),

                    // Achievements/Milestones
                    _buildAchievements(),

                    // Submitted Ideas
                    // const SizedBox(height: 32),
                    // _buildSection(
                    //   title: 'Your Ideas',
                    //   subtitle: '${_submittedIdeas.length} submitted',
                    //   child: _buildIdeasList(),
                    // ),

                    // Scheduled Ideas (from notifications)
                    if (_scheduledNotifications.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      _buildSection(
                        title: 'Ideas That Made It',
                        subtitle: '${_scheduledNotifications.length} scheduled',
                        child: _buildScheduledNotificationsList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildUserHeader() {
    final double scale = (MediaQuery.of(context).size.width / 390.0).clamp(
      1.0,
      1.4,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [Colors.pink[400]!, Colors.purple[400]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            _nickname,
            style: GoogleFonts.poppins(
              fontSize: 24 * scale,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        Text(
          'Your current nickname',
          style: GoogleFonts.poppins(
            fontSize: 14 * scale,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationToggle() {
    final double scale = (MediaQuery.of(context).size.width / 390.0).clamp(
      1.0,
      1.4,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Idea notifications',
                  style: GoogleFonts.poppins(
                    fontSize: 15 * scale,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Text(
                  _notificationsOptedIn
                      ? 'You\'ll be notified when your idea gets scheduled'
                      : 'Notifications off — won\'t be notified for future ideas',
                  style: GoogleFonts.poppins(
                    fontSize: 12 * scale,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _notificationsOptedIn,
            onChanged: _setNotificationOptIn,
            activeColor: Colors.pink[400],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements() {
    final double scale = (MediaQuery.of(context).size.width / 390.0).clamp(
      1.0,
      1.4,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Achievements',
          style: GoogleFonts.poppins(
            fontSize: 20 * scale,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildAchievementCard(
                icon: Icons.check_circle,
                count: _achievements['tasksCompleted']!,
                label: 'Tasks Done',
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAchievementCard(
                icon: Icons.lightbulb,
                count: _achievements['ideasSubmitted']!,
                label: 'Ideas',
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAchievementCard(
                icon: Icons.local_fire_department,
                count: _achievements['streakDays']!,
                label: 'Day Streak',
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildMilestones(),
      ],
    );
  }

  Widget _buildAchievementCard({
    required IconData icon,
    required int count,
    required String label,
    required Color color,
  }) {
    final double scale = (MediaQuery.of(context).size.width / 390.0).clamp(
      1.0,
      1.4,
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.black, size: 28 * scale),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: GoogleFonts.poppins(
              fontSize: 24 * scale,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12 * scale,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMilestones() {
    final double scale = (MediaQuery.of(context).size.width / 390.0).clamp(
      1.0,
      1.4,
    );
    final tasksCompleted = _achievements['tasksCompleted']!;
    final ideasSubmitted = _achievements['ideasSubmitted']!;

    List<Map<String, dynamic>> milestones = [];

    // Task completion milestones
    if (tasksCompleted >= 1)
      milestones.add({'label': 'First Task', 'unlocked': true});
    if (tasksCompleted >= 7)
      milestones.add({'label': 'Week Warrior', 'unlocked': true});
    if (tasksCompleted >= 30)
      milestones.add({'label': 'Month Master', 'unlocked': true});
    if (tasksCompleted >= 100)
      milestones.add({'label': 'Century Club', 'unlocked': true});

    // Idea submission milestones
    if (ideasSubmitted >= 1)
      milestones.add({'label': 'Idea Starter', 'unlocked': true});
    if (ideasSubmitted >= 5)
      milestones.add({'label': 'Idea Generator', 'unlocked': true});
    if (ideasSubmitted >= 10)
      milestones.add({'label': 'Idea Champion', 'unlocked': true});

    // Streak milestones
    final streak = _achievements['streakDays']!;
    if (streak >= 3) milestones.add({'label': 'On Fire', 'unlocked': true});
    if (streak >= 7) milestones.add({'label': 'Unstoppable', 'unlocked': true});
    if (streak >= 30) milestones.add({'label': 'Legend', 'unlocked': true});

    if (milestones.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Milestones',
          style: GoogleFonts.poppins(
            fontSize: 20 * scale,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: milestones.map((milestone) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.pink[400]!, Colors.purple[400]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18.5),
                  ),
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [Colors.pink[400]!, Colors.purple[400]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      milestone['label'],
                      style: GoogleFonts.poppins(
                        fontSize: 13 * scale,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final double scale = (MediaQuery.of(context).size.width / 390.0).clamp(
      1.0,
      1.4,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 20 * scale,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 14 * scale,
                color: Colors.black45,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  Widget _buildIdeasList() {
    if (_submittedIdeas.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'No submitted ideas scheduled yet.',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: _submittedIdeas.map((idea) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                idea['idea'] ?? '',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 12, color: Colors.black45),
                  const SizedBox(width: 4),
                  Text(
                    idea['date'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  bool _isNotificationLive(Map<String, String> notification) {
    try {
      final date = notification['date'];
      final slot = notification['slot'];

      if (date == null || slot == null) return false;

      // Parse the notification date
      final notificationDate = DateFormat('yyyy-MM-dd').parse(date);
      final now = DateTime.now().toUtc();

      // Calculate UTC start/end times accounting for all timezones (UTC-12 to UTC+14 = 26 hour span)
      // The slot is live from when the earliest timezone (UTC+14) enters it
      // until the latest timezone (UTC-12) exits it

      DateTime startUtc;
      DateTime endUtc;

      switch (slot.toLowerCase()) {
        case 'morning': // 5:00-12:00 local
          // Earliest start: date 5:00 UTC+14 = (date-1) 15:00 UTC
          startUtc = DateTime.utc(
            notificationDate.year,
            notificationDate.month,
            notificationDate.day - 1,
            15,
            0,
          );
          // Latest end: date 12:00 UTC-12 = date 24:00 UTC = (date+1) 00:00 UTC
          endUtc = DateTime.utc(
            notificationDate.year,
            notificationDate.month,
            notificationDate.day + 1,
            0,
            0,
          );
          break;

        case 'noon': // 12:00-17:00 local
          // Earliest start: date 12:00 UTC+14 = (date-1) 22:00 UTC
          startUtc = DateTime.utc(
            notificationDate.year,
            notificationDate.month,
            notificationDate.day - 1,
            22,
            0,
          );
          // Latest end: date 17:00 UTC-12 = (date+1) 05:00 UTC
          endUtc = DateTime.utc(
            notificationDate.year,
            notificationDate.month,
            notificationDate.day + 1,
            5,
            0,
          );
          break;

        case 'afternoon': // 17:00-22:00 local
          // Earliest start: date 17:00 UTC+14 = date 03:00 UTC
          startUtc = DateTime.utc(
            notificationDate.year,
            notificationDate.month,
            notificationDate.day,
            3,
            0,
          );
          // Latest end: date 22:00 UTC-12 = (date+1) 10:00 UTC
          endUtc = DateTime.utc(
            notificationDate.year,
            notificationDate.month,
            notificationDate.day + 1,
            10,
            0,
          );
          break;

        case 'night': // 22:00-5:00 local
          // Earliest start: date 22:00 UTC+14 = date 08:00 UTC
          startUtc = DateTime.utc(
            notificationDate.year,
            notificationDate.month,
            notificationDate.day,
            8,
            0,
          );
          // Latest end: (date+1) 05:00 UTC-12 = (date+1) 17:00 UTC
          endUtc = DateTime.utc(
            notificationDate.year,
            notificationDate.month,
            notificationDate.day + 1,
            17,
            0,
          );
          break;

        default:
          return false;
      }

      // Check if current UTC time is within the live window
      return now.isAfter(startUtc) && now.isBefore(endUtc);
    } catch (e) {
      return false;
    }
  }

  bool _isNotificationPast(Map<String, String> notification) {
    try {
      final date = notification['date'];
      final slot = notification['slot'];

      if (date == null || slot == null) return false;

      // Parse the notification date
      final notificationDate = DateFormat('yyyy-MM-dd').parse(date);
      final now = DateTime.now().toUtc();

      // Calculate the end time for the slot (same calculation as in _isNotificationLive)
      // The slot is past only when the latest timezone (UTC-12) has finished

      DateTime endUtc;

      switch (slot.toLowerCase()) {
        case 'morning':
          // Latest end: date 12:00 UTC-12 = (date+1) 00:00 UTC
          endUtc = DateTime.utc(
            notificationDate.year,
            notificationDate.month,
            notificationDate.day + 1,
            0,
            0,
          );
          break;

        case 'noon':
          // Latest end: date 17:00 UTC-12 = (date+1) 05:00 UTC
          endUtc = DateTime.utc(
            notificationDate.year,
            notificationDate.month,
            notificationDate.day + 1,
            5,
            0,
          );
          break;

        case 'afternoon':
          // Latest end: date 22:00 UTC-12 = (date+1) 10:00 UTC
          endUtc = DateTime.utc(
            notificationDate.year,
            notificationDate.month,
            notificationDate.day + 1,
            10,
            0,
          );
          break;

        case 'night':
          // Latest end: (date+1) 05:00 UTC-12 = (date+1) 17:00 UTC
          endUtc = DateTime.utc(
            notificationDate.year,
            notificationDate.month,
            notificationDate.day + 1,
            17,
            0,
          );
          break;

        default:
          return false;
      }

      // The slot is past only when the current UTC time is after the end time
      return now.isAfter(endUtc);
    } catch (e) {
      return false;
    }
  }

  String _slotEndUtcMinus12(String slot) {
    switch (slot.toLowerCase()) {
      case 'morning':
        return '12:00';
      case 'noon':
        return '17:00';
      case 'afternoon':
        return '22:00';
      case 'night':
        return '05:00 (next day)';
      default:
        return '';
    }
  }

  // Returns the slot's absolute end time in the user's local timezone.
  // UTC end times: morning → date+1 00:00, noon → date+1 05:00,
  //                afternoon → date+1 10:00, night → date+1 17:00
  String _slotEndLocalTime(Map<String, String> notification) {
    try {
      final date = notification['date'];
      final slot = notification['slot']?.toLowerCase();
      if (date == null || slot == null) return '';
      final d = DateFormat('yyyy-MM-dd').parse(date);
      DateTime endUtc;
      switch (slot) {
        case 'morning':
          endUtc = DateTime.utc(d.year, d.month, d.day + 1, 0, 0);
          break;
        case 'noon':
          endUtc = DateTime.utc(d.year, d.month, d.day + 1, 5, 0);
          break;
        case 'afternoon':
          endUtc = DateTime.utc(d.year, d.month, d.day + 1, 10, 0);
          break;
        case 'night':
          endUtc = DateTime.utc(d.year, d.month, d.day + 1, 17, 0);
          break;
        default:
          return '';
      }
      final local = endUtc.toLocal();
      final h = local.hour.toString().padLeft(2, '0');
      final m = local.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return '';
    }
  }

  Widget _buildScheduledNotificationsList() {
    final double scale = (MediaQuery.of(context).size.width / 390.0).clamp(
      1.0,
      1.4,
    );
    return Column(
      children: _scheduledNotifications.map((notification) {
        final isLiveNow = _isNotificationLive(notification);
        final isPast = _isNotificationPast(notification);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: isLiveNow
              ? BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.pink[400]!, Colors.purple[400]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
          padding: isLiveNow ? const EdgeInsets.all(2) : null,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isLiveNow ? Colors.white : Colors.grey[100],
              borderRadius: BorderRadius.circular(isLiveNow ? 10 : 12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isLiveNow || isPast) ...[
                  Row(
                    children: [
                      if (isLiveNow) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.pink[400]!, Colors.purple[400]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, color: Colors.white, size: 8),
                              const SizedBox(width: 4),
                              Text(
                                'LIVE NOW',
                                style: GoogleFonts.poppins(
                                  fontSize: 10 * scale,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ends ${_slotEndUtcMinus12(notification['slot'] ?? '')} in UTC−12 (your time: ${_slotEndLocalTime(notification)})',
                          style: GoogleFonts.poppins(
                            fontSize: 11 * scale,
                            color: Colors.black45,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      if (isPast) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'COMPLETED',
                            style: GoogleFonts.poppins(
                              fontSize: 10 * scale,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                if (notification['body']?.isNotEmpty == true) ...[
                  Text(
                    notification['body'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 15 * scale,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14 * scale,
                      color: Colors.black,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      notification['date'] ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 13 * scale,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (notification['slot']?.isNotEmpty == true) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          notification['slot'] ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 11 * scale,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (notification['counter'] != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.people, size: 14 * scale, color: Colors.black),
                      const SizedBox(width: 4),
                      Text(
                        '${notification['counter']} completions',
                        style: GoogleFonts.poppins(
                          fontSize: 13 * scale,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.public, size: 14 * scale, color: Colors.black),
                      const SizedBox(width: 4),
                      Text(
                        '${notification['timezones']} timezones',
                        style: GoogleFonts.poppins(
                          fontSize: 13 * scale,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
