import 'package:flutter/material.dart';
import '../services/game_variant_service.dart';
import '../services/player_service.dart';
import '../services/stats_service.dart';
import '../services/server_service.dart';
import '../services/user_settings_service.dart';

class PlayerSettingsScreen extends StatefulWidget {
  const PlayerSettingsScreen({super.key});

  @override
  State<PlayerSettingsScreen> createState() => _PlayerSettingsScreenState();
}

class _PlayerSettingsScreenState extends State<PlayerSettingsScreen> {
  final TextEditingController _nameController = TextEditingController();

  bool _loading = true;
  String _statusText = '';
  GameVariant _variant = GameVariant.eighteenTwelve;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final name = await UserSettingsService.getPlayerName();
    final variant = await GameVariantService.getVariant();

    if (!mounted) return;

    setState(() {
      _nameController.text = name ?? '';
      _variant = variant;
      _loading = false;
    });
  }

  Future<void> _saveVariant(GameVariant variant) async {
    await GameVariantService.setVariant(variant);

    if (!mounted) return;

    setState(() {
      _variant = variant;
      _statusText = 'Spiltype valgt: ${GameVariantService.title(variant)}';
    });
  }

  Future<bool> _playerNameExistsOnline(String name) async {
    try {
      final leaderboard = await ServerService.getLeaderboard();
      final wantedName = name.trim().toLowerCase();

      for (final entry in leaderboard) {
        final existingName = (entry['player_name'] ?? '')
            .toString()
            .trim()
            .toLowerCase();

        if (existingName == wantedName) {
          return true;
        }
      }

      return false;
    } catch (_) {
      // Hvis serveren ikke svarer, tillader vi lokal gemning.
      // Ellers kan brugeren blive låst ude offline.
      return false;
    }
  }

  Future<void> _savePlayerName() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() {
        _statusText = 'Skriv et spillernavn først.';
      });
      return;
    }

    if (name.length < 2) {
      setState(() {
        _statusText = 'Spillernavn skal være mindst 2 tegn.';
      });
      return;
    }

    final currentName = await UserSettingsService.getPlayerName();

    final isSameAsCurrent =
        currentName != null &&
        currentName.trim().toLowerCase() == name.toLowerCase();

    if (!isSameAsCurrent) {
      final nameExists = await _playerNameExistsOnline(name);

      if (nameExists) {
        if (!mounted) return;

        setState(() {
          _statusText = 'Navnet "$name" er allerede i brug.';
        });
        return;
      }
    }

    await PlayerService.setPlayerName(name);

    if (!mounted) return;

    setState(() {
      _statusText = 'Spillernavn gemt: $name';
    });
  }

  Future<void> _resetLocalStats() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nulstil lokal statistik?'),
        content: const Text(
          'Dette sletter kun den lokale statistik på denne enhed.\n\n'
          'Leaderboard på serveren ændres ikke.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuller'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Nulstil'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await StatsService.resetStats();

    if (!mounted) return;

    setState(() {
      _statusText = 'Lokal statistik er nulstillet.';
    });
  }

  ButtonStyle _settingsButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFE0B080),
      foregroundColor: const Color(0xFF8B0000),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildVariantSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          RadioListTile<GameVariant>(
            title: const Text(
              '1812',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            subtitle: const Text(
              'Hærfører, Ingeniør, Ordonnans, Fælde og nye brikker',
              style: TextStyle(color: Colors.white70),
            ),
            activeColor: Color(0xFFE0B080),
            value: GameVariant.eighteenTwelve,
            groupValue: _variant,
            onChanged: (value) {
              if (value == null) return;
              _saveVariant(value);
            },
          ),
          RadioListTile<GameVariant>(
            title: const Text(
              'Klassisk',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            subtitle: const Text(
              'Marskal, Minør, Spejder, Bombe og originale brikker',
              style: TextStyle(color: Colors.white70),
            ),
            activeColor: Color(0xFFE0B080),
            value: GameVariant.classic,
            groupValue: _variant,
            onChanged: (value) {
              if (value == null) return;
              _saveVariant(value);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF06420B),
      appBar: AppBar(
        title: const Text('Indstillinger'),
        backgroundColor: const Color(0xFF06420B),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Spiltype',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Vælg om spillet skal bruge 1812-navne og brikker eller klassisk visning.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),

                  const SizedBox(height: 12),

                  _buildVariantSelector(),

                  const SizedBox(height: 36),

                  const Text(
                    'Spillernavn',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Navnet bruges til leaderboard og senere online-profiler.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    'Dit navn',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.black, fontSize: 24),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: _savePlayerName,
                    style: _settingsButtonStyle(),
                    child: const Text('Gem spillernavn'),
                  ),

                  const SizedBox(height: 14),

                  ElevatedButton(
                    onPressed: _resetLocalStats,
                    style: _settingsButtonStyle(),
                    child: const Text('Nulstil lokal statistik'),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    _statusText,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }
}
