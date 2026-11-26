import 'package:supabase_flutter/supabase_flutter.dart';

import '../../sanctuary/domain/recovery_models.dart';
import '../domain/sync_engine.dart';

class SupabaseSyncException implements Exception {
  const SupabaseSyncException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Optional Supabase Free-Tier sync adapter matching `supabase/schema.sql`.
/// Stays completely dormant until the user enters their own URL & Anon Key.
class SupabaseSyncAdapter {
  bool _initialized = false;
  String? _activeUrl;
  String? _activeKey;

  bool get isReady => _initialized;

  Future<void> configure({
    required String url,
    required String anonKey,
  }) async {
    final trimmedUrl = url.trim();
    final trimmedKey = anonKey.trim();
    if (trimmedUrl.isEmpty || trimmedKey.isEmpty) {
      throw const SupabaseSyncException(
        'Enter both your Supabase Project URL and Anon Key.',
      );
    }
    if (_initialized && _activeUrl == trimmedUrl && _activeKey == trimmedKey) {
      return;
    }
    await Supabase.initialize(url: trimmedUrl, publishableKey: trimmedKey);
    _initialized = true;
    _activeUrl = trimmedUrl;
    _activeKey = trimmedKey;
  }

  SupabaseClient get _client {
    if (!_initialized) {
      throw const SupabaseSyncException('Supabase is not configured yet.');
    }
    return Supabase.instance.client;
  }

  User? get currentUser => _initialized ? _client.auth.currentUser : null;

  Future<void> signInOrSignUp({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthException {
      await _client.auth.signUp(email: email, password: password);
    }
  }

  Future<void> signOut() async {
    if (!_initialized) return;
    await _client.auth.signOut();
  }

  Future<RecoverySnapshot> syncSnapshot(RecoverySnapshot local) async {
    final user = currentUser;
    if (user == null) {
      throw const SupabaseSyncException('Sign in to Supabase before syncing.');
    }

    final stateRows = await _client
        .from('user_state')
        .select('payload')
        .eq('user_id', user.id)
        .maybeSingle();

    final logRows = await _client
        .from('urge_logs')
        .select()
        .eq('user_id', user.id);

    final questRows = await _client
        .from('quests')
        .select()
        .eq('user_id', user.id);

    RecoverySnapshot merged = local;
    if (stateRows != null && stateRows['payload'] != null) {
      final remoteState = StreakState.fromJson(
        Map<String, dynamic>.from(stateRows['payload'] as Map),
      );
      final remoteLogs = (logRows as List<dynamic>).map((raw) {
        final m = Map<String, dynamic>.from(raw as Map);
        return UrgeLog(
          id: m['id'] as String,
          timestampUtc: DateTime.parse(m['timestamp_utc'] as String).toUtc(),
          type: UrgeLogType.fromWire(m['type'] as String? ?? 'checkIn'),
          intensity: (m['intensity'] as num?)?.toInt() ?? 5,
          triggers: (m['triggers'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toList(),
          mood: m['mood'] as String? ?? '',
          note: m['note'] as String? ?? '',
          updatedAtUtc: DateTime.parse(m['updated_at'] as String).toUtc(),
          isDeleted: m['is_deleted'] as bool? ?? false,
        );
      }).toList();

      final remoteQuests = (questRows as List<dynamic>).map((raw) {
        final m = Map<String, dynamic>.from(raw as Map);
        return QuestItem(
          id: m['id'] as String,
          title: m['title'] as String,
          description: '',
          xpReward: (m['xp_reward'] as num?)?.toInt() ?? 25,
          goldReward: (m['gold_reward'] as num?)?.toInt() ?? 10,
          lastCompletedDate: m['last_completed_date'] as String?,
          streakCount: (m['streak_count'] as num?)?.toInt() ?? 0,
          updatedAtUtc: DateTime.parse(m['updated_at'] as String).toUtc(),
          isDeleted: m['is_deleted'] as bool? ?? false,
        );
      }).toList();

      final remoteSnapshot = RecoverySnapshot(
        streakState: remoteState,
        urgeLogs: remoteLogs,
        quests: remoteQuests,
        exportedAtUtc: remoteState.updatedAtUtc,
      );
      merged = SyncEngine.mergeSnapshots(local, remoteSnapshot);
    }

    await _client.from('user_state').upsert({
      'user_id': user.id,
      'payload': merged.streakState.toJson(),
      'updated_at': merged.streakState.updatedAtUtc.toUtc().toIso8601String(),
    });

    if (merged.urgeLogs.isNotEmpty) {
      await _client.from('urge_logs').upsert(
        merged.urgeLogs
            .map(
              (log) => {
                'id': log.id,
                'user_id': user.id,
                'timestamp_utc': log.timestampUtc.toUtc().toIso8601String(),
                'type': log.type.wireValue,
                'intensity': log.intensity,
                'triggers': log.triggers,
                'mood': log.mood,
                'note': log.note,
                'updated_at': log.updatedAtUtc.toUtc().toIso8601String(),
                'is_deleted': log.isDeleted,
              },
            )
            .toList(),
      );
    }

    if (merged.quests.isNotEmpty) {
      await _client.from('quests').upsert(
        merged.quests
            .map(
              (q) => {
                'id': q.id,
                'user_id': user.id,
                'title': q.title,
                'xp_reward': q.xpReward,
                'gold_reward': q.goldReward,
                'completed_today': q.isCompletedOn(DateTime.now().toUtc()),
                'streak_count': q.streakCount,
                'last_completed_date': q.lastCompletedDate,
                'updated_at': q.updatedAtUtc.toUtc().toIso8601String(),
                'is_deleted': q.isDeleted,
              },
            )
            .toList(),
      );
    }

    return merged;
  }
}
