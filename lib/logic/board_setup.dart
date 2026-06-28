import 'dart:math';
import '../models/game_piece.dart';

class BoardSetup {
  static void setupPieces({
    required List<List<GamePiece?>> board,
    required int cols,
  }) {
    final random = Random();

    final playerArmy = createArmy(true);
    final computerArmy = createArmy(false);

    setupArmyWithRules(
      board: board,
      army: computerArmy,
      isPlayer: false,
      startRow: 0,
      endRow: 3,
      cols: cols,
      random: random,
    );

    setupArmyWithRules(
      board: board,
      army: playerArmy,
      isPlayer: true,
      startRow: 6,
      endRow: 9,
      cols: cols,
      random: random,
    );
  }

  static void setupRandomRedFromPlayerSetup({
    required List<List<GamePiece?>> board,
    required List<List<GamePiece?>> playerSetup,
  }) {
    final random = Random();

    final redPieces = <GamePiece>[];

    // Kopiér de samme briktyper som blå har valgt
    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 10; col++) {
        final piece = playerSetup[row][col];

        if (piece != null) {
          redPieces.add(GamePiece(type: piece.type, isPlayer: false));
        }
      }
    }

    // Hvis alle 40 brikker er med, skal rød følge opstillingsreglerne
    if (redPieces.length == 40) {
      setupArmyWithRules(
        board: board,
        army: redPieces,
        isPlayer: false,
        startRow: 0,
        endRow: 3,
        cols: 10,
        random: random,
      );

      _removeBombsFromFrontLakeSide(
        board: board,
        isPlayer: false,
        startRow: 0,
        endRow: 3,
      );

      return;
    }

    // Hvis der spilles med færre brikker, opstilles rød blot tilfældigt
    final positions = <Point<int>>[];

    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 10; col++) {
        positions.add(Point(row, col));
      }
    }

    positions.shuffle(random);
    redPieces.shuffle(random);

    for (int i = 0; i < redPieces.length && i < positions.length; i++) {
      final pos = positions[i];
      board[pos.x][pos.y] = redPieces[i];
    }
  }

  static List<GamePiece> createArmy(bool isPlayer) {
    final types = <String>[
      'flag',
      'bombe',
      'bombe',
      'bombe',
      'bombe',
      'bombe',
      'bombe',
      'spion',
      'spejder',
      'spejder',
      'spejder',
      'spejder',
      'spejder',
      'spejder',
      'spejder',
      'spejder',
      'minor',
      'minor',
      'minor',
      'minor',
      'minor',
      'sergent',
      'sergent',
      'sergent',
      'sergent',
      'lojtnant',
      'lojtnant',
      'lojtnant',
      'lojtnant',
      'kaptajn',
      'kaptajn',
      'kaptajn',
      'kaptajn',
      'major',
      'major',
      'major',
      'oberst',
      'oberst',
      'general',
      'marshal',
    ];

    return types.map((t) => GamePiece(type: t, isPlayer: isPlayer)).toList();
  }

  static void setupArmyWithRules({
    required List<List<GamePiece?>> board,
    required List<GamePiece> army,
    required bool isPlayer,
    required int startRow,
    required int endRow,
    required int cols,
    required Random random,
  }) {
    final positions = <Point<int>>[];

    for (int row = startRow; row <= endRow; row++) {
      for (int col = 0; col < cols; col++) {
        board[row][col] = null;
        positions.add(Point(row, col));
      }
    }

    final backRow = isPlayer ? endRow : startRow;
    final frontRow = isPlayer ? startRow : endRow;

    final flagCol = 1 + random.nextInt(8);

    final flag = army.firstWhere((p) => p.type == 'flag');
    board[backRow][flagCol] = flag;
    army.remove(flag);

    final frontOfFlagRow = isPlayer ? backRow - 1 : backRow + 1;

    final fixedBombs = <Point<int>>[
      Point(backRow, flagCol - 1),
      Point(backRow, flagCol + 1),
      Point(frontOfFlagRow, flagCol),
    ];

    for (final pos in fixedBombs) {
      final bomb = army.firstWhere((p) => p.type == 'bombe');
      board[pos.x][pos.y] = bomb;
      army.remove(bomb);
    }

    final frontPositions =
        positions
            .where((p) => p.x == frontRow && board[p.x][p.y] == null)
            .toList()
          ..shuffle(random);

    int scoutsInFront = 0;

    for (final pos in frontPositions) {
      final index = army.indexWhere((p) {
        if (p.type == 'bombe' || p.type == 'minor' || p.type == 'spion') {
          return false;
        }

        if (p.type == 'spejder' && scoutsInFront >= 2) {
          return false;
        }

        return true;
      });

      final piece = army.removeAt(index);

      if (piece.type == 'spejder') {
        scoutsInFront++;
      }

      board[pos.x][pos.y] = piece;
    }

    final restPositions =
        positions.where((p) => board[p.x][p.y] == null).toList()
          ..shuffle(random);

    army.shuffle(random);

    for (int i = 0; i < restPositions.length; i++) {
      final pos = restPositions[i];
      board[pos.x][pos.y] = army[i];
    }

    _repairImportantPieces(board, startRow, endRow);

    _removeBombsFromFrontLakeSide(
      board: board,
      isPlayer: isPlayer,
      startRow: startRow,
      endRow: endRow,
    );
  }

  static void _repairImportantPieces(
    List<List<GamePiece?>> board,
    int startRow,
    int endRow,
  ) {
    var changed = true;
    var safetyCounter = 0;

    while (changed && safetyCounter < 100) {
      changed = false;
      safetyCounter++;

      for (int row = startRow; row <= endRow; row++) {
        for (int col = 0; col < 10; col++) {
          final piece = board[row][col];

          if (piece == null) continue;

          // Bomber og fane må gerne stå fast.
          if (piece.type == 'bombe' || piece.type == 'flag') continue;

          // Alle bevægelige brikker skal have mindst én vej ud.
          if (!_isBlockedByBombs(board, row, col)) continue;

          final swapPosition = _findSafeSwapPosition(
            board,
            startRow,
            endRow,
            row,
            col,
          );

          if (swapPosition == null) continue;

          final temp = board[swapPosition.x][swapPosition.y];
          board[swapPosition.x][swapPosition.y] = board[row][col];
          board[row][col] = temp;

          changed = true;
        }
      }
    }
  }

  static Point<int>? _findSafeSwapPosition(
    List<List<GamePiece?>> board,
    int startRow,
    int endRow,
    int trappedRow,
    int trappedCol,
  ) {
    for (int row = startRow; row <= endRow; row++) {
      for (int col = 0; col < 10; col++) {
        if (row == trappedRow && col == trappedCol) continue;

        final piece = board[row][col];

        if (piece == null) continue;
        if (piece.type == 'bombe') continue;
        if (piece.type == 'flag') continue;

        // Prøv bytte midlertidigt
        final trappedPiece = board[trappedRow][trappedCol];

        board[trappedRow][trappedCol] = piece;
        board[row][col] = trappedPiece;

        final trappedIsNowFree = !_isBlockedByBombs(board, row, col);

        // Byt tilbage
        board[row][col] = piece;
        board[trappedRow][trappedCol] = trappedPiece;

        if (trappedIsNowFree) {
          return Point(row, col);
        }
      }
    }

    return null;
  }

  static void _removeBombsFromFrontLakeSide({
    required List<List<GamePiece?>> board,
    required bool isPlayer,
    required int startRow,
    required int endRow,
  }) {
    final frontRow = isPlayer ? startRow : endRow;

    // Felter i forreste række ved søerne
    const forbiddenCols = [2, 3, 6, 7];

    for (final col in forbiddenCols) {
      final piece = board[frontRow][col];

      if (piece == null) continue;
      if (piece.type != 'bombe') continue;

      final swap = _findNonBombSwapPosition(
        board: board,
        startRow: startRow,
        endRow: endRow,
        forbiddenRow: frontRow,
        forbiddenCol: col,
      );

      if (swap == null) continue;

      final temp = board[swap.x][swap.y];
      board[swap.x][swap.y] = board[frontRow][col];
      board[frontRow][col] = temp;
    }
  }

  static Point<int>? _findNonBombSwapPosition({
    required List<List<GamePiece?>> board,
    required int startRow,
    required int endRow,
    required int forbiddenRow,
    required int forbiddenCol,
  }) {
    for (int row = startRow; row <= endRow; row++) {
      for (int col = 0; col < 10; col++) {
        if (row == forbiddenRow && col == forbiddenCol) continue;

        final piece = board[row][col];

        if (piece == null) continue;
        if (piece.type == 'bombe') continue;
        if (piece.type == 'flag') continue;

        return Point(row, col);
      }
    }

    return null;
  }

  static void setupTestPieces({required List<List<GamePiece?>> board}) {
    for (int r = 0; r < board.length; r++) {
      for (int c = 0; c < board[r].length; c++) {
        board[r][c] = null;
      }
    }

    // Rød hær
    board[0][0] = GamePiece(type: 'marshal', isPlayer: false);
    board[0][1] = GamePiece(type: 'general', isPlayer: false);
    board[0][2] = GamePiece(type: 'lojtnant', isPlayer: false);
    board[0][3] = GamePiece(type: 'major', isPlayer: false);
    board[0][4] = GamePiece(type: 'spion', isPlayer: false);

    board[1][0] = GamePiece(type: 'sergent', isPlayer: false);
    board[1][1] = GamePiece(type: 'flag', isPlayer: false);
    board[1][2] = GamePiece(type: 'kaptajn', isPlayer: false);
    board[1][3] = GamePiece(type: 'spejder', isPlayer: false);
    board[1][4] = GamePiece(type: 'minor', isPlayer: false);

    // Blå hær
    board[8][5] = GamePiece(type: 'spion', isPlayer: true);
    board[8][6] = GamePiece(type: 'major', isPlayer: true);
    board[8][7] = GamePiece(type: 'lojtnant', isPlayer: true);
    board[8][8] = GamePiece(type: 'general', isPlayer: true);
    board[8][9] = GamePiece(type: 'marshal', isPlayer: true);

    board[9][5] = GamePiece(type: 'minor', isPlayer: true);
    board[9][6] = GamePiece(type: 'spejder', isPlayer: true);
    board[9][7] = GamePiece(type: 'kaptajn', isPlayer: true);
    board[9][8] = GamePiece(type: 'flag', isPlayer: true);
    board[9][9] = GamePiece(type: 'sergent', isPlayer: true);
  }

  static bool _isBlockedByBombs(
    List<List<GamePiece?>> board,
    int row,
    int col,
  ) {
    const directions = [Point(-1, 0), Point(1, 0), Point(0, -1), Point(0, 1)];

    var openDirections = 0;

    for (final d in directions) {
      final r = row + d.x;
      final c = col + d.y;

      if (r < 0 || r >= board.length) continue;
      if (c < 0 || c >= board[r].length) continue;

      final piece = board[r][c];

      if (piece == null) {
        openDirections++;
        continue;
      }

      if (piece.type != 'bombe' && piece.type != 'flag') {
        openDirections++;
      }
    }

    return openDirections == 0;
  }
}
