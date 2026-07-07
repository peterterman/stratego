import 'package:shared_preferences/shared_preferences.dart';

enum GameVariant { eighteenTwelve, classic }

class GameVariantService {
  static const _key = 'game_variant';

  static Future<GameVariant> getVariant() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);

    if (value == 'classic') {
      return GameVariant.classic;
    }

    return GameVariant.eighteenTwelve;
  }

  static String title(GameVariant variant) {
    switch (variant) {
      case GameVariant.eighteenTwelve:
        return '1812';
      case GameVariant.classic:
        return 'Klassisk';
    }
  }

  static Future<void> setVariant(GameVariant variant) async {
    final prefs = await SharedPreferences.getInstance();

    switch (variant) {
      case GameVariant.classic:
        await prefs.setString(_key, 'classic');
        break;
      case GameVariant.eighteenTwelve:
        await prefs.setString(_key, '1812');
        break;
    }
  }

  static String folder(GameVariant variant) {
    switch (variant) {
      case GameVariant.classic:
        return 'klassisk';
      case GameVariant.eighteenTwelve:
        return '1812';
    }
  }

  static String appTitle(GameVariant variant) {
    switch (variant) {
      case GameVariant.classic:
        return 'Klassisk';
      case GameVariant.eighteenTwelve:
        return '1812';
    }
  }

  static String pieceName(String type, GameVariant variant) {
    if (variant == GameVariant.eighteenTwelve) {
      return _pieceName1812(type);
    }

    return _pieceNameClassic(type);
  }

  static String _pieceNameClassic(String type) {
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

  static String _pieceName1812(String type) {
    switch (type) {
      case 'marshal':
        return 'Hærfører';
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
        return 'Ingeniør';
      case 'spejder':
        return 'Ordonnans';
      case 'spion':
        return 'Spion';
      case 'bombe':
        return 'Fælde';
      case 'flag':
        return 'Fane';
      default:
        return type;
    }
  }

  static String imagePath({
    required String type,
    required bool isRed,
    required GameVariant variant,
    bool hidden = false,
  }) {
    final folderName = folder(variant);
    final prefix = isRed ? 'roed' : 'blaa';

    if (hidden) {
      return 'assets/images/$folderName/${prefix}_bagside.png';
    }

    return 'assets/images/$folderName/${prefix}_$type.png';
  }
}
