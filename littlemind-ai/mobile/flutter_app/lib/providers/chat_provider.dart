import 'package:flutter/foundation.dart';
import 'dart:async';
import '../services/llm_provider_service.dart';
import '../services/tts_service.dart';
import '../providers/settings_provider.dart';
import '../providers/history_provider.dart';

class ChatMessage {
  final String text;
  final String role;
  final String? errorDetail;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.role,
    this.errorDetail,
    this.isError = false,
  });
}

class ChatProvider extends ChangeNotifier {
  final LlmProviderService _llmService = LlmProviderService();
  final TtsService _ttsService = TtsService();

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _currentSpeakingText; // Track what text is being spoken
  bool _isInitialized = false;
  Completer<void>? _requestCompleter; // For cancellation

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  
  // TTS state getters
  bool get isSpeaking => _ttsService.isSpeaking;
  bool get isPaused => _ttsService.isPaused;
  TtsState get ttsState => _ttsService.state;
  String? get currentSpeakingText => _currentSpeakingText;
  
  /// Get TTS progress (0.0 to 1.0)
  double get ttsProgress => _ttsService.progress;

  ChatProvider() {
    debugPrint('[CHAT_PROVIDER] Initializing ChatProvider');
    _initTtsService();
  }

  Future<void> _initTtsService() async {
    if (kIsWeb) return;
    // Only init on Android (flutter_tts is Android-only for this app)
    if (defaultTargetPlatform != TargetPlatform.android) return;

    if (_isInitialized) return;
    await _ttsService.init();
    // Register callback to notify when TTS state changes
    _ttsService.setOnStateChangedCallback(() {
      debugPrint('[CHAT_PROVIDER] TTS state changed: ${_ttsService.state}');
      notifyListeners();
    });
    _isInitialized = true;
    debugPrint('[CHAT_PROVIDER] TTS service initialized');
  }

