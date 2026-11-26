import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/engine/rpg_juice_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/rpg_widgets.dart';
import '../../sanctuary/domain/recovery_models.dart';

/// 2D Dark-Fantasy Turn-Based Combat Stage pairing painted guardian_knight.png
/// vs painted mirage_boss.png, with Hades HP trail bar, projectile beams,
/// crimson hit-flash, and Whisper / Defusion dialogue.
class BossBattleArenaCard extends StatelessWidget {
  const BossBattleArenaCard({
    super.key,
    required this.boss,
    required this.hp,
    required this.maxHp,
    required this.hitFlash,
    required this.defusionRevealed,
    required this.lastDamageText,
    required this.strikeSignal,
  });

  final UrgeBossSpec boss;
  final int hp;
  final int maxHp;
  final double hitFlash;
  final bool defusionRevealed;
  final String? lastDamageText;
  final ({int seq, Color color, bool isCrit})? strikeSignal;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final ratio = (hp / maxHp).clamp(0.0, 1.0);
    final defeated = hp <= 0;

    return OrnateRpgFrame(
      accentColor: defeated ? AppColors.arcaneEmerald : boss.accent,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      defeated ? 'MIRAGE SHATTERED' : 'MIRAGE ENCOUNTER',
                      style: AppTypography.microLabel(
                        width,
                        color: defeated ? AppColors.arcaneEmerald : AppColors.accentCrimson,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      boss.name,
                      style: AppTypography.cinzelTitle(
                        width,
                        color: defeated ? AppColors.arcaneEmerald : AppColors.textPrimary,
                      ),
                    ),
                    Text(boss.subtitle, style: AppTypography.bodyCopy(width)),
                  ],
                ),
              ),
              if (lastDamageText != null)
                RpgFloatingBanner(
                  text: lastDamageText!,
                  color: lastDamageText!.contains('CRIT')
                      ? AppColors.moltenGold
                      : AppColors.arcaneEmerald,
                ),
            ],
          ),
          const SizedBox(height: 10),
          // 2D Painted Combat Stage
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 164,
              decoration: BoxDecoration(
                border: Border.all(
                  color: (defeated ? AppColors.arcaneEmerald : boss.accent).withValues(alpha: 0.45),
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    GameArtAssets.citadelTier1,
                    fit: BoxFit.cover,
                    color: AppColors.twilightDeep.withValues(alpha: 0.72),
                    colorBlendMode: BlendMode.darken,
                    gaplessPlayback: true,
                  ),
                  EmberParticlesBackdrop(
                    count: 18,
                    color: defeated ? AppColors.arcaneEmerald : boss.accent,
                  ),
                  if (strikeSignal != null && !MediaQuery.disableAnimationsOf(context))
                    _ProjectileBeamOverlay(
                      key: ValueKey(strikeSignal!.seq),
                      color: strikeSignal!.color,
                      isCrit: strikeSignal!.isCrit,
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Guardian Knight sprite
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 82,
                              height: 82,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.arcaneEmerald.withValues(alpha: 0.35),
                                    blurRadius: 24,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 112,
                              height: 112,
                              child: Image.asset(
                                GameArtAssets.guardianKnight,
                                fit: BoxFit.contain,
                                gaplessPlayback: true,
                              ),
                            ),
                          ],
                        ),
                        // Painted Boss or Victory Chest
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 280),
                          opacity: defeated ? 0.25 : 1.0,
                          child: ColorFiltered(
                            colorFilter: ColorFilter.mode(
                              Colors.white.withValues(alpha: hitFlash.clamp(0.0, 0.85)),
                              BlendMode.srcATop,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 88,
                                  height: 88,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: boss.accent.withValues(alpha: 0.42),
                                        blurRadius: 28,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 124,
                                  height: 124,
                                  child: Image.asset(
                                    GameArtAssets.mirageBoss,
                                    fit: BoxFit.contain,
                                    gaplessPlayback: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (defusionRevealed ? AppColors.arcaneEmerald : AppColors.accentCrimson)
                  .withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: (defusionRevealed ? AppColors.arcaneEmerald : AppColors.accentCrimson)
                    .withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              defusionRevealed ? boss.defusionMantra : boss.illusionWhisper,
              style: AppTypography.bodyCopy(width).copyWith(
                color: defusionRevealed ? AppColors.arcaneEmerald : AppColors.textPrimary,
                fontStyle: defusionRevealed ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'MIRAGE INTEGRITY',
                  style: AppTypography.microLabel(width, color: AppColors.accentCrimson),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$hp / $maxHp HP',
                style: AppTypography.monoStat(
                  fontSize: 13,
                  color: defeated ? AppColors.arcaneEmerald : AppColors.accentCrimson,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          HadesProgressBar(
            value: ratio,
            fillColor: defeated ? AppColors.arcaneEmerald : AppColors.accentCrimson,
            height: 11,
          ),
        ],
      ),
    );
  }
}

class _ProjectileBeamOverlay extends StatelessWidget {
  const _ProjectileBeamOverlay({
    super.key,
    required this.color,
    required this.isCrit,
  });

