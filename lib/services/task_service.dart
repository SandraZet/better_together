import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get tasksCollection => _firestore.collection('tasks');
  CollectionReference get completionsCollection =>
      _firestore.collection('task_completions');
  CollectionReference get usersCollection => _firestore.collection('users');

  // Get current active task for a specific time slot
  Future<Task?> getCurrentTask(TimeSlot timeSlot) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    try {
      final querySnapshot = await tasksCollection
          .where('timeSlot', isEqualTo: timeSlot.name)
          .where('activeDate', isEqualTo: Timestamp.fromDate(today))
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return Task.fromMap(
          querySnapshot.docs.first.data() as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      print('Error getting current task: $e');
      return null;
    }
  }

  // Create a new task
  Future<String?> createTask(Task task) async {
    try {
      final docRef = await tasksCollection.add(task.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creating task: $e');
      return null;
    }
  }

  // Get all tasks for a specific date and time slot
  Future<List<Task>> getTasksForDateAndSlot(
    DateTime date,
    TimeSlot timeSlot,
  ) async {
    final dayStart = DateTime(date.year, date.month, date.day);

    try {
      final querySnapshot = await tasksCollection
          .where('timeSlot', isEqualTo: timeSlot.name)
          .where('activeDate', isEqualTo: Timestamp.fromDate(dayStart))
          .get();

      return querySnapshot.docs
          .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting tasks: $e');
      return [];
    }
  }

  // Set task as active for today
  Future<bool> setTaskActive(String taskId) async {
    try {
      await tasksCollection.doc(taskId).update({'isActive': true});
      return true;
    } catch (e) {
      print('Error setting task active: $e');
      return false;
    }
  }

  // Get user's completion status for current task
  Future<bool> hasUserCompletedTask(
    String taskId,
    String userNickname,
    DateTime date,
    TimeSlot timeSlot,
  ) async {
    final dayStart = DateTime(date.year, date.month, date.day);

    try {
      final querySnapshot = await completionsCollection
          .where('taskId', isEqualTo: taskId)
          .where('userNickname', isEqualTo: userNickname)
          .where('taskDate', isEqualTo: Timestamp.fromDate(dayStart))
          .where('timeSlot', isEqualTo: timeSlot.name)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking completion status: $e');
      return false;
    }
  }

  // Mark task as completed by user
  Future<bool> completeTask(
    String taskId,
    String userNickname,
    TimeSlot timeSlot,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    try {
      final completion = TaskCompletion(
        id: '', // Will be set by Firestore
        taskId: taskId,
        userNickname: userNickname,
        completedAt: now,
        taskDate: today,
        timeSlot: timeSlot,
      );

      await completionsCollection.add(completion.toMap());
      return true;
    } catch (e) {
      print('Error completing task: $e');
      return false;
    }
  }

  // Get completion count for a task on a specific date
  Future<int> getCompletionCount(
    String taskId,
    DateTime date,
    TimeSlot timeSlot,
  ) async {
    final dayStart = DateTime(date.year, date.month, date.day);

    try {
      final querySnapshot = await completionsCollection
          .where('taskId', isEqualTo: taskId)
          .where('taskDate', isEqualTo: Timestamp.fromDate(dayStart))
          .where('timeSlot', isEqualTo: timeSlot.name)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      print('Error getting completion count: $e');
      return 0;
    }
  }

  // Get list of users who completed a task (max 30 for UI)
  Future<List<String>> getCompletionNicknames(
    String taskId,
    DateTime date,
    TimeSlot timeSlot,
  ) async {
    final dayStart = DateTime(date.year, date.month, date.day);

    try {
      final querySnapshot = await completionsCollection
          .where('taskId', isEqualTo: taskId)
          .where('taskDate', isEqualTo: Timestamp.fromDate(dayStart))
          .where('timeSlot', isEqualTo: timeSlot.name)
          .orderBy('completedAt', descending: false)
          .limit(30)
          .get();

      return querySnapshot.docs
          .map(
            (doc) =>
                (doc.data() as Map<String, dynamic>)['userNickname'] as String,
          )
          .toList();
    } catch (e) {
      print('Error getting completion nicknames: $e');
      return [];
    }
  }

  // Stream for real-time completion count updates
  Stream<int> getCompletionCountStream(
    String taskId,
    DateTime date,
    TimeSlot timeSlot,
  ) {
    final dayStart = DateTime(date.year, date.month, date.day);

    return completionsCollection
        .where('taskId', isEqualTo: taskId)
        .where('taskDate', isEqualTo: Timestamp.fromDate(dayStart))
        .where('timeSlot', isEqualTo: timeSlot.name)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Create or update user
  Future<bool> createOrUpdateUser(AppUser user) async {
    try {
      await usersCollection.doc(user.nickname).set(user.toMap());
      return true;
    } catch (e) {
      print('Error creating/updating user: $e');
      return false;
    }
  }

  // Get user by nickname
  Future<AppUser?> getUser(String nickname) async {
    try {
      final doc = await usersCollection.doc(nickname).get();
      if (doc.exists) {
        return AppUser.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }
}
