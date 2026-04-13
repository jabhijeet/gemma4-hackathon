import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool isError;
  final String? errorDetail;
  final String language;

  const MessageBubble({
    super.key,
    required this.text,
    required this.isUser,
    this.isError = false,
    this.errorDetail,
    this.language = 'english',
  });

  void _showErrorDetail(BuildContext context) {
    if (errorDetail != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text("Error Details"),
          content: SingleChildScrollView(
            child: Text(errorDetail!),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Close"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Determine bubble colors based on theme
    Color bubbleColor;
    if (isError) {
      bubbleColor = isDark ? const Color(0xFF5C3A3A) : Colors.red[200]!;
    } else if (isUser) {
      bubbleColor = isDark ? const Color(0xFF3D5A80) : const Color(0xFF87CEEB);
    } else {
      bubbleColor = isDark ? const Color(0xFF2E4A3E) : const Color(0xFFE8F5E9);
    }

    // Preprocess text to convert image URLs to markdown image syntax
    String processedText = text;
    if (!isUser) {
      processedText = _convertImageUrlsToMarkdown(text);
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showErrorDetail(context),
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          padding: EdgeInsets.all(14),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.85,
          ),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: isUser
              ? Text(
                  text,
                  style: TextStyle(fontSize: 16),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: MarkdownBody(
                        data: processedText,
                        imageBuilder: (uri, title, alt) {
                          try {
                            // Handle different URI schemes
                            Widget imageWidget;
                            final uriString = uri.toString();
                            
                            if (uriString.startsWith('data:')) {
                              // Handle base64 data URIs
                              try {
                                Uint8List bytes = _decodeBase64Image(uriString);
                                imageWidget = Image.memory(
                                  bytes,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const SizedBox.shrink();
                                  },
                                );
                              } catch (e) {
                                debugPrint('[IMAGE] Failed to decode base64: $e');
                                imageWidget = const SizedBox.shrink();
                              }
                            } else if (uriString.startsWith('file://') || uriString.startsWith('/')) {
                              // Handle local file paths
                              imageWidget = Image.file(
                                File(uriString.replaceFirst('file://', '')),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const SizedBox.shrink();
                                },
                              );
                            } else {
                              // Handle network images
                              imageWidget = Image.network(
                                uriString,
                                fit: BoxFit.cover,
                                headers: const {
                                  'User-Agent': 'LittleMindAI/1.0',
                                  'Accept': 'image/*,*/*;q=0.8',
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    height: 150,
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                  loadingProgress.expectedTotalBytes!
                                              : null,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Loading image...',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: theme.textTheme.bodyMedium?.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  debugPrint('[IMAGE] Failed to load: $uriString — $error');
                                  return const SizedBox.shrink();
                                },
                              );
                            }
                            
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: imageWidget,
                              ),
                            );
                          } catch (e) {
                            debugPrint('[IMAGE] Error building image widget: $e');
                            return const SizedBox.shrink();
                          }
                        },
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(fontSize: 16, color: theme.textTheme.bodyLarge?.color),
                          listBullet: TextStyle(fontSize: 16, color: theme.textTheme.bodyLarge?.color),
                          code: TextStyle(
                            fontSize: 14,
                            backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.5),
                            fontFamily: 'monospace',
                          ),
                          codeblockDecoration: BoxDecoration(
                            color: theme.colorScheme.surface.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          blockquote: TextStyle(
                            fontSize: 14,
                            color: theme.textTheme.bodyMedium?.color,
                            fontStyle: FontStyle.italic,
                          ),
                          blockquoteDecoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: theme.primaryColor,
                                width: 4,
                              ),
                            ),
                          ),
                        ),
                        selectable: true,
                      ),
                    ),
                    // Manual speak button for bot messages
                    if (!isError && !kIsWeb && defaultTargetPlatform == TargetPlatform.android)
                      Consumer<ChatProvider>(
                        builder: (context, chatProvider, child) {
                          final isCurrentlySpeaking = chatProvider.isSpeaking;
                          return IconButton(
                            icon: Icon(
                              isCurrentlySpeaking ? Icons.volume_off : Icons.volume_up,
                              size: 20,
                              color: isCurrentlySpeaking ? theme.primaryColor : theme.textTheme.bodyMedium?.color,
                            ),
                            onPressed: isCurrentlySpeaking
                                ? null // Disable if already speaking
                                : () {
                                    // Extract plain text from markdown for TTS
                                    final plainText = text.replaceAll(RegExp(r'[*_`#]'), '').replaceAll(RegExp(r'!\[.*?\]\(.*?\)'), '');
                                    chatProvider.speakText(plainText, language: language);
                                  },
                            tooltip: 'Read aloud',
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                          );
                        },
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  /// Helper method to decode base64 image data
  Uint8List _decodeBase64Image(String dataUri) {
    try {
      // Extract the base64 part after the comma
      final base64Data = dataUri.split(',').last;
      // Strip any whitespace, newlines, etc. which can cause exceptions
      final cleanBase64 = base64Data.replaceAll(RegExp(r'\s+'), '');
      return base64Decode(cleanBase64);
    } catch (e) {
      debugPrint('[IMAGE] Exception decoding base64: $e');
      throw const FormatException('Invalid base64 image encoding');
    }
  }

  /// Convert bare image URLs in text to markdown image syntax.
  /// Carefully avoids double-converting URLs already in markdown syntax.
  String _convertImageUrlsToMarkdown(String text) {
    // Known image extensions
    const imageExtensions = r'(?:jpg|jpeg|png|gif|webp|svg|bmp|ico|tiff|avif)';

    // Regex for markdown images and links: ![...](...) or [...](...) 
    final markdownSyntaxRegex = RegExp(r'!?\[.*?\]\(.*?\)');

    String result = text;

    // 1. Rewrite dead Unsplash URLs to image.pollinations.ai based on query
    // Unsplash source API is permanently offline. Pollinations AI can generate images on the fly.
    result = result.replaceAllMapped(
      RegExp(r'(?:https?://)?(?:source\.unsplash\.com|images\.unsplash\.com|unsplash\.com/photos|unsplash\.com)[^\s\)\]]*', caseSensitive: false),
      (match) {
        final url = match.group(0)!;
        String query = 'random image';
        if (url.contains('?')) {
          query = url.split('?').last;
        } else {
          final segments = url.split('/');
          if (segments.length > 3 && segments.last.isNotEmpty && !segments.last.contains('x')) {
            query = segments.last;
          }
        }
        // Clean query: remove common UUIDs and photo ID structures before querying pollinators
        String cleanQuery = query.replaceAll(RegExp(r'[+,_\-&]'), ' ').trim();
        // optionally strip the trailing parts of unsplash ids e.g. photo-1599504165786-4ceb386a2d3a -> photo
        cleanQuery = cleanQuery.replaceAll(RegExp(r'\d{10,}.*'), '').trim();
        
        final encoded = Uri.encodeComponent(cleanQuery.isEmpty ? 'random' : cleanQuery);
        return 'https://image.pollinations.ai/prompt/$encoded?width=800&height=600&nologo=true';
      }
    );

    // 2. Convert text links pointing to images into proper image tags
    // This ensures that if the image is broken, flutter_markdown uses our errorBuilder (which hides it)
    // instead of showing the text link ("no need to show texts if no image")
    result = result.replaceAllMapped(
      RegExp(r'(?<!\!)\[([^\]]+)\]\((https?://[^\)]+)\)'),
      (match) {
        final alt = match.group(1)!;
        final url = match.group(2)!;
        if (_isImageUrl(url, imageExtensions)) {
          return '![$alt]($url)';
        }
        return match.group(0)!;
      }
    );

    // NOW that text replacements are done, recalculate spans for bare URLs
    
    // Collect all spans occupied by existing markdown syntax
    final protectedRanges = <List<int>>[];
    for (final match in markdownSyntaxRegex.allMatches(result)) {
      protectedRanges.add([match.start, match.end]);
    }

    // Check if a position overlaps an existing markdown span
    bool isProtected(int start, int end) {
      for (final range in protectedRanges) {
        if (start < range[1] && end > range[0]) return true;
      }
      return false;
    }

    // Match bare HTTP(S) URLs
    final urlRegex = RegExp(r'https?://[^\s\)\]]+', caseSensitive: false);
    final matches = urlRegex.allMatches(result).toList().reversed;

    for (final match in matches) {
      // Skip if this URL is already inside markdown syntax
      if (isProtected(match.start, match.end)) continue;

      final url = match.group(0)!;

      // Check if this URL looks like an image
      if (_isImageUrl(url, imageExtensions)) {
        // Clean trailing punctuation that may have been captured
        String cleanUrl = url.replaceAll(RegExp(r'[.,;:!?]+$'), '');
        final replacement = '![image]($cleanUrl)';

        result = result.substring(0, match.start) +
            replacement +
            result.substring(match.start + url.length);
      }
    }

    return result;
  }

  /// Check if a URL is likely an image URL
  bool _isImageUrl(String url, String extensionPattern) {
    final lowerUrl = url.toLowerCase();

    // 1. Has a known image file extension (before any query string)
    if (RegExp('\\.($extensionPattern)(\\?.*)?\\s*\$', caseSensitive: false)
        .hasMatch(url)) {
      return true;
    }

    // 2. Common image hosting/CDN patterns
    const imageHosts = [
      'imgur.com',
      'i.imgur.com',
      'images.unsplash.com',
      'source.unsplash.com',
      'images.pexels.com',
      'staticflickr.com',
      'cloudinary.com',
      'imgix.net',
      'googleusercontent.com',
      'ggpht.com',
      'twimg.com',
      'pinimg.com',
      'image.pollinations.ai',
    ];
    for (final host in imageHosts) {
      if (lowerUrl.contains(host)) return true;
    }

    // 3. URL path segments that strongly suggest an image resource
    if (RegExp(r'/(?:image|photo|picture|img|thumbnail|thumb|avatar|banner|poster|cover)/')
        .hasMatch(lowerUrl)) {
      if (!lowerUrl.endsWith('.html') &&
          !lowerUrl.endsWith('.htm') &&
          !lowerUrl.contains('.html?')) {
        return true;
      }
    }

    return false;
  }
}
