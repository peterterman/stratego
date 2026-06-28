import 'dart:math';
import 'package:flutter/material.dart';

import '../models/game_piece.dart';
import 'lakes_painter.dart';
import 'piece_widget.dart';

class GameBoard extends StatelessWidget {
  final List<List<GamePiece?>> board;
  final int? selectedRow;
  final int? selectedCol;
  final int? computerToRow;
  final int? computerToCol;
  final List<Point<int>> legalMoves;
  final bool Function(int row, int col) isLake;
  final bool Function(int row, int col) isLegalMoveCell;
  final void Function(int row, int col) onSelectPiece;
  final void Function(int row, int col) onMovePiece;

  const GameBoard({
    super.key,
    required this.board,
    required this.selectedRow,
    required this.selectedCol,
    required this.computerToRow,
    required this.computerToCol,
    required this.legalMoves,
    required this.isLake,
    required this.isLegalMoveCell,
    required this.onSelectPiece,
    required this.onMovePiece,
  });

  static const int rows = 10;
  static const int cols = 10;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final boardWidth = screen.width - 10;
    final boardHeight = boardWidth * 1.4;

    return Center(
      child: SizedBox(
        width: boardWidth,
        height: boardHeight,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 3),
          ),
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: LakesPainter())),
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: rows * cols,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  childAspectRatio: 1 / 1.4,
                ),
                itemBuilder: (context, index) {
                  final row = index ~/ cols;
                  final col = index % cols;
                  final piece = board[row][col];

                  return GestureDetector(
                    onTap: () {
                      if (isLake(row, col)) return;

                      if (isLegalMoveCell(row, col)) {
                        onMovePiece(row, col);
                      } else {
                        onSelectPiece(row, col);
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isLake(row, col)
                            ? Colors.transparent
                            : const Color(0xFF8B0000),
                        border: Border.all(color: Colors.grey, width: 0.6),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (piece != null)
                            PieceWidget(
                              piece: piece,
                              isSelected:
                                  selectedRow == row && selectedCol == col,
                              showRedOpen: false,
                            ),
                          if (row == computerToRow && col == computerToCol)
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.yellow,
                                  width: 3,
                                ),
                              ),
                            ),
                          if (isLegalMoveCell(row, col))
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
  }
}
