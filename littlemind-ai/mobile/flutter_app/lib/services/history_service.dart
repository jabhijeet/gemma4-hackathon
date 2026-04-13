import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

/// A single history entry representing a completed query-response interaction.
class HistoryEntry {
  final String id;
  final DateTime dateTime;
  final String providerName;
  final String modelName;
  final String query;
  final String response;

  HistoryEntry({
    required this.id,
    required this.dateTime,
    required this.providerName,
    required this.modelName,
    required this.query,
    required this.response,
  });

  /// Create from JSON map (deserialization)
  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      id: json['id'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
      providerName: json['providerName'] as String,
      modelName: json['modelName'] as String,
      query: json['query'] as String,
      response: json['response'] as String,
    );
  }

  /// Convert to JSON map (serialization)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dateTime': dateTime.toIso8601String(),
      'providerName': providerName,
      'modelName': modelName,
      'query': query,
      'response': response,
    };
  }
}

/// Service for persisting and retrieving history entries using SharedPreferences.
class HistoryService {
  static const int maxEntries = 100;

  /// Load all history entries from storage, newest first.
  Future<List<HistoryEntry>> loadAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(AppConfig.keyHistoryEntries);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      final entries = jsonList
          .map((item) => HistoryEntry.fromJson(item as Map<String, dynamic>))
          .toList();

      // Sort newest first
      entries.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      return entries;
    } catch (e) {
      debugPrint('[HISTORY_SERVICE] Error loading history: $e');
      return [];
    }
  }

  /// Save a new history entry. Prunes oldest entries if cap is reached.
  Future<void> saveEntry(HistoryEntry entry) async {
    try {
      final entries = await loadAll();
      entries.insert(0, entry); // Add to front (newest first)

      // Prune if over capacity
      final trimmed = entries.length > maxEntries
          ? entries.sublist(0, maxEntries)
          : entries;

      await _persist(trimmed);
      debugPrint('[HISTORY_SERVICE] Saved entry: ${entry.id}');
    } catch (e) {
      debugPrint('[HISTORY_SERVICE] Error saving entry: $e');
    }
  }

  /// Delete a single history entry by ID.
  Future<void> deleteEntry(String id) async {
    try {
      final entries = await loadAll();
      entries.removeWhere((e) => e.id == id);
      await _persist(entries);
      debugPrint('[HISTORY_SERVICE] Deleted entry: $id');
    } catch (e) {
      debugPrint('[HISTORY_SERVICE] Error deleting entry: $e');
    }
  }

  /// Clear all history entries.
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConfig.keyHistoryEntries);
      debugPrint('[HISTORY_SERVICE] Cleared all history');
    } catch (e) {
      debugPrint('[HISTORY_SERVICE] Error clearing history: $e');
    }
  }

  /// Persist the entries list to SharedPreferences.
  Future<void> _persist(List<HistoryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(AppConfig.keyHistoryEntries, jsonString);
  }
}
