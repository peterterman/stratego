import 'package:flutter/material.dart';

import '../models/game_piece.dart';
import '../services/game_variant_service.dart';

class PieceWidget extends StatefulWidget {
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
  State<PieceWidget> createState() => _PieceWidgetState();
}

class _PieceWidgetState extends State<PieceWidget> {
  GameVariant _variant = GameVariant.eighteenTwelve;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadVariant();
  }

  Future<void> _loadVariant() async {
    final variant = await GameVariantService.getVariant();

    if (!mounted) return;

    setState(() {
      _variant = variant;
      _loaded = true;
    });
  }

  String _imagePath() {
    final hidden = !widget.piece.isPlayer && !widget.showRedOpen;

    return widget.piece.imageForVariant(_variant, hidden: hidden);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const SizedBox.expand();
    }

    final image = _imagePath();

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          image,
          fit: BoxFit.fill,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('IMAGE ERROR: $image');
            debugPrint('$error');

            return Container(
              color: Colors.black54,
              child: const Center(
                child: Text(
                  'X',
                  style: TextStyle(
                    color: Colors.yellow,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
        if (widget.isSelected)
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.greenAccent, width: 3),
            ),
          ),
      ],
    );
  }
}
