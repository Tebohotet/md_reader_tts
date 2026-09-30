import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TtsService {
  final FlutterTts flutterTts = FlutterTts();

  double rate = 0.5;
  double pitch = 1.0;
  double volume = 1.0;

  String? selectedVoiceName;
  String? selectedVoiceLocale;   // ← keep the real locale

  TtsService() {
    _initialize();
  }

  Future<void> _initialize() async {
    // Prefer a language but don't force it too hard
    await flutterTts.setLanguage("en-US");

    final prefs = await SharedPreferences.getInstance();
    rate = prefs.getDouble('tts_rate') ?? rate;
    pitch = prefs.getDouble('tts_pitch') ?? pitch;
    volume = prefs.getDouble('tts_volume') ?? volume;
    selectedVoiceName = prefs.getString('tts_voice_name');
    selectedVoiceLocale = prefs.getString('tts_voice_locale');

    if (selectedVoiceName == null || selectedVoiceLocale == null) {
      await _setDefaultFemaleVoice();
    } else {
      await _applyVoice(selectedVoiceName!, selectedVoiceLocale!);
    }

    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);
    await flutterTts.setVolume(volume);
  }

  Future<void> _applyVoice(String name, String locale) async {
    try {
      await flutterTts.setVoice({"name": name, "locale": locale});
      selectedVoiceName = name;
      selectedVoiceLocale = locale;
    } catch (e) {
      print("Failed to set voice $name ($locale): $e");
    }
  }

  /// Better female-voice picker
  Future<void> _setDefaultFemaleVoice() async {
    try {
      final List<dynamic> voices = await flutterTts.getVoices;

      // Prefer explicit female markers first
      dynamic female = _findVoice(voices, (name, locale) {
        return locale.toLowerCase().contains("en") &&
            (name.toLowerCase().contains("female") ||
                name.toLowerCase().contains("woman") ||
                name.toLowerCase().contains("f_") ||
                name.toLowerCase().contains("-f-") ||
                name.toLowerCase().contains("_f_"));
      });

      // Common high-quality female voices on different platforms
      female ??= _findVoice(voices, (name, locale) {
        final n = name.toLowerCase();
        return locale.toLowerCase().contains("en") &&
            (n.contains("samantha") ||          // iOS
                n.contains("karen") ||
                n.contains("moira") ||
                n.contains("tessa") ||
                n.contains("zira") ||           // Windows
                n.contains("susan") ||
                n.contains("hazel") ||
                n.contains("sfg") ||            // Google Android
                n.contains("network") ||
                n.contains("en-us-x-sfg") ||
                n.contains("en-gb-x-rjs") ||
                n.contains("en-au-x-afh"));
      });

      // Last resort: any English voice that is not obviously male
      female ??= _findVoice(voices, (name, locale) {
        final n = name.toLowerCase();
        return locale.toLowerCase().contains("en") &&
            !n.contains("male") &&
            !n.contains("man") &&
            !n.contains("m_") &&
            !n.contains("-m-");
      });

      if (female != null) {
        final Map voiceMap = Map<String, dynamic>.from(female);
        final name = voiceMap["name"]?.toString() ?? "";
        final locale = voiceMap["locale"]?.toString() ?? "en-US";

        await _applyVoice(name, locale);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('tts_voice_name', name);
        await prefs.setString('tts_voice_locale', locale);

        print("Default female voice set → $name ($locale)");
      } else {
        print("No suitable female voice found");
      }
    } catch (e) {
      print("Error setting default female voice: $e");
    }
  }

  dynamic _findVoice(List<dynamic> voices, bool Function(String name, String locale) test) {
    try {
      return voices.firstWhere((v) {
        final Map m = Map<String, dynamic>.from(v);
        final name = m["name"]?.toString() ?? "";
        final locale = m["locale"]?.toString() ?? "";
        return test(name, locale);
      });
    } catch (_) {
      return null;
    }
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;

    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);

    // Always re-apply the voice with the correct locale
    if (selectedVoiceName != null && selectedVoiceLocale != null) {
      await _applyVoice(selectedVoiceName!, selectedVoiceLocale!);
    }

    await flutterTts.speak(text);
  }

  Future<void> stop() async => await flutterTts.stop();

  Future<void> setVoice(String name, String locale) async {
    await _applyVoice(name, locale);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tts_voice_name', name);
    await prefs.setString('tts_voice_locale', locale);
  }

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    await flutterTts.setVolume(volume);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tts_volume', volume);
  }

  Future<void> setRate(double r) async {
    rate = r.clamp(0.0, 1.0);
    await flutterTts.setSpeechRate(rate);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tts_rate', rate);
  }

  Future<void> setPitch(double p) async {
    pitch = p.clamp(0.5, 2.0);
    await flutterTts.setPitch(pitch);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tts_pitch', pitch);
  }
}