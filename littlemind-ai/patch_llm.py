import re

filepath = "mobile/flutter_app/lib/services/llm_provider_service.dart"
with open(filepath, "r", encoding="utf-8") as f:
    text = f.read()

# Split the file exactly at "// ============================================================\n  // Prompt Building"
splitter = "  // ============================================================\n  // Prompt Building"
parts = text.split(splitter)

new_head = """import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/foundation.dart';

import '../providers/settings_provider.dart';
import '../config/app_config.dart';
import 'prompt_template_service.dart';

class LlmProviderService {
  LlmProviderService();

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
  }) async* {
    debugPrint('[LLM_PROVIDER] ========================================');
    debugPrint('[LLM_PROVIDER] Provider type: $providerType');
    debugPrint('[LLM_PROVIDER] Message: $text');

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
        throw Exception("Backend returned ${response.statusCode}");
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
        throw Exception("Ollama returned ${response.statusCode}");
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
    if (apiKey.isEmpty) throw Exception("Gemini API key is not configured");

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
      if (response.statusCode != 200) throw Exception("Gemini returned ${response.statusCode}");
      
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
    if (url.isEmpty) throw Exception("Custom API URL is not configured");

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
      if (response.statusCode != 200) throw Exception("Custom API returned ${response.statusCode}");
      
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
    if (apiKey.isEmpty) throw Exception("OpenRouter API key is not configured");

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
      if (response.statusCode != 200) throw Exception("OpenRouter returned ${response.statusCode}");
      
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

"""

with open(filepath, "w", encoding="utf-8") as f:
    f.write(new_head + splitter + parts[1])

print("Patched llm_provider_service.dart")
