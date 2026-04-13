import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../config/app_config.dart';

class LlmProviderSettingsScreen extends StatefulWidget {
  const LlmProviderSettingsScreen({super.key});

  @override
  State<LlmProviderSettingsScreen> createState() =>
      _LlmProviderSettingsScreenState();
}

class _LlmProviderSettingsScreenState extends State<LlmProviderSettingsScreen> {
  late LlmProviderType _selectedProvider;
  late TextEditingController _ollamaUrlController;
  late TextEditingController _ollamaModelController;
  late TextEditingController _geminiApiUrlController;
  late TextEditingController _geminiApiKeyController;
  late TextEditingController _geminiModelController;
  late TextEditingController _customApiUrlController;
  late TextEditingController _customApiKeyController;
  late TextEditingController _customModelController;
  late TextEditingController _openrouterApiUrlController;
  late TextEditingController _openrouterApiKeyController;
  late TextEditingController _openrouterModelController;
  late TextEditingController _huggingfaceApiUrlController;
  late TextEditingController _huggingfaceApiKeyController;
  late TextEditingController _huggingfaceModelController;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _selectedProvider = settings.llmProviderType;
    _ollamaUrlController = TextEditingController(text: settings.ollamaUrl);
    _ollamaModelController = TextEditingController(text: settings.ollamaModel);
    _geminiApiUrlController = TextEditingController(text: settings.geminiApiUrl);
    _geminiApiKeyController =
        TextEditingController(text: settings.geminiApiKey);
    _geminiModelController = TextEditingController(text: settings.geminiModel);
    _customApiUrlController =
        TextEditingController(text: settings.customApiUrl);
    _customApiKeyController =
        TextEditingController(text: settings.customApiKey);
    _customModelController = TextEditingController(text: settings.customModel);
    _openrouterApiUrlController =
        TextEditingController(text: settings.openrouterApiUrl);
    _openrouterApiKeyController =
        TextEditingController(text: settings.openrouterApiKey);
    _openrouterModelController =
        TextEditingController(text: settings.openrouterModel);
    _huggingfaceApiUrlController =
        TextEditingController(text: settings.huggingfaceApiUrl);
    _huggingfaceApiKeyController =
        TextEditingController(text: settings.huggingfaceApiKey);
    _huggingfaceModelController =
        TextEditingController(text: settings.huggingfaceModel);
  }

  @override
  void dispose() {
    _ollamaUrlController.dispose();
    _ollamaModelController.dispose();
    _geminiApiUrlController.dispose();
    _geminiApiKeyController.dispose();
    _geminiModelController.dispose();
    _customApiUrlController.dispose();
    _customApiKeyController.dispose();
    _customModelController.dispose();
    _openrouterApiUrlController.dispose();
    _openrouterApiKeyController.dispose();
    _openrouterModelController.dispose();
    _huggingfaceApiUrlController.dispose();
    _huggingfaceApiKeyController.dispose();
    _huggingfaceModelController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final settings = context.read<SettingsProvider>();
    await settings.updateLlmProvider(
      providerType: _selectedProvider,
      ollamaUrl: _ollamaUrlController.text,
      ollamaModel: _ollamaModelController.text,
      geminiApiUrl: _geminiApiUrlController.text,
      geminiApiKey: _geminiApiKeyController.text,
      geminiModel: _geminiModelController.text,
      customApiUrl: _customApiUrlController.text,
      customApiKey: _customApiKeyController.text,
      customModel: _customModelController.text,
      openrouterApiUrl: _openrouterApiUrlController.text,
      openrouterApiKey: _openrouterApiKeyController.text,
      openrouterModel: _openrouterModelController.text,
      huggingfaceApiUrl: _huggingfaceApiUrlController.text,
      huggingfaceApiKey: _huggingfaceApiKeyController.text,
      huggingfaceModel: _huggingfaceModelController.text,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('LLM Provider settings saved!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('LLM Provider Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Select LLM Provider',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
            ),
            const SizedBox(height: 16),
            RadioGroup<LlmProviderType>(
              groupValue: _selectedProvider,
              onChanged: (value) {
                setState(() {
                  _selectedProvider = value!;
                });
              },
              child: Column(
                children: [
                  _buildProviderOption(LlmProviderType.ollama, '🏠',
                      'Local Ollama', 'Run Ollama locally on your network'),
                  _buildProviderOption(LlmProviderType.gemini, '🌐',
                      'Google Gemini', 'Use Google Gemini API'),
                  _buildProviderOption(LlmProviderType.custom, '🔧',
                      'Custom API', 'Use a custom OpenAI-compatible API'),
                  _buildProviderOption(LlmProviderType.openrouter, '🔗',
                      'OpenRouter', 'Use OpenRouter API (${AppConfig.defaultOpenRouterModel})'),
                  _buildProviderOption(LlmProviderType.huggingface, '🤗',
                      'Hugging Face', 'Use HF Inference API (${AppConfig.defaultHuggingFaceModel})'),
                  _buildProviderOption(LlmProviderType.backend, '🖥️',
                      'LittleMind Backend', 'Use existing backend server'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            if (_selectedProvider == LlmProviderType.ollama)
              ..._buildOllamaSettings(),
            if (_selectedProvider == LlmProviderType.gemini)
              ..._buildGeminiSettings(),
            if (_selectedProvider == LlmProviderType.custom)
              ..._buildCustomSettings(),
            if (_selectedProvider == LlmProviderType.openrouter)
              ..._buildOpenRouterSettings(),
            if (_selectedProvider == LlmProviderType.huggingface)
              ..._buildHuggingFaceSettings(),
            if (_selectedProvider == LlmProviderType.backend)
              ..._buildBackendInfo(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveSettings,
                icon: const Icon(Icons.save),
                label:
                    const Text('Save Settings', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderOption(
      LlmProviderType type, String emoji, String title, String description) {
    final isSelected = _selectedProvider == type;
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(
            color: isSelected ? theme.primaryColor : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: isSelected ? theme.primaryColor.withValues(alpha: 0.1) : theme.cardColor,
      ),
      child: ListTile(
        leading: Radio<LlmProviderType>(
          value: type,
          activeColor: theme.primaryColor,
        ),
        title: Text('$emoji $title',
            style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        subtitle: Text(description, style: const TextStyle(fontSize: 12)),
        onTap: () {
          setState(() {
            _selectedProvider = type;
          });
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  List<Widget> _buildOllamaSettings() {
    return [
      const Text('Ollama Configuration',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      TextField(
        controller: _ollamaUrlController,
        decoration: InputDecoration(
          labelText: 'Ollama API URL',
          hintText: AppConfig.defaultOllamaUrl,
          border: const OutlineInputBorder(),
          helperText: 'URL to your Ollama instance',
        ),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _ollamaModelController,
        decoration: InputDecoration(
          labelText: 'Model Name',
          hintText: AppConfig.defaultOllamaModel,
          border: const OutlineInputBorder(),
          helperText: 'Ollama model to use',
        ),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Make sure Ollama is running and accessible from your device. Check that CORS is enabled if accessing from web.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildGeminiSettings() {
    return [
      const Text('Google Gemini Configuration',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      TextField(
        controller: _geminiApiUrlController,
        decoration: InputDecoration(
          labelText: 'API URL',
          hintText: AppConfig.defaultGeminiUrl,
          border: const OutlineInputBorder(),
          helperText: 'Base URL for Gemini API',
        ),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _geminiApiKeyController,
        decoration: const InputDecoration(
          labelText: 'API Key',
          hintText: 'Enter your Gemini API key',
          border: OutlineInputBorder(),
          helperText: 'Get your API key from Google AI Studio',
        ),
        obscureText: true,
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _geminiModelController,
        decoration: InputDecoration(
          labelText: 'Model Name',
          hintText: AppConfig.defaultGeminiModel,
          border: const OutlineInputBorder(),
          helperText: 'Gemini model to use',
        ),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Get your API key from https://aistudio.google.com/apikey. Free tier available with rate limits.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildCustomSettings() {
    return [
      const Text('Custom API Configuration',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      TextField(
        controller: _customApiUrlController,
        decoration: const InputDecoration(
          labelText: 'API URL',
          hintText: 'https://your-api.com/v1/chat/completions',
          border: OutlineInputBorder(),
          helperText: 'OpenAI-compatible chat completions endpoint',
        ),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _customApiKeyController,
        decoration: const InputDecoration(
          labelText: 'API Key (Optional)',
          hintText: 'Enter your API key if required',
          border: OutlineInputBorder(),
        ),
        obscureText: true,
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _customModelController,
        decoration: const InputDecoration(
          labelText: 'Model Name (Optional)',
          hintText: 'gpt-4, llama-3, etc.',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Use any OpenAI-compatible API endpoint. The API expects the standard chat completions format.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildOpenRouterSettings() {
    return [
      const Text('OpenRouter Configuration',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      TextField(
        controller: _openrouterApiUrlController,
        decoration: InputDecoration(
          labelText: 'API URL',
          hintText: AppConfig.defaultOpenRouterUrl,
          border: const OutlineInputBorder(),
          helperText: 'OpenRouter API endpoint',
        ),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _openrouterApiKeyController,
        decoration: const InputDecoration(
          labelText: 'API Key',
          hintText: 'Enter your OpenRouter API key',
          border: OutlineInputBorder(),
          helperText: 'Get your API key from https://openrouter.ai/keys',
        ),
        obscureText: true,
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _openrouterModelController,
        decoration: InputDecoration(
          labelText: 'Model Name',
          hintText: AppConfig.defaultOpenRouterModel,
          border: const OutlineInputBorder(),
          helperText: 'OpenRouter model to use',
        ),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'OpenRouter provides access to multiple LLM providers through a single API. The default model is ${AppConfig.defaultOpenRouterModel}.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildBackendInfo() {
    return [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Using LittleMind Backend',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'The app will communicate with your existing LittleMind AI backend server.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Default URL: ${AppConfig.defaultBackendUrl}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildHuggingFaceSettings() {
    return [
      const Text('Hugging Face Configuration',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      TextField(
        controller: _huggingfaceApiUrlController,
        decoration: InputDecoration(
          labelText: 'API URL',
          hintText: AppConfig.defaultHuggingFaceUrl,
          border: const OutlineInputBorder(),
          helperText: 'Base URL for HF Inference API',
        ),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _huggingfaceApiKeyController,
        decoration: const InputDecoration(
          labelText: 'API Key',
          hintText: 'Enter your Hugging Face API token',
          border: OutlineInputBorder(),
          helperText: 'Get your token from huggingface.co/settings/tokens',
        ),
        obscureText: true,
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _huggingfaceModelController,
        decoration: InputDecoration(
          labelText: 'Model Name',
          hintText: AppConfig.defaultHuggingFaceModel,
          border: const OutlineInputBorder(),
          helperText: 'HF model ID (e.g. google/gemma-3-1b-it)',
        ),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Get your access token from https://huggingface.co/settings/tokens. Free tier includes serverless Inference API with rate limits. The model must support the chat completion (conversational) task.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    ];
  }
}
