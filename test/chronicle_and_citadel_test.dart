import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:at_recovery_rpg/core/engine/recovery_algorithm.dart';
import 'package:at_recovery_rpg/core/security/app_lock_service.dart';
import 'package:at_recovery_rpg/core/storage/recovery_storage.dart';
import 'package:at_recovery_rpg/features/sanctuary/application/app_providers.dart';
import 'package:at_recovery_rpg/features/sanctuary/application/recovery_controller.dart';
import 'package:at_recovery_rpg/features/sanctuary/domain/recovery_models.dart';

void main() {
  group('v1/v2 -> v3 Seamless Migration & Mirror of Truth Blueprint', () {
    test('StreakState.fromJson upgrades legacy JSON lacking v3 keys without data loss', () {
      final t1 = DateTime.utc(2026, 4, 10, 9, 0);
      final legacyJson = <String, dynamic>{
        'startTimeUtc': t1.toIso8601String(),
        'bestStreakSeconds': 86400 * 14,
        'totalCleanDays': 14,
        'xp': 320,
        'gold': 95,
        'whyIStarted': 'Legacy reason preserved.',
        'updatedAtUtc': t1.toIso8601String(),
      };

      final restored = StreakState.fromJson(legacyJson);
      expect(restored.xp, 320);
      expect(restored.gold, 95);
      expect(restored.whyIStarted, 'Legacy reason preserved.');
      expect(restored.lampbearerName, 'Warden');
      expect(restored.guidingVow, GuidingVow.clarity);
      expect(restored.prologueCompleted, isFalse);
      expect(restored.counterSpells.length, CounterSpell.defaults(t1).length);
    });

    test('RecoveryNotifier marks prologueCompleted automatically for migrating v1/v2 users', () async {
      final now = DateTime.utc(2026, 8, 5, 10, 0);
      final storage = InMemoryRecoveryStorage();
      await storage.init();
      await storage.saveStreakState(
        StreakState.initial(now.subtract(const Duration(days: 5)))
            .copyWith(xp: 120, prologueCompleted: false),
      );

      final container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(Clock.fixed(now)),
          storageProvider.overrideWithValue(storage),
          vaultProvider.overrideWithValue(InMemorySecretVault()),
        ],
      );
      addTearDown(container.dispose);

      final loaded = await container.read(recoveryProvider.future);
      expect(loaded.streakState.prologueCompleted, isTrue);
    });

    test('Chronicle moral choice, chest loot, HALT restoration & diagnostic blueprint apply cleanly', () async {
      final now = DateTime.utc(2026, 8, 5, 22, 30);
      final storage = InMemoryRecoveryStorage();
      await storage.init();
      await storage.saveStreakState(
        StreakState.initial(now.subtract(const Duration(days: 4))),
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

      final bp = PersonalRecoveryAlgorithm.buildBlueprint(
        goal: 'quit_90',
        dangerWindow: 'late_night',
        dominantTrigger: 'stress',
        urgeIntensity: 8,
        weeklyFrequency: 'daily',
        slipPattern: 'post_slip_chaser',
        guidingVow: GuidingVow.strength,
        customWhy: 'Stay sharp every morning.',
        preferredAction: 'pomodoro_sprint',
        lampbearerName: 'Kael',
        reminderHour: 21,
        sleepCutoffHour: 23,
        discreetPreferred: false,
        pinPreferred: false,
        nowUtc: now,
      );

      await notifier.applyDiagnosticBlueprint(bp);
      var s = container.read(recoveryProvider).value!.streakState;
      expect(s.prologueCompleted, isTrue);
      expect(s.lampbearerName, 'Kael');
      expect(s.guidingVow, GuidingVow.strength);
      expect(s.diagnosticProfile?.archetype, 'Nocturnal Sentinel');

      // Chronicle Act 1 choice + Act 2 Relic Chest unlock (Day 4 >= minDay 4)
      final act1 = kChronicleActs[0];
      expect(await notifier.selectChronicleChoice(actId: act1.id, choice: act1.choiceB), isTrue);
      expect(await notifier.selectChronicleChoice(actId: act1.id, choice: act1.choiceA), isFalse);

      await notifier.toggleHaltOrb('hungry');
      expect(container.read(recoveryProvider).value!.streakState.haltFlags['hungry'], isTrue);
      await notifier.completeHaltRestoration('hungry');
      s = container.read(recoveryProvider).value!.streakState;
      expect(s.haltFlags['hungry'], isFalse);
      expect(s.vitXp, greaterThanOrEqualTo(15));

      final goldBeforeWisp = s.gold;
      await notifier.collectEmberWispGold();
      s = container.read(recoveryProvider).value!.streakState;
      expect(s.gold, goldBeforeWisp + 5);
      expect(GameArtAssets.citadelForDays(0), GameArtAssets.citadelTier1);
      expect(GameArtAssets.citadelForDays(3), GameArtAssets.citadelTier2);
      expect(GameArtAssets.citadelForDays(14), GameArtAssets.citadelTier3);
      expect(GameArtAssets.citadelForDays(60), GameArtAssets.citadelTier4);
      expect(
        RecoverySnapshot(streakState: s, urgeLogs: const [], quests: const [], exportedAtUtc: now).schemaVersion,
        4,
      );
    });
  });
}
