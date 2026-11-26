part of 'recovery_controller.dart';

/// Eclipse Chronicle Onboarding, Acts, HALT, Counter-Spells, Citadel Upgrades,
/// Skill Tree, Armory, Quests, Pomodoro, Journal, and Lock controls.
mixin _RecoveryRpgMixin on AsyncNotifier<AppViewState> {
  RecoveryStorage get _storage;
  AppLockService get _lock;
  RpgSfxService get _sfx;
  RewardPopupEvent _nextPopup(AppViewState cur, String msg, {int xp = 0, int gold = 0});
  StreakState _syncMilestoneUnlocks(StreakState s, DateTime nowUtc);
  Future<void> _autoSyncIfConfigured(AppViewState current);
  Future<void> recordRelapsePostMortem({
    required List<String> triggers,
    required String mood,
    required String lessonNote,
    int intensity = 6,
  });

  Future<void> applyDiagnosticBlueprint(
    DiagnosticBlueprint bp, {
    String? customPin,
  }) async {
    final cur = state.value;
    if (cur == null) return;
    final nowUtc = ref.read(clockProvider).now().toUtc();

    final nextState = cur.streakState.copyWith(
      lampbearerName: bp.profile.lampbearerName,
      guidingVow: bp.profile.guidingVow,
      whyIStarted: bp.recommendedWhy,
      prologueCompleted: true,
      diagnosticProfile: bp.profile,
      counterSpells: bp.starterSpells,
      xp: cur.streakState.xp + 25,
      gold: cur.streakState.gold + 15,
      wilXp: cur.streakState.wilXp + 20,
      updatedAtUtc: nowUtc,
    );

    if (customPin != null && customPin.length == 4) {
      await _lock.setPin(customPin);
    }
    if (bp.profile.discreetPreferred != cur.discreetMode) {
      await _storage.setMeta(
        RecoveryNotifier._discreetMetaKey,
        bp.profile.discreetPreferred ? 'true' : 'false',
      );
      await PlatformBootstrap.setDiscreetWindowTitle(bp.profile.discreetPreferred);
    }

    await _storage.saveStreakState(nextState);
    await _storage.replaceAllQuests(bp.starterQuests);
    if (!ref.mounted) return;

    unawaited(_sfx.play(RpgSfx.levelUp, enabled: cur.sfxEnabled));
    final hasPin = await _lock.hasPinConfigured();
    if (!ref.mounted) return;

    final updated = cur.copyWith(
      streakState: nextState,
      allQuests: bp.starterQuests,
      discreetMode: bp.profile.discreetPreferred,
      hasPin: hasPin,
      isLocked: false,
      lastReward: _nextPopup(cur, 'Citadel Blueprint Forged', xp: 25, gold: 15),
    );
    state = AsyncData(updated);
    unawaited(_autoSyncIfConfigured(updated));
  }

  Future<void> skipOnboardingPrologue({
    String lampbearerName = 'Warden',
    GuidingVow vow = GuidingVow.clarity,
  }) async {
    final cur = state.value;
    if (cur == null) return;
    final nowUtc = ref.read(clockProvider).now().toUtc();
    final nextState = cur.streakState.copyWith(
      lampbearerName: lampbearerName,
      guidingVow: vow,
      prologueCompleted: true,
      updatedAtUtc: nowUtc,
    );
    await _storage.saveStreakState(nextState);
    if (!ref.mounted) return;
    state = AsyncData(cur.copyWith(streakState: nextState));
  }

  Future<bool> selectChronicleChoice({
    required String actId,
    required ActChoiceSpec choice,
  }) async {
    final cur = state.value;
    if (cur == null) return false;
    final act = kChronicleActs.firstWhere((a) => a.id == actId);
    final nowUtc = ref.read(clockProvider).now().toUtc();
    if (cur.streakState.currentDays(nowUtc) < act.minDay) return false;
    if (cur.streakState.chronicleChoices.containsKey(actId)) return false;

    final nextChoices = Map<String, String>.from(cur.streakState.chronicleChoices)
      ..[actId] = choice.id;
    final nextState = cur.streakState.copyWith(
      chronicleChoices: nextChoices,
      xp: cur.streakState.xp + 25,
      gold: cur.streakState.gold + 15,
      wilXp: cur.streakState.wilXp + choice.wilDelta,
      wisXp: cur.streakState.wisXp + choice.wisDelta,
      updatedAtUtc: nowUtc,
    );
    await _storage.saveStreakState(nextState);
    if (!ref.mounted) return true;

    unawaited(_sfx.play(RpgSfx.chest, enabled: cur.sfxEnabled));
    final updated = cur.copyWith(
      streakState: nextState,
      lastReward: _nextPopup(cur, 'Chronicle Act ${act.actNumber} Inscribed', xp: 25, gold: 15),
    );
    state = AsyncData(updated);
    unawaited(_autoSyncIfConfigured(updated));
    return true;
  }

  Future<bool> claimChronicleReward({
    required String nodeId,
    required int requiredDay,
    required int xpReward,
    required int goldReward,
    bool isBoss = false,
  }) async {
    final cur = state.value;
    if (cur == null) return false;
    final nowUtc = ref.read(clockProvider).now().toUtc();
    if (cur.streakState.currentDays(nowUtc) < requiredDay) return false;
    if (cur.streakState.claimedJourneyNodes.contains(nodeId)) return false;

    var nextState = cur.streakState.copyWith(
      claimedJourneyNodes: [...cur.streakState.claimedJourneyNodes, nodeId],
      xp: cur.streakState.xp + xpReward,
      gold: cur.streakState.gold + goldReward,
      wilXp: cur.streakState.wilXp + 20,
      vitXp: isBoss ? cur.streakState.vitXp + 25 : cur.streakState.vitXp,
      bossKills: isBoss ? cur.streakState.bossKills + 1 : cur.streakState.bossKills,
      updatedAtUtc: nowUtc,
    );
    nextState = _syncMilestoneUnlocks(nextState, nowUtc);
    await _storage.saveStreakState(nextState);
    if (!ref.mounted) return true;

    unawaited(_sfx.play(RpgSfx.chest, enabled: cur.sfxEnabled));
    final updated = cur.copyWith(
      streakState: nextState,
      lastReward: _nextPopup(cur, isBoss ? 'Act Boss Gate Cleared!' : 'Relic Chest Looted', xp: xpReward, gold: goldReward),
    );
    state = AsyncData(updated);
    unawaited(_autoSyncIfConfigured(updated));
    return true;
  }

  Future<void> toggleHaltOrb(String haltId) async {
    final cur = state.value;
    if (cur == null) return;
    final nowUtc = ref.read(clockProvider).now().toUtc();
    final nextFlags = Map<String, bool>.from(cur.streakState.haltFlags);
    nextFlags[haltId] = !(nextFlags[haltId] ?? false);
    final nextState = cur.streakState.copyWith(haltFlags: nextFlags, updatedAtUtc: nowUtc);
    await _storage.saveStreakState(nextState);
    if (!ref.mounted) return;
    state = AsyncData(cur.copyWith(streakState: nextState));
  }

  Future<void> completeHaltRestoration(String haltId) async {
    final cur = state.value;
    if (cur == null) return;
    final nowUtc = ref.read(clockProvider).now().toUtc();
    final nextFlags = Map<String, bool>.from(cur.streakState.haltFlags)..[haltId] = false;
    final bonus = cur.streakState.hasSkill('ember_ward') ? 15 : 10;
    final nextState = cur.streakState.copyWith(
      haltFlags: nextFlags,
      xp: cur.streakState.xp + bonus,
      vitXp: cur.streakState.vitXp + 15,
      updatedAtUtc: nowUtc,
    );
    await _storage.saveStreakState(nextState);
    if (!ref.mounted) return;
    unawaited(_sfx.play(RpgSfx.breath, enabled: cur.sfxEnabled));
    state = AsyncData(
      cur.copyWith(
        streakState: nextState,
        lastReward: _nextPopup(cur, 'Guardian Restoration Complete', xp: bonus),
      ),
    );
  }

  Future<void> addCounterSpell({
    required String triggerCue,
    required String actionPlan,
  }) async {
    final cur = state.value;
    if (cur == null) return;
    final nowUtc = ref.read(clockProvider).now().toUtc();
    final spell = CounterSpell(
      id: ref.read(uuidProvider).v4(),
      triggerCue: triggerCue.trim(),
      actionPlan: actionPlan.trim(),
      updatedAtUtc: nowUtc,
    );
    final nextState = cur.streakState.copyWith(
      counterSpells: [...cur.streakState.counterSpells, spell],
      updatedAtUtc: nowUtc,
    );
    await _storage.saveStreakState(nextState);
    if (!ref.mounted) return;
    state = AsyncData(cur.copyWith(streakState: nextState));
  }

  Future<void> castCounterSpell(String spellId) async {
    final cur = state.value;
    if (cur == null) return;
    final nowUtc = ref.read(clockProvider).now().toUtc();
    final updatedSpells = [
      for (final sp in cur.streakState.counterSpells)
        if (sp.id == spellId)
          sp.copyWith(
            casts: sp.casts + 1,
            rank: (1 + ((sp.casts + 1) ~/ 2)).clamp(1, 5),
            updatedAtUtc: nowUtc,
          )
        else
          sp,
    ];
    final nextState = cur.streakState.copyWith(
      counterSpells: updatedSpells,
      vitXp: cur.streakState.vitXp + 15,
      updatedAtUtc: nowUtc,
    );
    await _storage.saveStreakState(nextState);
    if (!ref.mounted) return;
    state = AsyncData(cur.copyWith(streakState: nextState));
  }

  Future<void> toggleSpellEquipped(String spellId) async {
    final cur = state.value;
    if (cur == null) return;
    final nowUtc = ref.read(clockProvider).now().toUtc();
    final nextSpells = [
      for (final sp in cur.streakState.counterSpells)
        if (sp.id == spellId) sp.copyWith(equipped: !sp.equipped, updatedAtUtc: nowUtc) else sp,
    ];
    final nextState = cur.streakState.copyWith(counterSpells: nextSpells, updatedAtUtc: nowUtc);
    await _storage.saveStreakState(nextState);
    if (!ref.mounted) return;
    state = AsyncData(cur.copyWith(streakState: nextState));
  }

  Future<void> addJournalLog({
    required UrgeLogType type,
    required int intensity,
    required List<String> triggers,
    required String mood,
    required String note,
  }) async {
    if (type == UrgeLogType.relapse) {
      await recordRelapsePostMortem(
        triggers: triggers,
        mood: mood,
        lessonNote: note,
        intensity: intensity,
      );
      return;
    }

    final cur = state.value;
    if (cur == null) return;
    final nowUtc = ref.read(clockProvider).now().toUtc();
    final log = UrgeLog(
      id: ref.read(uuidProvider).v4(),
      timestampUtc: nowUtc,
      type: type,
      intensity: intensity,
      triggers: triggers,
      mood: mood,
      note: note,
      updatedAtUtc: nowUtc,
    );

    final xpGain = type == UrgeLogType.urgeDefeated ? 50 : 15;
    final goldGain = type == UrgeLogType.urgeDefeated ? 20 : 5;
    final nextState = cur.streakState.copyWith(
      xp: cur.streakState.xp + xpGain,
      gold: cur.streakState.gold + goldGain,
      wisXp: cur.streakState.wisXp + 20,
      vitXp: type == UrgeLogType.urgeDefeated ? cur.streakState.vitXp + 20 : cur.streakState.vitXp,
      updatedAtUtc: nowUtc,
    );

    await _storage.saveStreakState(nextState);
    await _storage.saveUrgeLog(log);
    if (!ref.mounted) return;
    final updated = cur.copyWith(
      streakState: nextState,
      allUrgeLogs: [log, ...cur.allUrgeLogs],
      lastReward: _nextPopup(cur, 'Codex Log Inscribed', xp: xpGain, gold: goldGain),
    );
    state = AsyncData(updated);
    unawaited(_autoSyncIfConfigured(updated));
  }

  Future<void> softDeleteLog(String logId) async {
    final cur = state.value;
    if (cur == null) return;
    final nowUtc = ref.read(clockProvider).now().toUtc();
    UrgeLog? target;
    final updatedLogs = [
      for (final log in cur.allUrgeLogs)
        if (log.id == logId) (target = log.copyWith(isDeleted: true, updatedAtUtc: nowUtc)) else log,
    ];
    if (target == null) return;
    await _storage.saveUrgeLog(target);
    if (!ref.mounted) return;
    state = AsyncData(cur.copyWith(allUrgeLogs: updatedLogs));
  }

  Future<void> restoreLog(String logId) async {
    final cur = state.value;
    if (cur == null) return;
    final nowUtc = ref.read(clockProvider).now().toUtc();
    UrgeLog? target;
    final updatedLogs = [
      for (final log in cur.allUrgeLogs)
        if (log.id == logId) (target = log.copyWith(isDeleted: false, updatedAtUtc: nowUtc)) else log,
    ];
    if (target == null) return;
    await _storage.saveUrgeLog(target);
    if (!ref.mounted) return;
    state = AsyncData(cur.copyWith(allUrgeLogs: updatedLogs));
  }

  Future<void> completeQuest(String questId) async {
    final cur = state.value;
    if (cur == null) return;
    final nowLocal = ref.read(clockProvider).now();
    final nowUtc = nowLocal.toUtc();
    final dateKey = formatUtcDateKey(nowLocal);

    QuestItem? updatedQuest;
    final nextQuests = <QuestItem>[];
    for (final q in cur.allQuests) {
      if (q.id == questId && !q.isCompletedOn(nowLocal)) {
        updatedQuest = q.copyWith(lastCompletedDate: dateKey, streakCount: q.streakCount + 1, updatedAtUtc: nowUtc);
        nextQuests.add(updatedQuest);
      } else {
        nextQuests.add(q);
      }
    }
    if (updatedQuest == null) return;

    final s = cur.streakState;
    final combo = s.comboMultiplier(nowLocal);
    final forgeGold = s.structureLevel('arcane_forge') * 5;
    final gateMult = 1.0 + s.structureLevel('golden_gate') * 0.05;
    final xpGain = (updatedQuest.xpReward * combo * gateMult).round();
    final goldMult = s.hasSkill('golden_forge') ? 1.2 : 1.0;
    final goldGain = ((updatedQuest.goldReward + forgeGold) * goldMult).round();

    final nextState = s.copyWith(
      xp: s.xp + xpGain,
      gold: s.gold + goldGain,
      wilXp: s.wilXp + 15,
      focXp: s.focXp + 10,
      updatedAtUtc: nowUtc,
    );

    await _storage.saveQuest(updatedQuest);
    await _storage.saveStreakState(nextState);
    if (!ref.mounted) return;
    unawaited(_sfx.play(RpgSfx.chest, enabled: cur.sfxEnabled));
    final updated = cur.copyWith(
      streakState: nextState,
      allQuests: nextQuests,
      lastReward: _nextPopup(cur, updatedQuest.title, xp: xpGain, gold: goldGain),
    );
    state = AsyncData(updated);
    unawaited(_autoSyncIfConfigured(updated));
  }

  Future<bool> claimDailyQuestChest() async {
    final cur = state.value;
    if (cur == null) return false;
    final nowLocal = ref.read(clockProvider).now();
    final dateKey = formatUtcDateKey(nowLocal);
    if (cur.streakState.claimedDailyChestDate == dateKey) return false;
    if (cur.countQuestsCompletedOn(nowLocal) < 3) return false;

    final nowUtc = nowLocal.toUtc();
    const xpGain = 45;
    final goldGain = cur.streakState.hasSkill('golden_forge') ? 30 : 25;
    final nextState = cur.streakState.copyWith(
      xp: cur.streakState.xp + xpGain,
      gold: cur.streakState.gold + goldGain,
      wilXp: cur.streakState.wilXp + 20,
      claimedDailyChestDate: dateKey,
      updatedAtUtc: nowUtc,
    );
    await _storage.saveStreakState(nextState);
    if (!ref.mounted) return true;
    unawaited(_sfx.play(RpgSfx.chest, enabled: cur.sfxEnabled));
    final updated = cur.copyWith(
      streakState: nextState,
      lastReward: _nextPopup(cur, 'Daily Tribute Chest Opened!', xp: xpGain, gold: goldGain),
    );
    state = AsyncData(updated);
    unawaited(_autoSyncIfConfigured(updated));
    return true;
  }

  Future<void> toggleTriggerShield(String shieldId) async {
    final cur = state.value;
    if (cur == null) return;
    final nowLocal = ref.read(clockProvider).now();
    final nowUtc = nowLocal.toUtc();
    final today = formatUtcDateKey(nowLocal);
    final prevCount = cur.streakState.shieldCountOn(nowLocal);
    final nextChecks = Map<String, String>.from(cur.streakState.shieldChecks);
    nextChecks[shieldId] == today ? nextChecks.remove(shieldId) : nextChecks[shieldId] = today;

    var nextState = cur.streakState.copyWith(shieldChecks: nextChecks, updatedAtUtc: nowUtc);
    final nextCount = nextState.shieldCountOn(nowLocal);
    var bonusXp = 0;
    var bonusGold = 0;
    if (prevCount < kTriggerShieldItems.length && nextCount == kTriggerShieldItems.length) {
      bonusXp = 20;
      bonusGold = 10;
      nextState = nextState.copyWith(
        xp: nextState.xp + bonusXp,
        gold: nextState.gold + bonusGold,
        wilXp: nextState.wilXp + 15,
      );
    }
    await _storage.saveStreakState(nextState);
    if (!ref.mounted) return;
    state = AsyncData(
      cur.copyWith(
        streakState: nextState,
        lastReward: bonusXp > 0
            ? _nextPopup(cur, 'Boundary Shield 100% Fortified', xp: bonusXp, gold: bonusGold)
            : null,
      ),
    );
  }

  Future<void> addCustomQuest({
    required String title,
    required String description,
    int xpReward = 25,
    int goldReward = 10,
  }) async {
    final cur = state.value;
    if (cur == null) return;
    final nowUtc = ref.read(clockProvider).now().toUtc();
    final quest = QuestItem(
      id: ref.read(uuidProvider).v4(),
      title: title,
      description: description,
      xpReward: xpReward,
      goldReward: goldReward,
      lastCompletedDate: null,
      streakCount: 0,
      updatedAtUtc: nowUtc,
    );
    await _storage.saveQuest(quest);
    if (!ref.mounted) return;
    state = AsyncData(cur.copyWith(allQuests: [...cur.allQuests, quest]));
  }

  Future<void> deleteQuest(String questId) async {
    final cur = state.value;
    if (cur == null) return;
    final nowUtc = ref.read(clockProvider).now().toUtc();
    QuestItem? target;
    final nextQuests = [
      for (final q in cur.allQuests)
        if (q.id == questId) (target = q.copyWith(isDeleted: true, updatedAtUtc: nowUtc)) else q,
    ];
    if (target == null) return;
    await _storage.saveQuest(target);
    if (!ref.mounted) return;
    state = AsyncData(cur.copyWith(allQuests: nextQuests));
  }

  Future<void> completePomodoroFocus() async {
    final cur = state.value;
    if (cur == null) return;
    final nowLocal = ref.read(clockProvider).now();
    final nowUtc = nowLocal.toUtc();
    final dateKey = formatUtcDateKey(nowLocal);

    final nextQuests = [
      for (final q in cur.allQuests)
        if (q.id == 'quest_deep_focus' && !q.isCompletedOn(nowLocal))
          q.copyWith(lastCompletedDate: dateKey, streakCount: q.streakCount + 1, updatedAtUtc: nowUtc)
        else
          q,
    ];

    final xpMult = cur.streakState.hasSkill('focus_mastery') ? 1.3 : 1.0;
    final xpGain = (35 * xpMult).round();
    const goldGain = 15;
    final pomoDates = Map<String, int>.from(cur.streakState.pomodoroDates);
    pomoDates[dateKey] = (pomoDates[dateKey] ?? 0) + 1;

    final nextState = cur.streakState.copyWith(
      xp: cur.streakState.xp + xpGain,
      gold: cur.streakState.gold + goldGain,
      focXp: cur.streakState.focXp + 30,
      pomodoroSessionsCompleted: cur.streakState.pomodoroSessionsCompleted + 1,
      pomodoroDates: pomoDates,
      updatedAtUtc: nowUtc,
    );

    await _storage.saveStreakState(nextState);
    await _storage.replaceAllQuests(nextQuests);
    if (!ref.mounted) return;
    unawaited(_sfx.play(RpgSfx.chest, enabled: cur.sfxEnabled));
    final updated = cur.copyWith(
      streakState: nextState,
      allQuests: nextQuests,
      lastReward: _nextPopup(cur, 'Focus Session Complete', xp: xpGain, gold: goldGain),
    );
    state = AsyncData(updated);
    unawaited(_autoSyncIfConfigured(updated));
  }

  Future<bool> upgradeCastleStructure(String structureId) async {
    final cur = state.value;
    if (cur == null) return false;
    final def = kCastleStructures.firstWhere((e) => e.id == structureId);
    final level = cur.streakState.structureLevel(structureId);
    if (level >= def.maxLevel) return false;
    final cost = def.costForLevel(level, architectDiscount: cur.streakState.hasSkill('citadel_architect'));
    if (cur.streakState.gold < cost) return false;

    final nowUtc = ref.read(clockProvider).now().toUtc();
    final structures = Map<String, int>.from(cur.streakState.castleStructures)..[structureId] = level + 1;
    final nextState = cur.streakState.copyWith(
      gold: cur.streakState.gold - cost,
      xp: cur.streakState.xp + 20,
      wilXp: cur.streakState.wilXp + 15,
      castleStructures: structures,
      updatedAtUtc: nowUtc,
    );
    await _storage.saveStreakState(nextState);
    if (!ref.mounted) return true;
    unawaited(_sfx.play(RpgSfx.levelUp, enabled: cur.sfxEnabled));
    final updated = cur.copyWith(
      streakState: nextState,
      lastReward: _nextPopup(cur, '${def.name} Lv.${level + 1} Built', xp: 20),
    );
    state = AsyncData(updated);
    unawaited(_autoSyncIfConfigured(updated));
    return true;
  }

  Future<bool> unlockSkillPerk(String skillId) async {
    final cur = state.value;
    if (cur == null) return false;
    final s = cur.streakState;
    if (s.hasSkill(skillId) || s.availableSkillPoints <= 0) return false;
    final nowUtc = ref.read(clockProvider).now().toUtc();
    final nextState = s.copyWith(
      unlockedSkills: [...s.unlockedSkills, skillId],
      wisXp: s.wisXp + 15,
      updatedAtUtc: nowUtc,
    );
    await _storage.saveStreakState(nextState);
    if (!ref.mounted) return true;
    unawaited(_sfx.play(RpgSfx.levelUp, enabled: cur.sfxEnabled));
    final updated = cur.copyWith(
      streakState: nextState,
      lastReward: _nextPopup(cur, 'Skill Perk Unlocked!'),
    );
    state = AsyncData(updated);
    unawaited(_autoSyncIfConfigured(updated));
    return true;
  }

  Future<bool> buyOrEquipCosmetic(String cosmeticId) async {
    final cur = state.value;
    if (cur == null) return false;
    final item = kArmoryCosmetics.firstWhere((e) => e.id == cosmeticId);
    final s = cur.streakState;
    final owned = s.ownedCosmetics.contains(cosmeticId);
    if (!owned && s.gold < item.costGold) return false;

    final nowUtc = ref.read(clockProvider).now().toUtc();
    final nextOwned = owned ? s.ownedCosmetics : [...s.ownedCosmetics, cosmeticId];
    final nextState = s.copyWith(
      gold: owned ? s.gold : s.gold - item.costGold,
      ownedCosmetics: nextOwned,
      equippedOrbId: item.slot == CosmeticSlot.orb ? cosmeticId : s.equippedOrbId,
      equippedAuraId: item.slot == CosmeticSlot.aura ? cosmeticId : s.equippedAuraId,
      updatedAtUtc: nowUtc,
    );
    await _storage.saveStreakState(nextState);
    if (!ref.mounted) return true;
    unawaited(_sfx.play(RpgSfx.chest, enabled: cur.sfxEnabled));
    final updated = cur.copyWith(
      streakState: nextState,
      lastReward: _nextPopup(cur, '${item.name} Equipped'),
    );
    state = AsyncData(updated);
    unawaited(_autoSyncIfConfigured(updated));
    return true;
  }

  Future<void> addCustomReward({required String title, required int costGold}) async {
    final cur = state.value;
    if (cur == null) return;
    final nowUtc = ref.read(clockProvider).now().toUtc();
    final reward = CustomReward(
      id: ref.read(uuidProvider).v4(),
      title: title.trim(),
      costGold: math.max(10, costGold),
      updatedAtUtc: nowUtc,
    );
    final nextState = cur.streakState.copyWith(
      customRewards: [...cur.streakState.customRewards, reward],
      updatedAtUtc: nowUtc,
    );
    await _storage.saveStreakState(nextState);
    if (!ref.mounted) return;
    state = AsyncData(cur.copyWith(streakState: nextState));
  }

  Future<bool> claimCustomReward(String rewardId) async {
    final cur = state.value;
    if (cur == null) return false;
    final nowUtc = ref.read(clockProvider).now().toUtc();
    CustomReward? target;
    for (final r in cur.streakState.customRewards) {
      if (r.id == rewardId && !r.isDeleted) {
        target = r;
        break;
      }
    }
    if (target == null || cur.streakState.gold < target.costGold) return false;

    final updatedRewards = [
      for (final r in cur.streakState.customRewards)
        if (r.id == rewardId) r.copyWith(timesClaimed: r.timesClaimed + 1, updatedAtUtc: nowUtc) else r,
    ];
    final nextState = cur.streakState.copyWith(
      gold: cur.streakState.gold - target.costGold,
      customRewards: updatedRewards,
      updatedAtUtc: nowUtc,
    );
    await _storage.saveStreakState(nextState);
    if (!ref.mounted) return true;
    unawaited(_sfx.play(RpgSfx.chest, enabled: cur.sfxEnabled));
    state = AsyncData(
      cur.copyWith(
        streakState: nextState,
        lastReward: _nextPopup(cur, 'Claimed: ${target.title}'),
      ),
    );
    return true;
  }

  Future<void> collectEmberWispGold() async {
    final cur = state.value;
    if (cur == null) return;
    final nowUtc = ref.read(clockProvider).now().toUtc();
    final nextState = cur.streakState.copyWith(
      gold: cur.streakState.gold + 5,
      xp: cur.streakState.xp + 5,
      updatedAtUtc: nowUtc,
    );
    await _storage.saveStreakState(nextState);
    if (!ref.mounted) return;
    unawaited(_sfx.play(RpgSfx.chest, enabled: cur.sfxEnabled));
    state = AsyncData(
      cur.copyWith(
        streakState: nextState,
        lastReward: _nextPopup(cur, 'Ember Wisp Harvested', xp: 5, gold: 5),
      ),
    );
  }

  Future<void> updateWhyIStarted(String text) async {
    final cur = state.value;
    if (cur == null) return;
    final nowUtc = ref.read(clockProvider).now().toUtc();
    final nextState = cur.streakState.copyWith(whyIStarted: text.trim(), updatedAtUtc: nowUtc);
    await _storage.saveStreakState(nextState);
    if (!ref.mounted) return;
    state = AsyncData(cur.copyWith(streakState: nextState));
  }

  Future<void> toggleDiscreetMode() async {
    final cur = state.value;
    if (cur == null) return;
    final next = !cur.discreetMode;
    await _storage.setMeta(RecoveryNotifier._discreetMetaKey, next ? 'true' : 'false');
    await PlatformBootstrap.setDiscreetWindowTitle(next);
    if (!ref.mounted) return;
    state = AsyncData(cur.copyWith(discreetMode: next));
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    final cur = state.value;
    if (cur == null) return;
    await _storage.setMeta(RecoveryNotifier._hapticsMetaKey, enabled ? 'true' : 'false');
    if (!ref.mounted) return;
    state = AsyncData(cur.copyWith(hapticsEnabled: enabled));
  }

  Future<void> setSfxEnabled(bool enabled) async {
    final cur = state.value;
    if (cur == null) return;
    await _storage.setMeta(RecoveryNotifier._sfxMetaKey, enabled ? 'true' : 'false');
    if (!ref.mounted) return;
    state = AsyncData(cur.copyWith(sfxEnabled: enabled));
  }

  Future<bool> unlockWithPin(String pin) async {
    final ok = await _lock.verifyPin(pin);
    if (ok && state.value != null) {
      state = AsyncData(state.value!.copyWith(isLocked: false));
    }
    return ok;
  }

  Future<bool> unlockWithBiometrics() async {
    final ok = await _lock.authenticateWithBiometrics();
    if (ok && state.value != null) {
      state = AsyncData(state.value!.copyWith(isLocked: false));
    }
    return ok;
  }

  void lockNow() {
    final cur = state.value;
    if (cur == null || !cur.hasPin) return;
    state = AsyncData(cur.copyWith(isLocked: true));
  }

  Future<void> configurePin(String pin) async {
    await _lock.setPin(pin);
    if (!ref.mounted || state.value == null) return;
    state = AsyncData(state.value!.copyWith(hasPin: true, isLocked: false));
  }

  Future<void> disablePin() async {
    await _lock.clearPin();
    if (!ref.mounted || state.value == null) return;
    state = AsyncData(
      state.value!.copyWith(hasPin: false, isLocked: false, biometricsEnabled: false),
    );
  }

  Future<void> setBiometrics(bool enabled) async {
    await _lock.setBiometricsEnabled(enabled);
    if (!ref.mounted || state.value == null) return;
    state = AsyncData(state.value!.copyWith(biometricsEnabled: enabled));
  }
}
