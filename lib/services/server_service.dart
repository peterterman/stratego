import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ServerService {
  static const String baseUrl = 'https://stratego.toft-terman.dk';

  static Future<Map<String, dynamic>?> registerPlayer({
    required String playerId,
    required String playerName,
  }) async {
    final uri = Uri.parse('$baseUrl/register-player').replace(
      queryParameters: {'player_id': playerId, 'player_name': playerName},
    );

    debugPrint("URL: $uri");

    final response = await http.get(uri);

    debugPrint("STATUS: ${response.statusCode}");
    debugPrint("BODY: ${response.body}");

    if (response.statusCode != 200) return null;

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>?> reportResult({
    required String playerId,
    required String result,
    String winType = 'block',
  }) async {
    final uri = Uri.parse('$baseUrl/report-result').replace(
      queryParameters: {
        'player_id': playerId,
        'result': result,
        'win_type': winType,
      },
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) return null;

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getLeaderboard() async {
    final uri = Uri.parse('$baseUrl/leaderboard');

    final response = await http.get(uri);

    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (data['ok'] != true) return [];

    return data['leaderboard'] as List<dynamic>;
  }
}
