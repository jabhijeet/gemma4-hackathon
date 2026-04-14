import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/foundation.dart';

import '../widgets/message_bubble.dart';
import '../widgets/input_bar.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/history_provider.dart';
import '../services/speech_service.dart';
import '../config/app_config.dart';
import 'llm_provider_settings_screen.dart';
import 'history_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  final TextEditingController controller = TextEditingController();
  final SpeechService _speechService = SpeechService();
  bool isListening = false;
  late AnimationController _animController;
  late Animation<double> _breatheAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _breatheAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    controller.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (controller.text.isEmpty) return;

    if (isListening) {
      setState(() => isListening = false);
      _animController.duration = const Duration(seconds: 2);
      _animController.repeat(reverse: true);
      _speechService.stop();
    }

    final settings = context.read<SettingsProvider>();
    final providerConfig = settings.getProviderConfig();
    final historyProvider = context.read<HistoryProvider>();
    
    // Set the voice before sending (using language-appropriate voices)
    context.read<ChatProvider>().setVoice(settings.voiceIndex, language: settings.language);
    
    context.read<ChatProvider>().sendMessage(
      controller.text,
      name: settings.name,
      age: settings.age,
      interests: settings.interests,
      language: settings.language,
      selectedMode: settings.mode,
      autoSpeak: settings.autoSpeak,
      voiceIndex: settings.voiceIndex,
      providerType: settings.llmProviderType,
      ollamaUrl: providerConfig['url'],
      ollamaModel: providerConfig['model'],
      geminiApiUrl: providerConfig['api_url'],
      geminiApiKey: providerConfig['api_key'],
      geminiModel: providerConfig['model'],
      customApiUrl: providerConfig['url'],
      customApiKey: providerConfig['api_key'],
      customModel: providerConfig['model'],
      openrouterApiUrl: providerConfig['api_url'],
      openrouterApiKey: providerConfig['api_key'],
      openrouterModel: providerConfig['model'],
      huggingfaceApiUrl: providerConfig['api_url'],
      huggingfaceApiKey: providerConfig['api_key'],
      huggingfaceModel: providerConfig['model'],
      historyProvider: historyProvider,
      providerDisplayName: settings.llmProviderDisplayName,
      modelDisplayName: providerConfig['model'] ?? 'default',
    );
    controller.clear();
  }

  void startListening() async {
    bool available = await _speechService.init();

    if (available) {
      setState(() => isListening = true);
      _animController.duration = Duration(milliseconds: 500);
      _animController.repeat(reverse: true);

      _speechService.listen((recognizedWords) {
          controller.text = recognizedWords;
      });
    }
  }

  void stopListening() {
    setState(() => isListening = false);
    _animController.duration = Duration(seconds: 2);
    _animController.repeat(reverse: true);
    _speechService.stop();

    // Issue 1: Add a small delay to ensure recognized words are fully processed
    Future.delayed(Duration(milliseconds: 300), () {
      if (controller.text.isNotEmpty) {
        _sendMessage();
      }
    });
  }

  void _showSettingsModal() {
    final settings = context.read<SettingsProvider>();
    final nameCtrl = TextEditingController(text: settings.name);
    final ageCtrl = TextEditingController(text: settings.age.toString());
    final interestsCtrl = TextEditingController(text: settings.interests);
    String currentLanguage = settings.language;
    String currentMode = settings.mode;
    bool currentAutoSpeak = settings.autoSpeak;
    bool currentDarkMode = settings.isDarkMode;
    int currentVoiceIndex = settings.voiceIndex;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                  left: 20,
                  right: 20,
                  top: 20,
                ),
                child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("⚙️ Settings & Personalization", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    SizedBox(height: 20),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(labelText: "Child's Name", border: OutlineInputBorder()),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: ageCtrl,
                      decoration: InputDecoration(labelText: "Child's Age (e.g. 5)", border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: interestsCtrl,
                      decoration: InputDecoration(labelText: "Interests (e.g. magic, trains)", border: OutlineInputBorder()),
                    ),
                    SizedBox(height: 20),
                    // Dark mode toggle
                    SwitchListTile(
                      title: Text("🌙 Dark Mode", style: TextStyle(fontSize: 16)),
                      subtitle: Text("Switch to dark theme", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      value: currentDarkMode,
                      onChanged: (val) {
                        setState(() => currentDarkMode = val);
                        settings.toggleDarkMode(val);
                      },
                    ),
                    SizedBox(height: 10),
                    // Consolidated Voice & Language section
                    Text("🗣️ Voice & Language", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    
                    // Language selection
                    Text("Language Preference:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: AppConfig.getAvailableLanguages().map((lang) {
                        final isSelected = currentLanguage == lang['code'];
                        final theme = Theme.of(context);
                        return InkWell(
                          onTap: () {
                            setState(() => currentLanguage = lang['code']!);
                            // Auto-save on change
                            settings.updateSettings(
                              name: nameCtrl.text,
                              age: int.tryParse(ageCtrl.text) ?? 5,
                              interests: interestsCtrl.text,
                              language: lang['code']!,
                              mode: currentMode,
                              autoSpeak: currentAutoSpeak,
                              voiceIndex: currentVoiceIndex,
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: isSelected ? theme.primaryColor : Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(10),
                              color: isSelected ? theme.primaryColor.withValues(alpha: 0.1) : Colors.transparent,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                  color: isSelected ? theme.primaryColor : Colors.grey,
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(lang['name']!, style: TextStyle(fontSize: 14)),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16),
                    
                    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) ...[
                      // Auto-speak toggle
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: SwitchListTile(
                          title: Text("🔊 Auto-speak responses", style: TextStyle(fontSize: 14)),
                          subtitle: Text("Automatically read LLM responses aloud", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          value: currentAutoSpeak,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (val) {
                            setState(() => currentAutoSpeak = val);
                            settings.updateSettings(
                              name: nameCtrl.text,
                              age: int.tryParse(ageCtrl.text) ?? 5,
                              interests: interestsCtrl.text,
                              language: currentLanguage,
                              mode: currentMode,
                              autoSpeak: currentAutoSpeak,
                              voiceIndex: currentVoiceIndex,
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      // Voice selection
                      Text("TTS Voice Preference:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      SizedBox(height: 8),
                    Consumer<ChatProvider>(
                      builder: (context, chatProvider, child) {
                        // Filter voices based on current language selection
                        final voiceNames = chatProvider.getVoiceDisplayNames(language: currentLanguage);
                        if (voiceNames.isEmpty) {
                          return Text('Loading voices...', style: TextStyle(color: Colors.grey));
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: voiceNames.asMap().entries.map((entry) {
                            final isSelected = currentVoiceIndex == entry.key;
                            final theme = Theme.of(context);
                            final childName = nameCtrl.text.trim();
                            final previewPhrase = childName.isNotEmpty
                                ? 'Hello, I am ${entry.value.split(' ').first}. Nice to meet you, $childName!'
                                : 'Hello! I am ${entry.value.split(' ').first}. I am your story friend!';
                            return Container(
                              margin: EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isSelected ? theme.primaryColor : Colors.grey.shade300,
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                color: isSelected
                                    ? theme.primaryColor.withValues(alpha: 0.1)
                                    : Colors.transparent,
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  setState(() => currentVoiceIndex = entry.key);
                                  settings.updateVoiceIndex(entry.key);
                                  // If TTS is paused/playing, restart with new voice
                                  if (chatProvider.isPaused || chatProvider.isSpeaking) {
                                    chatProvider.restartWithNewVoice(
                                      voiceIndex: entry.key,
                                      language: currentLanguage,
                                    );
                                  }
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                                        color: isSelected ? theme.primaryColor : Colors.grey,
                                        size: 20,
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          entry.value,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                            color: isSelected
                                                ? theme.primaryColor
                                                : theme.textTheme.bodyLarge?.color,
                                          ),
                                        ),
                                      ),
                                      // 🔊 Test voice button
                                      Tooltip(
                                        message: 'Test this voice',
                                        child: InkWell(
                                          onTap: () {
                                            // Select voice first, then preview
                                            setState(() => currentVoiceIndex = entry.key);
                                            settings.updateVoiceIndex(entry.key);
                                            chatProvider.speakVoicePreview(
                                              voiceIndex: entry.key,
                                              language: currentLanguage,
                                              previewText: previewPhrase,
                                            );
                                          },
                                          borderRadius: BorderRadius.circular(20),
                                          child: Padding(
                                            padding: EdgeInsets.all(6),
                                            child: Icon(
                                              Icons.volume_up_rounded,
                                              size: 20,
                                              color: theme.primaryColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    SizedBox(height: 16),
                    ],
                    Text("Response Mode:", style: TextStyle(fontSize: 16)),
                    RadioGroup<String>(
                      groupValue: currentMode,
                      onChanged: (val) {
                        setState(() => currentMode = val!);
                        // Auto-save on change
                        settings.updateSettings(
                          name: nameCtrl.text,
                          age: int.tryParse(ageCtrl.text) ?? 5,
                          interests: interestsCtrl.text,
                          language: currentLanguage,
                          mode: currentMode,
                          autoSpeak: currentAutoSpeak,
                          voiceIndex: currentVoiceIndex,
                        );
                      },
                      child: Column(
                        children: [
                          _buildModeOption('auto', '🤖 Auto Detect', 'Let AI choose', currentMode),
                          _buildModeOption('story', '🌈 Story Mode', 'Magical stories', currentMode),
                          _buildModeOption('emotion', '🌙 Emotion Support', 'Gentle emotional guidance', currentMode),
                          _buildModeOption('parent', '👨‍👩‍👧 Parent Mode', 'Parenting advice', currentMode),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    // LLM Provider Settings Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx); // Close current modal
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LlmProviderSettingsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.dns),
                        label: const Text('⚡ LLM Provider Settings'),
                      ),
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          settings.updateSettings(
                            name: nameCtrl.text,
                            age: int.tryParse(ageCtrl.text) ?? 5,
                            interests: interestsCtrl.text,
                            language: currentLanguage,
                            mode: currentMode,
                            autoSpeak: currentAutoSpeak,
                            voiceIndex: currentVoiceIndex,
                          );
                          Navigator.pop(ctx);
                        },
                        child: Text("Save Preferences", style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            );
          },
        );
      },
    );
  }

  Widget _buildModeOption(String value, String title, String subtitle, String currentMode) {
    final isSelected = currentMode == value;
    final theme = Theme.of(context);
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: isSelected ? theme.primaryColor : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
        color: isSelected ? theme.primaryColor.withValues(alpha: 0.1) : theme.cardColor,
      ),
      child: RadioListTile<String>(
        title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12)),
        value: value,
        activeColor: theme.primaryColor,
        contentPadding: EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final isDark = settings.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(isDark ? "🌙 LittleMind AI" : "🌈 LittleMind AI"),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_stories_rounded),
            tooltip: 'Story Journal',
            onPressed: () async {
              final reAskQuery = await Navigator.push<String>(
                context,
                MaterialPageRoute(
                  builder: (context) => const HistoryScreen(),
                ),
              );
              // If a re-ask query came back, populate the input
              if (reAskQuery != null && mounted) {
                controller.text = reAskQuery;
              }
            },
          ),
          // LLM Provider dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: SizedBox(
              width: 150,
              child: DropdownButton<LlmProviderType>(
                value: settings.llmProviderType,
                icon: const Icon(Icons.arrow_drop_down, size: 20),
                elevation: 16,
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                underline: Container(
                  height: 0,
                ),
                dropdownColor: theme.colorScheme.surface,
                onChanged: (LlmProviderType? newValue) {
                  if (newValue != null && newValue != settings.llmProviderType) {
                    // Update provider type, keep existing configuration
                    settings.updateLlmProvider(
                      providerType: newValue,
                      ollamaUrl: null,
                      ollamaModel: null,
                      geminiApiUrl: null,
                      geminiApiKey: null,
                      geminiModel: null,
                      customApiUrl: null,
                      customApiKey: null,
                      customModel: null,
                      openrouterApiUrl: null,
                      openrouterApiKey: null,
                      openrouterModel: null,
                      huggingfaceApiUrl: null,
                      huggingfaceApiKey: null,
                      huggingfaceModel: null,
                    );
                  }
                },
                items: LlmProviderType.values.map<DropdownMenuItem<LlmProviderType>>((LlmProviderType type) {
                  String displayName;
                  switch (type) {
                    case LlmProviderType.ollama:
                      displayName = AppConfig.ollamaDisplayName;
                      break;
                    case LlmProviderType.backend:
                      displayName = AppConfig.backendDisplayName;
                      break;
                    case LlmProviderType.gemini:
                      displayName = AppConfig.geminiDisplayName;
                      break;
                    case LlmProviderType.custom:
                      displayName = AppConfig.customDisplayName;
                      break;
                    case LlmProviderType.openrouter:
                      displayName = AppConfig.openRouterDisplayName;
                      break;
                    case LlmProviderType.huggingface:
                      displayName = AppConfig.huggingFaceDisplayName;
                      break;
                  }
                  final model = settings.getModelForProvider(type);
                  return DropdownMenuItem<LlmProviderType>(
                    value: type,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          model,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => _showSettingsModal(),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF232D3F),
                    const Color(0xFF2D3A4F),
                  ]
                : [
                    const Color(0xFFE8F4FD),
                    const Color(0xFFE8F5E9),
                  ],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                children: [
                   ScaleTransition(
                     scale: chatProvider.isLoading ?
                            Tween<double>(begin: 1.0, end: 1.2).animate(CurvedAnimation(parent: _animController, curve: Curves.bounceIn))
                            : _breatheAnimation,
                     child: Text(
                        "🐼",
                        style: TextStyle(fontSize: 60),
                     ),
                   ),
                   SizedBox(height: 10),
                  Text(
                    "Hi ${settings.name.isNotEmpty ? settings.name : 'Friend'}! I'm your story friend",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    chatProvider.isLoading ? "Thinking of a story... 💭" : "Tap 🎤 and speak to me!",
                    style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: chatProvider.messages.length + (chatProvider.isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == chatProvider.messages.length) {
                    return Padding(
                      padding: EdgeInsets.all(10),
                      child: SpinKitThreeBounce(
                        color: theme.primaryColor,
                        size: 20,
                      ),
                    );
                  }
                  
                  final msg = chatProvider.messages[index];
                  return MessageBubble(
                    text: msg.text,
                    isUser: msg.role == "user",
                    isError: msg.isError,
                    errorDetail: msg.errorDetail,
                    language: settings.language,
                  );
                },
              ),
            ),
            // TTS control overlay
            if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android && (chatProvider.isSpeaking || chatProvider.isPaused))
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          chatProvider.isPaused ? Icons.pause_circle : Icons.volume_up,
                          color: theme.primaryColor,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          chatProvider.isPaused ? 'Paused' : 'Reading...',
                          style: TextStyle(color: theme.primaryColor, fontSize: 14),
                        ),
                        // Show progress if available
                        if (chatProvider.ttsProgress > 0)
                          Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Text(
                              '${(chatProvider.ttsProgress * 100).toInt()}%',
                              style: TextStyle(color: theme.primaryColor.withValues(alpha: 0.7), fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                    Row(
                      children: [
                        // Pause/Resume button
                        IconButton(
                          icon: Icon(
                            chatProvider.isPaused ? Icons.play_arrow : Icons.pause,
                            color: theme.primaryColor,
                            size: 20,
                          ),
                          onPressed: () => chatProvider.togglePauseResume(),
                          tooltip: chatProvider.isPaused ? 'Resume' : 'Pause',
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                        SizedBox(width: 8),
                        // Stop button
                        IconButton(
                          icon: Icon(Icons.stop, color: Colors.red, size: 20),
                          onPressed: () => chatProvider.stopSpeaking(),
                          tooltip: 'Stop reading',
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            SafeArea(
              child: Stack(
                alignment: Alignment.centerRight,
                children: [
                  InputBar(
                    controller: controller,
                    onSend: (text) => _sendMessage(),
                    onMicPressed: () {
                      isListening ? stopListening() : startListening();
                    },
                    isListening: isListening,
                    isDarkMode: isDark,
                  ),
                  // Cancel button during loading
                  if (chatProvider.isLoading)
                    Container(
                      margin: EdgeInsets.only(right: 80),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.stop, color: Colors.white, size: 20),
                        onPressed: () => chatProvider.cancelRequest(),
                        tooltip: 'Cancel request',
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
