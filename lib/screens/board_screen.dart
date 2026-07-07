import 'dart:math';
import 'package:flutter/material.dart';

import '../models/game_piece.dart';
import '../logic/board_setup.dart';
import '../logic/battle_logic.dart';
import '../services/sound_service.dart';
import '../logic/computer_logic.dart';
import '../services/stats_service.dart';
import '../logic/move_logic.dart';
import '../services/game_dialogs.dart';
import '../widgets/game_board.dart';
import '../services/player_service.dart';
import '../services/game_variant_service.dart';

class BoardScreen extends StatefulWidget {
  final List<List<GamePiece?>>? playerSetup;

  const BoardScreen({super.key, this.playerSetup});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  static const int rows = 10;
  static const int cols = 10;
  GameVariant _variant = GameVariant.eighteenTwelve;
  bool _variantLoaded = false;
  bool playerTurn = true;
  bool gameOver = false;
  bool statsRecorded = false;

  int? computerToRow;
  int? computerToCol;

  String statusText = 'Din tur';

  int? selectedRow;
  int? selectedCol;
  List<Point<int>> legalMoves = [];

  final List<List<GamePiece?>> board = List.generate(
    rows,
    (_) => List.generate(cols, (_) => null),
  );

  @override
  void initState() {
    super.initState();
    setupPieces();
    _registerPlayer();
    _loadVariant();
  }

  Future<void> _loadVariant() async {
    final variant = await GameVariantService.getVariant();

    if (!mounted) return;

    setState(() {
      _variant = variant;
      _variantLoaded = true;
    });
  }

  bool isLake(int row, int col) {
    if (_variant == GameVariant.eighteenTwelve) {
      return false;
    }

    return (row == 4 || row == 5) &&
        (col == 2 || col == 3 || col == 6 || col == 7);
  }

  Future<void> _registerPlayer() async {
    await PlayerService.registerOnline();
  }

  Future<void> registerWinOnce(bool flagWin) async {
    if (statsRecorded) return;

    statsRecorded = true;

    final serverPlayer = await PlayerService.reportWin(flagWin: flagWin);

    if (serverPlayer != null) {
      await StatsService.syncFromServerPlayer(serverPlayer);
    } else {
      await StatsService.registerWinLocal(flagWin: flagWin);
    }
  }

  Future<void> registerLossOnce() async {
    if (statsRecorded) return;

    statsRecorded = true;

    final serverPlayer = await PlayerService.reportLoss();

    if (serverPlayer != null) {
      await StatsService.syncFromServerPlayer(serverPlayer);
    } else {
      await StatsService.registerLossLocal();
    }
  }

  void setupPieces() {
    if (widget.playerSetup != null) {
      for (int row = 0; row < 4; row++) {
        for (int col = 0; col < cols; col++) {
          board[row + 6][col] = widget.playerSetup![row][col];
        }
      }

      BoardSetup.setupRandomRedFromPlayerSetup(
        board: board,
        playerSetup: widget.playerSetup!,
      );

      return;
    }

    BoardSetup.setupTestPieces(board: board);
  }

  bool isLegalMoveCell(int row, int col) {
    return legalMoves.any((p) => p.x == row && p.y == col);
  }

  void clearSelection() {
    selectedRow = null;
    selectedCol = null;
    legalMoves = [];
  }

  void markComputerMove(int row, int col) {
    setState(() {
      computerToRow = row;
      computerToCol = col;
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      setState(() {
        computerToRow = null;
        computerToCol = null;
      });
    });
  }

  void selectPiece(int row, int col) {
    if (!playerTurn) return;
    if (gameOver) return;

    final piece = board[row][col];

    if (piece == null) return;
    if (!piece.isPlayer) return;
    if (piece.type == 'bombe') return;
    if (piece.type == 'flag') return;

    final moves = MoveLogic.findLegalMoves(
      board: board,
      isLake: isLake,
      row: row,
      col: col,
      piece: piece,
    );

    if (moves.isEmpty) {
      setState(() {
        clearSelection();
      });
      return;
    }

    setState(() {
      selectedRow = row;
      selectedCol = col;
      legalMoves = moves;
    });
  }

