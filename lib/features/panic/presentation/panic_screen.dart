import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/engine/recovery_algorithm.dart';
import '../../../../core/engine/rpg_juice_widgets.dart';
import '../../../../core/engine/rpg_sfx_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/rpg_widgets.dart';
import '../../sanctuary/application/app_providers.dart';
import '../../sanctuary/application/recovery_controller.dart';
import '../../sanctuary/domain/recovery_models.dart';
import 'boss_battle_widgets.dart';
import 'reset_challenges.dart';

/// Full-Screen Turn-Based 2D Boss Arena (Mirage Ambush) with painted actors,
/// projectile attacks, Breath-Wave surfing, Counter-Spell CRITs, and painted Victory Loot Chest.
class PanicScreen extends ConsumerStatefulWidget {
  const PanicScreen({super.key});

  @override
  ConsumerState<PanicScreen> createState() => _PanicScreenState();
}

class _PanicScreenState extends ConsumerState<PanicScreen> {
  static const int _maxHp = 100;
  final RpgShakeController _shakeCtrl = RpgShakeController();

  int _bossHp = _maxHp;
  bool _submitting = false;
  double _hitFlash = 0.0;
  String? _lastDamageText;
  bool _defusionUsed = false;

  int _strikeSeq = 0;
  ({int seq, Color color, bool isCrit})? _strikeSignal;

