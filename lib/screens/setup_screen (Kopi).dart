import 'package:flutter/material.dart';
import '../logic/board_setup.dart';
import '../models/game_piece.dart';
import 'board_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    resetSetup();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06420B),
      appBar: AppBar(title: const Text('Manuel opstilling')),
      body: Column(
        children: [
          const SizedBox(height: 4),

          const Text(
            'Placér blå hær',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 2),
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
                    onTap: () {
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
                    onLongPress: () => removePiece(row, col),
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
                      child: piece == null
                          ? null
                          : Image.asset(piece.image, fit: BoxFit.fill),
                    ),
                  );
                },
              ),
            ),
          ),

          const Text(
            'Brikker',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          Expanded(
            flex: 4,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(8, 2, 8, 2),
              itemCount: availablePieces.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 10,
                childAspectRatio: 1 / 1.4,
              ),
              itemBuilder: (context, index) {
                final piece = availablePieces[index];
                final isSelected = identical(piece, selectedPiece);

                return GestureDetector(
                  onTap: () => selectPiece(piece),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Colors.yellow : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: Image.asset(piece.image, fit: BoxFit.fill),
                  ),
                );
              },
            ),
          ),

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
                    onPressed: () {
                      setState(() {
                        resetSetup();
                      });
                    },
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('NULSTIL'),
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
                    onPressed: isComplete()
                        ? () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    BoardScreen(playerSetup: setupBoard),
                              ),
                            );
                          }
                        : null,
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('START'),
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
