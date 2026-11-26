import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/rpg_widgets.dart';
import '../../sanctuary/application/app_providers.dart';
import '../../sanctuary/application/recovery_controller.dart';
import '../../sanctuary/domain/recovery_models.dart';
import 'chronicle_act_card.dart';
import 'journey_path_painter.dart';

/// Tab 2 — PLAYABLE 7-ACT STORY MAP over full-bleed painted realm_map_bg.png,
/// featuring glowing Guardian frontier token, painted loot chests & boss gates.
class JourneyScreen extends ConsumerStatefulWidget {
  const JourneyScreen({super.key});

  @override
  ConsumerState<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends ConsumerState<JourneyScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pinCtrl;

  @override
  void initState() {
    super.initState();
    _pinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disable = MediaQuery.disableAnimationsOf(context);
    if (disable && _pinCtrl.isAnimating) {
      _pinCtrl.stop();
    } else if (!disable && !_pinCtrl.isAnimating) {
      _pinCtrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  void _burstConfetti() {
    if (!mounted) return;
    try {
      Confetti.launch(
        context,
        options: const ConfettiOptions(
          particleCount: 40,
          spread: 60,
          y: 0.6,
          colors: [AppColors.moltenGold, AppColors.arcaneEmerald, AppColors.accentCyan],
        ),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final desktop = AppTypography.isDesktopWidth(width);
    final asyncState = ref.watch(recoveryProvider);
    final liveNow = ref.watch(liveClockStreamProvider).value ??
        ref.read(clockProvider).now().toUtc();

    return asyncState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: FilledButton(
          onPressed: () => ref.invalidate(recoveryProvider),
          child: const Text('Retry loading chronicle'),
        ),
      ),
      data: (appState) {
        final s = appState.streakState;
        final daysClean = s.currentDays(liveNow);
        final unlockedActs = kChronicleActs.where((a) => daysClean >= a.minDay).length;
        const rowHeight = 82.0;

        return Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              GameArtAssets.realmMapBg,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.twilightDeep.withValues(alpha: 0.72),
                    AppColors.bgVoid.withValues(alpha: 0.58),
                    AppColors.bgVoid.withValues(alpha: 0.90),
                  ],
                ),
              ),
            ),
            const EmberParticlesBackdrop(count: 20, color: AppColors.arcaneEmerald),
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, desktop ? 32 : 136),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('The Eclipse Chronicle', style: AppTypography.screenTitle(width)),
                              const SizedBox(height: 2),
                              Text(
                                '7 Story Acts · Moral crossroads, Relic Chests, and Boss Gates.',
                                style: AppTypography.bodyCopy(width),
                              ),
                            ],
                          ),
                          OrnateRpgFrame(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            borderRadius: 12,
                            showCornerDiamonds: false,
                            accentColor: AppColors.moltenGold,
                            child: Text(
                              'Day $daysClean / 90 · $unlockedActs / ${kChronicleActs.length} Acts Open',
                              style: AppTypography.monoStat(fontSize: 12, color: AppColors.moltenGold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      OrnateRpgFrame(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        accentColor: AppColors.arcaneEmerald,
                        child: LayoutBuilder(
                          builder: (_, box) {
                            final w = box.maxWidth;
                            final totalH = kChronicleActs.length * rowHeight;
                            return SizedBox(
                              height: totalH,
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: JourneyPathPainter(
                                        nodeCount: kChronicleActs.length,
                                        unlockedCount: unlockedActs,
                                        rowHeight: rowHeight,
                                      ),
                                    ),
                                  ),
                                  for (var i = 0; i < kChronicleActs.length; i++)
                                    _SerpentineActPin(
                                      index: i,
                                      act: kChronicleActs[i],
                                      maxWidth: w,
                                      rowHeight: rowHeight,
                                      unlocked: daysClean >= kChronicleActs[i].minDay,
                                      cleared: s.claimedJourneyNodes.contains(kChronicleActs[i].bossGateId),
                                      isFrontier: i == (unlockedActs - 1).clamp(0, kChronicleActs.length - 1),
                                      pinAnimation: _pinCtrl,
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      for (final act in kChronicleActs) ...[
                        ChronicleActCard(
                          act: act,
                          daysClean: daysClean,
                          chosenId: s.chronicleChoices[act.id],
                          chestClaimed: s.claimedJourneyNodes.contains(act.chestNodeId),
                          bossClaimed: s.claimedJourneyNodes.contains(act.bossGateId),
                          onChoose: (choice) async {
                            final ok = await ref
                                .read(recoveryProvider.notifier)
                                .selectChronicleChoice(actId: act.id, choice: choice);
                            if (ok && appState.hapticsEnabled) {
                              HapticFeedback.selectionClick();
                            }
                          },
                          onClaimChest: () async {
                            final ok = await ref
                                .read(recoveryProvider.notifier)
                                .claimChronicleReward(
                                  nodeId: act.chestNodeId,
                                  requiredDay: act.minDay,
                                  xpReward: act.rewardXp ~/ 2,
                                  goldReward: act.rewardGold ~/ 2,
                                );
                            if (ok) {
                              if (appState.hapticsEnabled) HapticFeedback.mediumImpact();
                              _burstConfetti();
                            }
                          },
                          onClaimBoss: () async {
                            final ok = await ref
                                .read(recoveryProvider.notifier)
                                .claimChronicleReward(
                                  nodeId: act.bossGateId,
                                  requiredDay: act.bossDayRequired,
                                  xpReward: act.rewardXp,
                                  goldReward: act.rewardGold,
                                  isBoss: true,
                                );
                            if (ok) {
                              if (appState.hapticsEnabled) HapticFeedback.heavyImpact();
                              _burstConfetti();
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
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

class _SerpentineActPin extends StatelessWidget {
  const _SerpentineActPin({
    required this.index,
    required this.act,
    required this.maxWidth,
    required this.rowHeight,
    required this.unlocked,
    required this.cleared,
    required this.isFrontier,
    required this.pinAnimation,
  });

  final int index;
  final ChronicleActSpec act;
  final double maxWidth;
  final double rowHeight;
  final bool unlocked;
  final bool cleared;
  final bool isFrontier;
  final Animation<double> pinAnimation;

  @override
  Widget build(BuildContext context) {
    final lane = switch (index % 4) { 0 => 0.50, 1 => 0.72, 2 => 0.50, _ => 0.28 };
    final cx = maxWidth * lane;
    final alignRight = lane <= 0.50;
    final color = cleared
        ? AppColors.arcaneEmerald
        : (unlocked ? AppColors.moltenGold : AppColors.textMuted);

    return Positioned(
      left: 0,
      right: 0,
      top: index * rowHeight,
      height: rowHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: (cx - 22).clamp(8.0, maxWidth - 52),
            top: rowHeight * 0.5 - 22,
            child: AnimatedBuilder(
              animation: pinAnimation,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, isFrontier ? -4.0 * pinAnimation.value : 0.0),
                child: child,
              ),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.twilightDeep.withValues(alpha: 0.92),
                  border: Border.all(color: color, width: isFrontier ? 2.4 : 1.5),
                  boxShadow: unlocked
                      ? [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 12)]
                      : null,
                ),
                child: isFrontier
                    ? ClipOval(
                        child: Image.asset(
                          GameArtAssets.guardianKnight,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                        ),
                      )
                    : ClipOval(
                        child: Opacity(
                          opacity: unlocked ? 1.0 : 0.45,
                          child: Image.asset(
                            cleared ? GameArtAssets.lootChest : GameArtAssets.mirageBoss,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          ),
                        ),
                      ),
              ),
            ),
          ),
          Positioned(
            left: alignRight ? (cx + 30).clamp(0.0, maxWidth - 150) : 8,
            right: alignRight ? 8 : (maxWidth - cx + 30).clamp(0.0, maxWidth - 150),
            top: rowHeight * 0.5 - 22,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.twilightDeep.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.45)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Act ${act.actNumber} · ${act.title}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    cleared ? 'Cleared (${act.dayRange})' : act.dayRange,
                    style: AppTypography.monoStat(fontSize: 10.5, color: color),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
