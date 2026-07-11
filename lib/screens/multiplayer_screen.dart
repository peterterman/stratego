import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/game_variant_service.dart';
import '../services/multiplayer_service.dart';
import 'setup_screen.dart';

class MultiplayerScreen extends StatefulWidget {
  final String playerName;

  const MultiplayerScreen({super.key, required this.playerName});

  @override
  State<MultiplayerScreen> createState() => _MultiplayerScreenState();
}

class _MultiplayerScreenState extends State<MultiplayerScreen> {
  final MultiplayerClient _client = MultiplayerClient();
  final TextEditingController _joinCodeController = TextEditingController();

  Timer? _pollTimer;
  String? _gameId;
  String? _inviteCode;
  String? _playerToken;
  int _playerNo = 0;
  int _version = 0;
  String _status = '';
  String _phase = '';
  bool _yourTurn = false;
  bool _busy = false;
  String? _errorText;
  List<dynamic> _players = const [];
  Map<String, dynamic> _gameState = const {};
  bool _openingSetup = false;
  GameVariant _selectedVariant = GameVariant.eighteenTwelve;

  @override
  void dispose() {
    _pollTimer?.cancel();
    _joinCodeController.dispose();
    _client.close();
    super.dispose();
  }

  Future<void> _createGame() async {
    await _runServerCall(() async {
      final session = await _client.createGame(
        playerName: widget.playerName,
      );

      // Spiller 1 vælger varianten. Den gemmes straks på serveren,
      // før modspilleren inviteres eller opstillingen åbnes.
      final state = await _client.setVariant(
        gameId: session.gameId,
        playerToken: session.playerToken,
        version: session.version,
        variant: _selectedVariant == GameVariant.classic ? 'classic' : '1812',
      );

      _playerToken = session.playerToken;
      _applyState(state);
      _startPolling();
    });
  }

