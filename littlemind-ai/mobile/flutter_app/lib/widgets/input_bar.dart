import 'package:flutter/material.dart';

class InputBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSend;
  final VoidCallback? onMicPressed;
  final bool isListening;
  final bool isDarkMode;

  const InputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.onMicPressed,
    this.isListening = false,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bubbleColor = isDarkMode ? const Color(0xFF2D3A4F) : Colors.white;
    final textFieldTextColor = isDarkMode ? const Color(0xFFE8E8E8) : const Color(0xFF2C3E50);
    final hintTextColor = isDarkMode ? const Color(0xFFA0AAB5) : const Color(0xFF7F8C8D);
    final micIconColor = isListening ? Colors.red : theme.primaryColor;
    final sendButtonColor = theme.primaryColor;

    return Container(
      margin: EdgeInsets.all(10),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (onMicPressed != null)
            IconButton(
              icon: Icon(
                isListening ? Icons.mic : Icons.mic_none,
                color: micIconColor,
              ),
              onPressed: onMicPressed,
            ),
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(fontSize: 16, color: textFieldTextColor),
              decoration: InputDecoration(
                hintText: "Ask me anything 🌈",
                hintStyle: TextStyle(color: hintTextColor),
                border: InputBorder.none,
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (text) {
                if (text.isNotEmpty) {
                  onSend(text);
                  controller.clear();
                }
              },
            ),
          ),
          SizedBox(width: 4),
          Container(
            margin: EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: sendButtonColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  onSend(controller.text);
                  controller.clear();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
