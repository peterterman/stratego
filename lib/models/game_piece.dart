import '../services/game_variant_service.dart';

class GamePiece {
  final String type;
  final bool isPlayer;

  GamePiece({required this.type, required this.isPlayer});

  // Fallback til gammel kode
  String get image {
    if (isPlayer) {
      return 'assets/images/blaa_$type.png';
    } else {
      return 'assets/images/roed_bagside.png';
    }
  }

  String imageForVariant(GameVariant variant, {bool hidden = false}) {
    return GameVariantService.imagePath(
      type: type,
      isRed: !isPlayer,
      variant: variant,
      hidden: hidden,
    );
  }
}