  Future<void> _joinGame() async {
    final code = _joinCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _errorText = 'Skriv invitationskoden først.');
      return;
    }

    await _runServerCall(() async {
      final session = await _client.joinGame(
        inviteCode: code,
        playerName: widget.playerName,
      );
      _applySession(session);
      _startPolling();
    });
  }

  Future<void> _pollState() async {
    final gameId = _gameId;
    final token = _playerToken;
    if (gameId == null || token == null || _busy) return;

    try {
      final state = await _client.getState(
        gameId: gameId,
        playerToken: token,
      );
      if (!mounted) return;
      setState(() {
        _applyState(state);
        _errorText = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorText = 'Kunne ikke hente status: $e');
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _pollState(),
    );
  }

  Future<void> _runServerCall(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _errorText = null;
    });

    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorText = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _busy = false);
    }
  }

  void _applySession(MultiplayerSession session) {
    _gameId = session.gameId;
    _inviteCode = session.inviteCode;
    _playerToken = session.playerToken;
    _playerNo = session.playerNo;
    _version = session.version;
    _status = session.status;
    _phase = session.phase;
    _yourTurn = session.yourTurn;
    _players = session.players;
    _gameState = session.state;
    _openSetupWhenReady();
  }

  void _applyState(MultiplayerState state) {
    _gameId = state.gameId;
    _inviteCode = state.inviteCode;
    _playerNo = state.youAre;
    _version = state.version;
    _status = state.status;
    _phase = state.phase;
    _yourTurn = state.yourTurn;
    _players = state.players;
    _gameState = state.state;
    _openSetupWhenReady();
  }

  void _openSetupWhenReady() {
    if (_openingSetup || _gameId == null || _playerToken == null) return;
    if (_players.length < 2 || _phase != 'setup') return;

    final ready = (_gameState['ready'] as Map?)?.cast<String, dynamic>();
    if (ready?['${_playerNo}'] == true) return;

    _openingSetup = true;
    _pollTimer?.cancel();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => SetupScreen(
            multiplayer: true,
            gameId: _gameId,
            playerToken: _playerToken,
            playerNo: _playerNo,
            initialVersion: _version,
            multiplayerVariant: (_gameState['variant'] ?? '1812').toString(),
          ),
        ),
      );
      if (!mounted) return;
      _openingSetup = false;
      _startPolling();
      await _pollState();
    });
  }

  String _playerNameFor(int playerNo) {
    for (final item in _players) {
      if (item is! Map) continue;
      final player = item.cast<String, dynamic>();
      if ((player['player_no'] as num? ?? 0).toInt() == playerNo) {
        final name = (player['player_name'] ?? '').toString().trim();
        if (name.isNotEmpty) return name;
      }
    }
    return playerNo == _playerNo ? widget.playerName : 'Venter...';
  }

  String get _serverVariantValue =>
      (_gameState['variant'] ?? '1812').toString();

  String get _variantTitle {
    return _serverVariantValue == 'classic' ? 'Klassisk Stratego' : '1812';
  }

  String get _statusText {
    if (_gameId == null) return 'Opret et spil eller deltag med en kode.';
    if (_status == 'waiting') return 'Venter på modspilleren.';
    if (_players.length >= 2) {
      return 'Begge spillere er forbundet. Næste trin er opstilling.';
    }
    return _phase.isEmpty ? _status : '$_status · $_phase';
  }

  Future<void> _copyInviteCode() async {
    final code = _inviteCode;
    if (code == null || code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invitationskoden er kopieret.')),
    );
  }


  Future<void> _sendSmsInvite() async {
    final code = _inviteCode;

    if (code == null || code.isEmpty) {
      if (!mounted) return;
      setState(() {
        _errorText = 'Der er ingen invitationskode endnu.';
      });
      return;
    }

    final text =
        'Vil du spille 1812 med mig?\n\n'
        'Åbn 1812-appen, vælg Multiplayer og indtast koden:\n\n'
        '$code\n\n'
        'Mvh\n'
        '${widget.playerName}';

    final uri = Uri.parse('sms:?body=${Uri.encodeComponent(text)}');

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && mounted) {
        setState(() {
          _errorText = 'Kunne ikke åbne SMS-appen.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = 'Kunne ikke åbne SMS-appen: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06420B),
      appBar: AppBar(
        title: const Text('Multiplayer'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        actions: [
          if (_gameId != null)
            IconButton(
              tooltip: 'Opdater',
              onPressed: _busy ? null : _pollState,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 14),
                  if (_gameId == null) _buildLobbyCard(),
                  if (_gameId != null) _buildPlayersCard(),
                  if (_errorText != null) ...[
                    const SizedBox(height: 14),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          _errorText!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_busy)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.18),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      color: const Color(0xFFE0B080),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '1812 mod en anden spiller',
              style: TextStyle(
                color: Color(0xFF8B0000),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Du spiller som: ${widget.playerName}'),
            Text(_statusText),
            if (_gameId != null) ...[
              const SizedBox(height: 6),
              Text('Du er spiller $_playerNo'),
              Text('Serverversion: $_version'),
              if (_yourTurn) const Text('Det er din tur.'),
            ],
            if (_inviteCode != null && _inviteCode!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      'Kode: $_inviteCode',
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Kopiér kode',
                    onPressed: _copyInviteCode,
                    icon: const Icon(Icons.copy),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _sendSmsInvite,
                  icon: const Icon(Icons.sms),
                  label: const Text('Invitér med SMS'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLobbyCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Vælg spiltype',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            RadioListTile<GameVariant>(
              contentPadding: EdgeInsets.zero,
              title: const Text('1812'),
              subtitle: const Text('Ingen søer og briknavne fra 1812'),
              value: GameVariant.eighteenTwelve,
              groupValue: _selectedVariant,
              onChanged: _busy
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() => _selectedVariant = value);
                    },
            ),
            RadioListTile<GameVariant>(
              contentPadding: EdgeInsets.zero,
              title: const Text('Klassisk Stratego'),
              subtitle: const Text('Klassiske brikker og søer på brættet'),
              value: GameVariant.classic,
              groupValue: _selectedVariant,
              onChanged: _busy
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() => _selectedVariant = value);
                    },
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _busy ? null : _createGame,
              child: Text(
                _selectedVariant == GameVariant.classic
                    ? 'Opret Klassisk Stratego'
                    : 'Opret 1812-spil',
              ),
            ),
            const SizedBox(height: 18),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Deltag med kode',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _joinCodeController,
              textCapitalization: TextCapitalization.characters,
              maxLength: 10,
              decoration: const InputDecoration(
                filled: true,
                border: OutlineInputBorder(),
                hintText: 'Fx YMMAKA',
              ),
            ),
            FilledButton.tonal(
              onPressed: _busy ? null : _joinGame,
              child: const Text('Deltag'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayersCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Spillere',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 6),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.extension),
              title: const Text('Spiltype'),
              subtitle: Text(_variantTitle),
            ),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(child: Text('1')),
              title: Text(_playerNameFor(1)),
            ),
            ListTile(
              leading: const CircleAvatar(child: Text('2')),
              title: Text(_playerNameFor(2)),
            ),
            if (_players.length >= 2) ...[
              const Divider(),
              const Text(
                'Begge spillere åbner nu automatisk opstillingen. Når begge har trykket KLAR, gemmes hærene på serveren.',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
