import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();
  bool _sttReady = false;
  bool _isSpeaking = false;

  Future<void> init() async {
    await _tts.setLanguage("en-IN");
    await _tts.setSpeechRate(0.52);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);

    try {
      await _tts.setEngine("com.google.android.tts");
    } catch (_) {}

    final voices = await _tts.getVoices;
    if (voices != null) {
      final voiceList = List<Map>.from(voices);
      try {
        final premium = voiceList.firstWhere(
          (v) =>
              v['locale']?.toString().contains('en-IN') == true &&
              (v['name']?.toString().contains('network') == true ||
                  v['name']?.toString().contains('neural') == true),
          orElse: () => voiceList.firstWhere(
            (v) => v['locale']?.toString().contains('en-IN') == true,
            orElse: () => voiceList.first,
          ),
        );
        await _tts.setVoice({
          "name": premium['name'].toString(),
          "locale": premium['locale'].toString(),
        });
      } catch (_) {}
    }

    await _tts.awaitSpeakCompletion(true);
    _tts.setStartHandler(() => _isSpeaking = true);
    _tts.setCompletionHandler(() => _isSpeaking = false);
    _tts.setErrorHandler((msg) => _isSpeaking = false);

    _sttReady = await _stt.initialize(
      onError: (e) => print("STT error: $e"),
      onStatus: (s) => print("STT status: $s"),
    );
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
    _isSpeaking = false;
  }

  bool get isSpeaking => _isSpeaking;

  Future<String> listen({
    Duration timeout = const Duration(seconds: 8),
    Duration pauseFor = const Duration(seconds: 2),
    Function(String)? onPartial,
  }) async {
    if (!_sttReady) {
      _sttReady = await _stt.initialize();
      if (!_sttReady) return "";
    }

    String result = "";
    bool done = false;

    await _stt.listen(
      onResult: (r) {
        result = r.recognizedWords;
        if (onPartial != null) onPartial(result);
        if (r.finalResult) done = true;
      },
      listenFor: timeout,
      pauseFor: pauseFor,
      partialResults: true,
      localeId: "en_IN",
      cancelOnError: true,
    );

    final start = DateTime.now();
    while (!done && _stt.isListening) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (DateTime.now().difference(start) > timeout) break;
    }

    await _stt.stop();
    return result.trim();
  }

  Future<void> stopListening() async {
    await _stt.stop();
  }

  bool get isListening => _stt.isListening;
}
