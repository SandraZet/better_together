import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';

class SampleDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createSampleTasks() async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // Sample tasks for each time slot
    final sampleTasks = [
      // Night tasks (0-3 Uhr) - Test Slot
      Task(
        id: '',
        title: 'Trinke ein Glas warme Milch 🥛',
        description: 'Entspanne dich für einen guten Schlaf',
        authorNickname: 'NightOwl',
        theme: TaskTheme.wellness,
        timeSlot: TimeSlot.night,
        createdAt: DateTime.now(),
        activeDate: todayDate,
        isActive: true,
      ),
      Task(
        id: '',
        title: 'Schreibe in dein Nacht-Tagebuch ✍️',
        description: 'Reflektiere über den Tag',
        authorNickname: 'MidnightThinker',
        theme: TaskTheme.mindfulness,
        timeSlot: TimeSlot.night,
        createdAt: DateTime.now(),
        activeDate: todayDate,
        isActive: false,
      ),

      // Morning tasks
      Task(
        id: '',
        title: 'Trinke ein großes Glas Wasser',
        description: 'Starte den Tag mit einem erfrischenden Glas Wasser',
        authorNickname: 'WellnessGuru',
        theme: TaskTheme.wellness,
        timeSlot: TimeSlot.morning,
        createdAt: DateTime.now(),
        activeDate: todayDate,
        isActive: true,
      ),
      Task(
        id: '',
        title: 'Mache 10 Hampelmänner',
        description: 'Bringe deinen Kreislauf in Schwung',
        authorNickname: 'FitnessCoach',
        theme: TaskTheme.fitness,
        timeSlot: TimeSlot.morning,
        createdAt: DateTime.now(),
        activeDate: todayDate,
        isActive: false,
      ),
      Task(
        id: '',
        title: 'Schreibe 3 Dinge auf, für die du dankbar bist',
        description: 'Beginne den Tag mit Dankbarkeit',
        authorNickname: 'ZenMaster',
        theme: TaskTheme.mindfulness,
        timeSlot: TimeSlot.morning,
        createdAt: DateTime.now(),
        activeDate: todayDate,
        isActive: false,
      ),

      // Afternoon tasks
      Task(
        id: '',
        title: 'Lerne ein neues Wort in einer Fremdsprache',
        description: 'Erweitere deinen Wortschatz',
        authorNickname: 'LanguageLover',
        theme: TaskTheme.learning,
        timeSlot: TimeSlot.afternoon,
        createdAt: DateTime.now(),
        activeDate: todayDate,
        isActive: true,
      ),
      Task(
        id: '',
        title: 'Bereite einen gesunden Snack zu',
        description: 'Etwas Leckeres und Nahrhaftes',
        authorNickname: 'HealthyChef',
        theme: TaskTheme.cooking,
        timeSlot: TimeSlot.afternoon,
        createdAt: DateTime.now(),
        activeDate: todayDate,
        isActive: false,
      ),

      // Evening tasks
      Task(
        id: '',
        title: 'Rufe einen Freund oder Familienmitglied an',
        description: 'Pflege deine sozialen Kontakte',
        authorNickname: 'SocialButterfly',
        theme: TaskTheme.social,
        timeSlot: TimeSlot.evening,
        createdAt: DateTime.now(),
        activeDate: todayDate,
        isActive: true,
      ),
      Task(
        id: '',
        title: 'Zeichne oder male etwas Schönes',
        description: 'Lass deiner Kreativität freien Lauf',
        authorNickname: 'ArtistSoul',
        theme: TaskTheme.creativity,
        timeSlot: TimeSlot.evening,
        createdAt: DateTime.now(),
        activeDate: todayDate,
        isActive: false,
      ),
    ];

    // Add sample tasks to Firestore
    for (final task in sampleTasks) {
      try {
        await _firestore.collection('tasks').add(task.toMap());
        print('Added sample task: ${task.title}');
      } catch (e) {
        print('Error adding sample task: $e');
      }
    }
  }

  Future<void> createSampleUsers() async {
    final sampleUsers = [
      AppUser(
        nickname: 'WellnessGuru',
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      ),
      AppUser(
        nickname: 'FitnessCoach',
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      ),
      AppUser(
        nickname: 'ZenMaster',
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      ),
      AppUser(
        nickname: 'LanguageLover',
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      ),
      AppUser(
        nickname: 'HealthyChef',
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      ),
      AppUser(
        nickname: 'SocialButterfly',
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      ),
      AppUser(
        nickname: 'ArtistSoul',
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      ),
    ];

    for (final user in sampleUsers) {
      try {
        await _firestore
            .collection('users')
            .doc(user.nickname)
            .set(user.toMap());
        print('Added sample user: ${user.nickname}');
      } catch (e) {
        print('Error adding sample user: $e');
      }
    }
  }
}
