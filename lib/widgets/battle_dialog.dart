import 'package:flutter/material.dart';

import '../models/game_piece.dart';
import '../logic/battle_logic.dart';
import '../services/game_variant_service.dart';

class BattleDialog extends StatefulWidget {
  final GamePiece attacker;
  final GamePiece defender;
  final BattleResult result;

  const BattleDialog({
    super.key,
    required this.attacker,
    required this.defender,
    required this.result,
  });

  @override
  State<BattleDialog> createState() => _BattleDialogState();
}

class _BattleDialogState extends State<BattleDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  late final Animation<Offset> topSlide;
  late final Animation<Offset> bottomSlide;

  GameVariant _variant = GameVariant.eighteenTwelve;

  @override
  void initState() {
    super.initState();

    _loadVariant();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    topSlide = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutBack));

    bottomSlide = Tween<Offset>(
      begin: const Offset(0, 1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutBack));

    controller.forward();
  }

  Future<void> _loadVariant() async {
    final variant = await GameVariantService.getVariant();

    if (!mounted) return;

    setState(() {
      _variant = variant;
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  String pieceImage(GamePiece piece) {
    return piece.imageForVariant(_variant, hidden: false);
  }

  String pieceName(String type) {
    return GameVariantService.pieceName(type, _variant);
  }

  String resultText() {
    final attacker = widget.attacker;
    final defender = widget.defender;
    final result = widget.result;

    if (result == BattleResult.capturedFlag) {
      return '${pieceName('flag')} er erobret';
    }

    if (defender.type == 'bombe') {
      if (attacker.type == 'minor') {
        return '${pieceName('minor')} uskadeliggør ${pieceName('bombe')}';
      }
      return '${pieceName('bombe')} stopper ${pieceName(attacker.type)}';
    }

    if (attacker.type == 'spion' &&
        defender.type == 'marshal' &&
        result == BattleResult.attackerWins) {
      return '${pieceName('spion')} slår ${pieceName('marshal')}';
    }

    if (result == BattleResult.bothDie) {
      return '${pieceName(attacker.type)} og ${pieceName(defender.type)} fjernes';
    }

    if (result == BattleResult.attackerWins) {
      return '${pieceName(attacker.type)} slår ${pieceName(defender.type)}';
    }

    return '${pieceName(defender.type)} slår ${pieceName(attacker.type)}';
  }

  @override
  Widget build(BuildContext context) {
    final topPiece = widget.attacker.isPlayer
        ? widget.defender
        : widget.attacker;

    final bottomPiece = widget.attacker.isPlayer
        ? widget.attacker
        : widget.defender;

    return AlertDialog(
      title: const Center(child: Text('KAMP')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SlideTransition(
            position: topSlide,
            child: Image.asset(
              pieceImage(topPiece),
              width: 90,
              height: 120,
              fit: BoxFit.fill,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('BATTLE IMAGE ERROR: ${pieceImage(topPiece)}');
                debugPrint('$error');
                return const SizedBox(
                  width: 90,
                  height: 120,
                  child: Center(child: Text('X')),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'VS',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          SlideTransition(
            position: bottomSlide,
            child: Image.asset(
              pieceImage(bottomPiece),
              width: 90,
              height: 120,
              fit: BoxFit.fill,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('BATTLE IMAGE ERROR: ${pieceImage(bottomPiece)}');
                debugPrint('$error');
                return const SizedBox(
                  width: 90,
                  height: 120,
                  child: Center(child: Text('X')),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          Text(
            resultText(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: const [],
    );
  }
}
