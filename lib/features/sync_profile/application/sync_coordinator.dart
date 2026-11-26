import 'dart:convert';

import '../../../core/security/app_lock_service.dart';
import '../../../core/security/crypto_service.dart';
import '../../../core/storage/recovery_storage.dart';
import '../../sanctuary/domain/recovery_models.dart';
import '../data/github_gist_sync.dart';
import '../data/supabase_sync.dart';
import '../domain/sync_engine.dart';

class SyncRunResult {
  const SyncRunResult({
    required this.snapshot,
    required this.syncedChannels,
    this.errorMessage,
  });

  final RecoverySnapshot snapshot;
  final List<String> syncedChannels;
  final String? errorMessage;
}

/// Orchestrates encrypted GitHub Gist sync, 1-tap QR pairing payloads,
/// optional Supabase sync, and encrypted .atp backup export/import.
class SyncCoordinator {
  const SyncCoordinator({
    required this._vault,
    required this._storage,
    required this._crypto,
    required this._gistClient,
    required this._supabaseAdapter,
  });

  final SecretVault _vault;
  final RecoveryStorage _storage;
  final CryptoService _crypto;
  final GithubGistSyncClient _gistClient;
  final SupabaseSyncAdapter _supabaseAdapter;

  Future<bool> hasAnySyncConfigured() async {
    final pat = await _vault.read(SecretKeys.githubPat);
    final pass = await _vault.read(SecretKeys.syncPassphrase);
    final supaUrl = await _vault.read(SecretKeys.supabaseUrl);
    final supaKey = await _vault.read(SecretKeys.supabaseAnonKey);
    final gistReady = (pat ?? '').isNotEmpty && (pass ?? '').isNotEmpty;
    final supaReady = (supaUrl ?? '').isNotEmpty && (supaKey ?? '').isNotEmpty;
    return gistReady || supaReady;
  }

  Future<SyncRunResult> syncAll(RecoverySnapshot local) async {
    var current = local;
    final channels = <String>[];
    final errors = <String>[];

    final pat = await _vault.read(SecretKeys.githubPat);
    final pass = await _vault.read(SecretKeys.syncPassphrase);
    if ((pat ?? '').isNotEmpty && (pass ?? '').isNotEmpty) {
      try {
        final gistId = await _vault.read(SecretKeys.githubGistId);
        final result = await _gistClient.sync(
          pat: pat!,
          passphrase: pass!,
          localSnapshot: current,
          existingGistId: gistId,
        );
        current = result.snapshot;
        if (result.gistId.isNotEmpty) {
          await _vault.write(SecretKeys.githubGistId, result.gistId);
        }
        channels.add('GitHub Gist');
      } catch (e) {
        errors.add('Gist: $e');
      }
    }

    final supaUrl = await _vault.read(SecretKeys.supabaseUrl);
    final supaKey = await _vault.read(SecretKeys.supabaseAnonKey);
    if ((supaUrl ?? '').isNotEmpty && (supaKey ?? '').isNotEmpty) {
      try {
        await _supabaseAdapter.configure(url: supaUrl!, anonKey: supaKey!);
        if (_supabaseAdapter.currentUser != null) {
          current = await _supabaseAdapter.syncSnapshot(current);
          channels.add('Supabase');
        }
      } catch (e) {
        errors.add('Supabase: $e');
      }
    }

    return SyncRunResult(
      snapshot: current,
      syncedChannels: channels,
      errorMessage: errors.isEmpty ? null : errors.join(' | '),
    );
  }

  /// Generates an encrypted pairing envelope protected by [passphrase]
  /// containing the GitHub PAT and Gist ID for 10-second QR/code device linking.
  Future<String> createDevicePairingPayload() async {
    final pat = await _vault.read(SecretKeys.githubPat) ?? '';
    final pass = await _vault.read(SecretKeys.syncPassphrase) ?? '';
    final gistId = await _vault.read(SecretKeys.githubGistId) ?? '';
    if (pat.isEmpty || pass.isEmpty) {
      throw const FormatException(
        'Save a GitHub PAT and Sync Passphrase before pairing.',
      );
    }
    final inner = jsonEncode({'pat': pat, 'gistId': gistId});
    final encrypted = await _crypto.encryptString(inner, pass);
    return 'ATP_PAIR_V2:${base64UrlEncode(utf8.encode(encrypted))}';
  }

  /// Decrypts a scanned/pasted QR pairing token using [passphrase] and
  /// configures GitHub Gist sync on this device automatically.
  Future<void> applyDevicePairingPayload(
    String rawPayload,
    String passphrase,
  ) async {
    final trimmed = rawPayload.trim();
    if (!trimmed.startsWith('ATP_PAIR_V2:')) {
      throw const FormatException('Invalid ATP Pomodoro pairing payload.');
    }
    final encoded = trimmed.substring('ATP_PAIR_V2:'.length);
    final envelopeJson = utf8.decode(base64Url.decode(encoded));
    final plain = await _crypto.decryptString(envelopeJson, passphrase.trim());
    final map = jsonDecode(plain) as Map<String, dynamic>;
    final pat = (map['pat'] as String? ?? '').trim();
    final gistId = (map['gistId'] as String? ?? '').trim();
    if (pat.isEmpty) {
      throw const FormatException('Pairing payload does not contain a valid token.');
    }
    await _vault.write(SecretKeys.githubPat, pat);
    await _vault.write(SecretKeys.syncPassphrase, passphrase.trim());
    if (gistId.isNotEmpty) {
      await _vault.write(SecretKeys.githubGistId, gistId);
    }
  }

  Future<String> exportEncryptedBackup(
    RecoverySnapshot snapshot,
    String passphrase,
  ) {
    return _crypto.encryptString(jsonEncode(snapshot.toJson()), passphrase);
  }

  Future<RecoverySnapshot> importEncryptedBackup(
    String payload,
    String passphrase,
    RecoverySnapshot local,
  ) async {
    final plain = await _crypto.decryptString(payload, passphrase);
    final imported = RecoverySnapshot.fromJson(
      jsonDecode(plain) as Map<String, dynamic>,
    );
    return SyncEngine.mergeSnapshots(local, imported);
  }

  Future<void> persistSnapshot(RecoverySnapshot snapshot) async {
    await _storage.saveStreakState(snapshot.streakState);
    await _storage.replaceAllUrgeLogs(snapshot.urgeLogs);
    await _storage.replaceAllQuests(snapshot.quests);
  }
}
