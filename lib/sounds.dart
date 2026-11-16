import 'package:audioplayers/audioplayers.dart';

import 'storage.dart';

// Doğru/yanlış cevap sesleri (assets/sounds)
class Sounds {
  static final _player = AudioPlayer();

  static Future<void> answer(bool correct) async {
    if (!Storage.soundOn) return;
    try {
      await _player.stop();
      await _player.play(AssetSource(correct ? 'sounds/correct.mp3' : 'sounds/wrong.mp3'));
    } catch (_) {
      // Ses çalınamazsa oyun devam etsin
    }
  }
}
