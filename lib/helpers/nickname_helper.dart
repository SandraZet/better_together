import 'package:better_together/services/revenue_cat_service.dart';

class NicknameHelper {
  /// Format nickname with ⭐ if user is a supporter
  static Future<String> formatNickname(String nickname) async {
    // Extract timestamp suffix for uniqueness
    String cleanNickname = nickname;

    if (nickname.contains('#')) {
      final parts = nickname.split('#');
      cleanNickname = parts[0];

      // Only add suffix for default nickname "tom" to differentiate multiple toms
      // Extract just the nickname part (before | if present)
      if (cleanNickname.contains('|')) {
        final nicknameParts = cleanNickname.split('|');
        final nicknameOnly = nicknameParts[0].trim();
        final location = nicknameParts[1].trim();

        if (nicknameOnly.toLowerCase() == 'tom' &&
            parts.length == 2 &&
            parts[1].length >= 4) {
          // Use last 4 chars of timestamp for better uniqueness
          final timestampStr = parts[1];
          final uniqueSuffix = timestampStr.substring(timestampStr.length - 4);
          cleanNickname = '$nicknameOnly-$uniqueSuffix | $location';
        }
      }
    }

    final isSupporter = await RevenueCatService().isSupporter();
    if (isSupporter) {
      return '⭐ $cleanNickname';
    }
    return cleanNickname;
  }

  /// Get display name (nickname | location) with star if supporter
  static Future<String> getDisplayName(String nickname, String location) async {
    final formattedNickname = await formatNickname(nickname);
    return '$formattedNickname | $location';
  }
}
