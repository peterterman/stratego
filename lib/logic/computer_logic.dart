import 'dart:math';

import '../models/game_piece.dart';

class ComputerMove {
  final int fromRow;
  final int fromCol;
  final int toRow;
  final int toCol;

  ComputerMove({
    required this.fromRow,
    required this.fromCol,
    required this.toRow,
    required this.toCol,
  });
}

class ComputerLogic {
  static const int rows = 10;
  static const int cols = 10;
  static ComputerMove? lastMove;
  static final Map<String, int> redPieceUseCount = {};

  // Hukommelse: rød kan huske blå brikker, der er blevet afsløret.
  // Nøgleformat: 'row_col', fx '7_4'
  static final Map<String, int> blueStillness = {};
  static final Map<String, String> knownBluePieces = {};
  static final Map<String, String> knownRedPieces = {};
  static int _pieceValue(String type) {
    switch (type) {
      case 'flag':
        return 10000;
      case 'marshal':
        return 1000;
      case 'general':
        return 700;
      case 'oberst':
        return 500;
      case 'major':
        return 300;
      case 'kaptajn':
        return 200;
      case 'lojtnant':
        return 120;
      case 'sergent':
        return 80;
      case 'minor':
        return 150;
      case 'spejder':
        return 50;
      case 'spion':
        return 100;
      default:
        return 0;
    }
  }

  static void moveBlueStillness({
    required int fromRow,
    required int fromCol,
    required int toRow,
    required int toCol,
  }) {
    blueStillness.remove(_key(fromRow, fromCol));
    blueStillness[_key(toRow, toCol)] = 0;
  }

  static void rememberRedPiece({
    required int row,
    required int col,
    required String type,
  }) {
    knownRedPieces['${row}_$col'] = type;
  }

