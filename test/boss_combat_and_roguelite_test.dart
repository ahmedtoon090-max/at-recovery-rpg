import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:at_recovery_rpg/core/security/app_lock_service.dart';
import 'package:at_recovery_rpg/core/storage/recovery_storage.dart';
import 'package:at_recovery_rpg/core/theme/app_theme.dart';
import 'package:at_recovery_rpg/features/panic/presentation/panic_screen.dart';
import 'package:at_recovery_rpg/features/sanctuary/application/app_providers.dart';
import 'package:at_recovery_rpg/features/sanctuary/application/recovery_controller.dart';
import 'package:at_recovery_rpg/features/sanctuary/domain/recovery_models.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Boss Combat State Machine & Roguelite Anti-Wipe Invariant', () {
    testWidgets('Mirage Ambush supports ACT Defusion, Breath-Wave & Counter-Spell CRIT leveling',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final now = DateTime.utc(2026, 8, 2, 23, 0);
      final storage = InMemoryRecoveryStorage();
      await storage.init();
      await storage.saveStreakState(
        StreakState.initial(now.subtract(const Duration(days: 5))).copyWith(
          prologueCompleted: true,
        ),
      );

      final container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(Clock.fixed(now)),
          storageProvider.overrideWithValue(storage),
          vaultProvider.overrideWithValue(InMemorySecretVault()),
          liveClockStreamProvider.overrideWith((ref) => Stream.value(now)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildObsidianTheme(),
            builder: (_, child) => MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: child!,
            ),
            home: const PanicScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Attack 1: Name the Illusion (-20 HP)
      await tester.ensureVisible(find.text('Name the Illusion (-20 HP)'));
      await tester.tap(find.text('Name the Illusion (-20 HP)'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('80 / 100 HP'), findsOneWidget);

      // Attack 2: Breath Strike (-25 HP)
      await tester.ensureVisible(find.text('Channel Breath Strike (-25 HP)'));
      await tester.tap(find.text('Channel Breath Strike (-25 HP)'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('55 / 100 HP'), findsOneWidget);

      // Attack 3: Cast Counter-Spell CRIT (-50 HP) + second cast finishes boss
      final firstSpell = find.textContaining('Cast Rank I:').first;
      await tester.ensureVisible(firstSpell);
      await tester.tap(firstSpell);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('5 / 100 HP'), findsOneWidget);

      await tester.tap(find.textContaining('Cast Rank I:').first);
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('0 / 100 HP'), findsOneWidget);

      await tester.ensureVisible(find.text('Claim Victory Loot (+75 XP / +40 Gold)'));
      await tester.tap(find.text('Claim Victory Loot (+75 XP / +40 Gold)'));
      await tester.pump(const Duration(milliseconds: 250));

      final after = container.read(recoveryProvider).value!.streakState;
      expect(after.bossKills, 1);
      expect(after.counterSpells.first.casts, 2);
      expect(after.counterSpells.first.rank, 2);
    });

    test('Roguelite Anti-Wipe Pact never erases Citadel, Chronicle, Spells, Stats or Foil Relics on slip',
        () async {
      final now = DateTime.utc(2026, 8, 20, 12, 0);
      final storage = InMemoryRecoveryStorage();
      await storage.init();
      await storage.saveStreakState(
        StreakState.initial(now.subtract(const Duration(days: 15))).copyWith(
          xp: 500,
          gold: 180,
          wilXp: 140,
          focXp: 90,
          vitXp: 110,
          wisXp: 40,
          bossKills: 4,
          prologueCompleted: true,
          castleStructures: const {'watchtower': 2, 'golden_gate': 1},
          chronicleChoices: const {'act_1_ember_wastes': 'share_ember'},
          unlockedSkills: const ['iron_shield', 'ember_ward'],
          milestoneUnlocks: const {'trophy_7d': '2026-08-12T00:00:00.000Z'},
          counterSpells: [
            CounterSpell(
              id: 'sp-rank5',
              triggerCue: 'Triggered late',
              actionPlan: '20 pushups',
              casts: 8,
              rank: 5,
              updatedAtUtc: now,
            ),
          ],
        ),
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
      await container.read(recoveryProvider.notifier).recordRelapsePostMortem(
            triggers: const ['Hungry', 'Tired'],
            mood: 'Drained',
            lessonNote: 'Eat dinner on time and dock phone outside.',
          );

      final s = container.read(recoveryProvider).value!.streakState;
      expect(s.currentDays(now), 0); // Active arc timer restarted cleanly
      expect(s.wisXp, 60); // +20 WIS XP awarded
      expect(s.xp, 520);
      expect(s.gold, 180);
      expect(s.bossKills, 4);
      expect(s.structureLevel('watchtower'), 2);
      expect(s.structureLevel('golden_gate'), 1);
      expect(s.chronicleChoices['act_1_ember_wastes'], 'share_ember');
      expect(s.unlockedSkills, containsAll(['iron_shield', 'ember_ward']));
      expect(s.milestoneUnlocks.containsKey('trophy_7d'), isTrue);
      expect(s.counterSpells.first.rank, 5);
    });
  });
}
