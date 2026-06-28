import '../models/game_piece.dart';

enum BattleResult { attackerWins, defenderWins, bothDie, capturedFlag }

class BattleLogic {
  static BattleResult resolve({
    required GamePiece attacker,
    required GamePiece defender,
  }) {
    if (defender.type == 'flag') {
      return BattleResult.capturedFlag;
    }

    if (defender.type == 'bombe') {
      if (attacker.type == 'minor') {
        return BattleResult.attackerWins;
      }
      return BattleResult.defenderWins;
    }

    if (attacker.type == 'spion' && defender.type == 'marshal') {
      return BattleResult.attackerWins;
    }

    final attackerRank = rank(attacker.type);
    final defenderRank = rank(defender.type);

    if (attackerRank > defenderRank) {
      return BattleResult.attackerWins;
    }

    if (attackerRank < defenderRank) {
      return BattleResult.defenderWins;
    }

    return BattleResult.bothDie;
  }

  static int rank(String type) {
    switch (type) {
      case 'marshal':
        return 10;
      case 'general':
        return 9;
      case 'oberst':
        return 8;
      case 'major':
        return 7;
      case 'kaptajn':
        return 6;
      case 'lojtnant':
        return 5;
      case 'sergent':
        return 4;
      case 'minor':
        return 3;
      case 'spejder':
        return 2;
      case 'spion':
        return 1;
      default:
        return 0;
    }
  }
}
