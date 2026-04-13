import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

// LLM Provider types
enum LlmProviderType {
  ollama, // Local Ollama
  backend, // Existing backend implementation
  gemini, // Google Gemini
  custom, // Custom API path
  openrouter, // OpenRouter
  huggingface, // Hugging Face Inference API
}

class SettingsProvider extends ChangeNotifier {
  String _name = '';
  int _age = AppConfig.defaultChildAge;
  String _interests = '';
  String _language = AppConfig.defaultLanguage;
  String _mode = AppConfig.defaultMode;
  bool _autoSpeak = AppConfig.defaultAutoSpeak;
  bool _isDarkMode = false;
  int _voiceIndex = 0; // Default voice index

  // LLM Provider settings
  LlmProviderType _llmProviderType = LlmProviderType.values[AppConfig.defaultLlmProviderTypeIndex];
  String _ollamaUrl = AppConfig.defaultOllamaUrl;
  String _ollamaModel = AppConfig.defaultOllamaModel;
  String _geminiApiUrl = AppConfig.defaultGeminiUrl;
  String _geminiApiKey = '';
  String _geminiModel = AppConfig.defaultGeminiModel;
  String _customApiUrl = '';
  String _customApiKey = '';
  String _customModel = '';
  String _openrouterApiUrl = AppConfig.defaultOpenRouterUrl;
  String _openrouterApiKey = '';
  String _openrouterModel = AppConfig.defaultOpenRouterModel;
  String _huggingfaceApiUrl = AppConfig.defaultHuggingFaceUrl;
  String _huggingfaceApiKey = '';
  String _huggingfaceModel = AppConfig.defaultHuggingFaceModel;

  bool _isLoaded = false;

  String get name => _name;
  int get age => _age;
  String get interests => _interests;
  String get language => _language;
  String get mode => _mode;
  bool get autoSpeak => _autoSpeak;
  bool get isDarkMode => _isDarkMode;
  bool get isLoaded => _isLoaded;
  int get voiceIndex => _voiceIndex;

  // LLM Provider getters
  LlmProviderType get llmProviderType => _llmProviderType;
  String get ollamaUrl => _ollamaUrl;
  String get ollamaModel => _ollamaModel;
  String get geminiApiUrl => _geminiApiUrl;
  String get geminiApiKey => _geminiApiKey;
  String get geminiModel => _geminiModel;
  String get customApiUrl => _customApiUrl;
  String get customApiKey => _customApiKey;
  String get customModel => _customModel;
  String get openrouterApiUrl => _openrouterApiUrl;
  String get openrouterApiKey => _openrouterApiKey;
  String get openrouterModel => _openrouterModel;
  String get huggingfaceApiUrl => _huggingfaceApiUrl;
  String get huggingfaceApiKey => _huggingfaceApiKey;
  String get huggingfaceModel => _huggingfaceModel;

  // Helper method to get the display name of provider type
  String get llmProviderDisplayName {
    switch (_llmProviderType) {
      case LlmProviderType.ollama:
        return AppConfig.ollamaDisplayName;
      case LlmProviderType.backend:
        return AppConfig.backendDisplayName;
      case LlmProviderType.gemini:
        return AppConfig.geminiDisplayName;
      case LlmProviderType.custom:
        return AppConfig.customDisplayName;
      case LlmProviderType.openrouter:
        return AppConfig.openRouterDisplayName;
      case LlmProviderType.huggingface:
        return AppConfig.huggingFaceDisplayName;
    }
  }

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _name = prefs.getString(AppConfig.keyChildName) ?? '';
    _age = prefs.getInt(AppConfig.keyChildAge) ?? AppConfig.defaultChildAge;
    _interests = prefs.getString(AppConfig.keyChildInterests) ?? '';
    _language = prefs.getString(AppConfig.keyAppLanguage) ?? AppConfig.defaultLanguage;
    _mode = prefs.getString(AppConfig.keyAppMode) ?? AppConfig.defaultMode;
    _autoSpeak = prefs.getBool(AppConfig.keyAutoSpeak) ?? AppConfig.defaultAutoSpeak;
    _isDarkMode = prefs.getBool(AppConfig.keyDarkMode) ?? false;
    _voiceIndex = prefs.getInt(AppConfig.keyVoiceIndex) ?? 0;

