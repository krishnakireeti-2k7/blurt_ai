import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isInitialized = false;
  Function()? _onStoppedCallback;

  Future<void> init({required Function() onStopped}) async {
    if (!_isInitialized) {
      _isInitialized = await _speech.initialize(
        onStatus: (status) {
          if (status == "notListening") {
            _onStoppedCallback?.call();
          }
        },
        onError: (error) {
          print("Speech error: $error");
        },
      );
    }

    _onStoppedCallback = onStopped;
  }

  Future<void> startListening({
    required Function(String text, bool isFinal) onResult,
    required Function() onStopped,
  }) async {
    await init(onStopped: onStopped);

    if (!_speech.isListening) {
      await _speech.listen(
        listenMode: stt.ListenMode.dictation,
        partialResults: false,
        listenFor: const Duration(minutes: 5),
        pauseFor: const Duration(seconds: 2),
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
