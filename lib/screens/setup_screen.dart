import 'package:flutter/material.dart';
import '../logic/board_setup.dart';
import '../models/game_piece.dart';
import '../services/game_variant_service.dart';
import 'board_screen.dart';
import 'dart:math';

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

  GameVariant _variant = GameVariant.eighteenTwelve;
  bool _variantLoaded = false;

  @override
  void initState() {
    super.initState();
    resetSetup();
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
          '${GameVariantService.title(_variant)} - Manuel opstilling',
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 4),

          const Text(
            'Placér blå hær',
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
                    onTap: () => selectPiece(piece),
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
                    onPressed: automaticSetup,
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
                    onPressed: () {
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
