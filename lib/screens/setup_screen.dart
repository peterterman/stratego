import 'dart:async';

import 'package:flutter/material.dart';
import '../logic/board_setup.dart';
import '../models/game_piece.dart';
import '../services/game_variant_service.dart';
import '../services/multiplayer_service.dart';
import 'board_screen.dart';
import 'multiplayer_board_screen.dart';
import 'dart:math';

class SetupScreen extends StatefulWidget {
  final bool multiplayer;
  final String? gameId;
  final String? playerToken;
  final int playerNo;
  final int initialVersion;
  final String? multiplayerVariant;

  const SetupScreen({
    super.key,
    this.multiplayer = false,
    this.gameId,
    this.playerToken,
    this.playerNo = 0,
    this.initialVersion = 0,
    this.multiplayerVariant,
  });

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int? selectedBoardRow;
  int? selectedBoardCol;
  static const int rows = 4;
  static const int cols = 10;

  late List<GamePiece> availablePieces;
  late List<List<GamePiece?>> setupBoard;

  GamePiece? selectedPiece;

  GameVariant _variant = GameVariant.eighteenTwelve;
  bool _variantLoaded = false;

  MultiplayerClient? _multiplayerClient;
  Timer? _pollTimer;
  late int _serverVersion;
  bool _submitting = false;
  bool _setupSubmitted = false;
  bool _bothReady = false;
  bool _openingBoard = false;
  String? _multiplayerError;

  @override
  void initState() {
    super.initState();
    resetSetup();
    _serverVersion = widget.initialVersion;
    if (widget.multiplayer) {
      _multiplayerClient = MultiplayerClient();
    }
    _loadVariant();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _multiplayerClient?.close();
    super.dispose();
  }

  Future<void> _loadVariant() async {
    final GameVariant variant;

    if (widget.multiplayer) {
      // Multiplayer-varianten bestemmes af spiller 1 og serveren.
      variant = widget.multiplayerVariant == 'classic'
          ? GameVariant.classic
          : GameVariant.eighteenTwelve;
    } else {
      variant = await GameVariantService.getVariant();
    }

    if (!mounted) return;

    setState(() {
      _variant = variant;
      _variantLoaded = true;
    });
  }

  String _pieceImage(GamePiece piece) {
    return piece.imageForVariant(_variant);
  }

  void resetSetup() {
    availablePieces = BoardSetup.createArmy(true);
    setupBoard = List.generate(rows, (_) => List.generate(cols, (_) => null));
    selectedPiece = null;
  }

  void selectPiece(GamePiece piece) {
    setState(() {
      selectedPiece = piece;
    });
  }

  void placePiece(int row, int col) {
    setState(() {
      // Flyt allerede placeret brik
      if (selectedBoardRow != null && selectedBoardCol != null) {
        if (setupBoard[row][col] == null) {
          setupBoard[row][col] =
              setupBoard[selectedBoardRow!][selectedBoardCol!];
          setupBoard[selectedBoardRow!][selectedBoardCol!] = null;
        }

        selectedBoardRow = null;
        selectedBoardCol = null;
        return;
      }

      // Placér ny brik fra listen
      if (selectedPiece == null) return;
      if (setupBoard[row][col] != null) return;

      setupBoard[row][col] = selectedPiece;
      availablePieces.remove(selectedPiece);
      selectedPiece = null;
    });
  }

  void removePiece(int row, int col) {
    final piece = setupBoard[row][col];
    if (piece == null) return;

    setState(() {
      availablePieces.add(piece);
      setupBoard[row][col] = null;
    });
  }

  bool isComplete() {
    for (final row in setupBoard) {
      for (final piece in row) {
        if (piece == null) return false;
      }
    }
    return true;
  }

