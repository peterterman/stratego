import 'package:flutter/material.dart';

import '../models/game_piece.dart';
import '../logic/battle_logic.dart';

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

  @override
  void initState() {
    super.initState();

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

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  String pieceImage(GamePiece piece) {
    if (piece.isPlayer) {
      return 'assets/images/blaa_${piece.type}.png';
    }
    return 'assets/images/roed_${piece.type}.png';
  }

  String pieceName(String type) {
    switch (type) {
      case 'marshal':
        return 'Marskal';
      case 'general':
        return 'General';
      case 'oberst':
        return 'Oberst';
      case 'major':
        return 'Major';
      case 'kaptajn':
        return 'Kaptajn';
      case 'lojtnant':
        return 'Løjtnant';
      case 'sergent':
        return 'Sergent';
      case 'minor':
        return 'Minør';
      case 'spejder':
        return 'Spejder';
      case 'spion':
        return 'Spion';
      case 'bombe':
        return 'Bombe';
      case 'flag':
        return 'Fane';
      default:
        return type;
    }
  }

  String resultText() {
    final attacker = widget.attacker;
    final defender = widget.defender;
    final result = widget.result;

    if (result == BattleResult.capturedFlag) {
      return 'Fanen er erobret';
    }

    if (defender.type == 'bombe') {
      if (attacker.type == 'minor') {
        return 'Minør desarmerer Bombe';
      }
      return 'Bombe stopper ${pieceName(attacker.type)}';
    }

    if (attacker.type == 'spion' &&
        defender.type == 'marshal' &&
        result == BattleResult.attackerWins) {
      return 'Spion dræber Marskal';
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
