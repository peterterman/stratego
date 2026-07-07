import 'package:flutter/material.dart';
import 'screens/setup_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/player_settings_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/rules_screen.dart';
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
      title: '1812',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  36,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/images/1812_ikon.png',
                      width: 130,
                      height: 130,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    '1812',
                    style: TextStyle(
                      fontSize: 46,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 6,
                    ),
                  ),

                  const SizedBox(height: 6),

                  if (playerName != null && playerRank != null)
                    Text(
                      '$playerName · $playerRank',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else
                    const Text(
                      'Ingen spiller valgt',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),

                  const SizedBox(height: 22),

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
                        MaterialPageRoute(
                          builder: (_) => const StatisticsScreen(),
                        ),
                      );
                    },
                  ),

                  _menuButton(
                    text: 'Regler',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RulesScreen()),
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
                          title: const Text('1812'),
                          content: const Text(
                            'Version 1.0\n\n'
                            'Udviklet af Peter Terman Hansen\n\n'
                            'Strategisk brætspil med AI-modstander.',
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
        ),
      ),
    );
  }

  Widget _menuButton({required String text, required VoidCallback onPressed}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SizedBox(
        width: 230,
        height: 48,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE0B080),
            foregroundColor: const Color(0xFF8B0000),
            textStyle: const TextStyle(
              fontSize: 21,
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
