import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'nowdb',
  );

  // ----------------------------
  // SLOT LOGIK
  // ----------------------------

  String getCurrentSlot() {
    final hour = DateTime.now().hour;

    if (hour >= 6 && hour < 12) {
      return 'morning';
    } else if (hour >= 12 && hour < 17) {
      return 'noon';
    } else if (hour >= 17 && hour < 22) {
      return 'afternoon';
    } else {
      return 'night';
    }
  }

  String getCurrentDate() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  // ----------------------------
  // LOAD CURRENT TASK (MERGED VIEW)
  // ----------------------------
  Future<Map<String, dynamic>> loadCurrentTask() async {
    final date = getCurrentDate();
    final slot = getCurrentSlot();

    try {
      // 1) Slot-Dokument holen
      final slotRef = _firestore
          .collection('slots')
          .doc(date)
          .collection(slot)
          .doc('data');

      final slotSnap = await slotRef.get();

      if (!slotSnap.exists) {
        return {
          'taskId': '',
          'headline': 'No task',
          'text': '',
          'submittedBy': '',
          'completions': 0,
          'slot': slot,
          'date': date,
        };
      }

      final slotData = slotSnap.data()!;
      final taskId = slotData['taskId'];

      // 2) Task-Dokument holen
      final taskSnap = await _firestore.collection('tasks').doc(taskId).get();

      if (!taskSnap.exists) {
        return {
          'taskId': taskId,
          'headline': 'Unknown Task',
          'text': '',
          'submittedBy': '',
          'completions': slotData['completions'] ?? 0,
          'slot': slot,
          'date': date,
        };
      }

      final taskData = taskSnap.data()!;

      return {
        'taskId': taskId,
        'headline': taskData['headline'],
        'text': taskData['text'],
        'submittedBy': taskData['submittedBy'],
        'completions': slotData['completions'],
        'slot': slot,
        'date': date,
      };
    } catch (e) {
      debugPrint('Error loading task: $e');
      return {
        'taskId': '',
        'headline': 'Connection issue',
        'text': 'Pull down to retry',
        'subline': '',
        'submittedBy': '',
        'sponsoredBy': '',
        'location': '',
        'nicknames': [],
        'completions': 0,
        'slot': slot,
        'date': date,
      };
    }
  }

  // ----------------------------
  // SAVE COMPLETION
  // ----------------------------
  Future<void> saveCompletion({
    required String date,
    required String slot,
    required String taskId,
    required String nickname,
  }) async {
    try {
      final slotRef = _firestore
          .collection('slots')
          .doc(date)
          .collection(slot)
          .doc('data');

      final taskRef = _firestore.collection('tasks').doc(taskId);

      // Slot aktualisieren
      await slotRef.update({
        'completions': FieldValue.increment(1),
        'nicknames': FieldValue.arrayUnion([nickname]),
      });

      // Task Statistiken aktualisieren
      await taskRef.set({
        'totalCompletions': FieldValue.increment(1),
        'usedInSlots': FieldValue.arrayUnion(["${date}_$slot"]),
      }, SetOptions(merge: true));

      // Local speichern, dass User diesen Slot erledigt hat
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('${date}_${slot}_done', true);
    } catch (e) {
      debugPrint('Error saving completion: $e');
      rethrow;
    }
  }

  // ----------------------------
  // CHECK IF CURRENT SLOT DONE
  // ----------------------------
  Future<bool> isCurrentSlotDone() async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${getCurrentDate()}_${getCurrentSlot()}_done';
    return prefs.getBool(key) ?? false;
  }

  // ----------------------------
  // GET USER NICKNAME
  // ----------------------------
  Future<String> getNickname() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('nickname') ?? 'tom';
  }

  // ----------------------------
  // GET STATISTICS (from launch day)
  // ----------------------------
  Future<List<Map<String, dynamic>>> getStatistics() async {
    final List<Map<String, dynamic>> statistics = [];

    try {
      // Start from launch day
      final launchDate = DateTime(2026, 2, 20);
      final today = DateTime.now();

      debugPrint('📊 Loading statistics from $launchDate to $today');

      // Generate all possible slot document IDs from launch to today
      var currentDate = DateTime(
        launchDate.year,
        launchDate.month,
        launchDate.day,
      );
      final endDate = DateTime(
        today.year,
        today.month,
        today.day,
      ).add(const Duration(days: 1));

      while (currentDate.isBefore(endDate)) {
        final dateString =
            '${currentDate.year}-${_padTwo(currentDate.month)}-${_padTwo(currentDate.day)}';

        for (final slotName in ['morning', 'noon', 'afternoon', 'night']) {
          final docId = '${dateString}_$slotName';

          try {
            final slotSnap = await _firestore
                .collection('slots')
                .doc(docId)
                .get();

            if (slotSnap.exists) {
              final slotData = slotSnap.data()!;
              final taskId = slotData['taskId'] as String?;
              final completions = slotData['completions'] as int? ?? 0;

              debugPrint(
                '📊 Found $docId: taskId=$taskId, completions=$completions, exists=true',
              );

              if (taskId != null && taskId.isNotEmpty && completions > 0) {
                // Get task details
                String headline = 'Unknown Task';
                String submittedBy = '';

                try {
                  final taskSnap = await _firestore
                      .collection('tasks')
                      .doc(taskId)
                      .get();
                  if (taskSnap.exists) {
                    final taskData = taskSnap.data()!;
                    headline = taskData['headline'] ?? 'Unknown Task';
                    submittedBy = taskData['submittedBy'] ?? '';
                  }
                } catch (e) {
                  debugPrint('⚠️ Error loading task $taskId: $e');
                }

                // Count unique timezones
                final nicknames = List<String>.from(
                  slotData['nicknames'] ?? [],
                );
                final timezones = <String>{};
                for (final nickname in nicknames) {
                  // Remove timestamp suffix first (e.g., "name|location|UTC+1#12345" -> "name|location|UTC+1")
                  final withoutTimestamp = nickname.split('#').first;
                  final parts = withoutTimestamp.split('|');
                  if (parts.length >= 3) {
                    timezones.add(parts[2]); // UTC timezone
                  }
                }

                statistics.add({
                  'date': dateString,
                  'slot': slotName,
                  'headline': headline,
                  'submittedBy': submittedBy,
                  'completions': completions,
                  'timezones': timezones.length,
                });

                debugPrint(
                  '✅ Added: $headline ($completions completions, ${timezones.length} timezones)',
                );
              }
            }
          } catch (e) {
            // Silently skip unavailable slots - they may not exist yet
            if (e.toString().contains('unavailable')) {
              continue;
            }
            debugPrint('📊 Error loading slot $docId: $e');
          }

          // Small delay to avoid overwhelming Firestore
          await Future.delayed(const Duration(milliseconds: 50));
        }

        currentDate = currentDate.add(const Duration(days: 1));
      }

      // Sort by date descending (newest first)
      statistics.sort((a, b) {
        final dateCompare = (b['date'] as String).compareTo(
          a['date'] as String,
        );
        if (dateCompare != 0) return dateCompare;

        // If same date, sort by slot order
        final slotOrder = {'morning': 0, 'noon': 1, 'afternoon': 2, 'night': 3};
        return (slotOrder[b['slot']] ?? 0).compareTo(slotOrder[a['slot']] ?? 0);
      });

      debugPrint('📊 Total statistics loaded: ${statistics.length}');
      return statistics;
    } catch (e) {
      debugPrint('❌ Error getting statistics: $e');
      return [];
    }
  }

  String _padTwo(int n) => n.toString().padLeft(2, '0');
}
