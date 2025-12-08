import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../utils/time_slot_manager.dart';

class AppStateProvider with ChangeNotifier {
  // User state
  String _userNickname = '';
  bool _isUserSetup = false;

  // Task state
  Task? _currentTask;
  TimeSlot? _currentTimeSlot;
  bool _isCurrentTaskCompleted = false;
  int _completionCount = 0;
  List<String> _completionNicknames = [];

  // Getters
  String get userNickname => _userNickname;
  bool get isUserSetup => _isUserSetup;
  Task? get currentTask => _currentTask;
  TimeSlot? get currentTimeSlot => _currentTimeSlot;
  bool get isCurrentTaskCompleted => _isCurrentTaskCompleted;
  int get completionCount => _completionCount;
  List<String> get completionNicknames => _completionNicknames;

  // User management
  void setUserNickname(String nickname) {
    _userNickname = nickname;
    _isUserSetup = nickname.isNotEmpty;
    notifyListeners();
  }

  // Time slot management
  void updateTimeSlot(TimeSlot? newTimeSlot) {
    if (_currentTimeSlot != newTimeSlot) {
      _currentTimeSlot = newTimeSlot;
      _currentTask = null;
      _isCurrentTaskCompleted = false;
      _completionCount = 0;
      _completionNicknames.clear();
      notifyListeners();
    }
  }

  // Task management
  void setCurrentTask(Task? task) {
    _currentTask = task;
    _isCurrentTaskCompleted = false;
    notifyListeners();
  }

  void setTaskCompleted(bool completed) {
    _isCurrentTaskCompleted = completed;
    if (completed) {
      _completionCount++;
      // Add current user to completion list if not already there
      if (!_completionNicknames.contains(_userNickname)) {
        _completionNicknames.insert(0, _userNickname);
      }
    }
    notifyListeners();
  }

  // Method to complete current task (called from UI)
  void completeCurrentTask() {
    setTaskCompleted(true);
  }

  void updateCompletionCount(int count) {
    _completionCount = count;
    notifyListeners();
  }

  void updateCompletionNicknames(List<String> nicknames) {
    _completionNicknames = List.from(nicknames);
    notifyListeners();
  }

  // Initialize app state
  void initializeApp() {
    _currentTimeSlot = TimeSlotManager.getCurrentTimeSlot();
    _loadDemoTask(); // Fallback demo task
    notifyListeners();
  }

  // Load a demo task as fallback
  void _loadDemoTask() {
    final currentSlot = _currentTimeSlot;
    if (currentSlot != null) {
      // Create demo tasks based on time slot
      switch (currentSlot) {
        case TimeSlot.night:
          _currentTask = Task(
            id: 'demo_night',
            title: 'Trinke ein Glas warme Milch 🥛',
            description: 'Entspanne dich für einen guten Schlaf',
            authorNickname: 'NightOwl',
            theme: TaskTheme.wellness,
            timeSlot: TimeSlot.night,
            createdAt: DateTime.now(),
            activeDate: DateTime.now(),
            isActive: true,
          );
          break;
        case TimeSlot.morning:
          _currentTask = Task(
            id: 'demo_morning',
            title: 'Trinke ein großes Glas Wasser',
            description: 'Starte den Tag mit Hydration',
            authorNickname: 'WellnessGuru',
            theme: TaskTheme.wellness,
            timeSlot: TimeSlot.morning,
            createdAt: DateTime.now(),
            activeDate: DateTime.now(),
            isActive: true,
          );
          break;
        case TimeSlot.afternoon:
          _currentTask = Task(
            id: 'demo_afternoon',
            title: 'Lerne ein neues Wort',
            description: 'Erweitere deinen Wortschatz',
            authorNickname: 'LanguageLover',
            theme: TaskTheme.learning,
            timeSlot: TimeSlot.afternoon,
            createdAt: DateTime.now(),
            activeDate: DateTime.now(),
            isActive: true,
          );
          break;
        case TimeSlot.evening:
          _currentTask = Task(
            id: 'demo_evening',
            title: 'Rufe einen Freund an',
            description: 'Pflege deine sozialen Kontakte',
            authorNickname: 'SocialButterfly',
            theme: TaskTheme.social,
            timeSlot: TimeSlot.evening,
            createdAt: DateTime.now(),
            activeDate: DateTime.now(),
            isActive: true,
          );
          break;
      }

      // Set some demo completion data
      _completionCount = 5 + (DateTime.now().hour % 10);
      _completionNicknames = ['DemoUser1', 'TestPerson', 'NightHero'];
    }
  }

  // Reset state (for testing or logout)
  void reset() {
    _userNickname = '';
    _isUserSetup = false;
    _currentTask = null;
    _currentTimeSlot = null;
    _isCurrentTaskCompleted = false;
    _completionCount = 0;
    _completionNicknames.clear();
    notifyListeners();
  }
}
