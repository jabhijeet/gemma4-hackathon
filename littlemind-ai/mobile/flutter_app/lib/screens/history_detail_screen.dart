import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../services/history_service.dart';

/// Full detail view for a single history entry.
class HistoryDetailScreen extends StatelessWidget {
  final HistoryEntry entry;

  const HistoryDetailScreen({super.key, required this.entry});

  String _formatDateTime(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} • $hour:$minute $amPm';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF232D3F), const Color(0xFF1A2332)]
                : [const Color(0xFFE8F4FD), const Color(0xFFF0F8FF)],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // Gradient app bar
            SliverAppBar(
              expandedHeight: 140,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  '📖 Story Detail',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFE8E8E8) : Colors.white,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [const Color(0xFF2D3A4F), const Color(0xFF344258)]
                          : [const Color(0xFF4A90D9), const Color(0xFF50C878)],
                    ),
                  ),
                ),
              ),
              actions: [
                // Copy response button
                IconButton(
                  icon: const Icon(Icons.copy_rounded),
                  tooltip: 'Copy response',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: entry.response));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('📋 Response copied!'),
                        backgroundColor: theme.primaryColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Metadata card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF344258).withValues(alpha: 0.8)
                            : Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date & time
                          Row(
                            children: [
                              Icon(Icons.schedule_rounded,
                                  size: 18, color: theme.primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                _formatDateTime(entry.dateTime),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.textTheme.bodyMedium?.color,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Provider & model chips
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildChip(
                                '🤖 ${entry.providerName}',
                                isDark
                                    ? const Color(0xFF3D5A80)
                                    : const Color(0xFF4A90D9).withValues(alpha: 0.15),
                                isDark ? Colors.white : const Color(0xFF4A90D9),
                              ),
                              _buildChip(
                                '⚙️ ${entry.modelName}',
                                isDark
                                    ? const Color(0xFF2E4A3E)
                                    : const Color(0xFF50C878).withValues(alpha: 0.15),
                                isDark ? Colors.white : const Color(0xFF2E7D4A),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Query section
                    _buildSectionHeader('💬 Your Question', theme),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF3D5A80).withValues(alpha: 0.5)
                            : const Color(0xFF87CEEB).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF5BA4E6).withValues(alpha: 0.3)
                              : const Color(0xFF4A90D9).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        entry.query,
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.textTheme.bodyLarge?.color,
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Response section
                    _buildSectionHeader('📝 Response', theme),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2E4A3E).withValues(alpha: 0.5)
                            : const Color(0xFFE8F5E9).withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF66D9A0).withValues(alpha: 0.3)
                              : const Color(0xFF50C878).withValues(alpha: 0.2),
                        ),
                      ),
                      child: MarkdownBody(
                        data: entry.response,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(
                            fontSize: 15,
                            color: theme.textTheme.bodyLarge?.color,
                            height: 1.6,
                          ),
                          listBullet: TextStyle(
                            fontSize: 15,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                          code: TextStyle(
                            fontSize: 13,
                            backgroundColor:
                                theme.colorScheme.surface.withValues(alpha: 0.5),
                            fontFamily: 'monospace',
                          ),
                          codeblockDecoration: BoxDecoration(
                            color: theme.colorScheme.surface.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Re-ask button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Pop back with the query to re-ask
                          Navigator.pop(context, entry.query);
                        },
                        icon: const Icon(Icons.replay_rounded),
                        label: const Text(
                          '🔄 Ask Again',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: theme.textTheme.bodyLarge?.color,
      ),
    );
  }

  Widget _buildChip(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