  Future<void> movePiece(int toRow, int toCol) async {
    if (selectedRow == null || selectedCol == null) return;
    if (!isLegalMoveCell(toRow, toCol)) return;
    if (!playerTurn) return;
    if (gameOver) return;

    final fromRow = selectedRow!;
    final fromCol = selectedCol!;
    final distance = (toRow - fromRow).abs() + (toCol - fromCol).abs();

    if (distance > 1) {
      ComputerLogic.rememberBluePiece(
        row: fromRow,
        col: fromCol,
        type: 'spejder',
      );

      ComputerLogic.moveKnownBluePiece(
        fromRow: fromRow,
        fromCol: fromCol,
        toRow: toRow,
        toCol: toCol,
      );

      ComputerLogic.moveBlueStillness(
        fromRow: fromRow,
        fromCol: fromCol,
        toRow: toRow,
        toCol: toCol,
      );
    }
    final attacker = board[fromRow][fromCol];
    final defender = board[toRow][toCol];

    if (defender != null && !defender.isPlayer) {
      ComputerLogic.rememberRedPiece(
        row: toRow,
        col: toCol,
        type: defender.type,
      );
    }
    if (attacker == null) return;

    if (defender == null) {
      await SoundService.move();

      ComputerLogic.moveKnownBluePiece(
        fromRow: fromRow,
        fromCol: fromCol,
        toRow: toRow,
        toCol: toCol,
      );

      setState(() {
        board[toRow][toCol] = attacker;
        board[fromRow][fromCol] = null;
        clearSelection();
        playerTurn = false;
        statusText = 'Computer tænker...';
      });

      await computerTurn();
      return;
    }

    final result = BattleLogic.resolve(attacker: attacker, defender: defender);

    if (defender.type == 'bombe') {
      if (attacker.type == 'minor') {
        await SoundService.sword();
      } else {
        await SoundService.explosion();
      }
    } else if (result == BattleResult.capturedFlag) {
      await SoundService.victory();
    } else {
      await SoundService.sword();
    }

    await GameDialogs.showBattlePopup(
      context: context,
      attacker: attacker,
      defender: defender,
      result: result,
    );

    setState(() {
      switch (result) {
        case BattleResult.attackerWins:
          board[toRow][toCol] = attacker;
          board[fromRow][fromCol] = null;
          break;
        case BattleResult.defenderWins:
          ComputerLogic.forgetBluePiece(row: fromRow, col: fromCol);
          board[fromRow][fromCol] = null;
          break;
        case BattleResult.bothDie:
          ComputerLogic.forgetBluePiece(row: fromRow, col: fromCol);
          board[fromRow][fromCol] = null;
          board[toRow][toCol] = null;
          break;
        case BattleResult.capturedFlag:
          board[toRow][toCol] = attacker;
          board[fromRow][fromCol] = null;
          gameOver = true;
          statusText = 'Du vandt!';
          break;
      }

      clearSelection();

      if (!gameOver) {
        playerTurn = false;
        statusText = 'Computer tænker...';
      }
    });

    // Blå har taget fanen
    if (result == BattleResult.capturedFlag) {
      await registerWinOnce(true);
    }

    if (result == BattleResult.capturedFlag) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Du vandt!'),
          content: const Text('Du har erobret fjendens fane.'),
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

    await computerTurn();
  }