  final Color color;
  final bool isCrit;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: isCrit ? 320 : 240),
      curve: Curves.easeOutCubic,
      builder: (_, t, _) {
        if (t >= 0.99) return const SizedBox.shrink();
        return IgnorePointer(
          child: CustomPaint(
            painter: _BeamPainter(t: t, color: color, isCrit: isCrit),
          ),
        );
      },
    );
  }
}

class _BeamPainter extends CustomPainter {
  const _BeamPainter({required this.t, required this.color, required this.isCrit});
  final double t;
  final Color color;
  final bool isCrit;

  @override
  void paint(Canvas canvas, Size size) {
    final start = Offset(size.width * 0.24, size.height * 0.56);
    final end = Offset(size.width * 0.78, size.height * 0.48);
    final pos = Offset.lerp(start, end, t)! - Offset(0, 14 * (1 - (2 * t - 1) * (2 * t - 1)));
    canvas.drawCircle(pos, isCrit ? 18 : 12, Paint()..color = color.withValues(alpha: 0.35));
    canvas.drawCircle(pos, isCrit ? 9 : 6, Paint()..color = Colors.white);
    canvas.drawLine(
      Offset.lerp(start, pos, 0.45)!,
      pos,
      Paint()
        ..color = color
        ..strokeWidth = isCrit ? 5 : 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_BeamPainter old) => old.t != t || old.color != color;
}

/// Interactive Qwittr-style 4-7-8 Mountain Breath-Wave curve inside OrnateRpgFrame.
class BreathWaveAttackCard extends StatefulWidget {
  const BreathWaveAttackCard({
    super.key,
    required this.strikeDamage,
    required this.disabled,
    required this.onBreathStrike,
  });

  final int strikeDamage;
  final bool disabled;
  final VoidCallback onBreathStrike;

  @override
  State<BreathWaveAttackCard> createState() => _BreathWaveAttackCardState();
}

class _BreathWaveAttackCardState extends State<BreathWaveAttackCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  int _lastCycleCount = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 19),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          _lastCycleCount++;
          if (!widget.disabled) widget.onBreathStrike();
          _ctrl.forward(from: 0);
        }
      });
    _ctrl.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disable = MediaQuery.disableAnimationsOf(context);
    if (disable && _ctrl.isAnimating) {
      _ctrl.stop();
    } else if (!disable && !_ctrl.isAnimating) {
      _ctrl.forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _phaseLabel(double t) {
    final sec = t * 19.0;
    if (sec < 4.0) return 'INHALE CLIMB · ${sec.ceil().clamp(1, 4)}s';
    if (sec < 11.0) return 'SUMMIT HOLD · ${(sec - 4).ceil().clamp(1, 7)}s';
    return 'EXHALE RELEASE · ${(sec - 11).ceil().clamp(1, 8)}s';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return OrnateRpgFrame(
      accentColor: AppColors.accentCyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.waves_rounded, size: 16, color: AppColors.accentCyan),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'SKILL 2 · SURF THE WAVE (-${widget.strikeDamage} HP)',
                  style: AppTypography.microLabel(width, color: AppColors.accentCyan),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'Waves: $_lastCycleCount',
                style: AppTypography.monoStat(fontSize: 11, color: AppColors.arcaneEmerald),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 108,
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, _) => Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: _BreathMountainPainter(progress: _ctrl.value)),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Text(
                      _phaseLabel(_ctrl.value),
                      style: AppTypography.monoStat(fontSize: 12, color: AppColors.moltenGold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          RpgBevelButton(
            icon: Icons.bolt_rounded,
            variant: RpgButtonVariant.emerald,
            label: 'Channel Breath Strike (-${widget.strikeDamage} HP)',
            onPressed: widget.disabled ? null : widget.onBreathStrike,
          ),
        ],
      ),
    );
  }
}

class _BreathMountainPainter extends CustomPainter {
  const _BreathMountainPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final baseY = h * 0.84;
    final peakY = h * 0.28;

    final path = ui.Path()
      ..moveTo(12, baseY)
      ..cubicTo(w * 0.14, baseY, w * 0.18, peakY, w * 0.26, peakY)
      ..lineTo(w * 0.58, peakY)
      ..cubicTo(w * 0.72, peakY, w * 0.82, baseY, w - 12, baseY);

    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          colors: [AppColors.accentCyan, AppColors.moltenGold, AppColors.arcaneEmerald],
        ).createShader(Rect.fromLTWH(0, 0, w, h))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final tangent = metrics.first.getTangentForOffset(metrics.first.length * progress.clamp(0.0, 1.0));
    if (tangent == null) return;
    canvas.drawCircle(tangent.position, 14, Paint()..color = AppColors.moltenGold.withValues(alpha: 0.28));
    canvas.drawCircle(tangent.position, 7, Paint()..color = AppColors.moltenGold);
  }

  @override
  bool shouldRepaint(_BreathMountainPainter old) => old.progress != progress;
}
