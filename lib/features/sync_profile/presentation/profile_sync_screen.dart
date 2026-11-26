import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/rpg_widgets.dart';
import '../../analytics/presentation/analytics_screen.dart';
import '../../journal/presentation/journal_screen.dart';
import '../../quests/presentation/relapse_postmortem_sheet.dart';
import '../../sanctuary/application/app_providers.dart';
import '../../sanctuary/application/recovery_controller.dart';
import '../../sanctuary/domain/recovery_models.dart';
import 'sync_integrations_cards.dart';

enum _CodexTab { telemetry, journal, vaultSync }

/// Tab 5 — STATS & SOVEREIGN CODEX:
/// Predictive Behavioral Analytics, Trigger Journal, Roguelite Fallen Run
/// Campfire, Auto-Setup Wizard Replay, PIN/Biometrics & $0 Encrypted Sync.
class ProfileSyncScreen extends ConsumerStatefulWidget {
  const ProfileSyncScreen({super.key});

  @override
  ConsumerState<ProfileSyncScreen> createState() => _ProfileSyncScreenState();
}

class _ProfileSyncScreenState extends ConsumerState<ProfileSyncScreen> {
  final _whyCtrl = TextEditingController();
  bool _whySeeded = false;
  _CodexTab _tab = _CodexTab.telemetry;

  @override
  void dispose() {
    _whyCtrl.dispose();
    super.dispose();
  }

