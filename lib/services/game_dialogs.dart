import 'package:flutter/material.dart';

import '../models/game_piece.dart';
import '../logic/battle_logic.dart';
import '../widgets/battle_dialog.dart';

class GameDialogs {
  static Future<void> showBattlePopup({
    required BuildContext context,
    required GamePiece attacker,
    required GamePiece defender,
    required BattleResult result,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          BattleDialog(attacker: attacker, defender: defender, result: result),
    );

    await Future.delayed(const Duration(milliseconds: 1500));

    if (context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  static Future<void> showWinByFlag(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Du vandt!'),
        content: const Text('Du har erobret fjendens fane.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static Future<void> showLossByFlag(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Du tabte!'),
        content: const Text('Computeren har erobret din fane.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static Future<void> showWinByBlockedRed(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        title: const Text('Sejr'),
        content: const Text(
          'Rød hær har ingen flytbare brikker tilbage.\n\nBlå hær vinder.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static Future<void> showLossByBlockedBlue(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        title: const Text('Nederlag'),
        content: const Text(
          'Blå hær har ingen flytbare brikker tilbage.\n\nRød hær vinder.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
