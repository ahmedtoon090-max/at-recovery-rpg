import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/platform/platform_bootstrap.dart';
import '../../../../core/security/app_lock_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/glass_card.dart';
import '../../sanctuary/application/app_providers.dart';
import '../../sanctuary/application/recovery_controller.dart';
import 'device_pairing_dialog.dart';

/// Encrypted GitHub Private Gist + 1-Tap QR Pairing, Optional Supabase Cloud
/// Sync ($0 free tier), and Zero-Cloud Encrypted .atp Backup controls.
class SyncIntegrationsCards extends ConsumerStatefulWidget {
  const SyncIntegrationsCards({super.key});

  @override
  ConsumerState<SyncIntegrationsCards> createState() =>
      _SyncIntegrationsCardsState();
}

class _SyncIntegrationsCardsState extends ConsumerState<SyncIntegrationsCards> {
  final _patCtrl = TextEditingController();
  final _passphraseCtrl = TextEditingController();
  final _supaUrlCtrl = TextEditingController();
  final _supaKeyCtrl = TextEditingController();
  final _supaEmailCtrl = TextEditingController();
  final _supaPassCtrl = TextEditingController();

  bool _loaded = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadSecrets();
  }

  Future<void> _loadSecrets() async {
    final vault = ref.read(vaultProvider);
    _patCtrl.text = await vault.read(SecretKeys.githubPat) ?? '';
    _passphraseCtrl.text = await vault.read(SecretKeys.syncPassphrase) ?? '';
    _supaUrlCtrl.text = await vault.read(SecretKeys.supabaseUrl) ?? '';
    _supaKeyCtrl.text = await vault.read(SecretKeys.supabaseAnonKey) ?? '';
    if (mounted) setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _patCtrl.dispose();
    _passphraseCtrl.dispose();
    _supaUrlCtrl.dispose();
    _supaKeyCtrl.dispose();
    _supaEmailCtrl.dispose();
    _supaPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveGistAndSync() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final vault = ref.read(vaultProvider);
    await vault.write(SecretKeys.githubPat, _patCtrl.text.trim());
    await vault.write(SecretKeys.syncPassphrase, _passphraseCtrl.text.trim());
    await ref.read(recoveryProvider.notifier).syncNow();
    if (!mounted) return;
    setState(() => _busy = false);
    final note = ref.read(recoveryProvider).value?.syncNote ?? 'Sync completed.';
    messenger.clearSnackBars();
    messenger.showSnackBar(SnackBar(content: Text(note)));
  }

  Future<void> _saveSupabaseAndSync() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final vault = ref.read(vaultProvider);
    final url = _supaUrlCtrl.text.trim();
    final key = _supaKeyCtrl.text.trim();
    await vault.write(SecretKeys.supabaseUrl, url);
    await vault.write(SecretKeys.supabaseAnonKey, key);

    String message;
    try {
      final adapter = ref.read(supabaseAdapterProvider);
      await adapter.configure(url: url, anonKey: key);
      if (_supaEmailCtrl.text.trim().isNotEmpty &&
          _supaPassCtrl.text.isNotEmpty) {
        await adapter.signInOrSignUp(
          email: _supaEmailCtrl.text.trim(),
          password: _supaPassCtrl.text,
        );
      }
      await ref.read(recoveryProvider.notifier).syncNow();
      message = ref.read(recoveryProvider).value?.syncNote ??
          'Supabase connection verified and synced.';
    } catch (e) {
      message = 'Supabase error: $e';
    }

    if (!mounted) return;
    setState(() => _busy = false);
    messenger.clearSnackBars();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _exportBackup() async {
    final passCtrl = TextEditingController(text: _passphraseCtrl.text);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export Encrypted .atp Backup'),
        content: TextField(
          controller: passCtrl,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Backup Passphrase',
            hintText: 'Minimum 6 characters recommended',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Export .atp'),
          ),
        ],
      ),
    );

    if (ok == true && passCtrl.text.trim().isNotEmpty && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      final cipher = await ref
          .read(recoveryProvider.notifier)
          .exportEncryptedBackup(passCtrl.text.trim());
      await Clipboard.setData(ClipboardData(text: cipher));
      final savedPath = await PlatformBootstrap.saveEncryptedAtpFile(
        cipher,
        'atp_recovery_backup.atp',
      );
      if (!mounted) return;
      final note = savedPath != null
          ? 'Saved .atp backup to $savedPath and copied to clipboard.'
          : 'AES-256-GCM .atp backup copied to clipboard.';
      messenger.showSnackBar(SnackBar(content: Text(note)));
    }
    passCtrl.dispose();
  }

  Future<void> _importBackup() async {
    final payloadCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: _passphraseCtrl.text);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Encrypted .atp Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: payloadCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Encrypted .atp Payload / JSON',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Backup Passphrase'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Decrypt & Merge'),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      try {
        await ref.read(recoveryProvider.notifier).importEncryptedBackup(
              payloadCtrl.text.trim(),
              passCtrl.text.trim(),
            );
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Backup decrypted and merged cleanly.')),
        );
      } catch (e) {
        if (!mounted) return;
        messenger.showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    }
    payloadCtrl.dispose();
    passCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final appState = ref.watch(recoveryProvider).value;

    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ObsidianCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Encrypted GitHub Gist Sync (\$0 Forever)',
                      style: AppTypography.cardTitle(width),
                    ),
                  ),
                  if (appState?.syncNote != null)
                    Flexible(
                      child: Text(
                        appState!.syncNote!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.accentEmeraldGlow,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Zero-server cross-device sync (PBKDF2 + AES-256-GCM) with 1-tap QR Device Pairing across Android, Windows, Web, and iOS.',
                style: AppTypography.bodyCopy(width),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _patCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'GitHub Personal Access Token (gist scope)',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passphraseCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Sync Encryption Passphrase',
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: _busy ? null : _saveGistAndSync,
                    icon: const Icon(Icons.sync_rounded, size: 18),
                    label: const Text('Save & Sync Now'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _busy
                        ? null
                        : () => showQrPairingExportDialog(context, ref),
                    icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                    label: const Text('Pair Another Device'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => showQrPairingImportDialog(
                              context,
                              ref,
                              _loadSecrets,
                            ),
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                    label: const Text('Link Device'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _exportBackup,
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Export .atp Backup'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _importBackup,
                    icon: const Icon(Icons.upload_rounded, size: 18),
                    label: const Text('Import .atp Backup'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ObsidianCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Optional Supabase Free-Tier Cloud Sync',
                style: AppTypography.cardTitle(width),
              ),
              const SizedBox(height: 4),
              Text(
                'Free-tier Postgres sync (50K MAUs / 500MB) using supabase/schema.sql with Row-Level Security.',
                style: AppTypography.bodyCopy(width),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _supaUrlCtrl,
                decoration:
                    const InputDecoration(labelText: 'Supabase Project URL'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _supaKeyCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Supabase Anon / Publishable Key',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _supaEmailCtrl,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _supaPassCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _busy ? null : _saveSupabaseAndSync,
                icon: const Icon(Icons.cloud_done_outlined, size: 18),
                label: const Text('Test Connection & Sync Now'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