  Future<void> _setPinDialog(BuildContext context) async {
    final pinCtrl = TextEditingController();
    String? error;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Set 4-Digit Sanctuary PIN'),
          content: TextField(
            controller: pinCtrl,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            decoration: InputDecoration(labelText: '4-digit PIN', errorText: error),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final val = pinCtrl.text.trim();
                if (val.length != 4 || int.tryParse(val) == null) {
                  setLocal(() => error = 'Enter exactly 4 digits.');
                  return;
                }
                Navigator.of(ctx).pop(true);
              },
              child: const Text('Save PIN'),
            ),
          ],
        ),
      ),
    );
    if (saved == true) {
      await ref.read(recoveryProvider.notifier).configurePin(pinCtrl.text.trim());
    }
    pinCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final desktop = AppTypography.isDesktopWidth(width);
    final asyncState = ref.watch(recoveryProvider);

    return asyncState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: FilledButton(
          onPressed: () => ref.invalidate(recoveryProvider),
          child: const Text('Retry loading stats'),
        ),
      ),
      data: (appState) {
        final s = appState.streakState;
        if (!_whySeeded) {
          _whyCtrl.text = s.whyIStarted;
          _whySeeded = true;
        }

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, desktop ? 32 : 136),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1020),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      Text('Stats & Sovereign Codex', style: AppTypography.screenTitle(width)),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Analytics'),
                            selected: _tab == _CodexTab.telemetry,
                            onSelected: (_) => setState(() => _tab = _CodexTab.telemetry),
                          ),
                          ChoiceChip(
                            label: const Text('Journal Logs'),
                            selected: _tab == _CodexTab.journal,
                            onSelected: (_) => setState(() => _tab = _CodexTab.journal),
                          ),
                          ChoiceChip(
                            label: const Text('Sync & Security'),
                            selected: _tab == _CodexTab.vaultSync,
                            onSelected: (_) => setState(() => _tab = _CodexTab.vaultSync),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_tab == _CodexTab.telemetry)
                    const AnalyticsScreen(embedded: true)
                  else if (_tab == _CodexTab.journal)
                    const JournalScreen(embedded: true)
                  else ...[
                    OrnateRpgFrame(
                      accentColor: AppColors.arcaneEmerald,
                      child: Wrap(
                        spacing: 14,
                        runSpacing: 10,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 52,
                                height: 52,
                                child: Image.asset(
                                  GameArtAssets.guardianKnight,
                                  fit: BoxFit.contain,
                                  gaplessPlayback: true,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ARCHETYPE · ${s.lampbearerName.toUpperCase()}',
                                    style: AppTypography.microLabel(width, color: AppColors.arcaneEmerald),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${s.diagnosticProfile?.archetype ?? "Sovereign Guardian"} · Vow of ${s.guidingVow.title}',
                                    style: AppTypography.cardTitle(width),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(s.guidingVow.mantra, style: AppTypography.bodyCopy(width)),
                                ],
                              ),
                            ],
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              RpgBevelButton(
                                compact: true,
                                variant: RpgButtonVariant.emerald,
                                icon: Icons.auto_awesome_rounded,
                                label: 'Re-run Auto-Setup Wizard',
                                onPressed: () => context.push('/onboarding'),
                              ),
                              RpgBevelButton(
                                compact: true,
                                variant: RpgButtonVariant.gold,
                                icon: Icons.local_fire_department_rounded,
                                label: 'Fallen Run Campfire',
                                onPressed: () => showModalBottomSheet<bool>(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (_) => const RelapsePostMortemSheet(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    OrnateRpgFrame(
                      accentColor: AppColors.moltenGold,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Why I Started Anchor', style: AppTypography.cardTitle(width)),
                          const SizedBox(height: 6),
                          Text('Shown inside Mirage Ambush when holding your Vow Shield.', style: AppTypography.bodyCopy(width)),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _whyCtrl,
                            maxLines: 2,
                            decoration: const InputDecoration(labelText: 'Personal commitment statement'),
                          ),
                          const SizedBox(height: 12),
                          RpgBevelButton(
                            compact: true,
                            variant: RpgButtonVariant.emerald,
                            label: 'Save Anchor',
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              await ref.read(recoveryProvider.notifier).updateWhyIStarted(_whyCtrl.text);
                              if (!mounted) return;
                              messenger.showSnackBar(const SnackBar(content: Text('Anchor statement updated.')));
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    OrnateRpgFrame(
                      accentColor: AppColors.accentCyan,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Discreet Mode, SFX, Haptics & Lock', style: AppTypography.cardTitle(width)),
                          const SizedBox(height: 8),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Discreet Mask (ATP Pomodoro)'),
                            subtitle: const Text(
                              'Swaps UI immediately into clean Pomodoro focus timer.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            value: appState.discreetMode,
                            onChanged: (_) => ref.read(recoveryProvider.notifier).toggleDiscreetMode(),
                          ),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Synthesized RPG Sound Effects'),
                            subtitle: const Text(
                              'Crisp breath, boss hit, chest loot & level-up cues.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            value: appState.sfxEnabled,
                            onChanged: (v) => ref.read(recoveryProvider.notifier).setSfxEnabled(v),
                          ),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Tactile Haptics'),
                            subtitle: const Text(
                              'Gentle vibration feedback on strikes & vows.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            value: appState.hapticsEnabled,
                            onChanged: (v) => ref.read(recoveryProvider.notifier).setHapticsEnabled(v),
                          ),
                          const Divider(height: 20),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              RpgBevelButton(
                                compact: true,
                                variant: RpgButtonVariant.twilight,
                                icon: Icons.pin_outlined,
                                label: appState.hasPin ? 'Change 4-Digit PIN' : 'Set 4-Digit PIN',
                                onPressed: () => _setPinDialog(context),
                              ),
                              if (appState.hasPin) ...[
                                OutlinedButton(
                                  onPressed: () => ref.read(recoveryProvider.notifier).lockNow(),
                                  child: const Text('Lock Now'),
                                ),
                                OutlinedButton(
                                  onPressed: () => ref.read(recoveryProvider.notifier).disablePin(),
                                  child: const Text('Remove PIN'),
                                ),
                              ],
                            ],
                          ),
                          if (appState.hasPin) ...[
                            const SizedBox(height: 8),
                            FutureBuilder<bool>(
                              future: ref.read(appLockServiceProvider).canUseBiometrics(),
                              builder: (context, snap) {
                                if (snap.data != true) return const SizedBox.shrink();
                                return SwitchListTile.adaptive(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Biometric Unlock'),
                                  value: appState.biometricsEnabled,
                                  onChanged: (v) => ref.read(recoveryProvider.notifier).setBiometrics(v),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const SyncIntegrationsCards(),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
