import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Prompt template data structure
class PromptTemplate {
  final String systemPrompt;
  final String userMessage;

  PromptTemplate({
    required this.systemPrompt,
    required this.userMessage,
  });

  factory PromptTemplate.fromJson(Map<String, dynamic> json) {
    return PromptTemplate(
      systemPrompt: json['system_prompt'] as String,
      userMessage: json['user_message'] as String,
    );
  }
}

/// Service to load prompt templates from JSON assets
class PromptTemplateService {
  static final Map<String, PromptTemplate> _cache = {};

  /// Load a prompt template by name (story, emotion, parent)
  static Future<PromptTemplate> loadTemplate(String name) async {
    if (_cache.containsKey(name)) {
      return _cache[name]!;
    }

    try {
      final jsonString = await rootBundle.loadString('assets/prompts/$name.json');
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final template = PromptTemplate.fromJson(json);
      _cache[name] = template;
      debugPrint('[PROMPT_TEMPLATE] Loaded template: $name.json');
      return template;
    } catch (e) {
      debugPrint('[PROMPT_TEMPLATE] Error loading template $name: $e');
      rethrow;
    }
  }

  /// Fill a template string with provided values
  static String fillTemplate(String template, Map<String, String> values) {
    String result = template;
    for (final entry in values.entries) {
      result = result.replaceAll('{${entry.key}}', entry.value);
    }
    return result;
  }

  /// Clear the template cache (useful for testing or hot reload)
  static void clearCache() {
    _cache.clear();
  }
}
