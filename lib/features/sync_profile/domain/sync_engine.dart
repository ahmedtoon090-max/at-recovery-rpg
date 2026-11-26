import 'dart:math' as math;

import '../../../features/sanctuary/domain/recovery_models.dart';

/// Deterministic conflict-free v3.0 snapshot merger across multiple devices.
abstract final class SyncEngine {
  static RecoverySnapshot mergeSnapshots(
    RecoverySnapshot local,
    RecoverySnapshot remote,
  ) {
    final mergedState = _mergeStreakState(local.streakState, remote.streakState);
    final mergedLogs = _mergeUrgeLogs(local.urgeLogs, remote.urgeLogs);
    final mergedQuests = _mergeQuests(local.quests, remote.quests);
    final latestExport = local.exportedAtUtc.isAfter(remote.exportedAtUtc)
        ? local.exportedAtUtc
        : remote.exportedAtUtc;

    return RecoverySnapshot(
      schemaVersion: math.max(4, math.max(local.schemaVersion, remote.schemaVersion)),
      streakState: mergedState,
      urgeLogs: mergedLogs,
      quests: mergedQuests,
      exportedAtUtc: latestExport,
    );
  }

  static StreakState _mergeStreakState(StreakState local, StreakState remote) {
    final primary =
        remote.updatedAtUtc.isAfter(local.updatedAtUtc) ? remote : local;

    final historyMap = <String, StreakRecord>{};
    for (final rec in local.streakHistory) {
      historyMap[rec.id] = rec;
    }
    for (final rec in remote.streakHistory) {
      final existing = historyMap[rec.id];
      if (existing == null || rec.updatedAtUtc.isAfter(existing.updatedAtUtc)) {
        historyMap[rec.id] = rec;
      }
    }
    final mergedHistory = historyMap.values.toList()
      ..sort((a, b) => b.endedAtUtc.compareTo(a.endedAtUtc));

    final mergedPledges = <String>{
      ...local.pledgeDates,
      ...remote.pledgeDates,
    }.toList()
      ..sort();

    final mergedCastle = <String, int>{...local.castleStructures};
    remote.castleStructures.forEach((key, val) {
      mergedCastle[key] = math.max(mergedCastle[key] ?? 0, val);
    });

    final mergedShields = <String, String>{...local.shieldChecks};
    remote.shieldChecks.forEach((key, val) {
      final prev = mergedShields[key];
      if (prev == null || val.compareTo(prev) > 0) mergedShields[key] = val;
    });

    final mergedUnlocks = <String, String>{...local.milestoneUnlocks};
    remote.milestoneUnlocks.forEach((key, val) {
      mergedUnlocks.putIfAbsent(key, () => val);
    });

    final rewardMap = <String, CustomReward>{
      for (final r in local.customRewards) r.id: r,
    };
    for (final r in remote.customRewards) {
      final prev = rewardMap[r.id];
      if (prev == null || r.updatedAtUtc.isAfter(prev.updatedAtUtc)) {
        rewardMap[r.id] = r;
      }
    }

    final spellMap = <String, CounterSpell>{
      for (final s in local.counterSpells) s.id: s,
    };
    for (final s in remote.counterSpells) {
      final prev = spellMap[s.id];
      if (prev == null) {
        spellMap[s.id] = s;
      } else {
        final newer = s.updatedAtUtc.isAfter(prev.updatedAtUtc) ? s : prev;
        spellMap[s.id] = newer.copyWith(
          casts: math.max(prev.casts, s.casts),
          rank: math.max(prev.rank, s.rank),
        );
      }
    }

    final mergedChoices = <String, String>{...local.chronicleChoices};
    remote.chronicleChoices.forEach((actId, choiceId) {
      mergedChoices.putIfAbsent(actId, () => choiceId);
    });

    final mergedPomoDates = <String, int>{...local.pomodoroDates};
    remote.pomodoroDates.forEach((dateKey, cnt) {
      mergedPomoDates[dateKey] = math.max(mergedPomoDates[dateKey] ?? 0, cnt);
    });

    return StreakState(
      startTimeUtc: primary.startTimeUtc,
      bestStreakSeconds: math.max(local.bestStreakSeconds, remote.bestStreakSeconds),
      totalCleanDays: math.max(local.totalCleanDays, remote.totalCleanDays),
      lastPledgeDate: primary.lastPledgeDate,
      xp: math.max(local.xp, remote.xp),
      gold: math.max(local.gold, remote.gold),
      whyIStarted: primary.whyIStarted,
      streakHistory: mergedHistory,
      pledgeDates: mergedPledges,
      pomodoroSessionsCompleted: math.max(
        local.pomodoroSessionsCompleted,
        remote.pomodoroSessionsCompleted,
      ),
      updatedAtUtc: primary.updatedAtUtc,
      bossKills: math.max(local.bossKills, remote.bossKills),
      wilXp: math.max(local.wilXp, remote.wilXp),
      focXp: math.max(local.focXp, remote.focXp),
      vitXp: math.max(local.vitXp, remote.vitXp),
      wisXp: math.max(local.wisXp, remote.wisXp),
      castleStructures: mergedCastle,
      claimedJourneyNodes: {
        ...local.claimedJourneyNodes,
        ...remote.claimedJourneyNodes,
      }.toList(),
      shieldChecks: mergedShields,
      milestoneUnlocks: mergedUnlocks,
      unlockedSkills: {
        ...local.unlockedSkills,
        ...remote.unlockedSkills,
      }.toList(),
      ownedCosmetics: {
        ...local.ownedCosmetics,
        ...remote.ownedCosmetics,
      }.toList(),
      equippedOrbId: primary.equippedOrbId,
      equippedAuraId: primary.equippedAuraId,
      customRewards: rewardMap.values.toList(),
      claimedDailyChestDate: primary.claimedDailyChestDate,
      lampbearerName: primary.lampbearerName,
      guidingVow: primary.guidingVow,
      prologueCompleted: local.prologueCompleted || remote.prologueCompleted,
      chronicleChoices: mergedChoices,
      counterSpells: spellMap.values.toList(),
      haltFlags: primary.haltFlags,
      pomodoroDates: mergedPomoDates,
      diagnosticProfile: primary.diagnosticProfile ?? local.diagnosticProfile ?? remote.diagnosticProfile,
    );
  }

  static List<UrgeLog> _mergeUrgeLogs(List<UrgeLog> local, List<UrgeLog> remote) {
    final map = <String, UrgeLog>{};
    for (final item in local) {
      map[item.id] = item;
    }
    for (final item in remote) {
      final existing = map[item.id];
      if (existing == null || item.updatedAtUtc.isAfter(existing.updatedAtUtc)) {
        map[item.id] = item;
      }
    }
    return map.values.toList()..sort((a, b) => b.timestampUtc.compareTo(a.timestampUtc));
  }

  static List<QuestItem> _mergeQuests(List<QuestItem> local, List<QuestItem> remote) {
    final map = <String, QuestItem>{};
    for (final item in local) {
      map[item.id] = item;
    }
    for (final item in remote) {
      final existing = map[item.id];
      if (existing == null || item.updatedAtUtc.isAfter(existing.updatedAtUtc)) {
        map[item.id] = item;
      }
    }
    return map.values.toList();
  }
}
