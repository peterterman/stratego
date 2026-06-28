import 'package:flutter/material.dart';
import '../services/rank_service.dart';
import '../services/server_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late Future<List<dynamic>> leaderboardFuture;

  @override
  void initState() {
    super.initState();
    leaderboardFuture = ServerService.getLeaderboard();
  }

  Future<void> refresh() async {
    setState(() {
      leaderboardFuture = ServerService.getLeaderboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06420B),
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: leaderboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final players = snapshot.data ?? [];

          if (players.isEmpty) {
            return const Center(
              child: Text(
                'Ingen resultater endnu',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: refresh,
            child: ListView.builder(
              itemCount: players.length,
              itemBuilder: (context, index) {
                final p = players[index];

                final name = p['player_name']?.toString() ?? 'Ukendt';
                final points = p['points'] is int
                    ? p['points'] as int
                    : int.tryParse(p['points'].toString()) ?? 1000;
                final played = p['played'] ?? 0;
                final wins = p['wins'] ?? 0;
                final losses = p['losses'] ?? 0;
                final rank = RankService.rankFromPoints(points);

                return Card(
                  color: const Color(0xFFE0B080),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF8B0000),
                      foregroundColor: Colors.white,
                      child: Text('${index + 1}'),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(
                        color: Color(0xFF8B0000),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '$rank · Kampe: $played  Sejre: $wins  Tab: $losses',
                      style: const TextStyle(
                        color: Color(0xFF8B0000),
                        fontSize: 14,
                      ),
                    ),
                    trailing: Text(
                      '$points',
                      style: const TextStyle(
                        color: Color(0xFF8B0000),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
