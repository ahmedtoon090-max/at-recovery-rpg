import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:at_recovery_rpg/core/security/app_lock_service.dart';
import 'package:at_recovery_rpg/core/security/crypto_service.dart';
import 'package:at_recovery_rpg/core/storage/recovery_storage.dart';
import 'package:at_recovery_rpg/features/sanctuary/domain/recovery_models.dart';
import 'package:at_recovery_rpg/features/sync_profile/application/sync_coordinator.dart';
import 'package:at_recovery_rpg/features/sync_profile/data/github_gist_sync.dart';
import 'package:at_recovery_rpg/features/sync_profile/data/supabase_sync.dart';
import 'package:at_recovery_rpg/features/sync_profile/domain/sync_engine.dart';
import 'package:http/http.dart' as http;

void main() {
  group('CryptoService AES-256-GCM + PBKDF2', () {
    final crypto = CryptoService(iterations: 1000);

    test('round-trip encrypts and decrypts cleanly', () async {
      const secret = 'Sanctuary secret payload with unicode: Emerald 90d';
      const pass = 'correct-horse-battery-staple';

      final env1 = await crypto.encryptString(secret, pass);
      final env2 = await crypto.encryptString(secret, pass);
      expect(env1, isNot(equals(env2)));

      final decoded1 = jsonDecode(env1) as Map<String, dynamic>;
      expect(decoded1['v'], 1);
      expect(decoded1['alg'], 'PBKDF2-HMAC-SHA256+AES-256-GCM');

      final decrypted = await crypto.decryptString(env1, pass);
      expect(decrypted, secret);
    });

    test('rejects wrong passphrase', () async {
      final cipher = await crypto.encryptString('private data', 'pass-one');
      await expectLater(
        () => crypto.decryptString(cipher, 'wrong-pass'),
        throwsA(isA<CryptoException>()),
      );
    });

    test('verifies salted SHA-256 PIN hashes', () {
      final salt = crypto.generateSaltHex();
      final hash = crypto.hashPin('4829', salt);
      expect(crypto.verifyPin('4829', salt, hash), isTrue);
      expect(crypto.verifyPin('0000', salt, hash), isFalse);
    });
  });

  group('SyncEngine deterministic multi-device merge', () {
    test('merges concurrent v2 RPG edits from Android and Windows cleanly', () {
      final t1 = DateTime.utc(2026, 5, 1, 10, 0);
      final t2 = DateTime.utc(2026, 5, 2, 14, 0);
      final t3 = DateTime.utc(2026, 5, 3, 21, 0);

      final local = RecoverySnapshot(
        streakState: StreakState.initial(t1).copyWith(
          xp: 180,
          gold: 45,
          bossKills: 2,
          wilXp: 80,
          castleStructures: const {'watchtower': 2},
          unlockedSkills: const ['iron_shield'],
          ownedCosmetics: const ['orb_obsidian_emerald', 'aura_ember', 'orb_solar_gold'],
          pledgeDates: const ['2026-05-01', '2026-05-02'],
          updatedAtUtc: t2,
        ),
        urgeLogs: [
          UrgeLog(
            id: 'log-android-1',
            timestampUtc: t2,
            type: UrgeLogType.urgeDefeated,
            intensity: 7,
            triggers: const ['Stress'],
            mood: 'Restless',
            note: 'Slayed Boss on Android',
            updatedAtUtc: t2,
          ),
          UrgeLog(
            id: 'log-shared',
            timestampUtc: t1,
            type: UrgeLogType.checkIn,
            intensity: 2,
            triggers: const ['Daily Pledge'],
            mood: 'Calm',
            note: 'Old note',
            updatedAtUtc: t1,
          ),
        ],
        quests: QuestItem.defaultQuests(t1),
        exportedAtUtc: t2,
      );

      final remote = RecoverySnapshot(
        streakState: StreakState.initial(t1).copyWith(
          xp: 140,
          gold: 90,
          bossKills: 3,
          focXp: 65,
          castleStructures: const {'arcane_forge': 1, 'watchtower': 1},
          claimedJourneyNodes: const ['j_ch1_start'],
          unlockedSkills: const ['golden_forge'],
          pledgeDates: const ['2026-05-03'],
          whyIStarted: 'Updated on Windows Desktop',
          updatedAtUtc: t3,
        ),
        urgeLogs: [
          UrgeLog(
            id: 'log-windows-1',
            timestampUtc: t3,
            type: UrgeLogType.urgeDefeated,
            intensity: 8,
            triggers: const ['Late Night'],
            mood: 'Tired',
            note: 'Completed Breath-Wave on Desktop',
            updatedAtUtc: t3,
          ),
          UrgeLog(
            id: 'log-shared',
            timestampUtc: t1,
            type: UrgeLogType.checkIn,
            intensity: 2,
            triggers: const ['Daily Pledge'],
            mood: 'Calm',
            note: 'Soft-deleted on Windows',
            updatedAtUtc: t3,
            isDeleted: true,
          ),
        ],
        quests: QuestItem.defaultQuests(t1),
        exportedAtUtc: t3,
      );

      final merged = SyncEngine.mergeSnapshots(local, remote);

      expect(merged.urgeLogs.length, 3);
      expect(merged.urgeLogs.firstWhere((e) => e.id == 'log-shared').isDeleted, isTrue);
      expect(merged.streakState.xp, 180);
      expect(merged.streakState.gold, 90);
      expect(merged.streakState.bossKills, 3);
      expect(merged.streakState.wilXp, 80);
      expect(merged.streakState.focXp, 65);
      expect(merged.streakState.castleStructures['watchtower'], 2);
      expect(merged.streakState.castleStructures['arcane_forge'], 1);
      expect(merged.streakState.unlockedSkills, containsAll(['iron_shield', 'golden_forge']));
      expect(merged.streakState.claimedJourneyNodes, contains('j_ch1_start'));
      expect(merged.streakState.pledgeDates, ['2026-05-01', '2026-05-02', '2026-05-03']);
      expect(merged.streakState.whyIStarted, 'Updated on Windows Desktop');
    });

    test('merges concurrent v3 Chronicle choices, CounterSpells, and Pomodoro dates', () {
      final t1 = DateTime.utc(2026, 8, 1, 10, 0);
      final t2 = DateTime.utc(2026, 8, 2, 12, 0);
      final t3 = DateTime.utc(2026, 8, 3, 22, 0);

      final devA = RecoverySnapshot(
        streakState: StreakState.initial(t1).copyWith(
          chronicleChoices: const {'act_1_ember_wastes': 'share_ember'},
          counterSpells: [
            CounterSpell(
              id: 'sp-1',
              triggerCue: 'Alone late',
              actionPlan: '20 pushups',
              casts: 4,
              rank: 3,
              updatedAtUtc: t2,
            ),
          ],
          pomodoroDates: const {'2026-08-01': 2, '2026-08-02': 1},
          haltFlags: const {'hungry': true},
          prologueCompleted: true,
          updatedAtUtc: t2,
        ),
        urgeLogs: const [],
        quests: QuestItem.defaultQuests(t1),
        exportedAtUtc: t2,
      );

      final devB = RecoverySnapshot(
        streakState: StreakState.initial(t1).copyWith(
          chronicleChoices: const {'act_2_whispering_woods': 'log_lure'},
          counterSpells: [
            CounterSpell(
              id: 'sp-1',
              triggerCue: 'Alone late',
              actionPlan: '20 pushups + cold water',
              casts: 2,
              rank: 2,
              updatedAtUtc: t3,
            ),
            CounterSpell(
              id: 'sp-2',
              triggerCue: 'Stressed',
              actionPlan: 'Physiological sighs',
              casts: 1,
              rank: 1,
              updatedAtUtc: t3,
            ),
          ],
          pomodoroDates: const {'2026-08-02': 3},
          haltFlags: const {'tired': true},
          updatedAtUtc: t3,
        ),
        urgeLogs: const [],
        quests: QuestItem.defaultQuests(t1),
        exportedAtUtc: t3,
      );

      final merged = SyncEngine.mergeSnapshots(devA, devB);
      expect(merged.schemaVersion, greaterThanOrEqualTo(3));
      expect(merged.streakState.prologueCompleted, isTrue);
      expect(merged.streakState.chronicleChoices['act_1_ember_wastes'], 'share_ember');
      expect(merged.streakState.chronicleChoices['act_2_whispering_woods'], 'log_lure');
      expect(merged.streakState.pomodoroDates['2026-08-01'], 2);
      expect(merged.streakState.pomodoroDates['2026-08-02'], 3);

      final sp1 = merged.streakState.counterSpells.firstWhere((c) => c.id == 'sp-1');
      expect(sp1.actionPlan, '20 pushups + cold water');
      expect(sp1.casts, 4);
      expect(sp1.rank, 3);
      expect(merged.streakState.counterSpells.any((c) => c.id == 'sp-2'), isTrue);
    });
  });

  group('QR Device Pairing Encrypted Payload', () {
    test('round-trips GitHub PAT + Gist ID safely under passphrase', () async {
      final vaultA = InMemorySecretVault();
      final vaultB = InMemorySecretVault();
      final storage = InMemoryRecoveryStorage();
      await storage.init();
      final crypto = CryptoService(iterations: 200);

      await vaultA.write(SecretKeys.githubPat, 'pat_test_sync_token_1234');
      await vaultA.write(SecretKeys.githubGistId, 'gist_abc_999');
      await vaultA.write(SecretKeys.syncPassphrase, 'my-strong-passphrase');

      final coordA = SyncCoordinator(
        vault: vaultA,
        storage: storage,
        crypto: crypto,
        gistClient: GithubGistSyncClient(httpClient: http.Client(), crypto: crypto),
        supabaseAdapter: SupabaseSyncAdapter(),
      );
      final coordB = SyncCoordinator(
        vault: vaultB,
        storage: storage,
        crypto: crypto,
        gistClient: GithubGistSyncClient(httpClient: http.Client(), crypto: crypto),
        supabaseAdapter: SupabaseSyncAdapter(),
      );

      final qrPayload = await coordA.createDevicePairingPayload();
      expect(qrPayload.startsWith('ATP_PAIR_V2:'), isTrue);

      await coordB.applyDevicePairingPayload(qrPayload, 'my-strong-passphrase');
      expect(await vaultB.read(SecretKeys.githubPat), 'pat_test_sync_token_1234');
      expect(await vaultB.read(SecretKeys.githubGistId), 'gist_abc_999');

      await expectLater(
        () => coordB.applyDevicePairingPayload(qrPayload, 'wrong-pass'),
        throwsA(isA<CryptoException>()),
      );
    });
  });
}
