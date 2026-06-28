import 'package:flutter/material.dart';
import '../services/stats_service.dart';
import '../services/user_settings_service.dart';
import '../services/rank_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _loading = true;

  String playerName = 'Spiller';
  int played = 0;
  int wins = 0;
  int losses = 0;
  int flagWins = 0;
  int blockWins = 0;
  int points = 1000;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await StatsService.getStats();
    final savedName = await UserSettingsService.getPlayerName();

    setState(() {
      playerName = savedName != null && savedName.trim().isNotEmpty
          ? savedName.trim()
          : 'Spiller';

      points = stats['points'] ?? 1000;
      played = stats['played'] ?? 0;
      wins = stats['wins'] ?? 0;
      losses = stats['losses'] ?? 0;
      flagWins = stats['flag_wins'] ?? 0;
      blockWins = stats['block_wins'] ?? 0;
      _loading = false;
    });
  }

  double get winPercent {
    if (played == 0) return 0;
    return wins * 100 / played;
  }

  Widget _statRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE0B080),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF8B0000),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF8B0000),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rank = RankService.rankFromPoints(points);
    final nextRank = RankService.nextRankFromPoints(points);
    final pointsLeft = RankService.pointsToNextRank(points);

    return Scaffold(
      backgroundColor: const Color(0xFF06420B),
      appBar: AppBar(
        title: const Text('Statistik'),
        backgroundColor: const Color(0xFF06420B),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    playerName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Rang: $rank',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    '$points point',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    pointsLeft == null
                        ? 'Højeste rang opnået'
                        : '$pointsLeft point til $nextRank',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),

                  const SizedBox(height: 14),

                  const Text(
                    'Lokal statistik',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 24),

                  _statRow('Spillede kampe', '$played'),
                  _statRow('Sejre', '$wins'),
                  _statRow('Nederlag', '$losses'),
                  _statRow('Flag-sejre', '$flagWins'),
                  _statRow('Blokerings-sejre', '$blockWins'),
                  _statRow(
                    'Sejrsprocent',
                    '${winPercent.toStringAsFixed(1)} %',
                  ),
                ],
              ),
            ),
    );
  }
}
