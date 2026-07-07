import 'package:shared_preferences/shared_preferences.dart';

class StatsService {
  static const _pointsKey = 'stats_points';
  static const _playedKey = 'stats_played';
  static const _winsKey = 'stats_wins';
  static const _lossesKey = 'stats_losses';
  static const _flagWinsKey = 'stats_flag_wins';
  static const _blockWinsKey = 'stats_block_wins';

  // Bruges kun hvis serverkald fejler/offline.
  static Future<void> registerWinLocal({required bool flagWin}) async {
    final prefs = await SharedPreferences.getInstance();

    final points = prefs.getInt(_pointsKey) ?? 1000;
    final played = prefs.getInt(_playedKey) ?? 0;
    final wins = prefs.getInt(_winsKey) ?? 0;
    final flagWins = prefs.getInt(_flagWinsKey) ?? 0;
    final blockWins = prefs.getInt(_blockWinsKey) ?? 0;

    // Skal matche serverens pointsystem.
    final pointGain = flagWin ? 15 : 10;

    await prefs.setInt(_pointsKey, points + pointGain);
    await prefs.setInt(_playedKey, played + 1);
    await prefs.setInt(_winsKey, wins + 1);

    if (flagWin) {
      await prefs.setInt(_flagWinsKey, flagWins + 1);
    } else {
      await prefs.setInt(_blockWinsKey, blockWins + 1);
    }
  }

  // Bruges kun hvis serverkald fejler/offline.
  static Future<void> registerLossLocal() async {
    final prefs = await SharedPreferences.getInstance();

    final points = prefs.getInt(_pointsKey) ?? 1000;

    await prefs.setInt(_pointsKey, points - 8);
    await prefs.setInt(_playedKey, (prefs.getInt(_playedKey) ?? 0) + 1);
    await prefs.setInt(_lossesKey, (prefs.getInt(_lossesKey) ?? 0) + 1);
  }

  // Dette er den vigtige nye funktion.
  // Den kopierer serverens player-data direkte til lokal statistik.
  static Future<void> syncFromServerPlayer(Map<String, dynamic> player) async {
    final prefs = await SharedPreferences.getInstance();

    int readInt(String key, int fallback) {
      final value = player[key];

      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;

      return fallback;
    }

    await prefs.setInt(_pointsKey, readInt('points', 1000));
    await prefs.setInt(_playedKey, readInt('played', 0));
    await prefs.setInt(_winsKey, readInt('wins', 0));
    await prefs.setInt(_lossesKey, readInt('losses', 0));
    await prefs.setInt(_flagWinsKey, readInt('flag_wins', 0));
    await prefs.setInt(_blockWinsKey, readInt('block_wins', 0));
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
