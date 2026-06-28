import 'package:flutter/material.dart';
import '../models/game_piece.dart';

class PieceWidget extends StatelessWidget {
  final GamePiece piece;
  final bool isSelected;
  final bool showRedOpen;

  const PieceWidget({
    super.key,
    required this.piece,
    required this.isSelected,
    this.showRedOpen = false,
  });

  @override
  Widget build(BuildContext context) {
    final image = piece.isPlayer
        ? piece.image
        : showRedOpen
        ? 'assets/images/roed_${piece.type}.png'
        : 'assets/images/roed_bagside.png';

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(image, fit: BoxFit.fill),
        if (isSelected)
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.greenAccent, width: 3),
            ),
          ),
      ],
    );
  }
}
