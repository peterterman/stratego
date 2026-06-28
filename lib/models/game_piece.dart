class GamePiece {
  final String type;
  final bool isPlayer;

  GamePiece({required this.type, required this.isPlayer});

  String get image {
    if (isPlayer) {
      return 'assets/images/blaa_$type.png';
    } else {
      return 'assets/images/roed_bagside.png';
    }
  }
}
