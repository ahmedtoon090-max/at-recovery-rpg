import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../features/sanctuary/domain/recovery_models.dart';
import 'recovery_storage.dart';

/// SQLite persistence implementation for Android, iOS, Windows, macOS, and Linux.
class SqliteRecoveryStorage implements RecoveryStorage {
  Database? _db;

  @override
  Future<void> init() async {
    if (_db != null) return;
    final dir = await getApplicationSupportDirectory();
    final dbPath = p.join(dir.path, 'at_recovery_rpg.db');
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE streak_state (
            id INTEGER PRIMARY KEY,
            payload TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE urge_logs (
            id TEXT PRIMARY KEY,
            timestamp_utc TEXT NOT NULL,
            payload TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            is_deleted INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE quests (
            id TEXT PRIMARY KEY,
            payload TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            is_deleted INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE app_meta (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Database get _database {
    final db = _db;
    if (db == null) {
      throw StateError('SqliteRecoveryStorage.init() must be called first.');
    }
    return db;
  }

  @override
  Future<StreakState?> loadStreakState() async {
    final rows = await _database.query('streak_state', where: 'id = 1');
    if (rows.isEmpty) return null;
    final jsonMap =
        jsonDecode(rows.first['payload'] as String) as Map<String, dynamic>;
    return StreakState.fromJson(jsonMap);
  }

  @override
  Future<void> saveStreakState(StreakState state) async {
    await _database.insert(
      'streak_state',
      {
        'id': 1,
        'payload': jsonEncode(state.toJson()),
        'updated_at': state.updatedAtUtc.toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<UrgeLog>> loadUrgeLogs() async {
    final rows = await _database.query(
      'urge_logs',
      orderBy: 'timestamp_utc DESC',
    );
    return rows
        .map(
          (r) => UrgeLog.fromJson(
            jsonDecode(r['payload'] as String) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  @override
  Future<void> saveUrgeLog(UrgeLog log) async {
    await _database.insert(
      'urge_logs',
      {
        'id': log.id,
        'timestamp_utc': log.timestampUtc.toUtc().toIso8601String(),
        'payload': jsonEncode(log.toJson()),
        'updated_at': log.updatedAtUtc.toUtc().toIso8601String(),
        'is_deleted': log.isDeleted ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> replaceAllUrgeLogs(List<UrgeLog> logs) async {
    await _database.transaction((txn) async {
      await txn.delete('urge_logs');
      for (final log in logs) {
        await txn.insert('urge_logs', {
          'id': log.id,
          'timestamp_utc': log.timestampUtc.toUtc().toIso8601String(),
          'payload': jsonEncode(log.toJson()),
          'updated_at': log.updatedAtUtc.toUtc().toIso8601String(),
          'is_deleted': log.isDeleted ? 1 : 0,
        });
      }
    });
  }

  @override
  Future<List<QuestItem>> loadQuests() async {
    final rows = await _database.query('quests');
    return rows
        .map(
          (r) => QuestItem.fromJson(
            jsonDecode(r['payload'] as String) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  @override
  Future<void> saveQuest(QuestItem quest) async {
    await _database.insert(
      'quests',
      {
        'id': quest.id,
        'payload': jsonEncode(quest.toJson()),
        'updated_at': quest.updatedAtUtc.toUtc().toIso8601String(),
        'is_deleted': quest.isDeleted ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> replaceAllQuests(List<QuestItem> quests) async {
    await _database.transaction((txn) async {
      await txn.delete('quests');
      for (final q in quests) {
        await txn.insert('quests', {
          'id': q.id,
          'payload': jsonEncode(q.toJson()),
          'updated_at': q.updatedAtUtc.toUtc().toIso8601String(),
          'is_deleted': q.isDeleted ? 1 : 0,
        });
      }
    });
  }

  @override
  Future<String?> getMeta(String key) async {
    final rows = await _database.query(
      'app_meta',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  @override
  Future<void> setMeta(String key, String? value) async {
    if (value == null) {
      await _database.delete('app_meta', where: 'key = ?', whereArgs: [key]);
      return;
    }
    await _database.insert(
      'app_meta',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
