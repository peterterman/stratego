import 'package:shared_preferences/shared_preferences.dart';

class UserSettingsService {
  static const String _playerNameKey = 'player_name';

  static Future<String?> getPlayerName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_playerNameKey);
  }

  static Future<void> setPlayerName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_playerNameKey, name.trim());
  }

  static Future<bool> hasPlayerName() async {
    final name = await getPlayerName();
    return name != null && name.trim().isNotEmpty;
  }
}
