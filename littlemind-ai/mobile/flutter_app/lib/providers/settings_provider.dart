import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

// LLM Provider types
enum LlmProviderType {
  gemini, // Google Gemini
  ollama, // Local Ollama
  backend, // Existing backend implementation
  custom, // Custom API path
  openrouter, // OpenRouter
  huggingface, // Hugging Face Inference API
}

class SettingsProvider extends ChangeNotifier {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  String _name = '';
  int _age = AppConfig.defaultChildAge;
  String _interests = '';
  String _language = AppConfig.defaultLanguage;
  String _mode = AppConfig.defaultMode;
  bool _autoSpeak = AppConfig.defaultAutoSpeak;
  bool _isDarkMode = false;
  int _voiceIndex = 0; // Default voice index

  // LLM Provider settings
  LlmProviderType _llmProviderType =
      LlmProviderType.values[AppConfig.defaultLlmProviderTypeIndex];
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
    _name = await _readString(AppConfig.keyChildName) ?? '';
    _age = await _readInt(AppConfig.keyChildAge) ?? AppConfig.defaultChildAge;
    _interests = await _readString(AppConfig.keyChildInterests) ?? '';
    _language = await _readString(AppConfig.keyAppLanguage) ??
        AppConfig.defaultLanguage;
    _mode = await _readString(AppConfig.keyAppMode) ?? AppConfig.defaultMode;
    _autoSpeak =
        await _readBool(AppConfig.keyAutoSpeak) ?? AppConfig.defaultAutoSpeak;
    _isDarkMode = await _readBool(AppConfig.keyDarkMode) ?? false;
    _voiceIndex = await _readInt(AppConfig.keyVoiceIndex) ?? 0;

    // Load LLM provider settings
    final providerIndex = await _readInt(AppConfig.keyLlmProviderType) ??
        AppConfig.defaultLlmProviderTypeIndex;
    _llmProviderType = LlmProviderType
        .values[providerIndex.clamp(0, LlmProviderType.values.length - 1)];
    _ollamaUrl =
        await _readString(AppConfig.keyOllamaUrl) ?? AppConfig.defaultOllamaUrl;
    _ollamaModel = await _readString(AppConfig.keyOllamaModel) ??
        AppConfig.defaultOllamaModel;
    _geminiApiUrl = await _readString(AppConfig.keyGeminiApiUrl) ??
        AppConfig.defaultGeminiUrl;
    _geminiApiKey = await _readString(AppConfig.keyGeminiApiKey) ?? '';
    _geminiModel = await _readString(AppConfig.keyGeminiModel) ??
        AppConfig.defaultGeminiModel;
    _customApiUrl = await _readString(AppConfig.keyCustomApiUrl) ?? '';
    _customApiKey = await _readString(AppConfig.keyCustomApiKey) ?? '';
    _customModel = await _readString(AppConfig.keyCustomModel) ?? '';
    _openrouterApiUrl = await _readString(AppConfig.keyOpenRouterApiUrl) ??
        AppConfig.defaultOpenRouterUrl;
    _openrouterApiKey = await _readString(AppConfig.keyOpenRouterApiKey) ?? '';
    _openrouterModel = await _readString(AppConfig.keyOpenRouterModel) ??
        AppConfig.defaultOpenRouterModel;
    _huggingfaceApiUrl = await _readString(AppConfig.keyHuggingFaceApiUrl) ??
        AppConfig.defaultHuggingFaceUrl;
    _huggingfaceApiKey =
        await _readString(AppConfig.keyHuggingFaceApiKey) ?? '';
    _huggingfaceModel = await _readString(AppConfig.keyHuggingFaceModel) ??
        AppConfig.defaultHuggingFaceModel;

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

    await _writeString(AppConfig.keyChildName, name);
    await _writeInt(AppConfig.keyChildAge, age);
    await _writeString(AppConfig.keyChildInterests, interests);
    await _writeString(AppConfig.keyAppLanguage, language);
    await _writeString(AppConfig.keyAppMode, _mode);
    await _writeBool(AppConfig.keyAutoSpeak, _autoSpeak);
    await _writeInt(AppConfig.keyVoiceIndex, _voiceIndex);
  }

  // Toggle dark mode
  Future<void> toggleDarkMode(bool value) async {
    _isDarkMode = value;
    notifyListeners();
    await _writeBool(AppConfig.keyDarkMode, value);
  }

  // Update voice index
  Future<void> updateVoiceIndex(int index) async {
    _voiceIndex = index;
    notifyListeners();
    await _writeInt(AppConfig.keyVoiceIndex, index);
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

    await _writeInt(AppConfig.keyLlmProviderType, providerType.index);
    await _writeString(AppConfig.keyOllamaUrl, _ollamaUrl);
    await _writeString(AppConfig.keyOllamaModel, _ollamaModel);
    await _writeString(AppConfig.keyGeminiApiUrl, _geminiApiUrl);
    await _writeString(AppConfig.keyGeminiApiKey, _geminiApiKey);
    await _writeString(AppConfig.keyGeminiModel, _geminiModel);
    await _writeString(AppConfig.keyCustomApiUrl, _customApiUrl);
    await _writeString(AppConfig.keyCustomApiKey, _customApiKey);
    await _writeString(AppConfig.keyCustomModel, _customModel);
    await _writeString(AppConfig.keyOpenRouterApiUrl, _openrouterApiUrl);
    await _writeString(AppConfig.keyOpenRouterApiKey, _openrouterApiKey);
    await _writeString(AppConfig.keyOpenRouterModel, _openrouterModel);
    await _writeString(AppConfig.keyHuggingFaceApiUrl, _huggingfaceApiUrl);
    await _writeString(AppConfig.keyHuggingFaceApiKey, _huggingfaceApiKey);
    await _writeString(AppConfig.keyHuggingFaceModel, _huggingfaceModel);
  }

  Future<String?> _readString(String key) {
    return _storage.read(key: key);
  }

  Future<int?> _readInt(String key) async {
    final value = await _readString(key);
    return value == null ? null : int.tryParse(value);
  }

  Future<bool?> _readBool(String key) async {
    final value = await _readString(key);
    return value == null ? null : bool.tryParse(value);
  }

  Future<void> _writeString(String key, String value) {
    return _storage.write(key: key, value: value);
  }

  Future<void> _writeInt(String key, int value) {
    return _writeString(key, value.toString());
  }

  Future<void> _writeBool(String key, bool value) {
    return _writeString(key, value.toString());
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

  // Get model name for a given provider type
  String getModelForProvider(LlmProviderType type) {
    switch (type) {
      case LlmProviderType.ollama:
        return _ollamaModel;
      case LlmProviderType.backend:
        return 'Backend';
      case LlmProviderType.gemini:
        return _geminiModel;
      case LlmProviderType.custom:
        return _customModel.isNotEmpty ? _customModel : 'Custom';
      case LlmProviderType.openrouter:
        return _openrouterModel;
      case LlmProviderType.huggingface:
        return _huggingfaceModel;
    }
  }
}