  static (int, int)? _findRedFlag(List<List<GamePiece?>> board) {
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final piece = board[row][col];

        if (piece == null) continue;
        if (piece.isPlayer) continue;

        if (piece.type == 'flag') {
          return (row, col);
        }
      }
    }

    return null;
  }

  static void increaseStillness(List<List<GamePiece?>> board) {
    for (int row = 6; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final piece = board[row][col];

        if (piece == null) continue;
        if (!piece.isPlayer) continue;

        final key = _key(row, col);
        blueStillness[key] = (blueStillness[key] ?? 0) + 1;
      }
    }
  }

  static ComputerMove? findMove({
    required List<List<GamePiece?>> board,
    required bool Function(int row, int col) isLake,
  }) {
    final moves = <ComputerMove>[];

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final piece = board[row][col];

        if (piece == null) continue;
        if (piece.isPlayer) continue;
        if (piece.type == 'bombe') continue;
        if (piece.type == 'flag') continue;

        final legalTargets = _legalTargets(
          board: board,
          row: row,
          col: col,
          piece: piece,
          isLake: isLake,
        );

        for (final target in legalTargets) {
          moves.add(
            ComputerMove(
              fromRow: row,
              fromCol: col,
              toRow: target.$1,
              toCol: target.$2,
            ),
          );
        }
      }
    }

    if (moves.isEmpty) return null;

    final scoredMoves = <(ComputerMove, int)>[];

    for (final move in moves) {
      int score = 0;

      final attacker = board[move.fromRow][move.fromCol];
      final flagPos = _findRedFlag(board);
      final spyPos = _findRedSpy(board);
      final likelyBlueFlag = _findLikelyBlueFlagTarget();
      final target = board[move.toRow][move.toCol];
      final stillness = blueStillness[_key(move.toRow, move.toCol)] ?? 0;
      final bombNeighbours = _bombNeighbours(board, move.toRow, move.toCol);

      if (attacker == null) continue;

      final attackerKey = _key(move.fromRow, move.fromCol);
      final useCount = redPieceUseCount[attackerKey] ?? 0;

      final hasTarget = target != null && target.isPlayer;
      final isMovingForward = move.toRow > move.fromRow;
      final isMovingBackward = move.toRow < move.fromRow;
      final moveDistance =
          (move.toRow - move.fromRow).abs() + (move.toCol - move.fromCol).abs();

      // Overordnet plan: rød skal have et konkret angrebsmål.
      // Hvis fane er sandsynlig/kendt, bruges den. Ellers angribes blå baglinje.
      final attackTarget = likelyBlueFlag ?? _defaultAttackTarget(move);

      final attackDistanceBefore =
          (move.fromRow - attackTarget.$1).abs() +
          (move.fromCol - attackTarget.$2).abs();

      final attackDistanceAfter =
          (move.toRow - attackTarget.$1).abs() +
          (move.toCol - attackTarget.$2).abs();

      if (!hasTarget) {
        if (attackDistanceAfter < attackDistanceBefore) {
          score += likelyBlueFlag != null ? 650 : 220;
        } else if (attackDistanceAfter > attackDistanceBefore) {
          score -= likelyBlueFlag != null ? 450 : 180;
        }
      }

      // Rød skal især presse ind i blå område.
      if (!hasTarget && move.toRow >= 6) {
        score += 80;
      }

      if (!hasTarget && move.toRow >= 8) {
        score += 180;
      }

      if (!hasTarget && move.toRow == 9) {
        score += 260;
      }

      // Brikroller: gør rød mindre formålsløs.
      if (!hasTarget) {
        switch (attacker.type) {
          case 'minor':
            if (attackDistanceAfter < attackDistanceBefore) {
              score += 160;
            }
            if (stillness > 8) {
              score += 180;
            }
            break;

          case 'spejder':
            if (moveDistance <= 3 &&
                attackDistanceAfter < attackDistanceBefore) {
              score += 120;
            }
            if (moveDistance > 4) {
              score -= 220;
            }
            break;

          case 'marshal':
          case 'general':
          case 'oberst':
          case 'major':
          case 'kaptajn':
            if (attackDistanceAfter < attackDistanceBefore) {
              score += 140;
            }
            break;

          case 'spion':
            // Spionen skal beskyttes og kun bruges taktisk.
            score -= 180;
            break;
        }
      }

      // Beskyt rød spion.
      // Spionen må helst ikke stå ved siden af en blå brik.
      if (attacker.type == 'spion') {
        if (_isNextToBluePiece(board, move.toRow, move.toCol)) {
          score -= 900;
        }

        // Spion skal normalt ikke bruges til almindelig fremrykning.
        if (!hasTarget) {
          score -= 120;
        }

        // Spion må gerne angribe blå marskal.
        if (target != null && target.isPlayer && target.type == 'marshal') {
          score += 1800;
        }
      }

      // Andre røde brikker beskytter spionen.
      if (spyPos != null && attacker.type != 'spion') {
        final beforeSpyDistance =
            (move.fromRow - spyPos.$1).abs() + (move.fromCol - spyPos.$2).abs();

        final afterSpyDistance =
            (move.toRow - spyPos.$1).abs() + (move.toCol - spyPos.$2).abs();

        if (afterSpyDistance < beforeSpyDistance) {
          score += 90;
        }

        if (afterSpyDistance == 1) {
          score += 180;
        }

        if (_blueCanMoveNextToRedSpyAfterMove(board: board, move: move)) {
          score -= 450;
        }
      }
      // Beløn fremrykning
      if (!hasTarget && isMovingForward) {
        score += 80;
      }

      // Straf baglæns bevægelse
      if (!hasTarget && isMovingBackward) {
        score -= 240;
      }

      // Lille straf for tom sideværts bevægelse
      if (!hasTarget && move.toRow == move.fromRow) {
        score -= 140;
      }
      // Straf kun gentagen brug af samme brik,
      // hvis den ikke angriber og ikke rykker frem.
      if (!hasTarget && !isMovingForward) {
        score -= useCount * 120;
      }

      if (attacker.type == 'spejder' && target == null && moveDistance > 3) {
        score -= 150;
      }
      // Vurder angreb ud fra rang i stedet for bare at angribe hovedløst.
      if (target != null && target.isPlayer) {
        final battleScore = _battleScore(attacker, target);
        score += battleScore;

        // Angreb skal være mere målrettede.
        if (battleScore > 0) {
          score += 220;
        }

        // Angreb i blå bagområde er ekstra værd.
        if (move.toRow >= 8) {
          score += 180;
        }

        // Husk blå brik, når den er synlig i en mulig kamp.
        rememberBluePiece(row: move.toRow, col: move.toCol, type: target.type);
      } else {
        // Bevæg dig ned mod spilleren, når feltet er tomt.
        score += move.toRow * 8;
      }

      // Brug også hukommelsen, hvis en blå brik tidligere er afsløret på feltet.
      final rememberedType = knownBluePieces[_key(move.toRow, move.toCol)];
      if (rememberedType != null && target != null && target.isPlayer) {
        final attackerRank = _rank(attacker.type);
        final defenderRank = _rank(rememberedType);

        if (attacker.type == 'spion' && rememberedType == 'marshal') {
          score += 1200;
        } else if (attacker.type == 'minor' && rememberedType == 'bombe') {
          score += 800;
        } else if (attackerRank < defenderRank) {
          continue;
        } else if (attackerRank > defenderRank) {
          score += _pieceValue(rememberedType);
        }
      }

      // Mistanke om bombe eller fane
      if (stillness > 12) {
        if (attacker.type == 'minor') {
          score += 120;
        } else {
          score -= 80;
        }

        // Bageste række er ekstra interessant
        if (move.toRow >= 8) {
          score += 60;
        }
      }

      // Meget stærk fanemistanke
      if (stillness > 20 && move.toRow >= 8) {
        if (attacker.type == 'minor') {
          score += 250;
        } else {
          score += 100;
        }
      }
      if (stillness > 15 && move.toRow >= 8 && bombNeighbours >= 2) {
        if (attacker.type == 'minor') {
          score += 400;
        } else {
          score += 200;
        }
      } // Undgå at gå direkte tilbage til feltet den lige kom fra.
      if (lastMove != null &&
          move.fromRow == lastMove!.toRow &&
          move.fromCol == lastMove!.toCol &&
          move.toRow == lastMove!.fromRow &&
          move.toCol == lastMove!.fromCol) {
        score -= 1000;
      }
      if (flagPos != null) {
        final distanceBefore =
            (move.fromRow - flagPos.$1).abs() +
            (move.fromCol - flagPos.$2).abs();

        final distanceAfter =
            (move.toRow - flagPos.$1).abs() + (move.toCol - flagPos.$2).abs();

        // Straf hvis en forsvarer forlader fanen
        if (distanceBefore <= 2 && distanceAfter > distanceBefore) {
          score -= 150;
        }

        // Lille bonus for at blive tæt på fanen
        if (distanceAfter <= 2) {
          score += 40;
        }
      }
      if (likelyBlueFlag != null) {
        final before =
            (move.fromRow - likelyBlueFlag.$1).abs() +
            (move.fromCol - likelyBlueFlag.$2).abs();

        final after =
            (move.toRow - likelyBlueFlag.$1).abs() +
            (move.toCol - likelyBlueFlag.$2).abs();

        if (after < before) {
          score += 900;
        } else if (after > before) {
          score -= 650;
        }

        if (after <= 3) {
          score += 300;
        }

        if (after <= 2) {
          score += 500;
        }

        if (after == 1) {
          score += 900;
        }

        if (target != null && target.isPlayer) {
          final rememberedType = knownBluePieces[_key(move.toRow, move.toCol)];

          if (target.type == 'flag' || rememberedType == 'flag') {
            score += 20000;
          }
        }
      }
      scoredMoves.add((move, score));
    }

    if (scoredMoves.isEmpty) return null;

    scoredMoves.sort((a, b) => b.$2.compareTo(a.$2));

    final bestScore = scoredMoves.first.$2;

    final bestMoves = scoredMoves
        .where((m) => m.$2 == bestScore)
        .map((m) => m.$1)
        .toList();

    bestMoves.shuffle(Random());

    final chosenMove = bestMoves.first;
    lastMove = chosenMove;
    final chosenKey = _key(chosenMove.toRow, chosenMove.toCol);
    redPieceUseCount[chosenKey] = (redPieceUseCount[chosenKey] ?? 0) + 1;
    return chosenMove;
  }

  static (int, int)? _findRedSpy(List<List<GamePiece?>> board) {
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final piece = board[row][col];

        if (piece == null) continue;
        if (piece.isPlayer) continue;

        if (piece.type == 'spion') {
          return (row, col);
        }
      }
    }

    return null;
  }

  static bool _isNextToBluePiece(
    List<List<GamePiece?>> board,
    int row,
    int col,
  ) {
    const dirs = [(-1, 0), (1, 0), (0, -1), (0, 1)];

    for (final d in dirs) {
      final r = row + d.$1;
      final c = col + d.$2;

      if (!_isInside(r, c)) continue;

      final piece = board[r][c];

      if (piece != null && piece.isPlayer) {
        return true;
      }
    }

    return false;
  }

  static bool _blueCanMoveNextToRedSpyAfterMove({
    required List<List<GamePiece?>> board,
    required ComputerMove move,
  }) {
    final attacker = board[move.fromRow][move.fromCol];
    if (attacker == null) return false;

    final simulated = List.generate(
      rows,
      (r) => List<GamePiece?>.from(board[r]),
    );

    simulated[move.toRow][move.toCol] = attacker;
    simulated[move.fromRow][move.fromCol] = null;

    final spyPos = _findRedSpy(simulated);
    if (spyPos == null) return false;

    const dirs = [(-1, 0), (1, 0), (0, -1), (0, 1)];

    for (final d in dirs) {
      final nearSpyRow = spyPos.$1 + d.$1;
      final nearSpyCol = spyPos.$2 + d.$2;

      if (!_isInside(nearSpyRow, nearSpyCol)) continue;

      final nearPiece = simulated[nearSpyRow][nearSpyCol];

      if (nearPiece != null) continue;

      for (final bd in dirs) {
        final blueRow = nearSpyRow + bd.$1;
        final blueCol = nearSpyCol + bd.$2;

        if (!_isInside(blueRow, blueCol)) continue;

        final bluePiece = simulated[blueRow][blueCol];

        if (bluePiece == null) continue;
        if (!bluePiece.isPlayer) continue;
        if (bluePiece.type == 'bombe') continue;
        if (bluePiece.type == 'flag') continue;

        return true;
      }
    }

    return false;
  }

  static int _bombNeighbours(List<List<GamePiece?>> board, int row, int col) {
    int count = 0;

    const dirs = [(-1, 0), (1, 0), (0, -1), (0, 1)];

    for (final d in dirs) {
      final r = row + d.$1;
      final c = col + d.$2;

      if (!_isInside(r, c)) continue;

      final piece = board[r][c];

      if (piece == null) continue;
      if (!piece.isPlayer) continue;

      final remembered = knownBluePieces[_key(r, c)];

      if (remembered == 'bombe') {
        count++;
      }
    }

    return count;
  }

  static void rememberBluePiece({
    required int row,
    required int col,
    required String type,
  }) {
    knownBluePieces[_key(row, col)] = type;
  }

  static (int, int)? _findLikelyBlueFlagTarget() {
    // Først: hvis rød faktisk kender blå fane.
    for (final entry in knownBluePieces.entries) {
      if (entry.value == 'flag') {
        final parts = entry.key.split('_');
        return (int.parse(parts[0]), int.parse(parts[1]));
      }
    }

    (int, int)? bestPos;
    int bestScore = 0;

    for (final entry in blueStillness.entries) {
      final parts = entry.key.split('_');
      final row = int.parse(parts[0]);
      final col = int.parse(parts[1]);
      final stillness = entry.value;

      int score = stillness;

      // Blå fane er næsten altid i blå bagområde.
      if (row == 9) score += 70;
      if (row == 8) score += 40;
      if (row == 7) score += 15;

      final keyType = knownBluePieces[_key(row, col)];
      if (keyType == 'flag') score += 10000;
      if (keyType == 'bombe') score -= 80;

      if (score > bestScore) {
        bestScore = score;
        bestPos = (row, col);
      }
    }

    // Lavere tærskel, så rød tidligere vælger et mål.
    if (bestScore < 12) return null;
    return bestPos;
  }

  static (int, int) _defaultAttackTarget(ComputerMove move) {
    // Rød skal mod blå baglinje.
    // Brug samme kolonne som brikken, men undgå at sigte direkte ind i sø-kolonnerne.
    var targetCol = move.fromCol;

    if (targetCol == 2 || targetCol == 3) targetCol = 1;
    if (targetCol == 6 || targetCol == 7) targetCol = 8;

    return (9, targetCol);
  }

  static void forgetBluePiece({required int row, required int col}) {
    knownBluePieces.remove(_key(row, col));
  }

  static void moveKnownBluePiece({
    required int fromRow,
    required int fromCol,
    required int toRow,
    required int toCol,
  }) {
    final type = knownBluePieces.remove(_key(fromRow, fromCol));
    if (type != null) {
      knownBluePieces[_key(toRow, toCol)] = type;
    }
  }

  static void clearMemory() {
    blueStillness.clear();
    knownBluePieces.clear();
    knownRedPieces.clear();
    redPieceUseCount.clear();
    lastMove = null;
  }

  static String _key(int row, int col) => '${row}_$col';

  static int _battleScore(GamePiece attacker, GamePiece defender) {
    final myValue = _pieceValue(attacker.type);
    final enemyValue = _pieceValue(defender.type);

    // Fane er altid bedste mål
    if (defender.type == 'flag') {
      return 10000;
    }

    // Bombe: kun minør bør angribe
    if (defender.type == 'bombe') {
      if (attacker.type == 'minor') {
        return 800;
      }
      return -800 - myValue;
    }

    // Spion kan slå marskal, men kun når spionen angriber
    if (attacker.type == 'spion' && defender.type == 'marshal') {
      return 1200;
    }

    final attackerRank = _rank(attacker.type);
    final defenderRank = _rank(defender.type);

    // Angriber vinder
    if (attackerRank > defenderRank) {
      return enemyValue - (myValue ~/ 10);
    }

    // Begge dør
    if (attackerRank == defenderRank) {
      return (enemyValue - myValue) ~/ 2;
    }

    // Angriber taber
    return -(myValue + enemyValue);
  }

  static int _rank(String type) {
    switch (type) {
      case 'marshal':
        return 10;
      case 'general':
        return 9;
      case 'oberst':
        return 8;
      case 'major':
        return 7;
      case 'kaptajn':
        return 6;
      case 'lojtnant':
        return 5;
      case 'sergent':
        return 4;
      case 'minor':
        return 3;
      case 'spejder':
        return 2;
      case 'spion':
        return 1;
      default:
        return 0;
    }
  }

  static List<(int, int)> _legalTargets({
    required List<List<GamePiece?>> board,
    required int row,
    required int col,
    required GamePiece piece,
    required bool Function(int row, int col) isLake,
  }) {
    if (piece.type == 'spejder') {
      return _scoutTargets(board: board, row: row, col: col, isLake: isLake);
    }

    final targets = <(int, int)>[];

    const directions = [(-1, 0), (1, 0), (0, -1), (0, 1)];

    for (final d in directions) {
      final r = row + d.$1;
      final c = col + d.$2;

      if (_isLegalTarget(board, r, c, isLake)) {
        targets.add((r, c));
      }
    }

    return targets;
  }

  static List<(int, int)> _scoutTargets({
    required List<List<GamePiece?>> board,
    required int row,
    required int col,
    required bool Function(int row, int col) isLake,
  }) {
    final targets = <(int, int)>[];

    const directions = [(-1, 0), (1, 0), (0, -1), (0, 1)];

    for (final d in directions) {
      var r = row + d.$1;
      var c = col + d.$2;

      while (_isInside(r, c) && !isLake(r, c)) {
        final target = board[r][c];

        if (target == null) {
          targets.add((r, c));
        } else {
          if (target.isPlayer) {
            targets.add((r, c));
          }
          break;
        }

        r += d.$1;
        c += d.$2;
      }
    }

    return targets;
  }

  static bool _isLegalTarget(
    List<List<GamePiece?>> board,
    int row,
    int col,
    bool Function(int row, int col) isLake,
  ) {
    if (!_isInside(row, col)) return false;
    if (isLake(row, col)) return false;

    final target = board[row][col];

    return target == null || target.isPlayer;
  }

  static bool _isInside(int row, int col) {
    return row >= 0 && row < rows && col >= 0 && col < cols;
  }
}
