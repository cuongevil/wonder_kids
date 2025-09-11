import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> play(String path) async {
    await _player.stop();
    await _player.play(AssetSource(path));
  }
}
