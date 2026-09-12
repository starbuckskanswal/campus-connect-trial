import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const String _interestedKey = 'interested_event_ids';
  static const String _dismissedKey = 'dismissed_event_ids';
  static const String _preferredSocietiesKey = 'preferred_societies';
  static const String _mutedSocietiesKey = 'muted_societies';

  static Future<Set<String>> _readIdSet(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(key) ?? [];
    return list.toSet();
  }

  static Future<void> _writeIdSet(String key, Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, ids.toList()..sort());
  }

  static Future<bool> isInterested(String id) async {
    final ids = await _readIdSet(_interestedKey);
    return ids.contains(id);
  }

  static Future<void> setInterested(String id, bool value) async {
    final interested = await _readIdSet(_interestedKey);
    final dismissed = await _readIdSet(_dismissedKey);

    if (value) {
      interested.add(id);
      dismissed.remove(id);
    } else {
      interested.remove(id);
    }

    await _writeIdSet(_interestedKey, interested);
    await _writeIdSet(_dismissedKey, dismissed);
  }

  static Future<void> toggleInterested(String id) async {
    final isCurrentlyInterested = await isInterested(id);
    await setInterested(id, !isCurrentlyInterested);
  }

  static Future<void> setDismissed(String id, bool value) async {
    final interested = await _readIdSet(_interestedKey);
    final dismissed = await _readIdSet(_dismissedKey);

    if (value) {
      dismissed.add(id);
      interested.remove(id);
    } else {
      dismissed.remove(id);
    }

    await _writeIdSet(_dismissedKey, dismissed);
    await _writeIdSet(_interestedKey, interested);
  }

  static Future<bool> isDismissed(String id) async {
    final ids = await _readIdSet(_dismissedKey);
    return ids.contains(id);
  }

  static Future<Set<String>> getInterestedIds() async {
    return _readIdSet(_interestedKey);
  }

  static Future<Set<String>> getDismissedIds() async {
    return _readIdSet(_dismissedKey);
  }

  static Future<Set<String>> getPreferredSocieties() async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_preferredSocietiesKey) ?? [];
    return values.toSet();
  }

  static Future<void> setPreferredSocieties(Iterable<String> societies) async {
    final prefs = await SharedPreferences.getInstance();
    final values = societies.toSet().toList()..sort();
    await prefs.setStringList(_preferredSocietiesKey, values);
  }

  static Future<Set<String>> getMutedSocieties() async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_mutedSocietiesKey) ?? [];
    return values.toSet();
  }

  static Future<void> setMutedSocieties(Iterable<String> societies) async {
    final prefs = await SharedPreferences.getInstance();
    final values = societies.toSet().toList()..sort();
    await prefs.setStringList(_mutedSocietiesKey, values);
  }

  static Future<void> clearEventPreference(String eventId) async {
    final interested = await _readIdSet(_interestedKey);
    final dismissed = await _readIdSet(_dismissedKey);
    interested.remove(eventId);
    dismissed.remove(eventId);
    await _writeIdSet(_interestedKey, interested);
    await _writeIdSet(_dismissedKey, dismissed);
  }

  // Backward-compatible aliases for existing code paths.
  static Future<bool> isFavorite(String id) => isInterested(id);

  static Future<void> toggleFavorite(String id) => toggleInterested(id);

  static Future<Set<String>> getFavoriteIds() => getInterestedIds();
}
