/// Application configuration constants
/// Centralized configuration for LLM providers and storage keys
class AppConfig {
  AppConfig._();

  // ============================================================
  // Default LLM Provider URLs
  // ============================================================
  static const String defaultOllamaUrl = 'http://192.168.1.4:11434/api/chat';
  static const String defaultBackendUrl = 'http://192.168.1.3:8000/ask';
  static const String defaultBackendStreamUrl =
      'http://192.168.1.3:8000/ask_stream';
  static const String defaultGeminiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/';
  static const String defaultOpenRouterUrl =
      'https://openrouter.ai/api/v1/chat/completions';
  static const String defaultHuggingFaceUrl =
      'https://api-inference.huggingface.co/models/';

  // ============================================================
  // Default LLM Models
  // ============================================================
  static const String defaultOllamaModel = 'gemma3:4b';
  static const String defaultGeminiModel = 'gemini-flash-latest';
  static const String defaultOpenRouterModel = 'openrouter/free';
  static const String defaultHuggingFaceModel = 'google/gemma-3-1b-it';

  // ============================================================
  // Storage Keys
  // ============================================================
  static const String keyChildName = 'child_name';
  static const String keyChildAge = 'child_age';
  static const String keyChildInterests = 'child_interests';
  static const String keyAppLanguage = 'app_language';
  static const String keyAppMode = 'app_mode';
  static const String keyAutoSpeak = 'auto_speak';
  static const String keyDarkMode = 'dark_mode';
  static const String keyVoiceIndex = 'voice_index';
  static const String keyLlmProviderType = 'llm_provider_type';
  static const String keyOllamaUrl = 'ollama_url';
  static const String keyOllamaModel = 'ollama_model';
  static const String keyGeminiApiUrl = 'gemini_api_url';
  static const String keyGeminiApiKey = 'gemini_api_key';
  static const String keyGeminiModel = 'gemini_model';
  static const String keyCustomApiUrl = 'custom_api_url';
  static const String keyCustomApiKey = 'custom_api_key';
  static const String keyCustomModel = 'custom_model';
  static const String keyOpenRouterApiUrl = 'openrouter_api_url';
  static const String keyOpenRouterApiKey = 'openrouter_api_key';
  static const String keyOpenRouterModel = 'openrouter_model';
  static const String keyHuggingFaceApiUrl = 'huggingface_api_url';
  static const String keyHuggingFaceApiKey = 'huggingface_api_key';
  static const String keyHuggingFaceModel = 'huggingface_model';
  static const String keyHistoryEntries = 'history_entries';
  static const String keyEncryptionKey = 'app_encryption_key';

  // ============================================================
  // Default Values
  // ============================================================
  static const int defaultChildAge = 5;
  static const String defaultLanguage = 'english';
  static const String defaultMode = 'auto';

  // ============================================================
  // Language Display Names
  // ============================================================
  static const Map<String, String> languageDisplayNames = {
    'english': '🇬🇧 English',
    'hinglish': '🇮🇳 Hinglish (हिंदी + English)',
  };

  /// Get the display name for a language code
  static String getLanguageDisplayName(String languageCode) {
    return languageDisplayNames[languageCode] ?? languageCode;
  }

  /// Get all available language options with display names
  static List<Map<String, String>> getAvailableLanguages() {
    return languageDisplayNames.entries.map((entry) {
      return {'code': entry.key, 'name': entry.value};
    }).toList();
  }

  static const bool defaultAutoSpeak = false;
  static const int defaultLlmProviderTypeIndex = 1; // backend

  // ============================================================
  // LLM Provider Display Names
  // ============================================================
  static const String ollamaDisplayName = 'Local Ollama';
  static const String backendDisplayName = 'LittleMind Backend';
  static const String geminiDisplayName = 'Google Gemini';
  static const String customDisplayName = 'Custom API';
  static const String openRouterDisplayName = 'OpenRouter';
  static const String huggingFaceDisplayName = 'Hugging Face';
  static const String agentRouterDisplayName = 'AgentRouter';

  // ============================================================
  // API Configuration
  // ============================================================
  static const String openRouterReferer = 'https://littlemind-ai.app';
  static const String openRouterTitle = 'Little Minds';
  static const String authorizationBearerPrefix = 'Bearer';
  static const String contentTypeHeaderName = 'Content-Type';
  static const String contentTypeJsonValue = 'application/json';

  // ============================================================
  // Model Generation Defaults
  // ============================================================
  static const double defaultTemperature = 0.6;
  static const int defaultMaxTokens = 4096;
  static const double defaultTopP = 0.8;
}
