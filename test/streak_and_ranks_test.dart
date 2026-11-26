import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:at_recovery_rpg/core/security/app_lock_service.dart';
import 'package:at_recovery_rpg/core/storage/recovery_storage.dart';
import 'package:at_recovery_rpg/features/sanctuary/application/app_providers.dart';
import 'package:at_recovery_rpg/features/sanctuary/application/recovery_controller.dart';
import 'package:at_recovery_rpg/features/sanctuary/domain/recovery_models.dart';

void main() {
  group('RankTier, CastleTier & 90-day rewiring math', () {
    test('maps every milestone & citadel threshold accurately', () {
      expect(RankTier.forDays(0), RankTier.novice);
      expect(RankTier.forDays(3), RankTier.seeker);
      expect(RankTier.forDays(7), RankTier.sentinel);
      expect(RankTier.forDays(14), RankTier.vanguard);
      expect(RankTier.forDays(30), RankTier.warden);
      expect(RankTier.forDays(60), RankTier.sovereign);
      expect(RankTier.forDays(90), RankTier.titan);

      expect(CastleTier.forDays(0), CastleTier.camp);
      expect(CastleTier.forDays(1), CastleTier.watchpost);
      expect(CastleTier.forDays(3), CastleTier.keep);
      expect(CastleTier.forDays(7), CastleTier.battlements);
      expect(CastleTier.forDays(14), CastleTier.citadel);
      expect(CastleTier.forDays(30), CastleTier.spire);
      expect(CastleTier.forDays(60), CastleTier.fortress);
      expect(CastleTier.forDays(90), CastleTier.celestial);
    });

    test('computes rewiring percentage cleanly from 0 to 100%', () {
      final start = DateTime.utc(2026, 1, 1, 0, 0, 0);
      final state = StreakState.initial(start);
      expect(state.rewiringProgress(start), 0.0);
      expect(
        state.rewiringProgress(start.add(const Duration(days: 45))),
        closeTo(0.5, 0.0001),
      );
      expect(
        state.rewiringProgress(start.add(const Duration(days: 90))),
        1.0,
      );
    });
  });

  group('RecoveryNotifier v2.0 Dark RPG Engine', () {
    test('pledge, urge victory, pomodoro, and post-mortem archive', () async {
      final now = DateTime.utc(2026, 6, 10, 12, 0, 0);
      final storage = InMemoryRecoveryStorage();
      await storage.init();
      await storage.saveStreakState(
        StreakState.initial(now.subtract(const Duration(days: 10))),
      );

      final container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(Clock.fixed(now)),
          storageProvider.overrideWithValue(storage),
          vaultProvider.overrideWithValue(InMemorySecretVault()),
        ],
      );
      addTearDown(container.dispose);

      final initial = await container.read(recoveryProvider.future);
      expect(initial.streakState.currentDays(now), 10);
      expect(initial.streakState.rankAt(now), RankTier.sentinel);
      expect(initial.streakState.castleTierAt(now), CastleTier.battlements);

      final firstPledge =
          await container.read(recoveryProvider.notifier).completeDailyPledge();
      final secondPledge =
          await container.read(recoveryProvider.notifier).completeDailyPledge();
      expect(firstPledge, isTrue);
      expect(secondPledge, isFalse);

      var after = container.read(recoveryProvider).value!;
      expect(after.streakState.xp, 25);
      expect(after.streakState.gold, 10);
      expect(after.streakState.totalCleanDays, 1);

      await container.read(recoveryProvider.notifier).recordUrgeDefeated();
      after = container.read(recoveryProvider).value!;
      expect(after.streakState.xp, 75);
      expect(after.streakState.gold, 30);

      await container.read(recoveryProvider.notifier).completePomodoroFocus();
      after = container.read(recoveryProvider).value!;
      expect(after.streakState.xp, 110);
      expect(after.streakState.level, 2);
      expect(after.streakState.gold, 45);
      expect(after.streakState.pomodoroSessionsCompleted, 1);

      await container.read(recoveryProvider.notifier).recordRelapsePostMortem(
            triggers: const ['Late Night', 'Fatigue'],
            mood: 'Drained',
            lessonNote: 'Charge phone in the hallway.',
          );

      after = container.read(recoveryProvider).value!;
      expect(after.streakState.streakHistory.length, 1);
      expect(after.streakState.streakHistory.first.days, 10);
      expect(after.streakState.currentDays(now), 0);
      expect(after.streakState.xp, 130);
    });

    test('Castle upgrades, Chronicle rewards, Skills, Armory, and Daily Chest',
        () async {
      final now = DateTime.utc(2026, 9, 1, 14, 0);
      final storage = InMemoryRecoveryStorage();
      await storage.init();
      await storage.saveStreakState(
        StreakState.initial(now.subtract(const Duration(days: 8)))
            .copyWith(xp: 220, gold: 250, prologueCompleted: true),
      );

      final container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(Clock.fixed(now)),
          storageProvider.overrideWithValue(storage),
          vaultProvider.overrideWithValue(InMemorySecretVault()),
        ],
      );
      addTearDown(container.dispose);

      await container.read(recoveryProvider.future);
      final notifier = container.read(recoveryProvider.notifier);

      // Chronicle rewards: Day 7 Gatekeeper unlocks on Day 8; Day 30 Boss stays locked
      expect(
        await notifier.claimChronicleReward(
          nodeId: 'j_ch2_boss',
          requiredDay: 7,
          xpReward: 60,
          goldReward: 45,
          isBoss: true,
        ),
        isTrue,
      );
      expect(
        await notifier.claimChronicleReward(
          nodeId: 'j_ch2_boss',
          requiredDay: 7,
          xpReward: 60,
          goldReward: 45,
          isBoss: true,
        ),
        isFalse,
      );
      expect(
        await notifier.claimChronicleReward(
          nodeId: 'j_ch4_boss',
          requiredDay: 30,
          xpReward: 120,
          goldReward: 90,
          isBoss: true,
        ),
        isFalse,
      );
      var s = container.read(recoveryProvider).value!.streakState;
      expect(s.bossKills, 1);
      expect(s.gold, 295);

      // Unlock Ember Ward skill perk & Citadel Architect
      expect(await notifier.unlockSkillPerk('citadel_architect'), isTrue);
      expect(await notifier.unlockSkillPerk('ember_ward'), isTrue);
      s = container.read(recoveryProvider).value!.streakState;
      expect(s.hasSkill('ember_ward'), isTrue);

      // Upgrade Watchtower with -15% Citadel Architect discount (base 40 -> 34 G)
      final goldBeforeBuild = s.gold;
      expect(await notifier.upgradeCastleStructure('watchtower'), isTrue);
      s = container.read(recoveryProvider).value!.streakState;
      expect(s.structureLevel('watchtower'), 1);
      expect(s.gold, goldBeforeBuild - 34);

      // Buy & equip Solar Gold Orb (50 G)
      expect(await notifier.buyOrEquipCosmetic('orb_solar_gold'), isTrue);
      s = container.read(recoveryProvider).value!.streakState;
      expect(s.equippedOrbId, 'orb_solar_gold');

      // Complete 3 quests then claim Daily Loot Chest
      for (final qid in const [
        'quest_morning_pledge',
        'quest_deep_focus',
        'quest_device_curfew',
      ]) {
        await notifier.completeQuest(qid);
      }
      expect(await notifier.claimDailyQuestChest(), isTrue);
      expect(await notifier.claimDailyQuestChest(), isFalse);

      // Roguelite Post-Mortem resets only active arc clock while preserving Citadel, Skills, and Relics
      await notifier.recordRelapsePostMortem(
        triggers: const ['Stress'],
        mood: 'Restless',
        lessonNote: 'Used breathing pause.',
      );
      s = container.read(recoveryProvider).value!.streakState;
      expect(s.currentDays(now), 0);
      expect(s.structureLevel('watchtower'), 1);
      expect(s.hasSkill('ember_ward'), isTrue);
      expect(s.equippedOrbId, 'orb_solar_gold');
      expect(s.bossKills, 1);
    });
  });
}
