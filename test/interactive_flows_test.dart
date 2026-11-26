import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:at_recovery_rpg/app.dart';
import 'package:at_recovery_rpg/core/security/app_lock_service.dart';
import 'package:at_recovery_rpg/core/security/crypto_service.dart';
import 'package:at_recovery_rpg/core/storage/recovery_storage.dart';
import 'package:at_recovery_rpg/core/theme/app_theme.dart';
import 'package:at_recovery_rpg/features/panic/presentation/panic_screen.dart';
import 'package:at_recovery_rpg/features/sanctuary/application/app_providers.dart';
import 'package:at_recovery_rpg/features/sanctuary/application/recovery_controller.dart';
import 'package:at_recovery_rpg/features/sanctuary/domain/recovery_models.dart';
import 'package:at_recovery_rpg/features/sanctuary/presentation/sanctuary_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Sanctuary renders cleanly at narrow 360x800 and wide 1440x900',
      (tester) async {
    final fixedNow = DateTime.utc(2026, 8, 1, 9, 0);
    for (final size in const [Size(360, 800), Size(1440, 900)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

      final storage = InMemoryRecoveryStorage();
      await storage.init();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clockProvider.overrideWithValue(Clock.fixed(fixedNow)),
            storageProvider.overrideWithValue(storage),
            vaultProvider.overrideWithValue(InMemorySecretVault()),
            liveClockStreamProvider.overrideWith((ref) => Stream.value(fixedNow)),
          ],
          child: MaterialApp(
            theme: buildObsidianTheme(),
            home: const Scaffold(body: SanctuaryScreen()),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));
      expect(tester.takeException(), isNull);
    }

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('PIN lock blocks app, rejects wrong PIN, and unlocks on match',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fixedNow = DateTime.utc(2026, 8, 1, 9, 0);
    final storage = InMemoryRecoveryStorage();
    await storage.init();
    await storage.saveStreakState(
      StreakState.initial(fixedNow).copyWith(prologueCompleted: true),
    );
    final vault = InMemorySecretVault();
    final crypto = CryptoService(iterations: 100);
    final lock = AppLockService(vault: vault, crypto: crypto);
    await lock.setPin('1357');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clockProvider.overrideWithValue(Clock.fixed(fixedNow)),
          storageProvider.overrideWithValue(storage),
          vaultProvider.overrideWithValue(vault),
          cryptoServiceProvider.overrideWithValue(crypto),
          liveClockStreamProvider.overrideWith((ref) => Stream.value(fixedNow)),
        ],
        child: const AtRecoveryRpgApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('ATP Pomodoro Locked'), findsOneWidget);

    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('9'));
      await tester.pump(const Duration(milliseconds: 20));
    }
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Incorrect PIN. Try again.'), findsOneWidget);

    for (final digit in const ['1', '3', '5', '7']) {
      await tester.tap(find.text(digit));
      await tester.pump(const Duration(milliseconds: 20));
    }
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('ATP Pomodoro Locked'), findsNothing);
    expect(find.text('Mirage Ambush'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Urge Boss Battle drops boss from 100 to 0 HP and awards Boss Loot',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fixedNow = DateTime.utc(2026, 8, 1, 23, 0);
    final storage = InMemoryRecoveryStorage();
    await storage.init();
    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(Clock.fixed(fixedNow)),
        storageProvider.overrideWithValue(storage),
        vaultProvider.overrideWithValue(InMemorySecretVault()),
        liveClockStreamProvider.overrideWith((ref) => Stream.value(fixedNow)),
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
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('100 / 100 HP'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Shuffle challenge'));
    await tester.tap(find.byTooltip('Shuffle challenge'));
    await tester.pump(const Duration(milliseconds: 50));

    // Breath Strike 1 (-25 HP) & Breath Strike 2 (-25 HP)
    await tester.ensureVisible(find.text('Channel Breath Strike (-25 HP)'));
    await tester.tap(find.text('Channel Breath Strike (-25 HP)'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('75 / 100 HP'), findsOneWidget);

    await tester.ensureVisible(find.text('Channel Breath Strike (-25 HP)'));
    await tester.tap(find.text('Channel Breath Strike (-25 HP)'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('50 / 100 HP'), findsOneWidget);

    // Physical Critical Strike (-50 HP) -> Boss at 0 HP
    await tester.ensureVisible(find.text('Land CRIT (-50 HP)'));
    await tester.tap(find.text('Land CRIT (-50 HP)'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('0 / 100 HP'), findsOneWidget);

    await tester.ensureVisible(find.text('Claim Victory Loot (+75 XP / +40 Gold)'));
    await tester.tap(find.text('Claim Victory Loot (+75 XP / +40 Gold)'));
    await tester.pump(const Duration(milliseconds: 350));

    final state = container.read(recoveryProvider).value!;
    expect(state.streakState.xp, 75);
    expect(state.streakState.gold, 40);
    expect(state.streakState.bossKills, 1);
    expect(state.urgeLogs.length, 1);
  });
}
