import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../sanctuary/application/recovery_controller.dart';

/// Displays an encrypted QR code + pairing string for 10-second multi-device setup.
Future<void> showQrPairingExportDialog(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  late final String payload;
  try {
    payload = await ref.read(recoveryProvider.notifier).createPairingPayload();
  } catch (e) {
    if (!context.mounted) return;
    messenger.clearSnackBars();
    messenger.showSnackBar(SnackBar(content: Text('$e')));
    return;
  }
  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.bgElevated,
      title: const Text('Pair Another Device'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Scan this QR or copy the pairing token to link Android, Windows, Web, or iOS. Still requires your Sync Passphrase to decrypt.',
              style: AppTypography.bodyCopy(360),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: QrImageView(
                data: payload,
                size: 184,
                gapless: true,
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(
              payload,
              maxLines: 2,
              style: AppTypography.monoStat(
                fontSize: 11,
                color: AppColors.accentCyan,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: payload));
            messenger.clearSnackBars();
            messenger.showSnackBar(
              const SnackBar(content: Text('Encrypted pairing token copied.')),
            );
          },
          child: const Text('Copy Token'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Done'),
        ),
      ],
    ),
  );
}

/// Imports an encrypted pairing token + passphrase on a second device.
Future<void> showQrPairingImportDialog(
  BuildContext context,
  WidgetRef ref,
  VoidCallback onPaired,
) async {
  final tokenCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.bgElevated,
      title: const Text('Link With Pairing Token'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: tokenCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'ATP_PAIR_V2 Token (from QR / clipboard)',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: passCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Sync Passphrase'),
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
          child: const Text('Pair & Sync'),
        ),
      ],
    ),
  );

  if (ok == true && context.mounted) {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(recoveryProvider.notifier)
          .applyPairingPayload(tokenCtrl.text, passCtrl.text);
      onPaired();
      if (!context.mounted) return;
      messenger.clearSnackBars();
      messenger.showSnackBar(
        const SnackBar(content: Text('Device paired and synced cleanly.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.clearSnackBars();
      messenger.showSnackBar(SnackBar(content: Text('Pairing failed: $e')));
    }
  }
  tokenCtrl.dispose();
  passCtrl.dispose();
}
