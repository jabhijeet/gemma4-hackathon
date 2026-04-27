import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../providers/settings_provider.dart';
import '../config/app_config.dart';
import 'prompt_template_service.dart';

class LlmProviderService {
  LlmProviderService();

  /// Convert HTTP status codes into friendly error messages
  String _friendlyHttpError(int statusCode, String provider) {
    switch (statusCode) {
      case 400:
        return 'The request to $provider was invalid. Please check your model name and settings.';
      case 401:
        return 'Your $provider API key is invalid or expired. Please update it in LLM Provider Settings.';
      case 403:
        return 'Access denied by $provider. Your API key may not have permission to use this model.';
      case 404:
        return 'The model was not found on $provider. Please check the model name in settings.';
      case 429:
        return '$provider is rate limiting your requests. Please wait a moment and try again.';
      case 500:
        return '$provider is experiencing server issues. Please try again later.';
      case 502:
      case 503:
        return '$provider is temporarily unavailable. Please try again in a few minutes.';
      default:
        return 'Something went wrong with $provider (error $statusCode). Please try again.';
    }
  }

  /// Send a message to the configured LLM provider and stream the response
  Stream<Map<String, dynamic>> sendMessageStream(
    String text, {
    required LlmProviderType providerType,
    String? name,
    int? age,
    String? interests,
    String? language,
    String? mode,
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
  }) async* {
    debugPrint('[LLM_PROVIDER] ========================================');
    debugPrint('[LLM_PROVIDER] Provider type: $providerType');
    debugPrint('[LLM_PROVIDER] Message: [ENCRYPTED CONTENT]');

    // Build prompt using backend-style mode detection
    final promptData = await _buildPrompt(text,
        name: name,
        age: age,
        interests: interests,
        language: language,
        mode: mode);
    debugPrint('[LLM_PROVIDER] Detected mode: ${promptData['mode']}');
    
    final pMode = promptData['mode'] as String;
    final systemPrompt = promptData['system_prompt'] as String;
    final userMessage = promptData['user_message'] as String;

    switch (providerType) {
      case LlmProviderType.ollama:
        yield* _sendToOllama(
          userMessage,
          systemPrompt: systemPrompt,
          url: ollamaUrl ?? AppConfig.defaultOllamaUrl,
          model: ollamaModel ?? AppConfig.defaultOllamaModel,
          detectedMode: pMode,
        );
        break;
      case LlmProviderType.backend:
        yield* _sendToBackend(
          text,
          name: name,
          age: age,
          interests: interests,
          language: language,
          mode: mode,
        );
        break;
      case LlmProviderType.gemini:
        yield* _sendToGemini(
          userMessage,
          systemPrompt: systemPrompt,
          apiUrl: geminiApiUrl ?? AppConfig.defaultGeminiUrl,
          apiKey: geminiApiKey ?? '',
          model: geminiModel ?? AppConfig.defaultGeminiModel,
          detectedMode: pMode,
        );
        break;
      case LlmProviderType.custom:
        yield* _sendToCustom(
          userMessage,
          systemPrompt: systemPrompt,
          url: customApiUrl ?? '',
          apiKey: customApiKey,
          model: customModel ?? '',
          detectedMode: pMode,
        );
        break;
      case LlmProviderType.openrouter:
        yield* _sendToOpenRouter(
          userMessage,
          systemPrompt: systemPrompt,
          apiUrl: openrouterApiUrl ?? AppConfig.defaultOpenRouterUrl,
          apiKey: openrouterApiKey ?? '',
          model: openrouterModel ?? AppConfig.defaultOpenRouterModel,
          detectedMode: pMode,
        );
        break;
      case LlmProviderType.huggingface:
        yield* _sendToHuggingFace(
          userMessage,
          systemPrompt: systemPrompt,
          apiUrl: huggingfaceApiUrl ?? AppConfig.defaultHuggingFaceUrl,
          apiKey: huggingfaceApiKey ?? '',
          model: huggingfaceModel ?? AppConfig.defaultHuggingFaceModel,
          detectedMode: pMode,
        );
        break;
    }
  }

