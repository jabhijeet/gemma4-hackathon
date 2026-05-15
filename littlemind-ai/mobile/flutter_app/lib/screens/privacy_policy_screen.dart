import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(theme, 'Introduction'),
              _buildSectionText(theme, 
                'Welcome to LittleMind AI. Your privacy and your child\'s safety are our top priorities. '
                'This Privacy Policy explains how we handle information in our application.'
              ),
              
              _buildSectionTitle(theme, 'Information Collection'),
              _buildSectionText(theme, 
                'LittleMind AI is designed with privacy in mind. We do not require a user account to use the basic features of the app. '
                'Information like your child\'s name, age, and interests is stored locally on your device and is used only to personalize the AI\'s responses.'
              ),
              
              _buildSectionTitle(theme, 'AI Processing & Data Handling'),
              _buildSectionText(theme, 
                'When you or your child speaks to LittleMind AI, the audio is converted to text. This text, along with the locally stored personalization data, '
                'is sent to the selected AI provider (e.g., Google Gemini, Ollama, or others you configure) to generate a response. '
                'We do not store your conversations on our servers. Your chat history is saved locally on your device for your reference.'
              ),
              
              _buildSectionTitle(theme, 'Encryption'),
              _buildSectionText(theme, 
                'We use industry-standard encryption to protect your locally stored data, including API keys and chat history.'
              ),
              
              _buildSectionTitle(theme, 'Third-Party Services'),
              _buildSectionText(theme, 
                'The app allows you to connect to various AI providers. Please review the privacy policies of the specific providers you choose to use (e.g., Google, OpenRouter, Hugging Face).'
              ),
              
              _buildSectionTitle(theme, 'Parental Controls'),
              _buildSectionText(theme, 
                'LittleMind AI includes features specifically for parents to guide the experience. We encourage parents to be involved in their child\'s interactions with AI.'
              ),
              
              _buildSectionTitle(theme, 'Changes to This Policy'),
              _buildSectionText(theme, 
                'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page.'
              ),
              
              _buildSectionTitle(theme, 'Contact Us'),
              _buildSectionText(theme, 
                'If you have any questions or suggestions about our Privacy Policy, do not hesitate to contact us.'
              ),
              
              const SizedBox(height: 40),
              Center(
                child: Text(
                  'Last Updated: May 15, 2026',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Text(
        title,
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSectionText(ThemeData theme, String text) {
    return Text(
      text,
      style: theme.textTheme.bodyLarge?.copyWith(
        height: 1.5,
      ),
    );
  }
}
