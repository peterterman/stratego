import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/game_piece.dart';
import '../logic/battle_logic.dart';
import '../services/game_dialogs.dart';
import '../widgets/battle_dialog.dart';
import '../widgets/lakes_painter.dart';
import '../services/game_variant_service.dart';
import '../services/multiplayer_service.dart';
import '../services/player_service.dart';
import '../services/sound_service.dart';
import '../services/stats_service.dart';

class MultiplayerBoardScreen extends StatefulWidget {
  final String gameId;
  final String playerToken;
  final int playerNo;
  final int initialVersion;

  const MultiplayerBoardScreen({
    super.key,
    required this.gameId,
    required this.playerToken,
    required this.playerNo,
    required this.initialVersion,
  });

  @override
  State<MultiplayerBoardScreen> createState() =>
      _MultiplayerBoardScreenState();
}

class _MpPiece {
  final int owner;
  final String? type;
  final bool hidden;

  const _MpPiece({required this.owner, this.type, required this.hidden});
}

class _MultiplayerBoardScreenState extends State<MultiplayerBoardScreen> {
  final MultiplayerClient _client = MultiplayerClient();
  Timer? _pollTimer;

  int _version = 0;
  int? _currentPlayer;
  String _phase = 'playing';
  String _status = 'active';
  Map<String, dynamic> _state = const {};
  List<dynamic> _players = const [];
  List<List<_MpPiece?>> _board = List.generate(
    10,
    (_) => List<_MpPiece?>.filled(10, null),
  );

  int? _selectedRow;
  int? _selectedCol;
  List<Point<int>> _legalMoves = const [];
  bool _busy = false;
  String? _errorText;
  int _shownMoveNo = 0;
  GameVariant _variant = GameVariant.eighteenTwelve;
  bool _multiplayerResultRecorded = false;
  bool _reportingMultiplayerResult = false;

  bool get _isMyTurn =>
      _phase == 'playing' && _currentPlayer == widget.playerNo;

  @override
  void initState() {
    super.initState();
    _version = widget.initialVersion;
    _loadInitialState();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _client.close();
    super.dispose();
  }

