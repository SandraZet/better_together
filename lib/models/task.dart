import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskTheme {
  creativity,
  fitness,
  mindfulness,
  social,
  productivity,
  learning,
  nature,
  cooking,
  entertainment,
  wellness,
}

enum TimeSlot {
  night, // 0-3 Uhr (Test-Slot)
  morning, // 6-12 Uhr
  afternoon, // 12-18 Uhr
  evening, // 18-22 Uhr
}

class Task {
  final String id;
  final String title;
  final String description;
  final String authorNickname;
  final TaskTheme theme;
  final TimeSlot timeSlot;
  final DateTime createdAt;
  final DateTime activeDate; // Das Datum, an dem diese Aufgabe aktiv ist
  final bool isActive;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.authorNickname,
    required this.theme,
    required this.timeSlot,
    required this.createdAt,
    required this.activeDate,
    this.isActive = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'authorNickname': authorNickname,
      'theme': theme.name,
      'timeSlot': timeSlot.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'activeDate': Timestamp.fromDate(activeDate),
      'isActive': isActive,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      authorNickname: map['authorNickname'] ?? '',
      theme: TaskTheme.values.firstWhere(
        (e) => e.name == map['theme'],
        orElse: () => TaskTheme.creativity,
      ),
      timeSlot: TimeSlot.values.firstWhere(
        (e) => e.name == map['timeSlot'],
        orElse: () => TimeSlot.morning,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      activeDate: (map['activeDate'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? false,
    );
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? authorNickname,
    TaskTheme? theme,
    TimeSlot? timeSlot,
    DateTime? createdAt,
    DateTime? activeDate,
    bool? isActive,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      authorNickname: authorNickname ?? this.authorNickname,
      theme: theme ?? this.theme,
      timeSlot: timeSlot ?? this.timeSlot,
      createdAt: createdAt ?? this.createdAt,
      activeDate: activeDate ?? this.activeDate,
      isActive: isActive ?? this.isActive,
    );
  }
}

class TaskCompletion {
  final String id;
  final String taskId;
  final String userNickname;
  final DateTime completedAt;
  final DateTime taskDate; // Das Datum der Aufgabe (ohne Zeit)
  final TimeSlot timeSlot;

  TaskCompletion({
    required this.id,
    required this.taskId,
    required this.userNickname,
    required this.completedAt,
    required this.taskDate,
    required this.timeSlot,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'userNickname': userNickname,
      'completedAt': Timestamp.fromDate(completedAt),
      'taskDate': Timestamp.fromDate(taskDate),
      'timeSlot': timeSlot.name,
    };
  }

  factory TaskCompletion.fromMap(Map<String, dynamic> map) {
    return TaskCompletion(
      id: map['id'] ?? '',
      taskId: map['taskId'] ?? '',
      userNickname: map['userNickname'] ?? '',
      completedAt: (map['completedAt'] as Timestamp).toDate(),
      taskDate: (map['taskDate'] as Timestamp).toDate(),
      timeSlot: TimeSlot.values.firstWhere(
        (e) => e.name == map['timeSlot'],
        orElse: () => TimeSlot.morning,
      ),
    );
  }
}

class AppUser {
  final String nickname;
  final DateTime createdAt;
  final DateTime lastActive;

  AppUser({
    required this.nickname,
    required this.createdAt,
    required this.lastActive,
  });

  Map<String, dynamic> toMap() {
    return {
      'nickname': nickname,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': Timestamp.fromDate(lastActive),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      nickname: map['nickname'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastActive: (map['lastActive'] as Timestamp).toDate(),
    );
  }
}
