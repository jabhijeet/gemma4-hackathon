import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  Future<bool> init() async {
    return await _speech.initialize();
  }

  void listen(Function(String) onResult) {
    _speech.listen(onResult: (result) {
      onResult(result.recognizedWords);
    });
  }

  void stop() {
    _speech.stop();
  }
}