  Future<void> computerTurn() async {
    ComputerLogic.increaseStillness(board);

    setState(() {
      clearSelection();
    });

    final move = ComputerLogic.findMove(board: board, isLake: isLake);

    if (move == null) {
      if (!mounted) return;

      setState(() {
        gameOver = true;
        statusText = 'Du vandt!';
      });

      await registerWinOnce(false);
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => AlertDialog(
          title: const Text('Sejr'),
          content: const Text(
            'Rød hær har ingen flytbare brikker tilbage.\n\nBlå hær vinder.',
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

    await Future.delayed(const Duration(milliseconds: 500));

    final attacker = board[move.fromRow][move.fromCol];
    final defender = board[move.toRow][move.toCol];

    if (defender != null && defender.isPlayer) {
      ComputerLogic.rememberBluePiece(
        row: move.toRow,
        col: move.toCol,
        type: defender.type,
      );
    }

    if (attacker == null) {
      if (!playerHasLegalMove()) {
        if (!mounted) return;

        setState(() {
          gameOver = true;
          statusText = 'Du tabte!';
        });

        await registerLossOnce();

        await showDialog(
          context: context,
          barrierDismissible: true,
          builder: (_) => AlertDialog(
            title: const Text('Nederlag'),
            content: const Text(
              'Blå hær har ingen flytbare brikker tilbage.\n\nRød hær vinder.',
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

      setState(() {
        playerTurn = true;
        statusText = 'Din tur';
      });
      return;
    }

    if (defender == null) {
      await SoundService.move();

      setState(() {
        board[move.toRow][move.toCol] = attacker;
        board[move.fromRow][move.fromCol] = null;
        playerTurn = true;
        statusText = 'Din tur';
      });

      if (!playerHasLegalMove()) {
        if (!mounted) return;

        setState(() {
          gameOver = true;
          statusText = 'Du tabte!';
        });

        await registerLossOnce();

        await showDialog(
          context: context,
          barrierDismissible: true,
          builder: (_) => AlertDialog(
            title: const Text('Nederlag'),
            content: const Text(
              'Blå hær har ingen flytbare brikker tilbage.\n\nRød hær vinder.',
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

      markComputerMove(move.toRow, move.toCol);
      return;
    }

    final result = BattleLogic.resolve(attacker: attacker, defender: defender);

    if (defender.type == 'bombe') {
      if (attacker.type == 'minor') {
        await SoundService.sword();
      } else {
        await SoundService.explosion();
      }
    } else if (result == BattleResult.capturedFlag) {
      await SoundService.victory();
    } else {
      await SoundService.sword();
    }

    await GameDialogs.showBattlePopup(
      context: context,
      attacker: attacker,
      defender: defender,
      result: result,
    );

    setState(() {
      switch (result) {
        case BattleResult.attackerWins:
          board[move.toRow][move.toCol] = attacker;
          board[move.fromRow][move.fromCol] = null;
          break;
        case BattleResult.defenderWins:
          board[move.fromRow][move.fromCol] = null;
          break;
        case BattleResult.bothDie:
          board[move.fromRow][move.fromCol] = null;
          board[move.toRow][move.toCol] = null;
          break;
        case BattleResult.capturedFlag:
          board[move.toRow][move.toCol] = attacker;
          board[move.fromRow][move.fromCol] = null;
          gameOver = true;
          statusText = 'Du tabte!';
          break;
      }

      if (!gameOver) {
        playerTurn = true;
        statusText = 'Din tur';
      }
    });

    if (result == BattleResult.capturedFlag) {
      await registerLossOnce();
    }

    if (!gameOver && !playerHasLegalMove()) {
      if (!mounted) return;

      setState(() {
        gameOver = true;
        statusText = 'Du tabte!';
      });

      await registerLossOnce();

      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => AlertDialog(
          title: const Text('Nederlag'),
          content: const Text(
            'Blå hær har ingen flytbare brikker tilbage.\n\nRød hær vinder.',
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

    markComputerMove(move.toRow, move.toCol);

    if (result == BattleResult.capturedFlag) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Du tabte!'),
          content: const Text('Computeren har erobret din fane.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  bool playerHasLegalMove() {
    return MoveLogic.playerHasLegalMove(board: board, isLake: isLake);
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final boardWidth = screen.width - 10;

    return Scaffold(
      backgroundColor: const Color(0xFF06420B),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              color: Colors.black54,
              child: Text(
                statusText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '1812',
              style: TextStyle(
                color: Colors.red,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: GameBoard(
                board: board,
                selectedRow: selectedRow,
                selectedCol: selectedCol,
                computerToRow: computerToRow,
                computerToCol: computerToCol,
                legalMoves: legalMoves,
                isLake: isLake,
                isLegalMoveCell: isLegalMoveCell,
                onSelectPiece: selectPiece,
                onMovePiece: movePiece,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('TILBAGE'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
