import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ServerService {
  static const String baseUrl = 'https://www.toft-terman.dk/sg';
  static const String apiUserAgent = 'StrategoFlutter/1.0 PeterTerman';

  static const Map<String, String> _headers = {
    'User-Agent': apiUserAgent,
    'Accept': 'application/json',
  };

  static Future<Map<String, dynamic>?> registerPlayer({
    required String playerId,
    required String playerName,
  }) async {
    final uri = Uri.parse('$baseUrl/register-player.php').replace(
      queryParameters: {'player_id': playerId, 'player_name': playerName},
    );

    debugPrint('URL: $uri');

    try {
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 8));

      debugPrint('STATUS: ${response.statusCode}');
      debugPrint('BODY: ${response.body}');

      if (response.statusCode != 200) return null;

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e, s) {
      debugPrint('REGISTER HTTP ERROR: $e');
      debugPrint('$s');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> reportResult({
    required String playerId,
    required String playerName,
    required String result,
    String winType = 'block',
  }) async {
    final uri = Uri.parse('$baseUrl/report-result.php').replace(
      queryParameters: {
        'player_id': playerId,
        'player_name': playerName,
        'result': result,
        'win_type': winType,
      },
    );

    debugPrint('REPORT URL: $uri');

    try {
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 8));

      debugPrint('REPORT STATUS: ${response.statusCode}');
      debugPrint('REPORT BODY: ${response.body}');

      if (response.statusCode != 200) return null;

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e, s) {
      debugPrint('REPORT ERROR: $e');
      debugPrint('$s');
      return null;
    }
  }

  static Future<List<dynamic>> getLeaderboard() async {
    final uri = Uri.parse('$baseUrl/leaderboard.php');

    try {
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['ok'] != true) return [];

      return data['leaderboard'] as List<dynamic>;
    } catch (e, s) {
      debugPrint('LEADERBOARD ERROR: $e');
      debugPrint('$s');
      return [];
    }
  }
}