  Future<void> sendMessage(String text, {
    String? name,
    int? age,
    String? interests,
    String? language,
    String? selectedMode,
    bool autoSpeak = false,
    int voiceIndex = 0,
    required LlmProviderType providerType,
    String? ollamaUrl,
    String? ollamaModel,
    String? geminiApiUrl,
    String? geminiApiKey,
    String? geminiModel,
    String? customApiUrl,
    String? customApiKey,
    String? customModel,
    String? openrouterApiUrl,
    String? openrouterApiKey,
    String? openrouterModel,
    String? huggingfaceApiUrl,
    String? huggingfaceApiKey,
    String? huggingfaceModel,
    HistoryProvider? historyProvider,
    String? providerDisplayName,
    String? modelDisplayName,
  }) async {
    if (text.trim().isEmpty) {
      debugPrint('[CHAT_PROVIDER] Ignoring empty message');
      return;
    }

    // Create a new completer for this request
    _requestCompleter = Completer<void>();

    debugPrint('[CHAT_PROVIDER] ========================================');
    debugPrint('[CHAT_PROVIDER] User sending message: "$text"');
    debugPrint('[CHAT_PROVIDER] Provider: $providerType');
    debugPrint('[CHAT_PROVIDER] Settings - name: $name, age: $age, interests: $interests, language: $language, mode: $selectedMode');

    _messages.add(ChatMessage(role: "user", text: text));
    _isLoading = true;
    notifyListeners();
    debugPrint('[CHAT_PROVIDER] Added user message to list, total messages: ${_messages.length}');

    try {
      debugPrint('[CHAT_PROVIDER] Calling LlmProviderService.sendMessageStream...');
      
      // Pre-add the empty bot message
      _messages.add(ChatMessage(role: "bot", text: "💭 Thinking..."));
      final int botMessageIndex = _messages.length - 1;
      notifyListeners();

      final stream = _llmService.sendMessageStream(
        text,
        providerType: providerType,
        name: name,
        age: age,
        interests: interests,
        language: language,
        mode: selectedMode,
        ollamaUrl: ollamaUrl,
        ollamaModel: ollamaModel,
        geminiApiUrl: geminiApiUrl,
        geminiApiKey: geminiApiKey,
        geminiModel: geminiModel,
        customApiUrl: customApiUrl,
        customApiKey: customApiKey,
        customModel: customModel,
        openrouterApiUrl: openrouterApiUrl,
        openrouterApiKey: openrouterApiKey,
        openrouterModel: openrouterModel,
        huggingfaceApiUrl: huggingfaceApiUrl,
        huggingfaceApiKey: huggingfaceApiKey,
        huggingfaceModel: huggingfaceModel,
      );

      String finalMode = "auto";
      String finalResponse = "";
      bool receivedContent = false;

      await for (final data in stream.timeout(
        const Duration(seconds: 65),
        onTimeout: (sink) {
          if (!_requestCompleter!.isCompleted) {
            _requestCompleter!.complete();
          }
          sink.addError(TimeoutException('Request timed out'));
        },
      )) {
        if (_requestCompleter!.isCompleted) {
          debugPrint('[CHAT_PROVIDER] Request cancelled during stream');
          break;
        }

        receivedContent = true;
        finalMode = data["mode"] ?? "story";
        finalResponse = data["response"] ?? "";
        
        String botResponseText = "${_llmService.getEmoji(finalMode)} $finalResponse";
        _messages[botMessageIndex] = ChatMessage(role: "bot", text: botResponseText);
        notifyListeners();
      }

      if (!receivedContent && _requestCompleter!.isCompleted) {
        _messages.removeAt(botMessageIndex);
        notifyListeners();
        return;
      }

      if (!receivedContent) {
        debugPrint('[CHAT_PROVIDER] WARNING: Empty response from LLM stream');
        _messages[botMessageIndex] = ChatMessage(
          role: "bot",
          text: "🤔 Hmm, I couldn't think of anything to say. Try asking something else!",
        );
        notifyListeners();
      } else {
        debugPrint('[CHAT_PROVIDER] Stream completed. Final length: ${finalResponse.length}');
        
        // Save to history
        if (historyProvider != null) {
          historyProvider.addEntry(
            providerName: providerDisplayName ?? providerType.name,
            modelName: modelDisplayName ?? 'unknown',
            query: text,
            response: finalResponse,
          );
          debugPrint('[CHAT_PROVIDER] Saved response to history');
        }
        
        // Auto-speak if the setting is enabled
        if (autoSpeak && !_requestCompleter!.isCompleted) {
          debugPrint('[CHAT_PROVIDER] Auto-speak enabled, speaking FULL response...');
          await speakText(finalResponse, voiceIndex: voiceIndex, language: language ?? 'english');
        }
      }
    } catch (e, stackTrace) {
      // Don't add error message if cancelled
      if (e is TimeoutException && _requestCompleter!.isCompleted) {
        debugPrint('[CHAT_PROVIDER] Request cancelled by user');
      } else {
        debugPrint('[CHAT_PROVIDER] ERROR during API call: $e');
        debugPrint('[CHAT_PROVIDER] Stack trace: $stackTrace');
        
        // Build a user-friendly error message
        String friendlyError = _getFriendlyError(e);
        
        _messages.add(ChatMessage(
          role: "bot",
          text: "⚠️ $friendlyError",
          isError: true,
          errorDetail: e.toString(),
        ));
        debugPrint('[CHAT_PROVIDER] Added error message to list');
      }
    } finally {
      _isLoading = false;
      _requestCompleter = null;
      notifyListeners();
      debugPrint('[CHAT_PROVIDER] Loading state set to false, notifying listeners');
      debugPrint('[CHAT_PROVIDER] ========================================');
    }
  }

  /// Convert raw exceptions into friendly user-facing messages
  String _getFriendlyError(Object e) {
    String raw = e.toString();
    
    // Strip the "Exception: " prefix that Dart adds
    if (raw.startsWith('Exception: ')) {
      raw = raw.substring(11);
    }
    
    // Handle common network errors
    if (raw.contains('SocketException') || raw.contains('Connection refused')) {
      return 'Could not connect to the server. Please check your internet connection and that the server is running.';
    }
    if (raw.contains('HandshakeException') || raw.contains('CERTIFICATE_VERIFY_FAILED')) {
      return 'Secure connection failed. Please check the API URL in your settings.';
    }
    if (e is TimeoutException || raw.contains('TimeoutException')) {
      return 'The request took too long. The server might be busy — please try again.';
    }
    if (raw.contains('Connection closed') || raw.contains('Connection reset')) {
      return 'The connection was interrupted. Please try again.';
    }
    
    // The message from llm_provider_service is already friendly, return it
    return raw;
  }

