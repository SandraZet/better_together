import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class SlotLoader {
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'nowdb',
  );

  // -------------------------
  // Slot / Date helpers
  // -------------------------
  String _two(int n) => n.toString().padLeft(2, '0');

  String getCurrentDateString([DateTime? dt]) {
    final d = dt ?? DateTime.now();

    // Night slot (22:00-06:00) can span two calendar days
    // If it's after midnight but before 6am, use YESTERDAY's date
    if (d.hour >= 0 && d.hour < 6) {
      final yesterday = d.subtract(const Duration(days: 1));
      return "${yesterday.year}-${_two(yesterday.month)}-${_two(yesterday.day)}";
    }

    return "${d.year}-${_two(d.month)}-${_two(d.day)}";
  }

  String getCurrentSlotName([DateTime? now]) {
    final n = now ?? DateTime.now();
    final hour = n.hour;
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'noon';
    if (hour >= 17 && hour < 22) return 'afternoon';
    return 'night';
  }

  String docIdFor(String dateString, String slot) => "${dateString}_$slot";

  // -------------------------
  // Stream for live updates
  // -------------------------
  /// Returns a Stream that emits the completions count whenever it changes
  Stream<int> getCompletionsStream({DateTime? now}) {
    return getSlotLiveStream(
      now: now,
    ).map((data) => data['completions'] as int? ?? 0);
  }

  /// Returns a Stream with both completions and nicknames for live updates
  Stream<Map<String, dynamic>> getSlotLiveStream({DateTime? now}) {
    final date = getCurrentDateString(now);
    final slot = getCurrentSlotName(now);
    final docId = docIdFor(date, slot);

    return _db.collection('slots').doc(docId).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) {
        return {'completions': 0, 'nicknames': <String>[]};
      }

      final rawNicknames = data['nicknames'];
      final nicknames = rawNicknames is Iterable
          ? rawNicknames.map((e) => e.toString()).toList()
          : <String>[];

      return {'completions': data['completions'] ?? 0, 'nicknames': nicknames};
    });
  }

  // -------------------------
  // Load merged slot + task
  // -------------------------
  /// Returns a Map with keys:
  /// 'taskId','headline','text','submittedBy','sponsoredBy','completions','slot','date'
  Future<Map<String, dynamic>> loadCurrentSlotTask({DateTime? now}) async {
    final date = getCurrentDateString(now);
    final slot = getCurrentSlotName(now);
    final docId = docIdFor(date, slot);

    print('🔍 Loading slot: $docId (date: $date, slot: $slot)');

    try {
      final snap = await _db.collection('slots').doc(docId).get();

      if (!snap.exists) {
        print('❌ Document $docId does NOT exist in Firestore');
        return {
          'taskId': '',
          'headline': 'No task',
          'text': '',
          'submittedBy': '',
          'location': '',
          'sponsoredBy': '',
          'completions': 0,
          'slot': slot,
          'date': date,
          'nicknames': <String>[],
        };
      }

      final slotData = snap.data()!;
      final taskId = slotData['taskId'] as String? ?? '';

      print('✅ Found slot data: taskId=$taskId');

      // load task doc if exists
      Map<String, dynamic> taskData = {};
      if (taskId.isNotEmpty) {
        final tSnap = await _db.collection('tasks').doc(taskId).get();
        if (tSnap.exists) {
          taskData = tSnap.data()!;
        }
      }

      final rawNicknames = slotData['nicknames'];
      final nicknames = rawNicknames is Iterable
          ? rawNicknames.map((e) => e.toString()).toList()
          : <String>[];

      return {
        'taskId': taskId,
        'headline': taskData['headline'] ?? slotData['headline'] ?? '',
        'subline': taskData['subline'] ?? '',
        'text': taskData['text'] ?? slotData['text'] ?? '',
        'location': taskData['location'] ?? '',
        'submittedBy': taskData['submittedBy'] ?? '',
        'sponsoredBy': slotData['sponsoredBy'] ?? '',
        'completions': slotData['completions'] ?? 0,
        'slot': slot,
        'date': date,
        'nicknames': nicknames,
      };
    } catch (e) {
      // fallback safe object
      return {
        'taskId': '',
        'headline': 'Error',
        'text': '',
        'submittedBy': '',
        'location': '',
        'sponsoredBy': '',
        'completions': 0,
        'slot': getCurrentSlotName(now),
        'date': getCurrentDateString(now),
        'nicknames': <String>[],
      };
    }
  }

  // -------------------------
  // Save completion (atomic increment + arrayUnion)
  // -------------------------
  /// Increments completions and appends nickname. Also marks local done flag.
  Future<void> addCompletion({required String nickname, DateTime? when}) async {
    final date = getCurrentDateString(when);
    final slot = getCurrentSlotName(when);
    final docId = docIdFor(date, slot);

    final slotRef = _db.collection('slots').doc(docId);

    // Make nickname unique with timestamp to avoid duplicates
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uniqueNickname = '$nickname#$timestamp';

    final batch = _db.batch();

    // Atomic increment + nickname with unique suffix
    batch.update(slotRef, {
      'completions': FieldValue.increment(1),
      'nicknames': FieldValue.arrayUnion([uniqueNickname]),
    });

    // commit
    await batch.commit();

    // locally mark done with explicit commit
    final prefs = await SharedPreferences.getInstance();
    final key = '${date}_${slot}_done';
    final success = await prefs.setBool(key, true);
    print('✅ Saved $key = $success (should be true)');
  }

  // -------------------------
  // Local helpers
  // -------------------------
  Future<bool> isCurrentSlotDone() async {
    final date = getCurrentDateString();
    final slot = getCurrentSlotName();
    final prefs = await SharedPreferences.getInstance();
    final key = '${date}_${slot}_done';
    final isDone = prefs.getBool(key) ?? false;
    print('🔍 Checking $key = $isDone');
    print('🔍 All keys: ${prefs.getKeys()}');
    return isDone;
  }

  Future<void> clearCurrentSlotDoneFlag({DateTime? when}) async {
    final date = getCurrentDateString(when);
    final slot = getCurrentSlotName(when);
    final prefs = await SharedPreferences.getInstance();
    final key = '${date}_${slot}_done';
    await prefs.remove(key);
    print('🗑️ Cleared $key');
  }
}
