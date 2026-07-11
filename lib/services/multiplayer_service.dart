import 'dart:convert';

import 'package:http/http.dart' as http;

const String kMultiplayerBaseUrl = 'https://www.toft-terman.dk/api/multiplayer';
const String kMultiplayerUserAgent = 'StrategoFlutter/1.0 PeterTerman';
const String kMultiplayerAppName = 'Stratego';
const String kStrategoGameType = 'stratego';

class MultiplayerException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? data;

  const MultiplayerException(this.message, {this.statusCode, this.data});

  @override
  String toString() => message;
}

class MultiplayerSession {
  final String gameId;
  final String gameType;
  final String inviteCode;
  final int playerNo;
  final String playerToken;
  final int version;
  final String status;
  final String phase;
  final bool yourTurn;
  final List<dynamic> players;
  final Map<String, dynamic> state;

  const MultiplayerSession({
    required this.gameId,
    required this.gameType,
    required this.inviteCode,
    required this.playerNo,
    required this.playerToken,
    required this.version,
    required this.status,
    required this.phase,
    required this.yourTurn,
    required this.players,
    required this.state,
  });

  factory MultiplayerSession.fromJson(Map<String, dynamic> json) {
    final playerNoValue = json['player_no'] ?? json['you_are'] ?? 0;

    return MultiplayerSession(
      gameId: (json['game_id'] ?? '').toString(),
      gameType: (json['game_type'] ?? '').toString(),
      inviteCode: (json['invite_code'] ?? '').toString(),
      playerNo: (playerNoValue as num? ?? 0).toInt(),
      playerToken: (json['player_token'] ?? '').toString(),
      version: (json['version'] as num? ?? 0).toInt(),
      status: (json['status'] ?? '').toString(),
      phase: (json['phase'] ?? '').toString(),
      yourTurn: json['your_turn'] == true,
      players: json['players'] as List<dynamic>? ?? const [],
      state: (json['state'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }
}

class MultiplayerState {
  final String gameId;
  final String gameType;
  final String inviteCode;
  final int youAre;
  final int version;
  final String status;
  final String phase;
  final bool yourTurn;
  final int? currentPlayer;
  final List<dynamic> players;
  final Map<String, dynamic> state;

  const MultiplayerState({
    required this.gameId,
    required this.gameType,
    required this.inviteCode,
    required this.youAre,
    required this.version,
    required this.status,
    required this.phase,
    required this.yourTurn,
    required this.currentPlayer,
    required this.players,
    required this.state,
  });

  factory MultiplayerState.fromJson(Map<String, dynamic> json) {
    return MultiplayerState(
      gameId: (json['game_id'] ?? '').toString(),
      gameType: (json['game_type'] ?? '').toString(),
      inviteCode: (json['invite_code'] ?? '').toString(),
      youAre: (json['you_are'] as num? ?? 0).toInt(),
      version: (json['version'] as num? ?? 0).toInt(),
      status: (json['status'] ?? '').toString(),
      phase: (json['phase'] ?? '').toString(),
      yourTurn: json['your_turn'] == true,
      currentPlayer: (json['current_player'] as num?)?.toInt(),
      players: json['players'] as List<dynamic>? ?? const [],
      state: (json['state'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }
}

class MultiplayerClient {
  final String baseUrl;
  final http.Client _http;

  MultiplayerClient({
    this.baseUrl = kMultiplayerBaseUrl,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  Future<Map<String, dynamic>> ping() {
    return _get(
      'ping.php',
      queryParameters: const {'app': kMultiplayerAppName},
    );
  }

  Future<MultiplayerSession> createGame({
    required String playerName,
    String gameType = kStrategoGameType,
  }) async {
    final json = await _post('create.php', {
      'game_type': gameType,
      'player_name': playerName,
    });
    return MultiplayerSession.fromJson(json);
  }

  Future<MultiplayerSession> joinGame({
    required String inviteCode,
    required String playerName,
  }) async {
    final json = await _post('join.php', {
      'invite_code': inviteCode.trim().toUpperCase(),
      'player_name': playerName,
    });
    return MultiplayerSession.fromJson(json);
  }

  Future<MultiplayerState> getState({
    required String gameId,
    required String playerToken,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/state.php',
    ).replace(queryParameters: {'game_id': gameId, 'token': playerToken});
    final response = await _http
        .get(uri, headers: _headers())
        .timeout(const Duration(seconds: 8));
    return MultiplayerState.fromJson(_decodeResponse(response));
  }

  Future<MultiplayerState> setVariant({
    required String gameId,
    required String playerToken,
    required int version,
    required String variant,
  }) {
    return sendAction(
      gameId: gameId,
      playerToken: playerToken,
      version: version,
      action: {'type': 'set_variant', 'variant': variant},
    );
  }

  Future<MultiplayerState> submitSetup({
    required String gameId,
    required String playerToken,
    required int version,
    required List<Map<String, dynamic>> pieces,
  }) {
    return sendAction(
      gameId: gameId,
      playerToken: playerToken,
      version: version,
      action: {'type': 'submit_setup', 'pieces': pieces},
    );
  }

  Future<MultiplayerState> move({
    required String gameId,
    required String playerToken,
    required int version,
    required int fromRow,
    required int fromCol,
    required int toRow,
    required int toCol,
  }) {
    return sendAction(
      gameId: gameId,
      playerToken: playerToken,
      version: version,
      action: {
        'type': 'move',
        'from': {'row': fromRow, 'col': fromCol},
        'to': {'row': toRow, 'col': toCol},
      },
    );
  }

  Future<MultiplayerState> resign({
    required String gameId,
    required String playerToken,
    required int version,
  }) {
    return sendAction(
      gameId: gameId,
      playerToken: playerToken,
      version: version,
      action: const {'type': 'resign'},
    );
  }

  Future<MultiplayerState> sendAction({
    required String gameId,
    required String playerToken,
    required int version,
    required Map<String, dynamic> action,
  }) async {
    final json = await _post('action.php', {
      'game_id': gameId,
      'token': playerToken,
      'version': version,
      'action': action,
    });
    return MultiplayerState.fromJson(json);
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final baseUri = Uri.parse('$baseUrl/$path');
    final uri = queryParameters == null
        ? baseUri
        : baseUri.replace(
            queryParameters: {...baseUri.queryParameters, ...queryParameters},
          );
    final response = await _http
        .get(uri, headers: _headers())
        .timeout(const Duration(seconds: 8));
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$baseUrl/$path');
    final requestBody = <String, dynamic>{'app': kMultiplayerAppName, ...body};
    final response = await _http
        .post(uri, headers: _headers(), body: jsonEncode(requestBody))
        .timeout(const Duration(seconds: 8));
    return _decodeResponse(response);
  }

  Map<String, String> _headers() => const {
    'User-Agent': kMultiplayerUserAgent,
    'X-App-Agent': kMultiplayerAppName,
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  Map<String, dynamic> _decodeResponse(http.Response response) {
    Map<String, dynamic> data;

    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw MultiplayerException(
        'Serveren svarede ikke med JSON: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        data['ok'] != true) {
      throw MultiplayerException(
        (data['error'] ?? 'Serverfejl ${response.statusCode}').toString(),
        statusCode: response.statusCode,
        data: data,
      );
    }

    return data;
  }

  void close() => _http.close();
}
