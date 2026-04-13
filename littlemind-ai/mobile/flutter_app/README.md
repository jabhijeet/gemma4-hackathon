# LittleMind AI App 🌈

LittleMind AI is a fun, interactive storytelling voice-assistant app designed for kids. It features voice interaction using Speech-to-Text and Text-to-Speech capabilities, allowing children to talk naturally to their story friend!

## Architecture 🏛️

The app follows a clean, modular architecture:

- **State Management:** Powered by `Provider` for reactive UI updates and centralized logic.
- **Service Layer:** Core logic is extracted into dedicated services:
  - `TtsService`: Manages text-to-speech functionality.
  - `SpeechService`: Handles voice recognition and microphone interactions.
  - `ChatApiService`: Manages backend communication and API responses.
- **Data Layer:** `ChatProvider` handles message history, loading states, and error diagnostics.
- **Optimized UI:** Uses `ListView.builder` for efficient rendering of long chat histories.

## Features 🚀

- **Voice Interaction 🎤:** Uses `speech_to_text` to listen to users when they press the microphone button.
- **Audible Responses 🔊:** The bot speaks its responses aloud using `flutter_tts` with a kid-friendly speech rate.
- **Smart Conversations:** Connects to a backend API to fetch intelligent responses.
- **Error Diagnostics:** Long-press any error message to see diagnostic details for troubleshooting.
- **Kid-Friendly UI/UX:** Colorful gradients and animated loading indicators.

## Permissions Needed 🔒

Ensure the following permissions are present on Android (`android/app/src/main/AndroidManifest.xml`):
- `android.permission.RECORD_AUDIO`: Required for voice input
- `android.permission.INTERNET`: Required for backend communication

## Setup Instructions 🛠️

1. **Clone the repository.**
2. **Install dependencies:**  
   `flutter pub get`
3. **Configure API Endpoint:**  
   Open `lib/services/chat_api_service.dart` and replace `YOUR_IP` with your backend server's IP address or domain.
4. **Run the App:**  
   `flutter run`
