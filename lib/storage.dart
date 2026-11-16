import 'package:shared_preferences/shared_preferences.dart';

import 'game_mode.dart';

// En iyi skorlar ve ses ayarı cihazda saklanıyor.
// SharedPreferences açılamazsa (ör. tarayıcıda depolama kapalı) uygulama yine çalışsın diye
// değerler sadece bellekte tutuluyor.
class Storage {
  static SharedPreferences? _prefs;
  static final Map<String, Object> _memory = {};

  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {
      _prefs = null;
    }
  }

  // Mod hiç oynanmadıysa null döner
  static int? bestScore(GameMode mode) {
    final key = 'best_${mode.name}';
    return _prefs?.getInt(key) ?? _memory[key] as int?;
  }

  // Yeni rekor kırıldıysa true döner
  static bool saveScore(GameMode mode, int score) {
    final best = bestScore(mode);
    if (best != null && score <= best) return false;
    final key = 'best_${mode.name}';
    _memory[key] = score;
    _prefs?.setInt(key, score);
    // İlk oyunu rekor saymıyoruz, karşılaştıracak bir şey yok
    return best != null;
  }

  static bool get soundOn => _prefs?.getBool('sound_on') ?? _memory['sound_on'] as bool? ?? true;

  static set soundOn(bool value) {
    _memory['sound_on'] = value;
    _prefs?.setBool('sound_on', value);
  }
}
