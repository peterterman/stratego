import 'package:flutter/material.dart';
import '../services/user_settings_service.dart';
import '../services/stats_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PlayerSettingsScreen extends StatefulWidget {
  const PlayerSettingsScreen({super.key});

  @override
  State<PlayerSettingsScreen> createState() => _PlayerSettingsScreenState();
}

class _PlayerSettingsScreenState extends State<PlayerSettingsScreen> {
  final TextEditingController _nameController = TextEditingController();

  bool _loading = true;
  String _statusText = '';

  Future<bool> _playerNameExistsOnline(String name) async {
    final url = Uri.parse('https://stratego.toft-terman.dk/leaderboard');

    try {
      final response = await http.get(url);

      if (response.statusCode != 200) {
        return false;
      }

      final data = jsonDecode(response.body);

      if (data['ok'] != true) {
        return false;
      }

      final leaderboard = data['leaderboard'] as List;

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

  @override
  void initState() {
    super.initState();
    _loadPlayerName();
  }

  Future<void> _loadPlayerName() async {
    final name = await UserSettingsService.getPlayerName();

    setState(() {
      _nameController.text = name ?? '';
      _loading = false;
    });
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

    await UserSettingsService.setPlayerName(name);

    if (!mounted) return;

    setState(() {
      _statusText = 'Spillernavn gemt: $name';
    });
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
