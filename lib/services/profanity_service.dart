import 'package:flutter/services.dart';

class ProfanityService {
  static final ProfanityService _instance = ProfanityService._internal();
  factory ProfanityService() => _instance;
  ProfanityService._internal();

  Set<String>? _profanityWords;
  bool _isLoaded = false;

  /// Load the profanity words list from assets
  Future<void> loadWords() async {
    if (_isLoaded) return;

    try {
      final String content = await rootBundle.loadString(
        'lib/assets/profanity_words.txt',
      );
      _profanityWords = content
          .split('\n')
          .map((word) => word.trim().toLowerCase())
          .where((word) => word.isNotEmpty)
          .toSet();
      _isLoaded = true;
      print('✅ Loaded ${_profanityWords!.length} profanity words');
    } catch (e) {
      print('❌ Error loading profanity words: $e');
      _profanityWords = {};
      _isLoaded = true;
    }
  }

  /// Check if text contains profanity
  /// Returns true if profanity is found
  bool containsProfanity(String text) {
    if (!_isLoaded || _profanityWords == null) {
      print('⚠️ Profanity words not loaded yet');
      return false;
    }

    final words = text.toLowerCase().split(RegExp(r'[\s\.,!\?;:\-]+'));

    for (final word in words) {
      if (word.isEmpty) continue;

      // Check exact match
      if (_profanityWords!.contains(word)) {
        return true;
      }

      // Check if the word contains profanity (for leetspeak variations like "f*ck" or "fvck")
      final cleanWord = word.replaceAll(RegExp(r'[^\w]'), '');
      if (_profanityWords!.contains(cleanWord)) {
        return true;
      }

      // Check for profanity + numbers pattern (e.g., "wixer69", "fick123")
      // Remove trailing numbers and check if the remaining part is profanity
      final withoutNumbers = cleanWord.replaceAll(RegExp(r'\d+$'), '');
      if (withoutNumbers.isNotEmpty &&
          withoutNumbers != cleanWord &&
          _profanityWords!.contains(withoutNumbers)) {
        return true;
      }

      // Check if word contains any profanity as substring (for combined words)
      // Only check for longer profanity words (4+ chars) to avoid false positives
      for (final profanity in _profanityWords!) {
        if (profanity.length >= 4 && cleanWord.contains(profanity)) {
          return true;
        }
      }
    }

    return false;
  }

  /// Get list of profanity words found in text (for debugging)
  List<String> findProfanityWords(String text) {
    if (!_isLoaded || _profanityWords == null) return [];

    final words = text.toLowerCase().split(RegExp(r'[\s\.,!\?;:\-]+'));
    final found = <String>[];

    for (final word in words) {
      if (word.isEmpty) continue;

      if (_profanityWords!.contains(word)) {
        found.add(word);
      }

      final cleanWord = word.replaceAll(RegExp(r'[^\w]'), '');
      if (_profanityWords!.contains(cleanWord) && !found.contains(cleanWord)) {
        found.add(cleanWord);
      }
    }

    return found;
  }
}
