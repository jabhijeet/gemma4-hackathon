import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/history_provider.dart';
import '../services/history_service.dart';
import 'history_detail_screen.dart';

/// Kid-friendly history screen — "My Story Journal" 📚
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} • $hour:$minute $amPm';
  }

  String _getRelativeDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return _formatDate(dt);
  }

  void _confirmClearAll(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🗑️ Clear All History?'),
        content: const Text(
          'This will remove all your saved stories and adventures. '
          'This action cannot be undone!',
          style: TextStyle(fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<HistoryProvider>().clearAll();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('✨ History cleared!'),
                  backgroundColor: theme.primaryColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE57373),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteEntry(BuildContext context, HistoryEntry entry) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🗑️ Delete Entry?'),
        content: Text(
          'Remove this story from your journal?\n\n"${entry.query.length > 60 ? '${entry.query.substring(0, 60)}...' : entry.query}"',
          style: const TextStyle(fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<HistoryProvider>().deleteEntry(entry.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE57373),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final historyProvider = context.watch<HistoryProvider>();
    final entries = historyProvider.entries;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF232D3F), const Color(0xFF1A2332)]
                : [const Color(0xFFE8F4FD), const Color(0xFFF5F0FF)],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // Beautiful gradient app bar
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              actions: [
                if (historyProvider.totalCount > 0)
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_rounded),
                    tooltip: 'Clear all history',
                    onPressed: () => _confirmClearAll(context),
                  ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  '📚 My Story Journal',
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
                          : [const Color(0xFF7B68EE), const Color(0xFF4A90D9), const Color(0xFF50C878)],
                    ),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 30),
                      child: Text(
                        '📖',
                        style: TextStyle(fontSize: 50),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF344258).withValues(alpha: 0.8)
                        : Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => historyProvider.setSearchQuery(value),
                    decoration: InputDecoration(
                      hintText: '🔍 Search your stories...',
                      hintStyle: TextStyle(
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                        fontSize: 15,
                      ),
                      prefixIcon: Icon(Icons.search_rounded, color: theme.primaryColor),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear_rounded,
                                  color: theme.textTheme.bodyMedium?.color),
                              onPressed: () {
                                _searchController.clear();
                                historyProvider.setSearchQuery('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),
            ),

            // Entry count
            if (historyProvider.totalCount > 0)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Text(
                    historyProvider.searchQuery.isNotEmpty
                        ? '${entries.length} of ${historyProvider.totalCount} stories found'
                        : '${historyProvider.totalCount} adventure${historyProvider.totalCount == 1 ? '' : 's'} saved ✨',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

            // Empty state or list
            if (!historyProvider.isLoaded)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (entries.isEmpty)
              SliverFillRemaining(
                child: _buildEmptyState(isDark, theme),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final entry = entries[index];
                      return _buildHistoryCard(
                        context,
                        entry,
                        index,
                        isDark,
                        theme,
                      );
                    },
                    childCount: entries.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Empty state with fun illustration
  Widget _buildEmptyState(bool isDark, ThemeData theme) {
    final isSearching = context.read<HistoryProvider>().searchQuery.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isSearching ? '🔍' : '📖',
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              isSearching ? 'No stories found!' : 'No adventures yet!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'Try a different search to find your stories 🌟'
                  : 'Start chatting to fill your journal\nwith magical stories! ✨',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: theme.textTheme.bodyMedium?.color,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build a single history card with staggered animation
  Widget _buildHistoryCard(
    BuildContext context,
    HistoryEntry entry,
    int index,
    bool isDark,
    ThemeData theme,
  ) {
    // Color palette for cards — cycles through
    final cardColors = isDark
        ? [
            const Color(0xFF344258),
            const Color(0xFF3D4A5C),
            const Color(0xFF2E4A3E),
            const Color(0xFF4A3D5C),
            const Color(0xFF3D5A80),
          ]
        : [
            const Color(0xFFFFFFFF),
            const Color(0xFFFFF8E7),
            const Color(0xFFF0FFF0),
            const Color(0xFFF5F0FF),
            const Color(0xFFE8F4FD),
          ];

    final borderColors = isDark
        ? [
            const Color(0xFF5BA4E6).withValues(alpha: 0.3),
            const Color(0xFFFFD54F).withValues(alpha: 0.3),
            const Color(0xFF66D9A0).withValues(alpha: 0.3),
            const Color(0xFFCE93D8).withValues(alpha: 0.3),
            const Color(0xFF81D4FA).withValues(alpha: 0.3),
          ]
        : [
            const Color(0xFF4A90D9).withValues(alpha: 0.2),
            const Color(0xFFFFB300).withValues(alpha: 0.2),
            const Color(0xFF50C878).withValues(alpha: 0.2),
            const Color(0xFF9C27B0).withValues(alpha: 0.15),
            const Color(0xFF03A9F4).withValues(alpha: 0.2),
          ];

    final colorIndex = index % cardColors.length;

    // Strip emoji prefix from response for preview
    String responsePreview = entry.response;
    if (responsePreview.length > 2 && !RegExp(r'^[a-zA-Z0-9]').hasMatch(responsePreview)) {
      // Response likely starts with emoji, keep it
    }
    if (responsePreview.length > 120) {
      responsePreview = '${responsePreview.substring(0, 120)}...';
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 80).clamp(0, 400)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () async {
              final result = await Navigator.push<String>(
                context,
                MaterialPageRoute(
                  builder: (context) => HistoryDetailScreen(entry: entry),
                ),
              );
              // If a re-ask query came back, pop this screen too
              if (result != null && context.mounted) {
                Navigator.pop(context, result);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColors[colorIndex],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColors[colorIndex], width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: date & delete
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded,
                          size: 14, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _getRelativeDate(entry.dateTime),
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      // Delete button
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _confirmDeleteEntry(context, entry),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Provider & model badges
                  Row(
                    children: [
                      _buildMiniChip(
                        '🤖 ${entry.providerName}',
                        isDark
                            ? const Color(0xFF5BA4E6).withValues(alpha: 0.2)
                            : const Color(0xFF4A90D9).withValues(alpha: 0.12),
                        isDark ? const Color(0xFF81D4FA) : const Color(0xFF4A90D9),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: _buildMiniChip(
                          '⚙️ ${entry.modelName}',
                          isDark
                              ? const Color(0xFF66D9A0).withValues(alpha: 0.2)
                              : const Color(0xFF50C878).withValues(alpha: 0.12),
                          isDark ? const Color(0xFF66D9A0) : const Color(0xFF2E7D4A),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Query
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : const Color(0xFF4A90D9).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💬 ', style: TextStyle(fontSize: 14)),
                        Expanded(
                          child: Text(
                            entry.query,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.bodyLarge?.color,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Response preview
                  Text(
                    responsePreview,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textTheme.bodyMedium?.color,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // "Tap to read more" hint
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Tap to read more →',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.primaryColor.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniChip(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
