import '../models/task.dart';

class TimeSlotManager {
  static TimeSlot? getCurrentTimeSlot() {
    final now = DateTime.now();
    final hour = now.hour;

    if (hour >= 0 && hour < 3) {
      return TimeSlot.night;
    } else if (hour >= 6 && hour < 12) {
      return TimeSlot.morning;
    } else if (hour >= 12 && hour < 18) {
      return TimeSlot.afternoon;
    } else if (hour >= 18 && hour < 22) {
      return TimeSlot.evening;
    } else {
      // 22-6 Uhr = Ruhezeit (außer 0-3 Uhr Test-Slot)
      return null;
    }
  }

  static bool isRestTime() {
    return getCurrentTimeSlot() == null;
  }

  static String getTimeSlotDisplayName(TimeSlot timeSlot) {
    switch (timeSlot) {
      case TimeSlot.night:
        return "Nacht (0-3 Uhr)";
      case TimeSlot.morning:
        return "Morgen (6-12 Uhr)";
      case TimeSlot.afternoon:
        return "Mittag (12-18 Uhr)";
      case TimeSlot.evening:
        return "Abend (18-22 Uhr)";
    }
  }

  static DateTime getNextSlotChangeTime() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (now.hour < 3) {
      // Nacht-Slot, nächster Wechsel ist 3 Uhr heute (Ruhezeit)
      return today.add(const Duration(hours: 3));
    } else if (now.hour < 6) {
      // Es ist Ruhezeit, nächster Wechsel ist 6 Uhr heute
      return today.add(const Duration(hours: 6));
    } else if (now.hour < 12) {
      // Morgenslot, nächster Wechsel ist 12 Uhr heute
      return today.add(const Duration(hours: 12));
    } else if (now.hour < 18) {
      // Mittagsslot, nächster Wechsel ist 18 Uhr heute
      return today.add(const Duration(hours: 18));
    } else if (now.hour < 22) {
      // Abendslot, nächster Wechsel ist 22 Uhr heute
      return today.add(const Duration(hours: 22));
    } else {
      // Es ist Ruhezeit, nächster Wechsel ist 0 Uhr morgen (Nacht-Slot)
      return today.add(const Duration(days: 1));
    }
  }

  static Duration getTimeUntilNextSlot() {
    final nextChange = getNextSlotChangeTime();
    final now = DateTime.now();
    return nextChange.difference(now);
  }

  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
    } else {
      return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
    }
  }

  static String getRestModeMessage() {
    final nextChange = getNextSlotChangeTime();
    final now = DateTime.now();
    final timeUntil = nextChange.difference(now);

    if (timeUntil.inHours > 0) {
      return "Ruhezeit - Nächste Aufgabe in ${timeUntil.inHours}h ${timeUntil.inMinutes.remainder(60)}min";
    } else {
      return "Ruhezeit - Nächste Aufgabe in ${timeUntil.inMinutes}min";
    }
  }

  static String getCurrentSlotDisplayName() {
    final currentSlot = getCurrentTimeSlot();
    if (currentSlot != null) {
      return getTimeSlotDisplayName(currentSlot);
    } else {
      return "Ruhezeit (22-6 Uhr)";
    }
  }
}