  /// Cancel the current LLM request
  Future<void> cancelRequest() async {
    if (_isLoading && _requestCompleter != null && !_requestCompleter!.isCompleted) {
      debugPrint('[CHAT_PROVIDER] Cancelling current request');
      _requestCompleter!.complete();
      _isLoading = false;
      _requestCompleter = null;
      notifyListeners();
    }
  }

  /// Speak the given text using TTS, filtering out image URLs
  Future<void> speakText(String text, {int? voiceIndex, String language = 'english'}) async {
    if (text.isEmpty) return;
    
    // Filter out image URLs and markdown image syntax from text
    String filteredText = _filterImageUrlsFromText(text);
    if (filteredText.isEmpty) return;
    
    debugPrint('[CHAT_PROVIDER] Starting TTS for text: ${filteredText.substring(0, filteredText.length > 50 ? 50 : filteredText.length)}...');
    _currentSpeakingText = filteredText;
    notifyListeners();
    
    // Always apply the voice with the correct language right before speaking
    await setVoice(voiceIndex ?? 0, language: language);
    
    await _ttsService.speak(filteredText);
    
    // Clear state after speaking completes
    _currentSpeakingText = null;
    notifyListeners();
    debugPrint('[CHAT_PROVIDER] TTS completed');
  }

  /// Set the voice for TTS
  Future<void> setVoice(int voiceIndex, {String language = 'english'}) async {
    final voiceMap = _ttsService.getVoiceAt(voiceIndex, language: language);
    if (voiceMap != null) {
      await _ttsService.setVoiceMap(voiceMap);
    }
  }

  /// Get available voice display names
  List<String> getVoiceDisplayNames({String language = 'english'}) => _ttsService.getVoiceDisplayNames(language: language);

  /// Get the friendly voice name for a given voice index
  String? getFriendlyVoiceNameAt(int index, {String language = 'english'}) => _ttsService.getFriendlyVoiceNameAt(index, language: language);

  /// Speak a short preview phrase with the given voice to let the user test it.
  Future<void> speakVoicePreview({
    required int voiceIndex,
    required String language,
    required String previewText,
  }) async {
    await setVoice(voiceIndex, language: language);
    await _ttsService.speakPreview(previewText);
  }

  /// Filter out image URLs and markdown image syntax from text
  String _filterImageUrlsFromText(String text) {
    // Remove markdown image syntax: ![alt](url)
    String filtered = text.replaceAll(RegExp(r'!\[.*?\]\(.*?\)'), '');
    // Remove standalone URLs that look like images
    filtered = filtered.replaceAll(RegExp(r'https?://\S+\.(jpg|jpeg|png|gif|webp|svg|bmp|ico)(\s|$)?', caseSensitive: false), '');
    // Remove any remaining URLs
    filtered = filtered.replaceAll(RegExp(r'https?://\S+\s*'), ' ');
    // Clean up extra whitespace
    filtered = filtered.replaceAll(RegExp(r'\s+'), ' ').trim();
    return filtered;
  }

  /// Stop the current TTS playback (resets position)
  Future<void> stopSpeaking() async {
    debugPrint('[CHAT_PROVIDER] Stopping TTS');
    await _ttsService.stop();
    _currentSpeakingText = null;
    notifyListeners();
  }

  /// Pause the current TTS playback (can be resumed)
  Future<void> pauseSpeaking() async {
    debugPrint('[CHAT_PROVIDER] Pausing TTS');
    await _ttsService.pause();
    notifyListeners();
  }

  /// Resume the paused TTS playback
  Future<void> resumeSpeaking() async {
    debugPrint('[CHAT_PROVIDER] Resuming TTS');
    await _ttsService.resume();
    notifyListeners();
  }

  /// Restart TTS with a new voice (used when voice changes while paused)
  Future<void> restartWithNewVoice({int? voiceIndex, String language = 'english'}) async {
    debugPrint('[CHAT_PROVIDER] Restarting TTS with new voice');
    // Set the new voice
    if (voiceIndex != null) {
      await setVoice(voiceIndex, language: language);
    }
    // Restart speech with new voice
    await _ttsService.restartWithNewVoice();
    notifyListeners();
  }

  /// Toggle between pause and resume
  Future<void> togglePauseResume() async {
    if (_ttsService.isPaused) {
      await resumeSpeaking();
    } else if (_ttsService.isSpeaking) {
      await pauseSpeaking();
    }
  }

  /// Get the current TTS state for UI display
  TtsState getTtsState() => _ttsService.state;
}