  /// Stream from backend FastAPI SSE
  Stream<Map<String, dynamic>> _sendToBackend(
    String text, {
    String? name,
    int? age,
    String? interests,
    String? language,
    String? mode,
  }) async* {
    final endpoint = AppConfig.defaultBackendStreamUrl;
    final requestBody = {
      "text": text,
      if (name != null && name.isNotEmpty) "name": name,
      if (age != null) "age": age,
      if (interests != null && interests.isNotEmpty) "interests": interests,
      if (language != null) "language": language,
      if (mode != null && mode.isNotEmpty && mode != 'auto') "mode": mode,
    };

    debugPrint('[LLM_PROVIDER] Streaming from backend: $endpoint');

    final request = http.Request('POST', Uri.parse(endpoint));
    request.headers[AppConfig.contentTypeHeaderName] = AppConfig.contentTypeJsonValue;
    request.body = jsonEncode(requestBody);

    try {
      final response = await request.send().timeout(const Duration(seconds: 60));
      if (response.statusCode != 200) {
        throw Exception(_friendlyHttpError(response.statusCode, 'LittleMind Backend'));
      }
      
      String accumulated = "";
      String finalMode = mode ?? "auto";

      await for (final line in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
        if (line.trim().isEmpty) continue;
        if (line.startsWith("data: ")) {
          final dataStr = line.substring(6).trim();
          if (dataStr == "[DONE]") break;
          try {
            final data = jsonDecode(dataStr);
            if (data["mode"] != null) finalMode = data["mode"];
            if (data["response"] != null) {
              accumulated += data["response"];
              yield {"response": accumulated, "mode": finalMode};
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('[LLM_PROVIDER] Backend error: $e');
      rethrow;
    }
  }

  /// Stream from local Ollama (NDJSON format)
  Stream<Map<String, dynamic>> _sendToOllama(
    String userMessage, {
    required String systemPrompt,
    required String url,
    required String model,
    required String detectedMode,
  }) async* {
    final requestBody = {
      "model": model,
      "messages": [
        {"role": "system", "content": systemPrompt},
        {"role": "user", "content": userMessage},
      ],
      "stream": true,
      "options": {
        "temperature": AppConfig.defaultTemperature,
        "num_predict": AppConfig.defaultMaxTokens,
        "top_p": AppConfig.defaultTopP,
      }
    };

    final request = http.Request('POST', Uri.parse(url));
    request.headers[AppConfig.contentTypeHeaderName] = AppConfig.contentTypeJsonValue;
    request.body = jsonEncode(requestBody);

    debugPrint('[LLM_PROVIDER] Streaming from Ollama: $url');

    try {
      final response = await request.send().timeout(const Duration(seconds: 60));
      if (response.statusCode != 200) {
        throw Exception(_friendlyHttpError(response.statusCode, 'Ollama'));
      }
      
      String accumulated = "";
      await for (final line in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
        if (line.trim().isEmpty) continue;
        try {
          final data = jsonDecode(line);
          String chunk = '';
          if (data['message'] != null && data['message']['content'] != null) {
            chunk = data['message']['content'];
          } else if (data['response'] != null) {
            chunk = data['response'];
          }
          if (chunk.isNotEmpty) {
            accumulated += chunk;
            yield {"response": accumulated, "mode": detectedMode};
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[LLM_PROVIDER] Ollama error: $e');
      rethrow;
    }
  }

  /// Stream from Google Gemini (SSE format)
  Stream<Map<String, dynamic>> _sendToGemini(
    String userMessage, {
    required String systemPrompt,
    required String apiUrl,
    required String apiKey,
    required String model,
    required String detectedMode,
  }) async* {
    if (apiKey.isEmpty) throw Exception('Please add your Gemini API key in LLM Provider Settings.');

    final url = '$apiUrl$model:streamGenerateContent?alt=sse&key=$apiKey';
    final requestBody = {
      "system_instruction": {"parts": [{"text": systemPrompt}]},
      "contents": [{"parts": [{"text": userMessage}]}],
      "generationConfig": {
        "temperature": AppConfig.defaultTemperature,
        "maxOutputTokens": AppConfig.defaultMaxTokens,
        "topP": AppConfig.defaultTopP,
      }
    };

    final request = http.Request('POST', Uri.parse(url));
    request.headers[AppConfig.contentTypeHeaderName] = AppConfig.contentTypeJsonValue;
    request.body = jsonEncode(requestBody);

    debugPrint('[LLM_PROVIDER] Streaming from Gemini (SSE)');

    try {
      final response = await request.send().timeout(const Duration(seconds: 60));
      if (response.statusCode != 200) {
        final errorBody = await response.stream.bytesToString();
        debugPrint('[LLM_PROVIDER] Gemini error body: $errorBody');
        throw Exception(_friendlyHttpError(response.statusCode, 'Google Gemini'));
      }
      
      String accumulated = "";
      await for (final line in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
        if (line.trim().isEmpty) continue;
        if (line.startsWith("data: ")) {
          final dataStr = line.substring(6).trim();
          try {
            final data = jsonDecode(dataStr);
            String chunk = '';
            if (data['candidates'] != null && data['candidates'].isNotEmpty &&
                data['candidates'][0]['content'] != null &&
                data['candidates'][0]['content']['parts'] != null &&
                data['candidates'][0]['content']['parts'].isNotEmpty) {
              chunk = data['candidates'][0]['content']['parts'][0]['text'] ?? '';
            }
            if (chunk.isNotEmpty) {
              accumulated += chunk;
              yield {"response": accumulated, "mode": detectedMode};
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('[LLM_PROVIDER] Gemini error: $e');
      rethrow;
    }
  }

  /// Stream from custom API (OpenAI SSE format)
  Stream<Map<String, dynamic>> _sendToCustom(
    String userMessage, {
    required String systemPrompt,
    required String url,
    String? apiKey,
    required String model,
    required String detectedMode,
  }) async* {
    if (url.isEmpty) throw Exception('Please set your Custom API URL in LLM Provider Settings.');

    final requestBody = {
      "model": model,
      "messages": [
        {"role": "system", "content": systemPrompt},
        {"role": "user", "content": userMessage},
      ],
      "stream": true,
      "temperature": AppConfig.defaultTemperature,
      "max_tokens": AppConfig.defaultMaxTokens,
    };

    final request = http.Request('POST', Uri.parse(url));
    request.headers[AppConfig.contentTypeHeaderName] = AppConfig.contentTypeJsonValue;
    if (apiKey != null && apiKey.isNotEmpty) {
      request.headers["Authorization"] = "Bearer $apiKey";
    }
    request.body = jsonEncode(requestBody);

    debugPrint('[LLM_PROVIDER] Streaming from Custom API');

    try {
      final response = await request.send().timeout(const Duration(seconds: 60));
      if (response.statusCode != 200) {
        final errorBody = await response.stream.bytesToString();
        debugPrint('[LLM_PROVIDER] Custom API error body: $errorBody');
        throw Exception(_friendlyHttpError(response.statusCode, 'Custom API'));
      }
      
      String accumulated = "";
      await for (final line in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
        if (line.trim().isEmpty) continue;
        if (line.startsWith("data: ")) {
          final dataStr = line.substring(6).trim();
          if (dataStr == "[DONE]") break;
          try {
            final data = jsonDecode(dataStr);
            String chunk = '';
            if (data['choices'] != null && data['choices'].isNotEmpty &&
                data['choices'][0]['delta'] != null &&
                data['choices'][0]['delta']['content'] != null) {
              chunk = data['choices'][0]['delta']['content'];
            }
            if (chunk.isNotEmpty) {
              accumulated += chunk;
              yield {"response": accumulated, "mode": detectedMode};
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('[LLM_PROVIDER] Custom API error: $e');
      rethrow;
    }
  }

  /// Stream from OpenRouter (OpenAI SSE format)
  Stream<Map<String, dynamic>> _sendToOpenRouter(
    String userMessage, {
    required String systemPrompt,
    required String apiUrl,
    required String apiKey,
    required String model,
    required String detectedMode,
  }) async* {
    if (apiKey.isEmpty) throw Exception('Please add your OpenRouter API key in LLM Provider Settings.');

    final requestBody = {
      "model": model,
      "messages": [
        {"role": "system", "content": systemPrompt},
        {"role": "user", "content": userMessage},
      ],
      "stream": true,
      "temperature": AppConfig.defaultTemperature,
      "max_tokens": AppConfig.defaultMaxTokens,
    };

    final request = http.Request('POST', Uri.parse(apiUrl));
    request.headers[AppConfig.contentTypeHeaderName] = AppConfig.contentTypeJsonValue;
    request.headers["Authorization"] = "Bearer $apiKey";
    request.headers["HTTP-Referer"] = AppConfig.openRouterReferer;
    request.headers["X-Title"] = AppConfig.openRouterTitle;
    request.body = jsonEncode(requestBody);

    debugPrint('[LLM_PROVIDER] Streaming from OpenRouter');

    try {
      final response = await request.send().timeout(const Duration(seconds: 60));
      if (response.statusCode != 200) {
        final errorBody = await response.stream.bytesToString();
        debugPrint('[LLM_PROVIDER] OpenRouter error body: $errorBody');
        throw Exception(_friendlyHttpError(response.statusCode, 'OpenRouter'));
      }
      
      String accumulated = "";
      await for (final line in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
        if (line.trim().isEmpty) continue;
        if (line.startsWith("data: ")) {
          final dataStr = line.substring(6).trim();
          if (dataStr == "[DONE]") break;
          try {
            final data = jsonDecode(dataStr);
            String chunk = '';
            if (data['choices'] != null && data['choices'].isNotEmpty &&
                data['choices'][0]['delta'] != null &&
                data['choices'][0]['delta']['content'] != null) {
              chunk = data['choices'][0]['delta']['content'];
            }
            if (chunk.isNotEmpty) {
              accumulated += chunk;
              yield {"response": accumulated, "mode": detectedMode};
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('[LLM_PROVIDER] OpenRouter error: $e');
      rethrow;
    }
  }

  /// Stream from Hugging Face Inference API (OpenAI-compatible SSE format)
  Stream<Map<String, dynamic>> _sendToHuggingFace(
    String userMessage, {
    required String systemPrompt,
    required String apiUrl,
    required String apiKey,
    required String model,
    required String detectedMode,
  }) async* {
    if (apiKey.isEmpty) throw Exception('Please add your Hugging Face API token in LLM Provider Settings.');

    // HuggingFace uses: {baseUrl}{model}/v1/chat/completions
    final url = '${apiUrl.endsWith('/') ? apiUrl : '$apiUrl/'}$model/v1/chat/completions';
    final requestBody = {
      "model": model,
      "messages": [
        {"role": "system", "content": systemPrompt},
        {"role": "user", "content": userMessage},
      ],
      "stream": true,
      "temperature": AppConfig.defaultTemperature,
      "max_tokens": AppConfig.defaultMaxTokens,
    };

    final request = http.Request('POST', Uri.parse(url));
    request.headers[AppConfig.contentTypeHeaderName] = AppConfig.contentTypeJsonValue;
    request.headers["Authorization"] = "Bearer $apiKey";
    request.body = jsonEncode(requestBody);

    debugPrint('[LLM_PROVIDER] Streaming from Hugging Face: $url');

    try {
      final response = await request.send().timeout(const Duration(seconds: 60));
      if (response.statusCode != 200) {
        final errorBody = await response.stream.bytesToString();
        debugPrint('[LLM_PROVIDER] HuggingFace error body: $errorBody');
        throw Exception(_friendlyHttpError(response.statusCode, 'Hugging Face'));
      }
      
      String accumulated = "";
      await for (final line in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
        if (line.trim().isEmpty) continue;
        if (line.startsWith("data: ")) {
          final dataStr = line.substring(6).trim();
          if (dataStr == "[DONE]") break;
          try {
            final data = jsonDecode(dataStr);
            String chunk = '';
            if (data['choices'] != null && data['choices'].isNotEmpty &&
                data['choices'][0]['delta'] != null &&
                data['choices'][0]['delta']['content'] != null) {
              chunk = data['choices'][0]['delta']['content'];
            }
            if (chunk.isNotEmpty) {
              accumulated += chunk;
              yield {"response": accumulated, "mode": detectedMode};
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('[LLM_PROVIDER] Hugging Face error: $e');
      rethrow;
    }
  }

  // ============================================================
  // Prompt Building (mirrors backend modes.py and prompts.py)
  // ============================================================

  /// Build prompt using backend-style mode detection (from modes.py build_prompt)
  Future<Map<String, dynamic>> _buildPrompt(
    String text, {
    String? name,
    int? age,
    String? interests,
    String? language,
    String? mode,
  }) async {
    final childName = name?.isNotEmpty == true ? name! : 'the child';
    final childAge = age ?? 5;
    final detectedMode =
        mode?.isNotEmpty == true && mode != 'auto' ? mode! : _detectMode(text);

    debugPrint(
        '[LLM_PROVIDER] Building prompt: name=$childName, age=$childAge, language=$language, mode=$detectedMode');

    switch (detectedMode) {
      case 'story':
        return await _buildStoryPrompt(
            text, childName, childAge, interests, language);
      case 'emotion':
        return await _buildEmotionPrompt(text, childName, childAge, language);
      case 'parent':
        return await _buildParentPrompt(text, childName, childAge, language);
      default:
        return await _buildStoryPrompt(
            text, childName, childAge, interests, language);
    }
  }

  /// Detect mode based on user input (from modes.py detect_mode)
  String _detectMode(String userInput) {
    final text = userInput.toLowerCase();

    final emotionalKeywords = [
      'scared',
      'afraid',
      'sad',
      'angry',
      'cry',
      'dark',
      'lonely',
      'worried',
      'nervous',
      'upset'
    ];
    final parentKeywords = [
      'how do i explain',
      'my child',
      'how to tell my child',
      'parenting',
      'discipline'
    ];

    if (emotionalKeywords.any((word) => text.contains(word))) {
      debugPrint(
          '[LLM_PROVIDER] Detected emotion mode based on emotional keywords');
      return 'emotion';
    }

    if (parentKeywords.any((keyword) => text.contains(keyword))) {
      debugPrint(
          '[LLM_PROVIDER] Detected parent mode based on parent-related keywords');
      return 'parent';
    }

    debugPrint('[LLM_PROVIDER] Defaulting to story mode');
    return 'story';
  }

  /// Build story prompt (from prompts.py story_prompt)
  Future<Map<String, dynamic>> _buildStoryPrompt(
    String text,
    String childName,
    int childAge,
    String? interests,
    String? language,
  ) async {
    final interestsText = interests?.isNotEmpty == true ? interests! : '';
    final hinglishText = _getHinglishInstruction(language);

    final template = await PromptTemplateService.loadTemplate('story');

    final systemPrompt = PromptTemplateService.fillTemplate(
      template.systemPrompt,
      {'hinglishText': hinglishText},
    );

    final userMessage = PromptTemplateService.fillTemplate(
      template.userMessage,
      {
        'childName': childName,
        'childAge': childAge.toString(),
        'text': text,
        'interestsText': interestsText,
      },
    );

    return {
      'system_prompt': systemPrompt,
      'user_message': userMessage,
      'mode': 'story',
    };
  }

  /// Build emotion prompt (from prompts.py emotion_prompt)
  Future<Map<String, dynamic>> _buildEmotionPrompt(
    String text,
    String childName,
    int childAge,
    String? language,
  ) async {
    final hinglishText = _getHinglishInstruction(language);

    final template = await PromptTemplateService.loadTemplate('emotion');

    final systemPrompt = PromptTemplateService.fillTemplate(
      template.systemPrompt,
      {'hinglishText': hinglishText},
    );

    final userMessage = PromptTemplateService.fillTemplate(
      template.userMessage,
      {
        'childName': childName,
        'childAge': childAge.toString(),
        'text': text,
      },
    );

    return {
      'system_prompt': systemPrompt,
      'user_message': userMessage,
      'mode': 'emotion',
    };
  }

  /// Build parent prompt (from prompts.py parent_prompt)
  Future<Map<String, dynamic>> _buildParentPrompt(
    String text,
    String childName,
    int childAge,
    String? language,
  ) async {
    final hinglishText = _getHinglishInstruction(language);

    final template = await PromptTemplateService.loadTemplate('parent');

    final systemPrompt = PromptTemplateService.fillTemplate(
      template.systemPrompt,
      {
        'hinglish': hinglishText,
      },
    );

    final userMessage = PromptTemplateService.fillTemplate(
      template.userMessage,
      {
        'childName': childName,
        'childAge': childAge.toString(),
        'text': text,
        'interestsText': '',
      },
    );

    return {
      'system_prompt': systemPrompt,
      'user_message': userMessage,
      'mode': 'parent',
    };
  }

  /// Get Hinglish language instruction (from prompts.py _get_hinglish_instruction)
  String _getHinglishInstruction(String? language) {
    if (language?.toLowerCase() == 'hinglish') {
      debugPrint('[LLM_PROVIDER] Hinglish language mode enabled');
      return "- IMPORTANT: Respond entirely in Hinglish (conversational Hindi written in English vocabulary/alphabet). Example: 'Tum ek bahot brave bache ho! Chalo ek kahani sunte hain.' Do NOT write in English or Devanagari script.";
    }
    return '';
  }

  /// Get emoji for response mode
  String getEmoji(String mode) {
    switch (mode) {
      case "emotion":
        return "🌙";
      case "parent":
        return "👨‍👩‍👧";
      default:
        return "🌈";
    }
  }
}