  double _holdProgress = 0.0;
  bool _anchorStrikeUsed = false;
  Timer? _holdTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final haptics = ref.read(recoveryProvider).value?.hapticsEnabled ?? true;
      if (haptics) HapticFeedback.heavyImpact();
    });
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _dealBossDamage(
    int amount, {
    bool isCrit = false,
    Color beamColor = AppColors.arcaneEmerald,
    RpgSfx sfx = RpgSfx.hit,
  }) {
    if (_bossHp <= 0) return;
    final appState = ref.read(recoveryProvider).value;
    if (appState?.hapticsEnabled ?? true) HapticFeedback.mediumImpact();
    unawaited(
      ref.read(sfxServiceProvider).play(
            _bossHp - amount <= 0 ? RpgSfx.levelUp : sfx,
            enabled: appState?.sfxEnabled ?? true,
          ),
    );

    final nextHp = math.max(0, _bossHp - amount);
    _strikeSeq++;
    _shakeCtrl.trigger(isCrit ? 1.0 : 0.65);

    setState(() {
      _bossHp = nextHp;
      _hitFlash = 1.0;
      _lastDamageText = isCrit ? 'CRIT -$amount!' : '-$amount HP';
      _strikeSignal = (seq: _strikeSeq, color: beamColor, isCrit: isCrit);
    });

    Future.delayed(const Duration(milliseconds: 160), () {
      if (mounted) setState(() => _hitFlash = 0.0);
    });

    if (nextHp == 0) {
      try {
        Confetti.launch(
          context,
          options: const ConfettiOptions(
            particleCount: 60,
            spread: 75,
            y: 0.55,
            colors: [AppColors.moltenGold, AppColors.arcaneEmerald, AppColors.accentCyan],
          ),
        );
      } catch (_) {}
    }
  }

  void _startHoldAnchor(int damage) {
    if (_anchorStrikeUsed || _bossHp <= 0) return;
    _holdTimer?.cancel();
    _holdTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _holdProgress = (_holdProgress + (1 / 30)).clamp(0.0, 1.0));
      if (_holdProgress >= 1.0) {
        t.cancel();
        setState(() => _anchorStrikeUsed = true);
        _dealBossDamage(damage, beamColor: AppColors.moltenGold);
      }
    });
  }

  void _stopHoldAnchor() {
    _holdTimer?.cancel();
    if (!_anchorStrikeUsed && mounted) setState(() => _holdProgress = 0.0);
  }

  Future<void> _finishBattle({required bool bossSlain}) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final haptics = ref.read(recoveryProvider).value?.hapticsEnabled ?? true;
    if (haptics) HapticFeedback.mediumImpact();

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.maybeOf(context);
    final navigator = Navigator.of(context);

    await ref.read(recoveryProvider.notifier).recordUrgeDefeated(
          bossSlain: bossSlain,
          note: bossSlain
              ? 'Vanquished Mirage Boss in Combat Arena.'
              : 'Used Mirage Ambush override and held the line.',
        );
    if (!mounted) return;

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          bossSlain
              ? 'Mirage Boss Shattered! +75 XP, +40 Gold & Victory Loot awarded.'
              : 'Urge overridden cleanly. +50 XP and +20 Gold awarded.',
        ),
      ),
    );
    if (router != null) {
      router.canPop() ? router.pop() : router.go('/sanctuary');
    } else {
      await navigator.maybePop();
    }
  }

  void _exitOverride() {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.canPop() ? router.pop() : router.go('/sanctuary');
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(recoveryProvider).value;
    final width = MediaQuery.sizeOf(context).width;
    final s = appState?.streakState;
    final nowUtc = ref.read(clockProvider).now().toUtc();

    final risk = s != null
        ? PersonalRecoveryAlgorithm.assessRisk(
            state: s,
            logs: appState?.urgeLogs ?? const [],
            nowUtc: nowUtc,
          )
        : null;
    final boss = risk?.suggestedBoss ?? kUrgeBosses.first;
    final equippedSpells =
        (s?.activeCounterSpells ?? const []).where((sp) => sp.equipped).take(3).toList();

    final skillMult = (s?.hasSkill('iron_shield') ?? false) ? 1.25 : 1.0;
    final fountainMult = 1.0 + (s?.structureLevel('mana_fountain') ?? 0) * 0.15;
    final defuseDmg = (20 * skillMult).round();
    final breathDmg = (25 * skillMult * fountainMult).round();
    final critDmg = (50 * skillMult).round();
    final shieldDmg = (25 * skillMult).round();
    final whyIStarted =
        s?.whyIStarted ?? 'Protect my focus, clarity, and self-respect every day.';

    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): _exitOverride},
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: AppColors.twilightDeep,
          body: SafeArea(
            child: RpgScreenShake(
              controller: _shakeCtrl,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 740),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.accentCrimson.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.accentCrimson.withValues(alpha: 0.55),
                                ),
                              ),
                              child: Text(
                                'MIRAGE AMBUSH ARENA',
                                style: AppTypography.microLabel(width, color: AppColors.accentCrimson),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              tooltip: 'Exit override',
                              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                              onPressed: _exitOverride,
                              icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        BossBattleArenaCard(
                          boss: boss,
                          hp: _bossHp,
                          maxHp: _maxHp,
                          hitFlash: _hitFlash,
                          defusionRevealed: _defusionUsed,
                          lastDamageText: _lastDamageText,
                          strikeSignal: _strikeSignal,
                        ),
                        const SizedBox(height: 14),
                        if (_bossHp <= 0)
                          OrnateRpgFrame(
                            accentColor: AppColors.moltenGold,
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: _submitting ? null : () => _finishBattle(bossSlain: true),
                                  child: SizedBox(
                                    width: 124,
                                    height: 124,
                                    child: Image.asset(
                                      GameArtAssets.lootChest,
                                      fit: BoxFit.contain,
                                      gaplessPlayback: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${boss.name} Vanquished!',
                                  style: AppTypography.cinzelDisplay(width, color: AppColors.moltenGold),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Tap the Obsidian Chest to claim your victory spoils.',
                                  style: AppTypography.bodyCopy(width),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 14),
                                RpgBevelButton(
                                  variant: RpgButtonVariant.gold,
                                  icon: Icons.inventory_2_rounded,
                                  label: 'Claim Victory Loot (+75 XP / +40 Gold)',
                                  onPressed: _submitting ? null : () => _finishBattle(bossSlain: true),
                                ),
                              ],
                            ),
                          )
                        else ...[
                          OrnateRpgFrame(
                            accentColor: AppColors.arcaneEmerald,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'SKILL 1 · NAME THE ILLUSION (-$defuseDmg HP)',
                                  style: AppTypography.microLabel(width, color: AppColors.arcaneEmerald),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Cracks the Mirage’s armor through ACT Cognitive Defusion: notice the thought cleanly without obeying it.',
                                  style: AppTypography.bodyCopy(width),
                                ),
                                const SizedBox(height: 10),
                                RpgBevelButton(
                                  icon: _defusionUsed ? Icons.verified_rounded : Icons.psychology_outlined,
                                  variant: _defusionUsed ? RpgButtonVariant.twilight : RpgButtonVariant.emerald,
                                  label: _defusionUsed
                                      ? 'Illusion Named (-$defuseDmg HP)'
                                      : 'Name the Illusion (-$defuseDmg HP)',
                                  onPressed: _defusionUsed
                                      ? null
                                      : () {
                                          setState(() => _defusionUsed = true);
                                          _dealBossDamage(defuseDmg, beamColor: AppColors.arcaneEmerald);
                                        },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          BreathWaveAttackCard(
                            strikeDamage: breathDmg,
                            disabled: _bossHp <= 0,
                            onBreathStrike: () => _dealBossDamage(
                              breathDmg,
                              beamColor: AppColors.accentCyan,
                              sfx: RpgSfx.breath,
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (equippedSpells.isNotEmpty) ...[
                            OrnateRpgFrame(
                              accentColor: AppColors.moltenGold,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'SKILL 3 · CAST IF-THEN COUNTER-SPELL (-$critDmg CRIT)',
                                    style: AppTypography.microLabel(width, color: AppColors.moltenGold),
                                  ),
                                  const SizedBox(height: 8),
                                  for (final sp in equippedSpells) ...[
                                    RpgBevelButton(
                                      compact: true,
                                      variant: RpgButtonVariant.gold,
                                      icon: Icons.auto_fix_high_rounded,
                                      label: 'Cast Rank ${sp.romanRank}: ${sp.actionPlan}',
                                      onPressed: () {
                                        ref.read(recoveryProvider.notifier).castCounterSpell(sp.id);
                                        _dealBossDamage(critDmg, isCrit: true, beamColor: AppColors.moltenGold);
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                          PhysicalResetCard(
                            critDamage: critDmg,
                            onCriticalStrike: () => _dealBossDamage(
                              critDmg,
                              isCrit: true,
                              beamColor: AppColors.moltenGold,
                            ),
                          ),
                          const SizedBox(height: 14),
                          OrnateRpgFrame(
                            accentColor: AppColors.moltenGold,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'VOW SHIELD HOLD (-$shieldDmg HP)',
                                  style: AppTypography.microLabel(width, color: AppColors.moltenGold),
                                ),
                                const SizedBox(height: 8),
                                Text('"$whyIStarted"', style: AppTypography.cardTitle(width)),
                                const SizedBox(height: 12),
                                HadesProgressBar(
                                  value: _anchorStrikeUsed ? 1.0 : _holdProgress,
                                  fillColor: AppColors.moltenGold,
                                  height: 9,
                                ),
                                const SizedBox(height: 10),
                                GestureDetector(
                                  onTapDown: (_) => _startHoldAnchor(shieldDmg),
                                  onTapUp: (_) => _stopHoldAnchor(),
                                  onTapCancel: _stopHoldAnchor,
                                  child: Container(
                                    height: 46,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: _anchorStrikeUsed
                                          ? AppColors.arcaneEmerald.withValues(alpha: 0.2)
                                          : AppColors.moltenGold.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _anchorStrikeUsed
                                            ? AppColors.arcaneEmerald
                                            : AppColors.moltenGold,
                                      ),
                                    ),
                                    child: Text(
                                      _anchorStrikeUsed
                                          ? 'Shield Strike Landed (-$shieldDmg HP)'
                                          : 'Hold 3 Seconds to Strike (-$shieldDmg HP)',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          RpgBevelButton(
                            variant: RpgButtonVariant.twilight,
                            icon: Icons.verified_rounded,
                            label: 'Urge Survived (+50 XP / +20 Gold)',
                            onPressed: _submitting ? null : () => _finishBattle(bossSlain: false),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