    // Load LLM provider settings
    final providerIndex =
        prefs.getInt(AppConfig.keyLlmProviderType) ?? AppConfig.defaultLlmProviderTypeIndex;
    _llmProviderType = LlmProviderType
        .values[providerIndex.clamp(0, LlmProviderType.values.length - 1)];
    _ollamaUrl =
        prefs.getString(AppConfig.keyOllamaUrl) ?? AppConfig.defaultOllamaUrl;
    _ollamaModel = prefs.getString(AppConfig.keyOllamaModel) ?? AppConfig.defaultOllamaModel;
    _geminiApiUrl = prefs.getString(AppConfig.keyGeminiApiUrl) ?? AppConfig.defaultGeminiUrl;
    _geminiApiKey = prefs.getString(AppConfig.keyGeminiApiKey) ?? '';
    _geminiModel = prefs.getString(AppConfig.keyGeminiModel) ?? AppConfig.defaultGeminiModel;
    _customApiUrl = prefs.getString(AppConfig.keyCustomApiUrl) ?? '';
    _customApiKey = prefs.getString(AppConfig.keyCustomApiKey) ?? '';
    _customModel = prefs.getString(AppConfig.keyCustomModel) ?? '';
    _openrouterApiUrl = prefs.getString(AppConfig.keyOpenRouterApiUrl) ?? AppConfig.defaultOpenRouterUrl;
    _openrouterApiKey = prefs.getString(AppConfig.keyOpenRouterApiKey) ?? '';
    _openrouterModel = prefs.getString(AppConfig.keyOpenRouterModel) ?? AppConfig.defaultOpenRouterModel;
    _huggingfaceApiUrl = prefs.getString(AppConfig.keyHuggingFaceApiUrl) ?? AppConfig.defaultHuggingFaceUrl;
    _huggingfaceApiKey = prefs.getString(AppConfig.keyHuggingFaceApiKey) ?? '';
    _huggingfaceModel = prefs.getString(AppConfig.keyHuggingFaceModel) ?? AppConfig.defaultHuggingFaceModel;

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> updateSettings({
    required String name,
    required int age,
    required String interests,
    required String language,
    String? mode,
    bool? autoSpeak,
    int? voiceIndex,
  }) async {
    _name = name;
    _age = age;
    _interests = interests;
    _language = language;
    if (mode != null) {
      _mode = mode;
    }
    if (autoSpeak != null) {
      _autoSpeak = autoSpeak;
    }
    if (voiceIndex != null) {
      _voiceIndex = voiceIndex;
    }

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.keyChildName, name);
    await prefs.setInt(AppConfig.keyChildAge, age);
    await prefs.setString(AppConfig.keyChildInterests, interests);
    await prefs.setString(AppConfig.keyAppLanguage, language);
    await prefs.setString(AppConfig.keyAppMode, _mode);
    await prefs.setBool(AppConfig.keyAutoSpeak, _autoSpeak);
    await prefs.setInt(AppConfig.keyVoiceIndex, _voiceIndex);
  }

  // Toggle dark mode
  Future<void> toggleDarkMode(bool value) async {
    _isDarkMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConfig.keyDarkMode, value);
  }

  // Update voice index
  Future<void> updateVoiceIndex(int index) async {
    _voiceIndex = index;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConfig.keyVoiceIndex, index);
  }

  // LLM Provider update methods
  Future<void> updateLlmProvider({
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
  }) async {
    _llmProviderType = providerType;
    if (ollamaUrl != null) _ollamaUrl = ollamaUrl;
    if (ollamaModel != null) _ollamaModel = ollamaModel;
    if (geminiApiUrl != null) _geminiApiUrl = geminiApiUrl;
    if (geminiApiKey != null) _geminiApiKey = geminiApiKey;
    if (geminiModel != null) _geminiModel = geminiModel;
    if (customApiUrl != null) _customApiUrl = customApiUrl;
    if (customApiKey != null) _customApiKey = customApiKey;
    if (customModel != null) _customModel = customModel;
    if (openrouterApiUrl != null) _openrouterApiUrl = openrouterApiUrl;
    if (openrouterApiKey != null) _openrouterApiKey = openrouterApiKey;
    if (openrouterModel != null) _openrouterModel = openrouterModel;
    if (huggingfaceApiUrl != null) _huggingfaceApiUrl = huggingfaceApiUrl;
    if (huggingfaceApiKey != null) _huggingfaceApiKey = huggingfaceApiKey;
    if (huggingfaceModel != null) _huggingfaceModel = huggingfaceModel;

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConfig.keyLlmProviderType, providerType.index);
    await prefs.setString(AppConfig.keyOllamaUrl, _ollamaUrl);
    await prefs.setString(AppConfig.keyOllamaModel, _ollamaModel);
    await prefs.setString(AppConfig.keyGeminiApiUrl, _geminiApiUrl);
    await prefs.setString(AppConfig.keyGeminiApiKey, _geminiApiKey);
    await prefs.setString(AppConfig.keyGeminiModel, _geminiModel);
    await prefs.setString(AppConfig.keyCustomApiUrl, _customApiUrl);
    await prefs.setString(AppConfig.keyCustomApiKey, _customApiKey);
    await prefs.setString(AppConfig.keyCustomModel, _customModel);
    await prefs.setString(AppConfig.keyOpenRouterApiUrl, _openrouterApiUrl);
    await prefs.setString(AppConfig.keyOpenRouterApiKey, _openrouterApiKey);
    await prefs.setString(AppConfig.keyOpenRouterModel, _openrouterModel);
    await prefs.setString(AppConfig.keyHuggingFaceApiUrl, _huggingfaceApiUrl);
    await prefs.setString(AppConfig.keyHuggingFaceApiKey, _huggingfaceApiKey);
    await prefs.setString(AppConfig.keyHuggingFaceModel, _huggingfaceModel);
  }

  // Get current provider configuration as a map
  Map<String, dynamic> getProviderConfig() {
    switch (_llmProviderType) {
      case LlmProviderType.ollama:
        return {
          'type': 'ollama',
          'url': _ollamaUrl,
          'model': _ollamaModel,
        };
      case LlmProviderType.backend:
        return {
          'type': 'backend',
        };
      case LlmProviderType.gemini:
        return {
          'type': 'gemini',
          'api_url': _geminiApiUrl,
          'api_key': _geminiApiKey,
          'model': _geminiModel,
        };
      case LlmProviderType.custom:
        return {
          'type': 'custom',
          'url': _customApiUrl,
          'api_key': _customApiKey,
          'model': _customModel,
        };
      case LlmProviderType.openrouter:
        return {
          'type': 'openrouter',
          'api_url': _openrouterApiUrl,
          'api_key': _openrouterApiKey,
          'model': _openrouterModel,
        };
      case LlmProviderType.huggingface:
        return {
          'type': 'huggingface',
          'api_url': _huggingfaceApiUrl,
          'api_key': _huggingfaceApiKey,
          'model': _huggingfaceModel,
        };
    }
  }
}
