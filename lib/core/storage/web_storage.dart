import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/sanctuary/domain/recovery_models.dart';
import 'recovery_storage.dart';

/// JSON-backed SharedPreferences storage implementation for Flutter Web.
class WebRecoveryStorage implements RecoveryStorage {
  SharedPreferences? _prefs;

  static const _streakKey = 'atp_streak_state_v1';
  static const _logsKey = 'atp_urge_logs_v1';
  static const _questsKey = 'atp_quests_v1';
  static const _metaPrefix = 'atp_meta_v1_';

  @override
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get _store {
    final prefs = _prefs;
    if (prefs == null) {
      throw StateError('WebRecoveryStorage.init() must be called first.');
    }
    return prefs;
  }

  @override
  Future<StreakState?> loadStreakState() async {
    final raw = _store.getString(_streakKey);
    if (raw == null || raw.isEmpty) return null;
    return StreakState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> saveStreakState(StreakState state) async {
    await _store.setString(_streakKey, jsonEncode(state.toJson()));
  }

  @override
  Future<List<UrgeLog>> loadUrgeLogs() async {
    final raw = _store.getString(_logsKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    final list = decoded
        .map((e) => UrgeLog.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.timestampUtc.compareTo(a.timestampUtc));
    return list;
  }

  @override
  Future<void> saveUrgeLog(UrgeLog log) async {
    final existing = await loadUrgeLogs();
    final map = {for (final item in existing) item.id: item};
    map[log.id] = log;
    await replaceAllUrgeLogs(map.values.toList());
  }

  @override
  Future<void> replaceAllUrgeLogs(List<UrgeLog> logs) async {
    final sorted = [...logs]
      ..sort((a, b) => b.timestampUtc.compareTo(a.timestampUtc));
    await _store.setString(
      _logsKey,
      jsonEncode(sorted.map((e) => e.toJson()).toList()),
    );
  }

  @override
  Future<List<QuestItem>> loadQuests() async {
    final raw = _store.getString(_questsKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => QuestItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<void> saveQuest(QuestItem quest) async {
    final existing = await loadQuests();
    final map = {for (final item in existing) item.id: item};
    map[quest.id] = quest;
    await replaceAllQuests(map.values.toList());
  }

  @override
  Future<void> replaceAllQuests(List<QuestItem> quests) async {
    await _store.setString(
      _questsKey,
      jsonEncode(quests.map((e) => e.toJson()).toList()),
    );
  }

  @override
  Future<String?> getMeta(String key) async => _store.getString('$_metaPrefix$key');

  @override
  Future<void> setMeta(String key, String? value) async {
    final fullKey = '$_metaPrefix$key';
    if (value == null) {
      await _store.remove(fullKey);
    } else {
      await _store.setString(fullKey, value);
    }
  }
}
