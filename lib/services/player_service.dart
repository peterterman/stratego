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
    if (id == null || id.trim().isEmpty) {
      id = const Uuid().v4();
      await prefs.setString(_playerIdKey, id);
      debugPrint('NEW LOCAL PLAYER ID: $id');
    }

    return id.trim();
  }

  static Future<void> setPlayerId(String id) async {
    final cleanId = id.trim();
    if (cleanId.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_playerIdKey, cleanId);

    debugPrint('SAVED SERVER PLAYER ID LOCALLY: $cleanId');
  }

  static Future<String> getPlayerName() async {
    final prefs = await SharedPreferences.getInstance();

    final savedName = prefs.getString(_playerNameKey);
    if (savedName != null && savedName.trim().isNotEmpty) {
      return savedName.trim();
    }

    final id = await getPlayerId();
    final shortId = id.substring(id.length - 4).toUpperCase();

    final autoName = 'Spiller-$shortId';
    await prefs.setString(_playerNameKey, autoName);

    debugPrint('AUTO PLAYER NAME: $autoName');

    return autoName;
  }

  static Future<void> setPlayerName(String name) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_playerNameKey, cleanName);

    debugPrint('SAVED PLAYER NAME LOCALLY: $cleanName');

    await registerOnline();
  }

  static Future<Map<String, dynamic>?> registerOnline() async {
    try {
      final localId = await getPlayerId();
      final name = await getPlayerName();

      debugPrint('REGISTER ONLINE');
      debugPrint('LOCAL PLAYER ID   : $localId');
      debugPrint('LOCAL PLAYER NAME : $name');

      final result = await ServerService.registerPlayer(
        playerId: localId,
        playerName: name,
      );

      debugPrint('REGISTER RESULT: $result');

      if (result == null || result['ok'] != true) {
        return null;
      }

      final playerRaw = result['player'];
      if (playerRaw is! Map) {
        return null;
      }

      final player = Map<String, dynamic>.from(playerRaw);

      final serverId = player['player_id']?.toString().trim();
      final serverName = player['player_name']?.toString().trim();

      if (serverId != null && serverId.isNotEmpty && serverId != localId) {
        debugPrint('SERVER RETURNED EXISTING PLAYER ID');
        debugPrint('OLD LOCAL ID : $localId');
        debugPrint('SERVER ID    : $serverId');

        await setPlayerId(serverId);
      }

      if (serverName != null && serverName.isNotEmpty && serverName != name) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_playerNameKey, serverName);
        debugPrint('SAVED SERVER PLAYER NAME LOCALLY: $serverName');
      }

      return player;
    } catch (e, s) {
      debugPrint('REGISTER ERROR: $e');
      debugPrint('$s');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> reportWin({
    required bool flagWin,
  }) async {
    try {
      await registerOnline();

      final id = await getPlayerId();
      final name = await getPlayerName();

      debugPrint('REPORT WIN: $id $name flagWin=$flagWin');

      final result = await ServerService.reportResult(
        playerId: id,
        playerName: name,
        result: 'win',
        winType: flagWin ? 'flag' : 'block',
      );

      debugPrint('REPORT WIN RESULT: $result');

      if (result == null || result['ok'] != true) return null;

      final playerRaw = result['player'];
      if (playerRaw is Map) {
        return Map<String, dynamic>.from(playerRaw);
      }

      return null;
    } catch (e, s) {
      debugPrint('REPORT WIN ERROR: $e');
      debugPrint('$s');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> reportLoss() async {
    try {
      await registerOnline();

      final id = await getPlayerId();
      final name = await getPlayerName();

      debugPrint('REPORT LOSS: $id $name');

      final result = await ServerService.reportResult(
        playerId: id,
        playerName: name,
        result: 'loss',
      );

      debugPrint('REPORT LOSS RESULT: $result');

      if (result == null || result['ok'] != true) return null;

      final playerRaw = result['player'];
      if (playerRaw is Map) {
        return Map<String, dynamic>.from(playerRaw);
      }

      return null;
    } catch (e, s) {
      debugPrint('REPORT LOSS ERROR: $e');
      debugPrint('$s');
      return null;
    }
  }
}
