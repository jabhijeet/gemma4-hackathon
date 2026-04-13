import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

class ChatApiService {
  final String _endpoint = AppConfig.defaultBackendUrl;

  Future<Map<String, dynamic>> sendMessage(
    String text, {
    String? name,
    int? age,
    String? interests,
    String? language,
    String? mode,
  }) async {
    final requestBody = {
      "text": text,
      if (name != null && name.isNotEmpty) "name": name,
      if (age != null) "age": age,
      if (interests != null && interests.isNotEmpty) "interests": interests,
      if (language != null) "language": language,
      if (mode != null && mode.isNotEmpty && mode != 'auto') "mode": mode,
    };

    debugPrint('[CHAT_API] ========================================');
    debugPrint('[CHAT_API] Sending request to backend: $_endpoint');
    debugPrint('[CHAT_API] Request body: $requestBody');

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {AppConfig.contentTypeHeaderName: AppConfig.contentTypeJsonValue},
        body: jsonEncode(requestBody),
      );

      debugPrint('[CHAT_API] Response status code: ${response.statusCode}');
      debugPrint('[CHAT_API] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint(
            '[CHAT_API] Successfully parsed response: mode=${data["mode"]}, response length=${data["response"]?.toString().length ?? 0}');
        debugPrint('[CHAT_API] ========================================');
        return data;
      } else {
        debugPrint(
            '[CHAT_API] ERROR: Server returned status code ${response.statusCode}');
        debugPrint('[CHAT_API] Error body: ${response.body}');
        debugPrint('[CHAT_API] ========================================');
        throw Exception(
            "Server returned ${response.statusCode}: ${response.body}");
      }
    } on http.ClientException catch (e) {
      debugPrint('[CHAT_API] ERROR: Network/Connection error - $e');
      debugPrint(
          '[CHAT_API] Make sure the backend is running and IP address is correct');
      debugPrint('[CHAT_API] ========================================');
      throw Exception(
          "Cannot connect to server at $_endpoint. Check IP and ensure backend is running.");
    } catch (e) {
      debugPrint('[CHAT_API] ERROR: Unexpected error - $e');
      debugPrint('[CHAT_API] ========================================');
      throw Exception("Error: $e");
    }
  }

  String getEmoji(String mode) {
    debugPrint('[CHAT_API] Getting emoji for mode: $mode');
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
