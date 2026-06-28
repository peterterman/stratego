import 'package:shared_preferences/shared_preferences.dart';

class StatsService {
  static const _pointsKey = 'stats_points';
  static const _playedKey = 'stats_played';
  static const _winsKey = 'stats_wins';
  static const _lossesKey = 'stats_losses';
  static const _flagWinsKey = 'stats_flag_wins';
  static const _blockWinsKey = 'stats_block_wins';

  static Future<void> registerWin({required bool flagWin}) async {
    final prefs = await SharedPreferences.getInstance();

    final points = prefs.getInt(_pointsKey) ?? 1000;
    final played = prefs.getInt(_playedKey) ?? 0;
    final wins = prefs.getInt(_winsKey) ?? 0;
    final flagWins = prefs.getInt(_flagWinsKey) ?? 0;
    final blockWins = prefs.getInt(_blockWinsKey) ?? 0;

    final pointGain = flagWin ? 20 : 12;

    await prefs.setInt(_pointsKey, points + pointGain);
    await prefs.setInt(_playedKey, played + 1);
    await prefs.setInt(_winsKey, wins + 1);

    if (flagWin) {
      await prefs.setInt(_flagWinsKey, flagWins + 1);
    } else {
      await prefs.setInt(_blockWinsKey, blockWins + 1);
    }
  }

  static Future<void> registerLoss() async {
    final prefs = await SharedPreferences.getInstance();

    final points = prefs.getInt(_pointsKey) ?? 1000;

    await prefs.setInt(_pointsKey, points - 8);
    await prefs.setInt(_playedKey, (prefs.getInt(_playedKey) ?? 0) + 1);
    await prefs.setInt(_lossesKey, (prefs.getInt(_lossesKey) ?? 0) + 1);
  }

  static Future<Map<String, int>> getStats() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'points': prefs.getInt(_pointsKey) ?? 1000,
      'played': prefs.getInt(_playedKey) ?? 0,
      'wins': prefs.getInt(_winsKey) ?? 0,
      'losses': prefs.getInt(_lossesKey) ?? 0,
      'flag_wins': prefs.getInt(_flagWinsKey) ?? 0,
      'block_wins': prefs.getInt(_blockWinsKey) ?? 0,
    };
  }

  static Future<void> resetStats() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_pointsKey);
    await prefs.remove(_playedKey);
    await prefs.remove(_winsKey);
    await prefs.remove(_lossesKey);
    await prefs.remove(_flagWinsKey);
    await prefs.remove(_blockWinsKey);
  }
}