  Future<void> _loadInitialState() async {
    await _pollState();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _pollState(),
    );
  }

  Future<void> _pollState() async {
    if (_busy) return;
    try {
      final response = await _client.getState(
        gameId: widget.gameId,
        playerToken: widget.playerToken,
      );
      if (!mounted) return;
      _applyState(response);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorText = 'Kunne ikke hente spillet: $e');
    }
  }

  void _applyState(MultiplayerState response) {
    final variantText = (response.state['variant'] ?? '1812').toString();
    final nextVariant = variantText == 'classic'
        ? GameVariant.classic
        : GameVariant.eighteenTwelve;
    final parsedBoard = _parseBoard(response.state['board']);
    final lastMove = (response.state['last_move'] as Map?)
        ?.cast<String, dynamic>();

    setState(() {
      _version = response.version;
      _currentPlayer = response.currentPlayer;
      _phase = response.phase;
      _status = response.status;
      _state = response.state;
      _players = response.players;
      _variant = nextVariant;
      _board = parsedBoard;
      _errorText = null;
      if (!_isMyTurn) _clearSelection();
    });

    if (lastMove != null) {
      final no = (lastMove['no'] as num? ?? 0).toInt();
      if (no > _shownMoveNo) {
        _shownMoveNo = no;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showMoveResult(lastMove);
        });
      }
    }

    final statePhase = (response.state['phase'] ?? '').toString();
    final isFinished =
        response.phase == 'finished' ||
        response.status == 'finished' ||
        statePhase == 'finished' ||
        response.state['winner'] != null;

    if (isFinished) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _reportMultiplayerResultIfNeeded();
      });
    }
  }

  List<List<_MpPiece?>> _parseBoard(dynamic raw) {
    final result = List.generate(10, (_) => List<_MpPiece?>.filled(10, null));
    if (raw is! List) return result;
    for (var r = 0; r < min(10, raw.length); r++) {
      final row = raw[r];
      if (row is! List) continue;
      for (var c = 0; c < min(10, row.length); c++) {
        final item = row[c];
        if (item is! Map) continue;
        final map = item.cast<String, dynamic>();
        result[r][c] = _MpPiece(
          owner: (map['owner'] as num? ?? 0).toInt(),
          type: map['type']?.toString(),
          hidden: map['hidden'] == true,
        );
      }
    }
    return result;
  }

  Point<int> _displayToServer(int row, int col) {
    if (widget.playerNo == 1) return Point(row, col);
    return Point(9 - row, 9 - col);
  }

  Point<int> _serverToDisplay(int row, int col) {
    if (widget.playerNo == 1) return Point(row, col);
    return Point(9 - row, 9 - col);
  }

  _MpPiece? _pieceAtDisplay(int row, int col) {
    final p = _displayToServer(row, col);
    return _board[p.x][p.y];
  }

  bool _isLake(int displayRow, int displayCol) {
    if (_variant == GameVariant.eighteenTwelve) return false;
    final p = _displayToServer(displayRow, displayCol);
    return (p.x == 4 || p.x == 5) &&
        (p.y == 2 || p.y == 3 || p.y == 6 || p.y == 7);
  }

  void _selectPiece(int row, int col) {
    if (!_isMyTurn || _busy || _phase != 'playing') return;
    final piece = _pieceAtDisplay(row, col);
    if (piece == null || piece.owner != widget.playerNo) return;
    if (piece.type == 'bombe' || piece.type == 'flag') return;

    final moves = _findLegalMoves(row, col, piece);
    setState(() {
      _selectedRow = row;
      _selectedCol = col;
      _legalMoves = moves;
    });
  }

  List<Point<int>> _findLegalMoves(int row, int col, _MpPiece piece) {
    final result = <Point<int>>[];
    const directions = [Point(-1, 0), Point(1, 0), Point(0, -1), Point(0, 1)];
    final maxSteps = piece.type == 'spejder' ? 9 : 1;

    for (final d in directions) {
      for (var step = 1; step <= maxSteps; step++) {
        final r = row + d.x * step;
        final c = col + d.y * step;
        if (r < 0 || r >= 10 || c < 0 || c >= 10 || _isLake(r, c)) break;
        final target = _pieceAtDisplay(r, c);
        if (target == null) {
          result.add(Point(r, c));
          continue;
        }
        if (target.owner != widget.playerNo) result.add(Point(r, c));
        break;
      }
    }
    return result;
  }

  bool _isLegal(int row, int col) =>
      _legalMoves.any((p) => p.x == row && p.y == col);

  void _clearSelection() {
    _selectedRow = null;
    _selectedCol = null;
    _legalMoves = const [];
  }

  Future<void> _moveTo(int row, int col) async {
    if (_selectedRow == null || _selectedCol == null || !_isLegal(row, col)) {
      return;
    }
    final from = _displayToServer(_selectedRow!, _selectedCol!);
    final to = _displayToServer(row, col);

    setState(() {
      _busy = true;
      _errorText = null;
    });
    try {
      final response = await _client.move(
        gameId: widget.gameId,
        playerToken: widget.playerToken,
        version: _version,
        fromRow: from.x,
        fromCol: from.y,
        toRow: to.x,
        toCol: to.y,
      );
      await SoundService.move();
      if (!mounted) return;
      _clearSelection();
      _applyState(response);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorText = e.toString());
      await _pollState();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showMoveResult(Map<String, dynamic> move) async {
    final result = (move['result'] ?? 'move').toString();
    if (result == 'move') return;

    final attackerType = (move['attacker_type'] ?? '').toString();
    final defenderType = (move['defender_type'] ?? '').toString();

    if (result == 'captured_flag') {
      await SoundService.victory();
    } else if (defenderType == 'bombe') {
      // Minør i klassisk Stratego og Ingeniør i 1812 bruger begge
      // den interne type "minor". Når den desarmerer bomben/fælden,
      // skal der ikke afspilles eksplosionslyd.
      if (attackerType == 'minor' && result == 'attacker_wins') {
        await SoundService.sword();
      } else {
        await SoundService.explosion();
      }
    } else {
      await SoundService.sword();
    }
    if (!mounted) return;

    final attackerOwner = (move['player'] as num? ?? 1).toInt();
    final defenderOwner = attackerOwner == 1 ? 2 : 1;

    final attackerPiece = GamePiece(
      type: attackerType,
      isPlayer: attackerOwner == 1,
    );
    final defenderPiece = GamePiece(
      type: defenderType,
      isPlayer: defenderOwner == 1,
    );

    final battleResult = switch (result) {
      'captured_flag' => BattleResult.capturedFlag,
      'attacker_wins' => BattleResult.attackerWins,
      'defender_wins' => BattleResult.defenderWins,
      'both_die' => BattleResult.bothDie,
      _ => BattleResult.bothDie,
    };

    final movedByMe = attackerOwner == widget.playerNo;

    if (movedByMe) {
      // Spilleren, der foretog trækket, ser resultatet kortvarigt.
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => BattleDialog(
          attacker: attackerPiece,
          defender: defenderPiece,
          result: battleResult,
          variant: _variant,
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 1500));

      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } else {
      // Modspilleren skal aktivt bekræfte kampresultatet.
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => BattleDialog(
          attacker: attackerPiece,
          defender: defenderPiece,
          result: battleResult,
          showOkButton: true,
          variant: _variant,
        ),
      );
    }
  }

  Future<void> _reportMultiplayerResultIfNeeded() async {
    if (_multiplayerResultRecorded || _reportingMultiplayerResult) return;

    final finished =
        _phase == 'finished' ||
        _status == 'finished' ||
        (_state['phase'] ?? '').toString() == 'finished' ||
        _state['winner'] != null;
    if (!finished) return;

    final winnerRaw = _state['winner'];
    final winner = winnerRaw is num
        ? winnerRaw.toInt()
        : int.tryParse(winnerRaw?.toString() ?? '');
    if (winner == null || winner <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Spillet er slut, men serveren sendte ingen gyldig vinder.',
            ),
          ),
        );
      }
      return;
    }

    _reportingMultiplayerResult = true;

    final won = winner == widget.playerNo;
    final reason = (_state['win_reason'] ?? '').toString().toLowerCase();

    String winType = '';
    if (won && reason == 'flag') {
      winType = 'flag';
    } else if (won &&
        (reason == 'block' ||
            reason == 'blocked' ||
            reason == 'no_moves' ||
            reason == 'no_legal_moves')) {
      winType = 'block';
    }

    try {
      final serverPlayer = await PlayerService.reportMultiplayerResult(
        gameId: widget.gameId,
        won: won,
        winType: winType,
      );

      if (serverPlayer == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Kunne ikke registrere multiplayerresultatet på leaderboard.',
              ),
            ),
          );
        }
        // Behold false, så næste polling kan prøve igen.
        return;
      }

      await StatsService.syncFromServerPlayer(serverPlayer);
      _multiplayerResultRecorded = true;

      if (mounted) {
        final deltaText = won ? '+20' : '-15';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              won
                  ? 'Multiplayersejr registreret: $deltaText point'
                  : 'Multiplayernederlag registreret: $deltaText point',
            ),
          ),
        );
      }
    } finally {
      _reportingMultiplayerResult = false;
    }
  }

  Future<void> _resign() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Opgiv spillet?'),
        content: const Text('Modspilleren bliver registreret som vinder.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Nej')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Opgiv')),
        ],
      ),
    );
    if (yes != true) return;
    try {
      final response = await _client.resign(
        gameId: widget.gameId,
        playerToken: widget.playerToken,
        version: _version,
      );
      if (mounted) _applyState(response);
    } catch (e) {
      if (mounted) setState(() => _errorText = e.toString());
    }
  }

  String _playerName(int no) {
    for (final item in _players) {
      if (item is Map && (item['player_no'] as num? ?? 0).toInt() == no) {
        return (item['player_name'] ?? 'Spiller $no').toString();
      }
    }
    return 'Spiller $no';
  }

  Widget _pieceWidget(_MpPiece piece) {
    final own = piece.owner == widget.playerNo;
    final hidden = !own || piece.hidden;
    final type = piece.type ?? 'flag';

    // Bagsiderne ligger fælles i assets/images og ikke nødvendigvis
    // i variantmapperne 1812/ og klassisk/.
    final String image;
    if (hidden) {
      image = piece.owner == 1
          ? 'assets/images/blaa_bagside.png'
          : 'assets/images/roed_bagside.png';
    } else {
      final model = GamePiece(type: type, isPlayer: piece.owner == 1);
      image = model.imageForVariant(_variant, hidden: false);
    }

    return Image.asset(
      image,
      fit: BoxFit.fill,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('MULTIPLAYER IMAGE ERROR: $image');
        debugPrint('$error');
        return Container(
          color: Colors.black54,
          child: const Center(
            child: Text(
              'X',
              style: TextStyle(
                color: Colors.yellow,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final winner = (_state['winner'] as num?)?.toInt();
    final reason = (_state['win_reason'] ?? '').toString();
    final lastMove = (_state['last_move'] as Map?)?.cast<String, dynamic>();
    Point<int>? lastTo;
    if (lastMove?['to'] is Map) {
      final to = (lastMove!['to'] as Map).cast<String, dynamic>();
      lastTo = _serverToDisplay(
        (to['row'] as num? ?? -1).toInt(),
        (to['col'] as num? ?? -1).toInt(),
      );
    }

    final statusText = _phase == 'finished'
        ? winner == widget.playerNo
            ? 'Du vandt${reason == 'flag' ? ' – fanen blev erobret' : ''}!'
            : 'Du tabte.'
        : _isMyTurn
            ? 'Din tur – du spiller ${widget.playerNo == 1 ? 'blå' : 'rød'}'
            : 'Venter på ${_playerName(_currentPlayer ?? 0)}';

    return Scaffold(
      backgroundColor: const Color(0xFF06420B),
      appBar: AppBar(
        title: Text('${GameVariantService.title(_variant)} – Multiplayer'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _busy ? null : _pollState, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: _phase == 'playing' ? _resign : null, icon: const Icon(Icons.flag)),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                statusText,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth - 8;
                  final height = min(constraints.maxHeight, width * 1.4);
                  return Center(
                    child: SizedBox(
                      width: width,
                      height: height,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 3),
                        ),
                        child: Stack(
                          children: [
                            if (_variant == GameVariant.classic)
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: LakesPainter(),
                                ),
                              ),
                            GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: 100,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 10,
                                childAspectRatio: 1 / 1.4,
                              ),
                              itemBuilder: (context, index) {
                                final row = index ~/ 10;
                                final col = index % 10;
                                final piece = _pieceAtDisplay(row, col);
                                final selected =
                                    row == _selectedRow && col == _selectedCol;
                                final legal = _isLegal(row, col);
                                final isLast =
                                    lastTo?.x == row && lastTo?.y == col;

                                return GestureDetector(
                                  onTap: () {
                                    if (_isLake(row, col)) return;

                                    if (legal) {
                                      _moveTo(row, col);
                                    } else {
                                      _selectPiece(row, col);
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _isLake(row, col)
                                          ? Colors.transparent
                                          : const Color(0xFF8B0000),
                                      border: Border.all(
                                        color: selected
                                            ? Colors.greenAccent
                                            : isLast
                                                ? Colors.yellow
                                                : Colors.grey,
                                        width: selected || isLast ? 3 : 0.6,
                                      ),
                                    ),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        if (piece != null) _pieceWidget(piece),
                                        if (legal)
                                          Center(
                                            child: Container(
                                              width: 12,
                                              height: 12,
                                              decoration: const BoxDecoration(
                                                color: Colors.greenAccent,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_errorText != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(_errorText!, style: const TextStyle(color: Colors.yellow)),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
              child: Text(
                '${_playerName(1)} (blå)  mod  ${_playerName(2)} (rød)',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