  void automaticSetup() {
    final tempBoard = List.generate(
      rows,
      (_) => List.generate(cols, (_) => null as GamePiece?),
    );

    final army = BoardSetup.createArmy(true);

    BoardSetup.setupArmyWithRules(
      board: tempBoard,
      army: army,
      isPlayer: true,
      startRow: 0,
      endRow: 3,
      cols: cols,
      random: Random(),
    );

    setState(() {
      setupBoard = tempBoard;
      availablePieces.clear();
      selectedPiece = null;
      selectedBoardRow = null;
      selectedBoardCol = null;
    });
  }

  bool isValidSetup() {
    var hasFlag = false;
    var hasMovablePiece = false;

    for (final row in setupBoard) {
      for (final piece in row) {
        if (piece == null) continue;

        if (piece.type == 'flag') {
          hasFlag = true;
        }

        if (piece.type != 'flag' && piece.type != 'bombe') {
          hasMovablePiece = true;
        }
      }
    }

    return hasFlag && hasMovablePiece;
  }

  List<Map<String, dynamic>> _serializeSetup() {
    final pieces = <Map<String, dynamic>>[];
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final piece = setupBoard[row][col];
        if (piece == null) continue;
        pieces.add({'row': row, 'col': col, 'type': piece.type});
      }
    }
    return pieces;
  }

  Future<void> _submitMultiplayerSetup() async {
    if (_submitting || _setupSubmitted) return;
    if (!isComplete() || !isValidSetup()) {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Opstillingen er ikke færdig'),
          content: const Text(
            'Alle 40 felter skal være udfyldt, og opstillingen skal indeholde en fane og mindst én bevægelig brik.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final client = _multiplayerClient;
    final gameId = widget.gameId;
    final token = widget.playerToken;
    if (client == null || gameId == null || token == null) return;

    setState(() {
      _submitting = true;
      _multiplayerError = null;
    });

    try {
      bool isVersionConflict(MultiplayerException e) {
        final message = e.message.toLowerCase();
        return e.statusCode == 409 ||
            message.contains('spiltilstanden er ændret') ||
            message.contains('hent state igen') ||
            message.contains('version');
      }

      Future<void> refreshVersion() async {
        final freshState = await client.getState(
          gameId: gameId,
          playerToken: token,
        );
        _serverVersion = freshState.version;
      }

      // Varianten er allerede valgt og gemt af spiller 1 i lobbyen.

      MultiplayerState? state;

      // Flere forsøg er nødvendige, fordi modspilleren kan nå at ændre
      // state igen mellem GET state og POST submit_setup.
      for (var attempt = 0; attempt < 6; attempt++) {
        try {
          state = await client.submitSetup(
            gameId: gameId,
            playerToken: token,
            version: _serverVersion,
            pieces: _serializeSetup(),
          );
          break;
        } on MultiplayerException catch (e) {
          if (!isVersionConflict(e) || attempt == 5) rethrow;

          await refreshVersion();
          await Future<void>.delayed(
            Duration(milliseconds: 150 * (attempt + 1)),
          );
        }
      }

      if (state == null) {
        throw const MultiplayerException(
          'Kunne ikke gemme opstillingen efter flere forsøg.',
        );
      }

      _applyMultiplayerState(state);
      _setupSubmitted = true;
      _startSetupPolling();
    } catch (e) {
      _multiplayerError = e.toString();
    } finally {
      if (!mounted) return;
      setState(() => _submitting = false);
    }
  }

  void _startSetupPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _pollSetupState(),
    );
  }

  Future<void> _pollSetupState() async {
    final client = _multiplayerClient;
    final gameId = widget.gameId;
    final token = widget.playerToken;
    if (client == null || gameId == null || token == null || _submitting) return;

    try {
      final state = await client.getState(gameId: gameId, playerToken: token);
      if (!mounted) return;
      setState(() {
        _applyMultiplayerState(state);
        _multiplayerError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _multiplayerError = 'Kunne ikke hente status: $e');
    }
  }

  void _applyMultiplayerState(MultiplayerState state) {
    _serverVersion = state.version;
    if (state.phase == 'playing') {
      _bothReady = true;
      _pollTimer?.cancel();
      _openMultiplayerBoard();
    }
  }

  void _openMultiplayerBoard() {
    if (_openingBoard || !widget.multiplayer) return;
    final gameId = widget.gameId;
    final token = widget.playerToken;
    if (gameId == null || token == null) return;

    _openingBoard = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MultiplayerBoardScreen(
            gameId: gameId,
            playerToken: token,
            playerNo: widget.playerNo,
            initialVersion: _serverVersion,
          ),
        ),
      );
    });
  }

  Widget _pieceImageWidget(GamePiece piece) {
    final image = _pieceImage(piece);

    return Image.asset(
      image,
      fit: BoxFit.fill,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('SETUP IMAGE ERROR: $image');
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
    if (!_variantLoaded) {
      return const Scaffold(
        backgroundColor: Color(0xFF06420B),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF06420B),
      appBar: AppBar(
        title: Text(
          widget.multiplayer
              ? '${GameVariantService.title(_variant)} - Multiplayer-opstilling'
              : '${GameVariantService.title(_variant)} - Manuel opstilling',
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 4),

          Text(
            widget.multiplayer ? 'Placér din hær' : 'Placér blå hær',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          SizedBox(
            height: MediaQuery.of(context).size.width * 0.56,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: rows * cols,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  childAspectRatio: 1 / 1.4,
                ),
                itemBuilder: (context, index) {
                  final row = index ~/ cols;
                  final col = index % cols;
                  final piece = setupBoard[row][col];

                  final isSelectedBoardPiece =
                      selectedBoardRow == row && selectedBoardCol == col;

                  return GestureDetector(
                    onTap: _setupSubmitted ? null : () {
                      if (setupBoard[row][col] != null &&
                          selectedPiece == null) {
                        setState(() {
                          selectedBoardRow = row;
                          selectedBoardCol = col;
                        });
                      } else {
                        placePiece(row, col);
                      }
                    },
                    onLongPress: _setupSubmitted ? null : () => removePiece(row, col),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B0000),
                        border: Border.all(
                          color: isSelectedBoardPiece
                              ? Colors.yellow
                              : Colors.grey,
                          width: isSelectedBoardPiece ? 3 : 0.6,
                        ),
                      ),
                      child: piece == null ? null : _pieceImageWidget(piece),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'Brikker',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          SizedBox(
            height: MediaQuery.of(context).size.width * 0.56,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: availablePieces.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 10,
                  childAspectRatio: 1 / 1.4,
                ),
                itemBuilder: (context, index) {
                  final piece = availablePieces[index];
                  final isSelected = identical(piece, selectedPiece);

                  return GestureDetector(
                    onTap: _setupSubmitted ? null : () => selectPiece(piece),
                    child: Container(
                      margin: const EdgeInsets.all(1.5),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? Colors.yellow
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: _pieceImageWidget(piece),
                    ),
                  );
                },
              ),
            ),
          ),

          if (widget.multiplayer && (_setupSubmitted || _multiplayerError != null))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Card(
                color: _bothReady ? Colors.lightGreen.shade100 : Colors.amber.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      if (_bothReady)
                        const Text(
                          'Begge spillere er klar. Opstillingerne er gemt, og spillet kan nu kobles på brættet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        )
                      else if (_setupSubmitted)
                        const Text(
                          'Din opstilling er gemt. Venter på modspilleren…',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      if (_multiplayerError != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _multiplayerError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

          const Spacer(),

          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 8,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: _setupSubmitted || _submitting ? null : automaticSetup,
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('AUTOMATISK'),
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 8,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: _submitting || _setupSubmitted
                        ? null
                        : () {
                            if (widget.multiplayer) {
                              _submitMultiplayerSetup();
                              return;
                            }

                            if (!isValidSetup()) {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Ugyldig opstilling'),
                                  content: const Text(
                                    'Du skal mindst have 1 fane og 1 bevægelig brik.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                              return;
                            }

                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BoardScreen(playerSetup: setupBoard),
                              ),
                            );
                          },
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(widget.multiplayer ? 'KLAR' : 'START'),
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 8,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('TILBAGE'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
