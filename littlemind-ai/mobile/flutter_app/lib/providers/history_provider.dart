import 'package:flutter/foundation.dart';
import '../services/history_service.dart';
import '../services/encryption_service.dart';

/// Provider for managing response history state.
class HistoryProvider extends ChangeNotifier {
  final HistoryService _historyService = HistoryService();

  List<HistoryEntry> _entries = [];
  bool _isLoaded = false;
  String _searchQuery = '';

  List<HistoryEntry> get entries {
    if (_searchQuery.isEmpty) return _entries;
    final query = _searchQuery.toLowerCase();
    return _entries.where((e) {
      // Decrypt transiently for search — plaintext is not retained.
      return e.decryptedQuery.toLowerCase().contains(query) ||
          e.decryptedResponse.toLowerCase().contains(query) ||
          e.providerName.toLowerCase().contains(query) ||
          e.modelName.toLowerCase().contains(query);
    }).toList();
  }

  List<HistoryEntry> get allEntries => _entries;
  bool get isLoaded => _isLoaded;
  String get searchQuery => _searchQuery;
  int get totalCount => _entries.length;

  HistoryProvider() {
    _loadHistory();
  }

  /// Load history from persistent storage.
  Future<void> _loadHistory() async {
    _entries = await _historyService.loadAll();
    _isLoaded = true;
    notifyListeners();
    debugPrint('[HISTORY_PROVIDER] Loaded ${_entries.length} history entries');
  }

  /// Add a new history entry after a successful LLM response.
  /// Query and response are encrypted before storage.
  Future<void> addEntry({
    required String providerName,
    required String modelName,
    required String query,
    required String response,
  }) async {
    final enc = EncryptionService.instance;
    final entry = HistoryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      dateTime: DateTime.now(),
      providerName: providerName,
      modelName: modelName,
      query: enc.encrypt(query),
      response: enc.encrypt(response),
    );

    _entries.insert(0, entry);
    // Prune in memory too
    if (_entries.length > HistoryService.maxEntries) {
      _entries = _entries.sublist(0, HistoryService.maxEntries);
    }
    notifyListeners();

    await _historyService.saveEntry(entry);
    debugPrint('[HISTORY_PROVIDER] Added encrypted entry: ${entry.id}');
  }

  /// Delete a single entry by ID.
  Future<void> deleteEntry(String id) async {
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
    await _historyService.deleteEntry(id);
  }

  /// Clear all history entries.
  Future<void> clearAll() async {
    _entries.clear();
    notifyListeners();
    await _historyService.clearAll();
    debugPrint('[HISTORY_PROVIDER] Cleared all history');
  }

  /// Update search/filter query.
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Refresh history from storage.
  Future<void> refresh() async {
    _entries = await _historyService.loadAll();
    notifyListeners();
  }
}
