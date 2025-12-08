import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
        'headline': 'Error',
        'text': '',
        'submittedBy': '',
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
}
