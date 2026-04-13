import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsState {
  stopped,
  playing,
  paused,
}

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();

  TtsState _state = TtsState.stopped;
  String _currentText = '';
  int _currentWordIndex = 0;
  List<String> _words = [];

  Map<String, String>? _selectedVoice;

  // Populated at construction so UI can read voices before init() is called
  final List<Map<String, String>> _availableVoices = [
    {'name': 'Amy (English)', 'locale': 'en-US', 'internalId': 'amy'},
    {'name': 'Priya (Hindi Girl)', 'locale': 'hi-IN', 'internalId': 'priyamvada'},
    {'name': 'Rohan (Hindi Boy)', 'locale': 'hi-IN', 'internalId': 'rohan'},
  ];

  bool _initialized = false;

  TtsState get state => _state;
  bool get isSpeaking => _state == TtsState.playing;
  bool get isPaused => _state == TtsState.paused;
  String get currentText => _currentText;
  int get currentWordIndex => _currentWordIndex;
  Map<String, String>? get selectedVoice => _selectedVoice;
  List<dynamic> get availableVoices => _availableVoices;

  double get progress {
    if (_words.isEmpty) return 0.0;
    return _currentWordIndex / _words.length;
  }

  String get remainingText {
    if (_words.isEmpty || _currentWordIndex >= _words.length) return '';
    return _words.sublist(_currentWordIndex).join(' ');
  }

  String get spokenText {
    if (_words.isEmpty || _currentWordIndex <= 0) return '';
    return _words.sublist(0, _currentWordIndex).join(' ');
  }

  VoidCallback? _onStateChanged;

  void setOnStateChangedCallback(VoidCallback callback) {
    _onStateChanged = callback;
  }

  String _cleanTextForTts(String text) {
    String cleaned = text;
    cleaned = cleaned.replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1');
    cleaned = cleaned.replaceAll(RegExp(r'\*(.+?)\*'), r'$1');
    cleaned = cleaned.replaceAll(RegExp(r'__(.+?)__'), r'$1');
    cleaned = cleaned.replaceAll(RegExp(r'_(.+?)_'), r'$1');
    cleaned = cleaned.replaceAll(RegExp(r'~~(.+?)~~'), r'$1');
    cleaned = cleaned.replaceAll(RegExp(r'`(.+?)`'), r'$1');
    cleaned = cleaned.replaceAll(RegExp(r'#{1,6}\s*'), '');
    cleaned = cleaned.replaceAll(RegExp(r'!\[.*?\]\(.*?\)'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\[(.*?)\]\(.*?\)'), r'$1');
    cleaned = cleaned.replaceAll(RegExp(r'^\s*[-*+]\s+', multiLine: true), '');
    cleaned = cleaned.replaceAll(RegExp(r'^\s*\d+\.\s+', multiLine: true), '');
    cleaned = cleaned.replaceAll(RegExp(r'[#|>]+'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'---'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\*\s+'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'_\s+'), ' ');
    cleaned = cleaned.replaceAll(
      RegExp(
        r'[\u{1F300}-\u{1F64F}\u{1F680}-\u{1F6FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F900}-\u{1F9FF}\u{1F1E0}-\u{1F1FF}]',
        unicode: true,
      ),
      '',
    );
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned;
  }

  Future<void> init() async {
    if (_initialized) return;
    debugPrint('[TTS] Initializing flutter_tts engine...');

    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      debugPrint('[TTS] Started speaking');
      _state = TtsState.playing;
      _onStateChanged?.call();
    });

    _flutterTts.setCompletionHandler(() {
      debugPrint('[TTS] Completed speaking');
      _state = TtsState.stopped;
      _currentText = '';
      _currentWordIndex = 0;
      _words = [];
      _onStateChanged?.call();
    });

    _flutterTts.setPauseHandler(() {
      debugPrint('[TTS] Paused speaking');
      _state = TtsState.paused;
      _onStateChanged?.call();
    });

    _flutterTts.setContinueHandler(() {
      debugPrint('[TTS] Resumed speaking');
      _state = TtsState.playing;
      _onStateChanged?.call();
    });

    _flutterTts.setErrorHandler((msg) {
      debugPrint('[TTS] Error: $msg');
      _state = TtsState.stopped;
      _onStateChanged?.call();
    });

    _flutterTts.setProgressHandler((String text, int startOffset, int endOffset, String word) {
      // Track word progress
      if (_words.isNotEmpty) {
        _currentWordIndex = _words.indexWhere(
          (w) => w.toLowerCase() == word.toLowerCase(),
        );
        if (_currentWordIndex < 0) _currentWordIndex = 0;
      }
    });

    _selectedVoice ??= _availableVoices.first;
    _initialized = true;
    debugPrint('[TTS] flutter_tts engine initialized.');
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;

    String cleanedText = _cleanTextForTts(text);
    if (cleanedText.isEmpty) return;

    debugPrint('[TTS] Speaking: ${cleanedText.substring(0, cleanedText.length > 50 ? 50 : cleanedText.length)}...');
    _currentText = cleanedText;
    _words = cleanedText.split(RegExp(r'\s+'));
    _currentWordIndex = 0;

    // Apply locale based on selected voice
    if (_selectedVoice != null) {
      final locale = _selectedVoice!['locale'] ?? 'en-US';
      await _flutterTts.setLanguage(locale);
      // Adjust pitch to make it sound more kid-friendly
      if (locale.startsWith('hi')) {
        await _flutterTts.setPitch(1.1);
      } else {
        await _flutterTts.setPitch(1.0);
      }
    }

    try {
      await _flutterTts.speak(cleanedText);
    } catch (e) {
      debugPrint('[TTS] Failed to speak: $e');
    }
  }

  Future<void> setVoiceMap(Map<String, String> voiceMap) async {
    _selectedVoice = voiceMap;
    debugPrint('[TTS] Voice set to: $voiceMap');
  }

  List<Map<String, dynamic>> getKidVoices({String language = 'english'}) {
    bool wantHindi =
        language.toLowerCase() == 'hinglish' || language.toLowerCase() == 'hindi';

    if (wantHindi) {
      return [
        _availableVoices.firstWhere(
          (v) => v['internalId'] == 'priyamvada',
          orElse: () => _availableVoices.first,
        ),
        _availableVoices.firstWhere(
          (v) => v['internalId'] == 'rohan',
          orElse: () => _availableVoices.first,
        ),
      ];
    } else {
      return [
        _availableVoices.firstWhere(
          (v) => v['internalId'] == 'amy',
          orElse: () => _availableVoices.first,
        ),
      ];
    }
  }

  List<String> getVoiceDisplayNames({String language = 'english'}) {
    final voices = getKidVoices(language: language);
    return voices.map((v) => v['name'].toString()).toList();
  }

  Map<String, String>? getVoiceAt(int index, {String language = 'english'}) {
    final voices = getKidVoices(language: language);
    if (index >= 0 && index < voices.length) {
      return Map<String, String>.from(voices[index]);
    }
    return null;
  }

  String? getFriendlyVoiceNameAt(int index, {String language = 'english'}) {
    final voices = getKidVoices(language: language);
    if (index >= 0 && index < voices.length) {
      return voices[index]['name'].toString();
    }
    return null;
  }

  Future<void> resume() async {
    if (_state != TtsState.paused) return;
    debugPrint('[TTS] Resuming speech...');
    // flutter_tts does not support true resume on Android — restart from saved text
    final textToResume = _currentText;
    if (textToResume.isNotEmpty) {
      await _flutterTts.speak(textToResume);
    } else {
      // Nothing to resume, reset state
      _state = TtsState.stopped;
      _onStateChanged?.call();
    }
  }

  Future<void> restartWithNewVoice() async {
    if (_currentText.isEmpty) return;
    // Capture text BEFORE stop() clears it
    final textToSpeak = _currentText;
    await stop();
    await speak(textToSpeak);
  }

  /// Speak a short preview phrase to test the currently selected voice.
  /// Stops any ongoing playback first.
  Future<void> speakPreview(String phrase) async {
    if (_state == TtsState.playing || _state == TtsState.paused) {
      try { await _flutterTts.stop(); } catch (_) {}
      _state = TtsState.stopped;
    }
    // Apply the selected voice locale
    if (_selectedVoice != null) {
      final locale = _selectedVoice!['locale'] ?? 'en-US';
      await _flutterTts.setLanguage(locale);
      await _flutterTts.setPitch(locale.startsWith('hi') ? 1.1 : 1.0);
    }
    try {
      await _flutterTts.speak(phrase);
    } catch (e) {
      debugPrint('[TTS] speakPreview failed: $e');
    }
  }

  Future<void> stop() async {
    debugPrint('[TTS] Stopping speech');
    await _flutterTts.stop();
    _state = TtsState.stopped;
    _currentText = '';
    _currentWordIndex = 0;
    _words = [];
    _onStateChanged?.call();
  }

  Future<void> pause() async {
    if (_state != TtsState.playing) return;
    debugPrint('[TTS] Pausing speech');
    try {
      await _flutterTts.pause();
      // State update is handled by setPauseHandler callback
    } catch (e) {
      // flutter_tts on Android has a known bug where pause() throws
      // StringIndexOutOfBoundsException when the internal word-boundary
      // offset is stale. We stop the engine but keep _currentText so
      // resume() can restart from the beginning.
      debugPrint('[TTS] pause() failed (flutter_tts Android bug), stopping instead: $e');
      try { await _flutterTts.stop(); } catch (_) {}
      _state = TtsState.paused; // Treat as paused so resume button still works
      _onStateChanged?.call();
    }
  }

  void reset() {
    _state = TtsState.stopped;
    _currentText = '';
    _currentWordIndex = 0;
    _words = [];
  }

  String get stateString {
    switch (_state) {
      case TtsState.stopped:
        return 'stopped';
      case TtsState.playing:
        return 'playing';
      case TtsState.paused:
        return 'paused';
    }
  }
}
