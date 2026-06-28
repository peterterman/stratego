import 'dart:math';

import '../models/game_piece.dart';

class MoveLogic {
  static bool isInsideBoard(int row, int col) {
    return row >= 0 && row < 10 && col >= 0 && col < 10;
  }

  static bool isLegalTarget({
    required List<List<GamePiece?>> board,
    required bool Function(int row, int col) isLake,
    required int row,
    required int col,
  }) {
    if (!isInsideBoard(row, col)) return false;
    if (isLake(row, col)) return false;

    final target = board[row][col];
    return target == null || !target.isPlayer;
  }

  static List<Point<int>> findLegalMoves({
    required List<List<GamePiece?>> board,
    required bool Function(int row, int col) isLake,
    required int row,
    required int col,
    required GamePiece piece,
  }) {
    if (piece.type == 'bombe' || piece.type == 'flag') return [];

    if (piece.type == 'spejder') {
      return findScoutMoves(board: board, isLake: isLake, row: row, col: col);
    }

    final moves = <Point<int>>[];
    const directions = [Point(-1, 0), Point(1, 0), Point(0, -1), Point(0, 1)];

    for (final d in directions) {
      final r = row + d.x;
      final c = col + d.y;

      if (isLegalTarget(board: board, isLake: isLake, row: r, col: c)) {
        moves.add(Point(r, c));
      }
    }

    return moves;
  }

  static List<Point<int>> findScoutMoves({
    required List<List<GamePiece?>> board,
    required bool Function(int row, int col) isLake,
    required int row,
    required int col,
  }) {
    final moves = <Point<int>>[];
    const directions = [Point(-1, 0), Point(1, 0), Point(0, -1), Point(0, 1)];

    for (final d in directions) {
      var r = row + d.x;
      var c = col + d.y;

      while (isInsideBoard(r, c) && !isLake(r, c)) {
        final target = board[r][c];

        if (target == null) {
          moves.add(Point(r, c));
        } else {
          if (!target.isPlayer) {
            moves.add(Point(r, c));
          }
          break;
        }

        r += d.x;
        c += d.y;
      }
    }

    return moves;
  }

  static bool playerHasLegalMove({
    required List<List<GamePiece?>> board,
    required bool Function(int row, int col) isLake,
  }) {
    for (int row = 0; row < 10; row++) {
      for (int col = 0; col < 10; col++) {
        final piece = board[row][col];

        if (piece == null) continue;
        if (!piece.isPlayer) continue;
        if (piece.type == 'bombe') continue;
        if (piece.type == 'flag') continue;

        final moves = findLegalMoves(
          board: board,
          isLake: isLake,
          row: row,
          col: col,
          piece: piece,
        );

        if (moves.isNotEmpty) return true;
      }
    }

    return false;
  }
}
