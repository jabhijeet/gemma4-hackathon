filepath = "mobile/flutter_app/lib/providers/chat_provider.dart"
with open(filepath, "r", encoding="utf-8") as f:
    text = f.read()

import re

# Find the try catch block
start_str = "    try {\n      debugPrint('[CHAT_PROVIDER] Calling LlmProviderService.sendMessage..."
end_str = "    } catch (e, stackTrace) {"

start_index = text.find("    try {" + "\n      debugPrint('[CHAT_PROVIDER] Calling LlmProviderService.sendMessage...")
if start_index == -1:
    start_index = text.find("    try {")
end_index = text.find("    } catch (e, stackTrace) {")

replacement = """    try {
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
        
        // Auto-speak if the setting is enabled
        if (autoSpeak && !_requestCompleter!.isCompleted) {
          debugPrint('[CHAT_PROVIDER] Auto-speak enabled, speaking FULL response...');
          await speakText(finalResponse, language: language ?? 'english');
        }
      }
"""

new_text = text[:start_index] + replacement + text[end_index:]

with open(filepath, "w", encoding="utf-8") as f:
    f.write(new_text)

print("Patched chat_provider.dart")
