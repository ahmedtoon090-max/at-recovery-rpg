import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:at_recovery_rpg/app.dart';
import 'package:at_recovery_rpg/core/security/app_lock_service.dart';
import 'package:at_recovery_rpg/core/storage/recovery_storage.dart';
import 'package:at_recovery_rpg/core/theme/app_theme.dart';
import 'package:at_recovery_rpg/features/analytics/presentation/analytics_screen.dart';
import 'package:at_recovery_rpg/features/hero/presentation/hero_screen.dart';
import 'package:at_recovery_rpg/features/journal/presentation/journal_screen.dart';
import 'package:at_recovery_rpg/features/journey/presentation/journey_screen.dart';
import 'package:at_recovery_rpg/features/onboarding/presentation/onboarding_diagnostic_screen.dart';
import 'package:at_recovery_rpg/features/panic/presentation/panic_screen.dart';
import 'package:at_recovery_rpg/features/quests/presentation/pomodoro_discreet_screen.dart';
import 'package:at_recovery_rpg/features/quests/presentation/quests_screen.dart';
import 'package:at_recovery_rpg/features/sanctuary/application/app_providers.dart';
import 'package:at_recovery_rpg/features/sanctuary/domain/recovery_models.dart';
import 'package:at_recovery_rpg/features/sanctuary/presentation/sanctuary_screen.dart';
import 'package:at_recovery_rpg/features/sync_profile/presentation/profile_sync_screen.dart';

Future<ProviderScope> _buildScopedApp({
  required Widget child,
  double textScale = 1.0,
}) async {
  final fixedNow = DateTime.utc(2026, 7, 15, 18, 30);
  final storage = InMemoryRecoveryStorage();
  await storage.init();
  await storage.saveStreakState(
    StreakState.initial(fixedNow.subtract(const Duration(days: 14, hours: 6)))
        .copyWith(
      xp: 420,
      gold: 135,
      bossKills: 2,
      wilXp: 110,
      focXp: 70,
      vitXp: 90,
      wisXp: 45,
      pledgeDates: const ['2026-07-13', '2026-07-14', '2026-07-15'],
    ),
  );
  await storage.saveUrgeLog(
    UrgeLog(
      id: 'sample-log-1',
      timestampUtc: fixedNow.subtract(const Duration(hours: 2)),
      type: UrgeLogType.urgeDefeated,
      intensity: 7,
      triggers: const ['Stress', 'Late Night'],
      mood: 'Restless',
      note: 'Slayed urge boss cleanly.',
      updatedAtUtc: fixedNow,
    ),
  );

  return ProviderScope(
    overrides: [
      clockProvider.overrideWithValue(Clock.fixed(fixedNow)),
      storageProvider.overrideWithValue(storage),
      vaultProvider.overrideWithValue(InMemorySecretVault()),
      liveClockStreamProvider.overrideWith((ref) => Stream.value(fixedNow)),
    ],
    child: MaterialApp(
      theme: buildObsidianTheme(),
      builder: (context, appChild) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: appChild ?? const SizedBox.shrink(),
      ),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final screens = <({String name, Widget widget})>[
    (name: 'OnboardingDiagnosticScreen', widget: const OnboardingDiagnosticScreen()),
    (name: 'SanctuaryScreen', widget: const SanctuaryScreen()),
    (name: 'JourneyScreen', widget: const JourneyScreen()),
    (name: 'HeroScreen', widget: const HeroScreen()),
    (name: 'PanicScreen', widget: const PanicScreen()),
    (name: 'QuestsScreen', widget: const QuestsScreen()),
    (name: 'JournalScreen', widget: const JournalScreen()),
    (name: 'AnalyticsScreen', widget: const AnalyticsScreen()),
    (name: 'ProfileSyncScreen', widget: const ProfileSyncScreen()),
    (name: 'PomodoroDiscreetScreen', widget: const PomodoroDiscreetScreen()),
  ];

  group('Zero-overflow responsive smoke tests', () {
    for (final entry in screens) {
      testWidgets('${entry.name} renders cleanly on Mobile (390x844 @ 1.15x)',
          (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final scoped = await _buildScopedApp(
          child: entry.widget,
          textScale: 1.15,
        );
        await tester.pumpWidget(scoped);
        await tester.pump(const Duration(milliseconds: 350));
        expect(tester.takeException(), isNull);
      });

      testWidgets('${entry.name} renders cleanly on Desktop (1280x800)',
          (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final scoped = await _buildScopedApp(child: entry.widget);
        await tester.pumpWidget(scoped);
        await tester.pump(const Duration(milliseconds: 350));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('Hero sub-tabs (Armory & 3D Vault) render cleanly on 390x844',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final scoped = await _buildScopedApp(
        child: const HeroScreen(),
        textScale: 1.15,
      );
      await tester.pumpWidget(scoped);
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Armory Shop'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('ORB SHADERS'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('3D Vault'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('First Spark'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Full router shell + Chronicle tab + Codex Analytics & Discreet Mask work on 390x844',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fixedNow = DateTime.utc(2026, 7, 15, 18, 30);
      final storage = InMemoryRecoveryStorage();
      await storage.init();
      await storage.saveStreakState(
        StreakState.initial(fixedNow).copyWith(prologueCompleted: true),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clockProvider.overrideWithValue(Clock.fixed(fixedNow)),
            storageProvider.overrideWithValue(storage),
            vaultProvider.overrideWithValue(InMemorySecretVault()),
            liveClockStreamProvider.overrideWith((ref) => Stream.value(fixedNow)),
          ],
          child: const AtRecoveryRpgApp(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Mirage Ambush'), findsOneWidget);
      expect(find.text('Mask'), findsOneWidget);

      await tester.tap(find.text('Journey'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('The Eclipse Chronicle'), findsOneWidget);

      await tester.tap(find.text('Stats'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Stats & Sovereign Codex'), findsOneWidget);
      expect(find.text('LIVE RISK FORECAST'), findsOneWidget);
      await tester.tap(find.text('Journal Logs'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('No journal entries yet'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('World'));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(find.text('HALT Orbs'));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Campfire HALT Vitality'), findsOneWidget);
      Navigator.of(tester.element(find.text('Campfire HALT Vitality'))).pop();
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(find.text('Mask'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('ATP Pomodoro'), findsOneWidget);
      expect(find.text('DEEP FOCUS'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
