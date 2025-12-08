import 'package:better_together/services/revenue_cat_service.dart';

class NicknameHelper {
  /// Format nickname with ⭐ if user is a supporter
  static Future<String> formatNickname(String nickname) async {
    // Remove unique suffix (#123) if present
    final cleanNickname = nickname.contains('#')
        ? nickname.substring(0, nickname.lastIndexOf('#'))
        : nickname;

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
