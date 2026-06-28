import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

import 'server_service.dart';

class PlayerService {
  static const _playerIdKey = 'player_id';
  static const _playerNameKey = 'player_name';

  static Future<String> getPlayerId() async {
    final prefs = await SharedPreferences.getInstance();

    var id = prefs.getString(_playerIdKey);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await prefs.setString(_playerIdKey, id);
    }

    return id;
  }

  static Future<String> getPlayerName() async {
    final prefs = await SharedPreferences.getInstance();

    final savedName = prefs.getString(_playerNameKey);
    if (savedName != null && savedName.isNotEmpty) {
      return savedName;
    }

    final id = await getPlayerId();
    final shortId = id.substring(id.length - 4).toUpperCase();

    final autoName = 'Spiller-$shortId';
    await prefs.setString(_playerNameKey, autoName);

    return autoName;
  }

  static Future<void> setPlayerName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_playerNameKey, name.trim());
  }

  static Future<void> registerOnline() async {
    try {
      final id = await getPlayerId();
      final name = await getPlayerName();

      debugPrint("PLAYER ID   : $id");
      debugPrint("PLAYER NAME : $name");

      final result = await ServerService.registerPlayer(
        playerId: id,
        playerName: name,
      );

      debugPrint("SERVER RESULT: $result");
    } catch (e, s) {
      debugPrint("REGISTER ERROR: $e");
      debugPrint("$s");
    }
  }

  static Future<void> reportWin({required bool flagWin}) async {
    final id = await getPlayerId();

    debugPrint('REPORT WIN: $id flagWin=$flagWin');

    final result = await ServerService.reportResult(
      playerId: id,
      result: 'win',
      winType: flagWin ? 'flag' : 'block',
    );

    debugPrint('REPORT WIN RESULT: $result');
  }

  static Future<void> reportLoss() async {
    final id = await getPlayerId();

    debugPrint('REPORT LOSS: $id');

    final result = await ServerService.reportResult(
      playerId: id,
      result: 'loss',
    );

    debugPrint('REPORT LOSS RESULT: $result');
  }
}
