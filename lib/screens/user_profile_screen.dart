import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isLoading = true;
  String _nickname = '';
  List<Map<String, dynamic>> _submittedIdeas = [];
  List<Map<String, dynamic>> _scheduledTasks = [];
  Map<String, int> _achievements = {
    'tasksCompleted': 0,
    'ideasSubmitted': 0,
    'streakDays': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      _nickname = prefs.getString('nickname') ?? 'tom';

      final db = FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'nowdb',
      );

      // Load submitted ideas
      final ideasSnapshot = await db
          .collection('ideas')
          .where('nickname', isEqualTo: _nickname)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      _submittedIdeas = ideasSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'idea': data['idea'] ?? '',
          'date': data['date'] ?? '',
          'timestamp': data['timestamp'],
          'location': data['location'] ?? '',
        };
      }).toList();

      // Find tasks that were created from user's ideas
      final tasksSnapshot = await db.collection('tasks').get();

      _scheduledTasks = [];
      for (var taskDoc in tasksSnapshot.docs) {
        final taskData = taskDoc.data();
        final ideaId = taskData['ideaId'];

        if (ideaId != null) {
          // Check if this idea belongs to the user
          for (var idea in _submittedIdeas) {
            if (idea['id'] == ideaId) {
              // Find when this task was scheduled
              final slotsSnapshot = await db
                  .collection('slots')
                  .where('taskId', isEqualTo: taskDoc.id)
                  .limit(1)
                  .get();

              if (slotsSnapshot.docs.isNotEmpty) {
                final slotData = slotsSnapshot.docs.first.data();
                _scheduledTasks.add({
                  'taskId': taskDoc.id,
                  'headline': taskData['headline'] ?? '',
                  'date': slotData['date'] ?? '',
                  'slot': slotData['slot'] ?? '',
                  'counter': slotData['counter'] ?? 0,
                  'nicknames': slotData['nicknames'] ?? [],
                });
              }
              break;
            }
          }
        }
      }

      // Calculate completed tasks count
      int completedCount = 0;
      for (final key in prefs.getKeys()) {
        if (key.endsWith('_done') && prefs.getBool(key) == true) {
          completedCount++;
        }
      }

      // Calculate streak
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
          'ideasSubmitted': _submittedIdeas.length,
          'streakDays': streak,
        };
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Your Profile',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User info
                    _buildUserHeader(),
                    const SizedBox(height: 24),

                    // Achievements/Milestones
                    _buildAchievements(),
                    const SizedBox(height: 32),

                    // Submitted Ideas
                    _buildSection(
                      title: 'Your Ideas',
                      subtitle: '${_submittedIdeas.length} submitted',
                      child: _buildIdeasList(),
                    ),
                    const SizedBox(height: 32),

                    // Scheduled Tasks
                    _buildSection(
                      title: 'Ideas That Made It',
                      subtitle: '${_scheduledTasks.length} scheduled',
                      child: _buildScheduledTasksList(),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildUserHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.pink[400]!, Colors.purple[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _nickname.isNotEmpty ? _nickname[0].toUpperCase() : 'T',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.purple[400],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nickname,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Community Member',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Achievements',
          style: GoogleFonts.poppins(
            fontSize: 20,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMilestones() {
    final tasksCompleted = _achievements['tasksCompleted']!;
    final ideasSubmitted = _achievements['ideasSubmitted']!;

    List<Map<String, dynamic>> milestones = [];

    // Task completion milestones
    if (tasksCompleted >= 1)
      milestones.add({'label': '🌟 First Task', 'unlocked': true});
    if (tasksCompleted >= 7)
      milestones.add({'label': '🎯 Week Warrior', 'unlocked': true});
    if (tasksCompleted >= 30)
      milestones.add({'label': '🏆 Month Master', 'unlocked': true});
    if (tasksCompleted >= 100)
      milestones.add({'label': '💎 Century Club', 'unlocked': true});

    // Idea submission milestones
    if (ideasSubmitted >= 1)
      milestones.add({'label': '💡 Idea Starter', 'unlocked': true});
    if (ideasSubmitted >= 5)
      milestones.add({'label': '🚀 Idea Generator', 'unlocked': true});
    if (ideasSubmitted >= 10)
      milestones.add({'label': '⭐ Idea Champion', 'unlocked': true});

    // Scheduled task milestones
    if (_scheduledTasks.isNotEmpty) {
      milestones.add({'label': '🎉 Published Idea', 'unlocked': true});
    }
    if (_scheduledTasks.length >= 3) {
      milestones.add({'label': '🌈 Community Hero', 'unlocked': true});
    }

    // Streak milestones
    final streak = _achievements['streakDays']!;
    if (streak >= 3) milestones.add({'label': '🔥 On Fire', 'unlocked': true});
    if (streak >= 7)
      milestones.add({'label': '⚡ Unstoppable', 'unlocked': true});
    if (streak >= 30) milestones.add({'label': '👑 Legend', 'unlocked': true});

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
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: milestones.map((milestone) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.purple[200]!),
              ),
              child: Text(
                milestone['label'],
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.purple[700],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black45),
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
            'No ideas submitted yet.\nTap the ⚡ button to share your first idea!',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: _submittedIdeas.map((idea) {
        // Check if this idea was scheduled
        final isScheduled = _scheduledTasks.any(
          (task) => _submittedIdeas.any((i) => i['id'] == idea['id']),
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isScheduled ? Colors.green[50] : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isScheduled ? Colors.green[200]! : Colors.grey[200]!,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      idea['idea'],
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  if (isScheduled) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[600],
                      size: 20,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 12, color: Colors.black45),
                  const SizedBox(width: 4),
                  Text(
                    idea['date'],
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.black45,
                    ),
                  ),
                  if (idea['location'].isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.location_on, size: 12, color: Colors.black45),
                    const SizedBox(width: 4),
                    Text(
                      idea['location'],
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildScheduledTasksList() {
    if (_scheduledTasks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'None of your ideas have been scheduled yet.\nKeep submitting - your idea might be next!',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: _scheduledTasks.map((task) {
        final nicknames = task['nicknames'] as List;
        final timezones = nicknames.length;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple[50]!, Colors.pink[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task['headline'],
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.purple[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    task['date'],
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      task['slot'],
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.purple[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.people, size: 14, color: Colors.pink[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${task['counter']} completions',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.public, size: 14, color: Colors.pink[600]),
                  const SizedBox(width: 4),
                  Text(
                    '$timezones timezones',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.black87,
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
}
