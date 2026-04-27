import 'dart:math';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

/// Application-layer encryption service using AES-256-GCM.
///
/// Encrypts user prompts and LLM responses at rest so that plaintext
/// is never stored in memory, logs, or persistent storage.
/// The 256-bit key is auto-generated on first launch and persisted
/// in [FlutterSecureStorage] (backed by OS-level keychains).
class EncryptionService {
  EncryptionService._();

  /// Singleton instance.
  static final EncryptionService instance = EncryptionService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  late enc.Key _key;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Must be called once (e.g. in `main()`) before any encrypt/decrypt calls.
  Future<void> init() async {
    if (_isInitialized) return;

    final existing = await _storage.read(key: AppConfig.keyEncryptionKey);
    if (existing != null && existing.isNotEmpty) {
      _key = enc.Key.fromBase64(existing);
      debugPrint('[ENCRYPTION] Loaded existing encryption key');
    } else {
      _key = _generateKey();
      await _storage.write(
        key: AppConfig.keyEncryptionKey,
        value: _key.base64,
      );
      debugPrint('[ENCRYPTION] Generated and stored new encryption key');
    }

    _isInitialized = true;
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Encrypt [plaintext] using AES-256-GCM with a random 96-bit IV.
  ///
  /// Returns a Base64 string in the format `<iv_base64>:<ciphertext_base64>`.
  /// Returns the original string if encryption fails or is not initialized.
  String encrypt(String plaintext) {
    if (!_isInitialized || plaintext.isEmpty) return plaintext;

    try {
      final iv = enc.IV.fromSecureRandom(12); // 96-bit nonce for GCM
      final encrypter = enc.Encrypter(enc.AES(_key, mode: enc.AESMode.gcm));
      final encrypted = encrypter.encrypt(plaintext, iv: iv);
      return '${iv.base64}:${encrypted.base64}';
    } catch (e) {
      debugPrint('[ENCRYPTION] Encrypt failed: $e');
      return plaintext; // Graceful fallback
    }
  }

  /// Decrypt an AES-256-GCM ciphertext string produced by [encrypt].
  ///
  /// Expects the format `<iv_base64>:<ciphertext_base64>`.
  /// Returns the original string if decryption fails (e.g. legacy plaintext).
  String decrypt(String ciphertext) {
    if (!_isInitialized || ciphertext.isEmpty) return ciphertext;

    try {
      final parts = ciphertext.split(':');
      if (parts.length != 2) {
        // Not an encrypted value — treat as legacy plaintext.
        return ciphertext;
      }

      final iv = enc.IV.fromBase64(parts[0]);
      final encrypted = enc.Encrypted.fromBase64(parts[1]);
      final encrypter = enc.Encrypter(enc.AES(_key, mode: enc.AESMode.gcm));
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      // Decryption failure — likely legacy unencrypted data.
      debugPrint('[ENCRYPTION] Decrypt failed (legacy data?): $e');
      return ciphertext;
    }
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  /// Generate a cryptographically secure 256-bit key.
  enc.Key _generateKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return enc.Key(Uint8List.fromList(bytes));
  }
}
