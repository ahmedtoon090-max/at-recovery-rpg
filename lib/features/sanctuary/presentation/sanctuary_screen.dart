import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/engine/recovery_algorithm.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/rpg_widgets.dart';
import '../application/app_providers.dart';
import '../application/recovery_controller.dart';
import '../domain/recovery_models.dart';
import 'widgets/citadel_drawers.dart';
import 'widgets/citadel_world_layers.dart';

/// Tab 1 — FULL-BLEED INTERACTIVE 2D MOONLIT CITADEL WORLD:
/// - Full-screen painted citadel_tier_1..4.png + interactive Ember Wisps
/// - Center-top floating Cinzel Days Medallion & timer (zero clipping)
/// - Foreground painted Guardian Knight with Hades speech bubble
/// - Bottom 4-button tactile RPG Hotbar (Dawn Vow, Mirage Ambush, HALT Orbs, Shield & Focus)
class SanctuaryScreen extends ConsumerStatefulWidget {
  const SanctuaryScreen({super.key});

  @override
  ConsumerState<SanctuaryScreen> createState() => _SanctuaryScreenState();
}

class _SanctuaryScreenState extends ConsumerState<SanctuaryScreen> {
  Future<void> _handleDailyPledge(bool hapticsEnabled) async {
    final messenger = ScaffoldMessenger.of(context);
    final pledged = await ref.read(recoveryProvider.notifier).completeDailyPledge();
    if (!mounted) return;
    if (!pledged) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Dawn Vow already sealed today.')));
      return;
    }
    if (hapticsEnabled) HapticFeedback.mediumImpact();
    try {
      Confetti.launch(
        context,
        options: const ConfettiOptions(
          particleCount: 38,
          spread: 58,
          y: 0.65,
          colors: [AppColors.arcaneEmerald, AppColors.moltenGold, AppColors.accentCyan],
        ),
      );
    } catch (_) {}
  }

  List<String> _buildDialogueLines(
    StreakState s,
    LiveRiskAssessment risk,
    bool pledgedToday,
    int urgesToday,
    int daysClean,
  ) {
    final next = s.rankAt(DateTime.now().toUtc()).nextTier;
    return [
      if (risk.isHighAlert && risk.primarySpell != null)
        'Danger window active — keep "${risk.primarySpell!.actionPlan}" ready.'
      else if (!pledgedToday)
        'The gate is quiet tonight. Seal your Dawn Vow for +25 XP.'
      else if (urgesToday > 0)
        'Lantern holding steady — we shattered $urgesToday Mirage ${urgesToday == 1 ? 'wave' : 'waves'} today.'
      else
        'Every kept hour fortifies the Citadel against impulse static.',
      'Guiding Vow of ${s.guidingVow.title}: "${s.guidingVow.mantra}"',
      if (next != null)
        '${(next.minDays - daysClean).clamp(1, 90)} days remain until ${next.title} (${next.companionName}) awakens.'
      else
        'All Citadel spires stand unbroken. Keep guarding your focus.',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final desktop = AppTypography.isDesktopWidth(width);
    final asyncState = ref.watch(recoveryProvider);
    final liveNow = ref.watch(liveClockStreamProvider).value ??
        ref.read(clockProvider).now().toUtc();

    ref.listen<AsyncValue<AppViewState>>(recoveryProvider, (prev, next) {
      final prevSeq = prev?.value?.lastReward?.seq;
      final ev = next.value?.lastReward;
      if (ev != null && ev.seq != prevSeq && mounted) {
        final suffix = [if (ev.xp > 0) '+${ev.xp} XP', if (ev.gold > 0) '+${ev.gold} G'].join(' · ');
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 2),
              content: Text(suffix.isEmpty ? ev.message : '${ev.message} ($suffix)'),
            ),
          );
      }
    });

    return asyncState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: FilledButton(
          onPressed: () => ref.invalidate(recoveryProvider),
          child: const Text('Retry loading citadel'),
        ),
      ),
      data: (appState) {
        final s = appState.streakState;
        final elapsed = s.currentStreak(liveNow);
        final daysClean = s.currentDays(liveNow);
        final rank = s.rankAt(liveNow);
        final castle = s.castleTierAt(liveNow);
        final nowLocal = liveNow.toLocal();
        final pledgedToday = s.hasPledgedOn(nowLocal);
        final questsDoneToday = appState.countQuestsCompletedOn(nowLocal);
        final urgesToday = appState.urgesDefeatedOn(nowLocal);
        final builtCount = s.castleStructures.values.fold<int>(0, (sum, lvl) => sum + lvl);
        final activeHaltCount = kHaltOrbs.where((h) => s.haltFlags[h.id] == true).length;
        final risk = PersonalRecoveryAlgorithm.assessRisk(
          state: s,
          logs: appState.urgeLogs,
          nowUtc: liveNow,
        );
        final shieldPct = (s.shieldIntegrity(nowLocal, questsDoneToday: questsDoneToday) * 100).round();
        final dialogueLines = _buildDialogueLines(s, risk, pledgedToday, urgesToday, daysClean);

        return Stack(
          fit: StackFit.expand,
          children: [
            CitadelWorldBackdrop(
              assetPath: GameArtAssets.citadelForDays(daysClean),
              highAlert: risk.isHighAlert,
              onTapWisp: () => ref.read(recoveryProvider.notifier).collectEmberWispGold(),
            ),
            SafeArea(
              bottom: !desktop,
              child: LayoutBuilder(
                builder: (_, box) => SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(14, 10, 14, desktop ? 22 : 96),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (box.maxHeight - (desktop ? 32 : 106)).clamp(0, 2000),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 960),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Column(
                              children: [
                                CitadelTopGameHud(
                                  lampbearerName: s.lampbearerName,
                                  level: s.level,
                                  xpIntoLevel: s.xpIntoLevel,
                                  gold: s.gold,
                                  syncStatus: appState.syncStatus,
                                  sfxEnabled: appState.sfxEnabled,
                                  onSyncTap: () => ref.read(recoveryProvider.notifier).syncNow(),
                                  onToggleSfx: () => ref.read(recoveryProvider.notifier).setSfxEnabled(!appState.sfxEnabled),
                                  onToggleDiscreet: () => ref.read(recoveryProvider.notifier).toggleDiscreetMode(),
                                ),
                                SizedBox(height: desktop ? 22 : 16),
                                CitadelHeroMedallion(
                                  rank: rank,
                                  castle: castle,
                                  elapsed: elapsed,
                                  sovereigntyPercent: s.sovereigntyRatioPercent(liveNow),
                                  rewiringProgress: s.rewiringProgress(liveNow),
                                  builtCount: builtCount,
                                  onTapForge: () => showForgeAndShieldDrawer(context, ref),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                CitadelGuardianForeground(
                                  dialogueLines: dialogueLines,
                                  shieldPct: shieldPct,
                                  highAlert: risk.isHighAlert,
                                ),
                                const SizedBox(height: 14),
                                _GameHotbar(
                                  desktop: desktop,
                                  pledgedToday: pledgedToday,
                                  activeHaltCount: activeHaltCount,
                                  onPledge: () => _handleDailyPledge(appState.hapticsEnabled),
                                  onAmbush: () {
                                    if (appState.hapticsEnabled) HapticFeedback.heavyImpact();
                                    context.push('/panic');
                                  },
                                  onHaltDrawer: () => showCampfireVitalityDrawer(context, ref),
                                  onShieldDrawer: () => showForgeAndShieldDrawer(context, ref),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GameHotbar extends StatelessWidget {
  const _GameHotbar({
    required this.desktop,
    required this.pledgedToday,
    required this.activeHaltCount,
    required this.onPledge,
    required this.onAmbush,
    required this.onHaltDrawer,
    required this.onShieldDrawer,
  });

  final bool desktop;
  final bool pledgedToday;
  final int activeHaltCount;
  final VoidCallback onPledge;
  final VoidCallback onAmbush;
  final VoidCallback onHaltDrawer;
  final VoidCallback onShieldDrawer;

  @override
  Widget build(BuildContext context) {
    final btns = [
      RpgBevelButton(
        compact: !desktop,
        icon: pledgedToday ? Icons.check_circle_rounded : Icons.auto_awesome_rounded,
        variant: RpgButtonVariant.emerald,
        label: pledgedToday ? 'Vow Sealed' : 'Dawn Vow',
        onPressed: onPledge,
      ),
      RpgBevelButton(
        compact: !desktop,
        icon: Icons.shield_moon_rounded,
        variant: RpgButtonVariant.crimson,
        label: 'Mirage Ambush',
        onPressed: onAmbush,
      ),
      RpgBevelButton(
        compact: !desktop,
        icon: Icons.local_fire_department_rounded,
        variant: RpgButtonVariant.gold,
        label: 'HALT Orbs',
        badgeText: activeHaltCount > 0 ? '$activeHaltCount' : null,
        onPressed: onHaltDrawer,
      ),
      RpgBevelButton(
        compact: !desktop,
        icon: Icons.security_rounded,
        variant: RpgButtonVariant.twilight,
        label: 'Shield & Focus',
        onPressed: onShieldDrawer,
      ),
    ];

    if (desktop) {
      return Row(
        children: [
          for (var i = 0; i < btns.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: btns[i]),
          ],
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: btns[0]),
            const SizedBox(width: 8),
            Expanded(child: btns[1]),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: btns[2]),
            const SizedBox(width: 8),
            Expanded(child: btns[3]),
          ],
        ),
      ],
    );
  }
}
