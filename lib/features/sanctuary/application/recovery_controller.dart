import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/engine/recovery_algorithm.dart';
import '../../../core/engine/rpg_sfx_service.dart';
import '../../../core/platform/platform_bootstrap.dart';
import '../../../core/security/app_lock_service.dart';
import '../../../core/storage/recovery_storage.dart';
import '../../sync_profile/application/sync_coordinator.dart';
import '../domain/recovery_models.dart';
import 'app_providers.dart';

part 'recovery_rpg_actions.dart';

enum SyncStatus { idle, syncing, synced, error }

class RewardPopupEvent {
  const RewardPopupEvent({
    required this.seq,
    required this.message,
    this.xp = 0,
    this.gold = 0,
  });

  final int seq;
  final String message;
  final int xp;
  final int gold;
}

class AppViewState {
  const AppViewState({
    required this.streakState,
    required this.allUrgeLogs,
    required this.allQuests,
    required this.discreetMode,
    required this.isLocked,
    required this.hasPin,
    required this.biometricsEnabled,
    required this.hapticsEnabled,
    required this.sfxEnabled,
    required this.syncStatus,
    this.lastSyncedAtUtc,
    this.syncNote,
    this.lastReward,
  });

  final StreakState streakState;
  final List<UrgeLog> allUrgeLogs;
  final List<QuestItem> allQuests;
  final bool discreetMode;
  final bool isLocked;
  final bool hasPin;
  final bool biometricsEnabled;
  final bool hapticsEnabled;
  final bool sfxEnabled;
  final SyncStatus syncStatus;
  final DateTime? lastSyncedAtUtc;
  final String? syncNote;
  final RewardPopupEvent? lastReward;

  List<UrgeLog> get urgeLogs =>
      allUrgeLogs.where((e) => !e.isDeleted).toList(growable: false);

  List<QuestItem> get quests =>
      allQuests.where((e) => !e.isDeleted).toList(growable: false);

  int countQuestsCompletedOn(DateTime now) =>
      quests.where((q) => q.isCompletedOn(now)).length;

  int urgesDefeatedOn(DateTime nowLocal) {
    final key = formatUtcDateKey(nowLocal);
    return urgeLogs
        .where((l) =>
            l.type == UrgeLogType.urgeDefeated &&
            formatUtcDateKey(l.timestampUtc) == key)
        .length;
  }

  RecoverySnapshot toSnapshot(DateTime nowUtc) => RecoverySnapshot(
        schemaVersion: 3,
        streakState: streakState,
        urgeLogs: allUrgeLogs,
        quests: allQuests,
        exportedAtUtc: nowUtc.toUtc(),
      );

  AppViewState copyWith({
    StreakState? streakState,
    List<UrgeLog>? allUrgeLogs,
    List<QuestItem>? allQuests,
    bool? discreetMode,
    bool? isLocked,
    bool? hasPin,
    bool? biometricsEnabled,
    bool? hapticsEnabled,
    bool? sfxEnabled,
    SyncStatus? syncStatus,
    DateTime? lastSyncedAtUtc,
    String? syncNote,
    bool clearSyncNote = false,
    RewardPopupEvent? lastReward,
  }) =>
      AppViewState(
        streakState: streakState ?? this.streakState,
        allUrgeLogs: allUrgeLogs ?? this.allUrgeLogs,
        allQuests: allQuests ?? this.allQuests,
        discreetMode: discreetMode ?? this.discreetMode,
        isLocked: isLocked ?? this.isLocked,
        hasPin: hasPin ?? this.hasPin,
        biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
        hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
        sfxEnabled: sfxEnabled ?? this.sfxEnabled,
        syncStatus: syncStatus ?? this.syncStatus,
        lastSyncedAtUtc: lastSyncedAtUtc ?? this.lastSyncedAtUtc,
        syncNote: clearSyncNote ? null : (syncNote ?? this.syncNote),
        lastReward: lastReward ?? this.lastReward,
      );
}

final syncCoordinatorProvider = Provider<SyncCoordinator>(
  (ref) => SyncCoordinator(
    vault: ref.watch(vaultProvider),
    storage: ref.watch(storageProvider),
    crypto: ref.watch(cryptoServiceProvider),
    gistClient: ref.watch(githubGistClientProvider),
    supabaseAdapter: ref.watch(supabaseAdapterProvider),
  ),
);

