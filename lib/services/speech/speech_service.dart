import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_error.dart';

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isInitialized = false;
  bool _sessionRequested = false;
  bool _manualStop = false;
  bool _stopNotified = false;

  void Function(String text, bool isFinal)? _onResultCallback;
  void Function()? _onStoppedCallback;
  void Function(bool isListening)? _onListeningStateChanged;

  Future<void> init() async {
    if (!_isInitialized) {
      _isInitialized = await _speech.initialize(
        onStatus: _handleStatus,
        onError: _handleError,
      );
    }
  }

  Future<void> startListening({
    required Function(String text, bool isFinal) onResult,
    required Function() onStopped,
    required Function(bool isListening) onListeningStateChanged,
  }) async {
    await init();

    if (!_isInitialized) {
      onStopped();
      return;
    }

    _sessionRequested = true;
    _manualStop = false;
    _stopNotified = false;

    _onResultCallback = onResult;
    _onStoppedCallback = onStopped;
    _onListeningStateChanged = onListeningStateChanged;

    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
        cancelOnError: false,
      ),
      listenFor: const Duration(minutes: 2),
      pauseFor: const Duration(seconds: 8),
      onResult: (result) {
        _onResultCallback?.call(result.recognizedWords, result.finalResult);
      },
    );
  }

  Future<void> stopListening() async {
    _sessionRequested = false;
    _manualStop = true;

    if (_speech.isListening) {
      await _speech.stop();
    }

    _notifyListeningState(false);
    _notifyStopped();
  }

  void _handleStatus(String status) {
    final normalized = status.toLowerCase();

    if (normalized == 'listening') {
      _notifyListeningState(true);
      return;
    }

    if (normalized == 'notlistening' || normalized == 'done') {
      _notifyListeningState(false);

      // If user manually stopped, end cleanly
      if (_manualStop) {
        _notifyStopped();
        return;
      }

      // If session was active but Android stopped it,
      // just end cleanly. DO NOT restart.
      if (_sessionRequested) {
        _sessionRequested = false;
        _notifyStopped();
      }
    }
  }

  void _handleError(SpeechRecognitionError error) {
    _notifyListeningState(false);
    _notifyStopped();
  }

  void _notifyListeningState(bool isListening) {
    _onListeningStateChanged?.call(isListening);
  }

  void _notifyStopped() {
    if (_stopNotified) return;
    _stopNotified = true;
    _onStoppedCallback?.call();
  }
}
