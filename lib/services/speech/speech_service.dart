import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isInitialized = false;
  bool get isListening => _speech.isListening;

  Future<void> init() async {
    if (!_isInitialized) {
      _isInitialized = await _speech.initialize();
    }
  }

  Future<void> startListening({
    required Function(String text, bool isFinal) onResult,
  }) async {
    await init();

    if (!_speech.isListening) {
      await _speech.listen(
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
        listenFor: const Duration(minutes: 5),
        pauseFor: const Duration(minutes: 5),
        onResult: (result) {
          onResult(result.recognizedWords, result.finalResult);
        },
      );
    }
  }

  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }
}