/// Authoritative v3.0 "Eclipse Chronicle" state & RPG engine controller.
class RecoveryNotifier extends AsyncNotifier<AppViewState>
    with _RecoveryRpgMixin {
  static const _discreetMetaKey = 'discreet_mode';
  static const _hapticsMetaKey = 'haptics_enabled';
  static const _sfxMetaKey = 'sfx_enabled';
  static const _lastSyncMetaKey = 'last_sync_utc';

  @override
  RecoveryStorage get _storage => ref.read(storageProvider);
  SyncCoordinator get _sync => ref.read(syncCoordinatorProvider);
  @override
  AppLockService get _lock => ref.read(appLockServiceProvider);
  @override
  RpgSfxService get _sfx => ref.read(sfxServiceProvider);

  @override
  Future<AppViewState> build() async {
    final nowUtc = ref.read(clockProvider).now().toUtc();
    var streakState = await _storage.loadStreakState();
    final logs = await _storage.loadUrgeLogs();

    if (streakState == null) {
      streakState = StreakState.initial(nowUtc);
      await _storage.saveStreakState(streakState);
    } else {
      // Seamless v1/v2 -> v3 migration preserving existing user progress
      final hadPriorProgress = streakState.xp > 0 ||
          streakState.totalCleanDays > 0 ||
          logs.isNotEmpty ||
          streakState.currentDays(nowUtc) > 0;
      if (streakState.customRewards.isEmpty) {
        streakState = streakState.copyWith(customRewards: CustomReward.defaults(nowUtc));
      }
      if (streakState.counterSpells.isEmpty) {
        streakState = streakState.copyWith(counterSpells: CounterSpell.defaults(nowUtc));
      }
      if (!streakState.prologueCompleted && hadPriorProgress) {
        streakState = streakState.copyWith(prologueCompleted: true);
      }
    }

    streakState = _syncMilestoneUnlocks(streakState, nowUtc);
    var quests = await _storage.loadQuests();
    if (quests.isEmpty) {
      quests = QuestItem.defaultQuests(nowUtc);
      await _storage.replaceAllQuests(quests);
    }

    final discreet = (await _storage.getMeta(_discreetMetaKey)) == 'true';
    final hapticsRaw = await _storage.getMeta(_hapticsMetaKey);
    final haptics = hapticsRaw == null ? true : hapticsRaw == 'true';
    final sfxRaw = await _storage.getMeta(_sfxMetaKey);
    final sfx = sfxRaw == null ? true : sfxRaw == 'true';
    final lastSyncRaw = await _storage.getMeta(_lastSyncMetaKey);
    final lastSync = lastSyncRaw != null ? DateTime.tryParse(lastSyncRaw)?.toUtc() : null;

    final hasPin = await _lock.hasPinConfigured();
    final bioEnabled = await _lock.isBiometricsEnabled();
    unawaited(PlatformBootstrap.setDiscreetWindowTitle(discreet));

    final initial = AppViewState(
      streakState: streakState,
      allUrgeLogs: logs,
      allQuests: quests,
      discreetMode: discreet,
      isLocked: hasPin,
      hasPin: hasPin,
      biometricsEnabled: bioEnabled,
      hapticsEnabled: haptics,
      sfxEnabled: sfx,
      syncStatus: lastSync != null ? SyncStatus.synced : SyncStatus.idle,
      lastSyncedAtUtc: lastSync,
    );

    unawaited(_autoSyncIfConfigured(initial));
    return initial;
  }

  @override
  RewardPopupEvent _nextPopup(AppViewState cur, String msg, {int xp = 0, int gold = 0}) {
    final seq = (cur.lastReward?.seq ?? 0) + 1;
    return RewardPopupEvent(seq: seq, message: msg, xp: xp, gold: gold);
  }

  @override
  StreakState _syncMilestoneUnlocks(StreakState s, DateTime nowUtc) {
    final bestDays = s.effectiveBestDays(nowUtc);
    final unlocks = Map<String, String>.from(s.milestoneUnlocks);
    var changed = false;
    final dateStr = nowUtc.toUtc().toIso8601String();
    for (final card in kTrophyCards) {
      if (bestDays >= card.minDays && !unlocks.containsKey(card.id)) {
        unlocks[card.id] = dateStr;
        changed = true;
      }
    }
    return changed ? s.copyWith(milestoneUnlocks: unlocks) : s;
  }

  @override
  Future<void> _autoSyncIfConfigured(AppViewState current) async {
    if (await _sync.hasAnySyncConfigured()) {
      await syncNow(overrideState: current);
    }
  }

  Future<bool> completeDailyPledge() async {
    final cur = state.value;
    if (cur == null) return false;
    final nowLocal = ref.read(clockProvider).now();
    final nowUtc = nowLocal.toUtc();
    if (cur.streakState.hasPledgedOn(nowLocal)) return false;

    final dateKey = formatUtcDateKey(nowLocal);
    final updatedPledges = <String>{...cur.streakState.pledgeDates, dateKey}.toList()..sort();
    final watchtowerBonus = cur.streakState.structureLevel('watchtower') * 5;
    final xpGain = (25 * cur.streakState.comboMultiplier(nowLocal)).round() + watchtowerBonus;
    const goldGain = 10;

    final prevLvl = cur.streakState.level;
    var nextState = cur.streakState.copyWith(
      lastPledgeDate: dateKey,
      totalCleanDays: cur.streakState.totalCleanDays + 1,
      xp: cur.streakState.xp + xpGain,
      gold: cur.streakState.gold + goldGain,
      wilXp: cur.streakState.wilXp + xpGain,
      pledgeDates: updatedPledges,
      bestStreakSeconds: cur.streakState.effectiveBestSeconds(nowUtc),
      updatedAtUtc: nowUtc,
    );
    nextState = _syncMilestoneUnlocks(nextState, nowUtc);

    final pledgeLog = UrgeLog(
      id: ref.read(uuidProvider).v4(),
      timestampUtc: nowUtc,
      type: UrgeLogType.checkIn,
      intensity: 1,
      triggers: const ['Daily Pledge'],
      mood: 'Committed',
      note: 'Morning anchor vow sealed.',
      updatedAtUtc: nowUtc,
    );

    final updatedQuests = [
      for (final q in cur.allQuests)
        if (q.id == 'quest_morning_pledge' && !q.isCompletedOn(nowLocal))
          q.copyWith(lastCompletedDate: dateKey, streakCount: q.streakCount + 1, updatedAtUtc: nowUtc)
        else
          q,
    ];

    await _storage.saveStreakState(nextState);
    await _storage.saveUrgeLog(pledgeLog);
    await _storage.replaceAllQuests(updatedQuests);
    if (!ref.mounted) return true;

    unawaited(_sfx.play(
      nextState.level > prevLvl ? RpgSfx.levelUp : RpgSfx.chest,
      enabled: cur.sfxEnabled,
    ));

    final updated = cur.copyWith(
      streakState: nextState,
      allUrgeLogs: [pledgeLog, ...cur.allUrgeLogs],
      allQuests: updatedQuests,
      lastReward: _nextPopup(cur, 'Daily Vow Sealed', xp: xpGain, gold: goldGain),
    );
    state = AsyncData(updated);
    unawaited(_autoSyncIfConfigured(updated));
    return true;
  }

  Future<void> recordUrgeDefeated({
    int intensity = 6,
    List<String> triggers = const ['Urge Wave'],
    String mood = 'Resilient',
    String note = 'Vanquished Mirage phantom in Arena.',
    bool bossSlain = false,
  }) async {
    final cur = state.value;
    if (cur == null) return;
    final nowUtc = ref.read(clockProvider).now().toUtc();
    final xpGain = bossSlain ? 75 : 50;
    final goldGain = bossSlain ? 40 : 20;
    final vitGain = bossSlain ? 40 : 25;

    final log = UrgeLog(
      id: ref.read(uuidProvider).v4(),
      timestampUtc: nowUtc,
      type: UrgeLogType.urgeDefeated,
      intensity: intensity,
      triggers: triggers.isEmpty ? const ['Urge Wave'] : triggers,
      mood: mood,
      note: note,
      updatedAtUtc: nowUtc,
    );

    final prevLvl = cur.streakState.level;
    var nextState = cur.streakState.copyWith(
      xp: cur.streakState.xp + xpGain,
      gold: cur.streakState.gold + goldGain,
      vitXp: cur.streakState.vitXp + vitGain,
      bossKills: cur.streakState.bossKills + (bossSlain ? 1 : 0),
      bestStreakSeconds: cur.streakState.effectiveBestSeconds(nowUtc),
      updatedAtUtc: nowUtc,
    );
    nextState = _syncMilestoneUnlocks(nextState, nowUtc);

    await _storage.saveStreakState(nextState);
    await _storage.saveUrgeLog(log);
    if (!ref.mounted) return;

    unawaited(_sfx.play(
      nextState.level > prevLvl ? RpgSfx.levelUp : RpgSfx.chest,
      enabled: cur.sfxEnabled,
    ));

    final updated = cur.copyWith(
      streakState: nextState,
      allUrgeLogs: [log, ...cur.allUrgeLogs],
      lastReward: _nextPopup(
        cur,
        bossSlain ? 'Mirage Boss Slain!' : 'Urge Overcome',
        xp: xpGain,
        gold: goldGain,
      ),
    );
    state = AsyncData(updated);
    unawaited(_autoSyncIfConfigured(updated));
  }

  /// Roguelite Harm-Reduction Campfire: NEVER wipes Citadel, Story Acts, Spells,
  /// Stats, Skill Tree, or Foil Relics. Resets active arc timer and awards +20 WIS XP.
  @override
  Future<void> recordRelapsePostMortem({
    required List<String> triggers,
    required String mood,
    required String lessonNote,
    int intensity = 6,
  }) async {
    final cur = state.value;
    if (cur == null) return;
    final nowUtc = ref.read(clockProvider).now().toUtc();
    final elapsedSeconds = cur.streakState.currentStreak(nowUtc).inSeconds;
    final newBest = math.max(cur.streakState.bestStreakSeconds, elapsedSeconds);

    final relapseLog = UrgeLog(
      id: ref.read(uuidProvider).v4(),
      timestampUtc: nowUtc,
      type: UrgeLogType.relapse,
      intensity: intensity,
      triggers: triggers,
      mood: mood,
      note: lessonNote,
      updatedAtUtc: nowUtc,
    );

    final archived = StreakRecord(
      id: ref.read(uuidProvider).v4(),
      startedAtUtc: cur.streakState.startTimeUtc,
      endedAtUtc: nowUtc,
      durationSeconds: elapsedSeconds,
      triggers: triggers,
      mood: mood,
      lessonNote: lessonNote,
      updatedAtUtc: nowUtc,
    );

    final nextState = cur.streakState.copyWith(
      startTimeUtc: nowUtc,
      bestStreakSeconds: newBest,
      xp: cur.streakState.xp + 20,
      wisXp: cur.streakState.wisXp + 20,
      streakHistory: [archived, ...cur.streakState.streakHistory],
      updatedAtUtc: nowUtc,
    );

    await _storage.saveStreakState(nextState);
    await _storage.saveUrgeLog(relapseLog);
    if (!ref.mounted) return;

    final updated = cur.copyWith(
      streakState: nextState,
      allUrgeLogs: [relapseLog, ...cur.allUrgeLogs],
      lastReward: _nextPopup(cur, 'Campfire Reflection Logged', xp: 20),
    );
    state = AsyncData(updated);
    unawaited(_autoSyncIfConfigured(updated));
  }

  Future<void> syncNow({AppViewState? overrideState}) async {
    final cur = overrideState ?? state.value;
    if (cur == null) return;
    final nowUtc = ref.read(clockProvider).now().toUtc();

    state = AsyncData(cur.copyWith(syncStatus: SyncStatus.syncing, clearSyncNote: true));
    final result = await _sync.syncAll(cur.toSnapshot(nowUtc));
    await _sync.persistSnapshot(result.snapshot);

    final syncedNow = result.errorMessage == null && result.syncedChannels.isNotEmpty;
    if (syncedNow) {
      await _storage.setMeta(_lastSyncMetaKey, nowUtc.toIso8601String());
    }
    if (!ref.mounted) return;
    state = AsyncData(
      cur.copyWith(
        streakState: result.snapshot.streakState,
        allUrgeLogs: result.snapshot.urgeLogs,
        allQuests: result.snapshot.quests,
        syncStatus: result.errorMessage != null
            ? SyncStatus.error
            : (syncedNow ? SyncStatus.synced : SyncStatus.idle),
        lastSyncedAtUtc: syncedNow ? nowUtc : cur.lastSyncedAtUtc,
        syncNote: result.errorMessage ??
            (syncedNow
                ? 'Synced: ${result.syncedChannels.join(' + ')}'
                : 'Local mode (configure Gist or Supabase below)'),
      ),
    );
  }

  Future<String> createPairingPayload() => _sync.createDevicePairingPayload();

  Future<void> applyPairingPayload(String rawPayload, String passphrase) async {
    await _sync.applyDevicePairingPayload(rawPayload, passphrase);
    await syncNow();
  }

  Future<String> exportEncryptedBackup(String passphrase) async {
    final cur = state.value;
    if (cur == null) throw StateError('App state not loaded');
    final nowUtc = ref.read(clockProvider).now().toUtc();
    return _sync.exportEncryptedBackup(cur.toSnapshot(nowUtc), passphrase);
  }

  Future<void> importEncryptedBackup(String payload, String passphrase) async {
    final cur = state.value;
    if (cur == null) throw StateError('App state not loaded');
    final nowUtc = ref.read(clockProvider).now().toUtc();
    final merged = await _sync.importEncryptedBackup(payload, passphrase, cur.toSnapshot(nowUtc));
    await _sync.persistSnapshot(merged);
    if (!ref.mounted) return;
    state = AsyncData(
      cur.copyWith(
        streakState: merged.streakState,
        allUrgeLogs: merged.urgeLogs,
        allQuests: merged.quests,
      ),
    );
  }
}

final recoveryProvider =
    AsyncNotifierProvider<RecoveryNotifier, AppViewState>(
  RecoveryNotifier.new,
);
