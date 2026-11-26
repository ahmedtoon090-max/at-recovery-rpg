import '../../features/sanctuary/domain/recovery_models.dart';

/// Platform-agnostic persistence interface backed by SQLite on IO and
/// SharedPreferences JSON on Web.
abstract interface class RecoveryStorage {
  Future<void> init();

  Future<StreakState?> loadStreakState();
  Future<void> saveStreakState(StreakState state);

  Future<List<UrgeLog>> loadUrgeLogs();
  Future<void> saveUrgeLog(UrgeLog log);
  Future<void> replaceAllUrgeLogs(List<UrgeLog> logs);

  Future<List<QuestItem>> loadQuests();
  Future<void> saveQuest(QuestItem quest);
  Future<void> replaceAllQuests(List<QuestItem> quests);

  Future<String?> getMeta(String key);
  Future<void> setMeta(String key, String? value);
}

/// Deterministic in-memory storage used for unit and widget tests.
class InMemoryRecoveryStorage implements RecoveryStorage {
  StreakState? _streakState;
  final Map<String, UrgeLog> _logs = {};
  final Map<String, QuestItem> _quests = {};
  final Map<String, String> _meta = {};

  @override
  Future<void> init() async {}

  @override
  Future<StreakState?> loadStreakState() async => _streakState;

  @override
  Future<void> saveStreakState(StreakState state) async {
    _streakState = state;
  }

  @override
  Future<List<UrgeLog>> loadUrgeLogs() async {
    final list = _logs.values.toList()
      ..sort((a, b) => b.timestampUtc.compareTo(a.timestampUtc));
    return list;
  }

  @override
  Future<void> saveUrgeLog(UrgeLog log) async {
    _logs[log.id] = log;
  }

  @override
  Future<void> replaceAllUrgeLogs(List<UrgeLog> logs) async {
    _logs
      ..clear()
      ..addEntries(logs.map((e) => MapEntry(e.id, e)));
  }

  @override
  Future<List<QuestItem>> loadQuests() async => _quests.values.toList();

  @override
  Future<void> saveQuest(QuestItem quest) async {
    _quests[quest.id] = quest;
  }

  @override
  Future<void> replaceAllQuests(List<QuestItem> quests) async {
    _quests
      ..clear()
      ..addEntries(quests.map((e) => MapEntry(e.id, e)));
  }

  @override
  Future<String?> getMeta(String key) async => _meta[key];

  @override
  Future<void> setMeta(String key, String? value) async {
    if (value == null) {
      _meta.remove(key);
    } else {
      _meta[key] = value;
    }
  }
}
