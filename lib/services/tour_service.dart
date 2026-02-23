import 'package:shared_preferences/shared_preferences.dart';

class TourService {
  static const String _hasSeenTourKey = 'has_seen_first_tour';

  /// Check if user has already seen the first tour
  static Future<bool> hasSeenTour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenTourKey) ?? false;
  }

  /// Mark the tour as seen
  static Future<void> markTourAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenTourKey, true);
  }

  /// Reset tour status (useful for testing or settings)
  static Future<void> resetTour() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hasSeenTourKey);
  }
}
