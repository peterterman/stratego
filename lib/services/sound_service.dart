import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> play(String file) async {
    await _player.stop();
    await _player.play(AssetSource('sounds/$file'));
  }

  static Future<void> move() async {
    await play('trin1.ogg');
  }

  static Future<void> explosion() async {
    await play('explode.ogg');
  }

  static Future<void> victory() async {
    await play('nextlevel.ogg');
  }

  static Future<void> sword() async {
    await play('sword.ogg');
  }
}
