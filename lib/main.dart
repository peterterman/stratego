import 'package:flutter/material.dart';
import 'screens/setup_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/player_settings_screen.dart';
import 'screens/statistics_screen.dart';
import 'services/user_settings_service.dart';
import 'services/stats_service.dart';
import 'services/rank_service.dart';

void main() {
  runApp(const StrategoApp());
}

class StrategoApp extends StatelessWidget {
  const StrategoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stratego',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: const FrontPage(),
    );
  }
}

class FrontPage extends StatefulWidget {
  const FrontPage({super.key});

  @override
  State<FrontPage> createState() => _FrontPageState();
}

class _FrontPageState extends State<FrontPage> {
  String? playerName;
  String? playerRank;

  @override
  void initState() {
    super.initState();
    _loadPlayerInfo();
  }

  Future<void> _loadPlayerInfo() async {
    final name = await UserSettingsService.getPlayerName();
    final stats = await StatsService.getStats();
    final points = stats['points'] ?? 1000;

    if (!mounted) return;

    setState(() {
      if (name != null && name.trim().isNotEmpty) {
        playerName = name.trim();
        playerRank = RankService.rankFromPoints(points);
      } else {
        playerName = null;
        playerRank = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06420B),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(
                  'assets/images/stratego_icon.png',
                  width: 170,
                  height: 170,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'STRATEGO',
                style: TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  letterSpacing: 3,
                ),
              ),

              const SizedBox(height: 10),

              if (playerName != null && playerRank != null)
                Text(
                  '$playerName · $playerRank',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                const Text(
                  'Ingen spiller valgt',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),

              const SizedBox(height: 44),

              _menuButton(
                text: 'Nyt spil',
                onPressed: () async {
                  final hasName = await UserSettingsService.hasPlayerName();

                  if (!context.mounted) return;

                  if (!hasName) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PlayerSettingsScreen(),
                      ),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SetupScreen()),
                  );
                },
              ),
              _menuButton(
                text: 'Leaderboard',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LeaderboardScreen(),
                    ),
                  );
                },
              ),

              _menuButton(
                text: 'Statistik',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StatisticsScreen()),
                  );
                },
              ),
              _menuButton(
                text: 'Indstillinger',
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PlayerSettingsScreen(),
                    ),
                  );

                  await _loadPlayerInfo();
                },
              ),

              _menuButton(
                text: 'Om',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Stratego'),
                      content: const Text(
                        'Version 1.0\n\n'
                        'Udviklet af Peter Terman Hansen\n\n'
                        'Flutter-version af Stratego med AI-modstander.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuButton({required String text, required VoidCallback onPressed}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SizedBox(
        width: 230,
        height: 58,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE0B080),
            foregroundColor: const Color(0xFF8B0000),
            textStyle: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: onPressed,
          child: Text(text),
        ),
      ),
    );
  }
}

class RulesPage extends StatelessWidget {
  const RulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Regler')),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          'Stratego-regler indsættes her.\n\n'
          'Målet er at erobre modstanderens fane.',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Indstillinger')),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          'Indstillinger kommer her.\n\n'
          'Senere: dansk/engelsk, lyd til/fra, sværhedsgrad.',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

class SetupPage extends StatelessWidget {
  const SetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06420B),
      appBar: AppBar(title: const Text('Manuel opstilling')),
      body: const Center(
        child: Text(
          'Kommer i næste version',
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
    );
  }
}
