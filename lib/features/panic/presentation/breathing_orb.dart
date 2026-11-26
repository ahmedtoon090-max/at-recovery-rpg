import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

enum BreathingPhase {
  inhale(label: 'INHALE', durationSeconds: 4, hint: 'Breathe in deeply through your nose'),
  hold(label: 'HOLD', durationSeconds: 7, hint: 'Keep chest calm and shoulders dropped'),
  exhale(label: 'EXHALE', durationSeconds: 8, hint: 'Release slowly through your mouth');

  const BreathingPhase({
    required this.label,
    required this.durationSeconds,
    required this.hint,
  });

  final String label;
  final int durationSeconds;
  final String hint;
}

/// Interactive 4-7-8 breathing orb with phase-transition haptics.
class BreathingOrb extends StatefulWidget {
  const BreathingOrb({
    super.key,
    required this.hapticsEnabled,
    this.size = 220,
  });

  final bool hapticsEnabled;
  final double size;

  @override
  State<BreathingOrb> createState() => _BreathingOrbState();
}

class _BreathingOrbState extends State<BreathingOrb>
    with SingleTickerProviderStateMixin {
  static const int _totalCycleSeconds = 19; // 4 + 7 + 8
  late final AnimationController _controller;
  BreathingPhase _lastPhase = BreathingPhase.inhale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _totalCycleSeconds),
    )
      ..addListener(_checkPhaseTransition)
      ..repeat();
  }

  void _checkPhaseTransition() {
    final phase = _phaseAt(_controller.value).phase;
    if (phase != _lastPhase) {
      _lastPhase = phase;
      if (widget.hapticsEnabled) {
        HapticFeedback.heavyImpact();
      }
    }
  }

  ({BreathingPhase phase, double phaseProgress, int secondsLeft}) _phaseAt(
    double t,
  ) {
    final elapsed = t * _totalCycleSeconds;
    if (elapsed < 4.0) {
      return (
        phase: BreathingPhase.inhale,
        phaseProgress: (elapsed / 4.0).clamp(0.0, 1.0),
        secondsLeft: (4.0 - elapsed).ceil().clamp(1, 4),
      );
    }
    if (elapsed < 11.0) {
      final p = (elapsed - 4.0) / 7.0;
      return (
        phase: BreathingPhase.hold,
        phaseProgress: p.clamp(0.0, 1.0),
        secondsLeft: (11.0 - elapsed).ceil().clamp(1, 7),
      );
    }
    final p = (elapsed - 11.0) / 8.0;
    return (
      phase: BreathingPhase.exhale,
      phaseProgress: p.clamp(0.0, 1.0),
      secondsLeft: (19.0 - elapsed).ceil().clamp(1, 8),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_checkPhaseTransition);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final state = _phaseAt(_controller.value);
        final scale = switch (state.phase) {
          BreathingPhase.inhale =>
            0.64 + 0.36 * Curves.easeInOutSine.transform(state.phaseProgress),
          BreathingPhase.hold =>
            1.0 + 0.03 * math.sin(state.phaseProgress * math.pi * 4),
          BreathingPhase.exhale =>
            1.0 - 0.36 * Curves.easeInOutSine.transform(state.phaseProgress),
        };

        final ringColor = switch (state.phase) {
          BreathingPhase.inhale => AppColors.accentCyan,
          BreathingPhase.hold => AppColors.accentEmeraldGlow,
          BreathingPhase.exhale => AppColors.accentEmerald,
        };

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label:
                  '${state.phase.label}, ${state.secondsLeft} seconds remaining',
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    RepaintBoundary(
                      child: CustomPaint(
                        size: Size(widget.size, widget.size),
                        painter: _BreathingOrbPainter(
                          scale: scale,
                          color: ringColor,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          state.phase.label,
                          style: AppTypography.microLabel(
                            width,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${state.secondsLeft}s',
                          style: AppTypography.monoStat(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.phase.hint,
              style: AppTypography.bodyCopy(width),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }
}

class _BreathingOrbPainter extends CustomPainter {
  _BreathingOrbPainter({required this.scale, required this.color});

  final double scale;
  final Color color;

  final Paint _haloPaint = Paint();
  final Paint _corePaint = Paint();
  final Paint _ringPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.2;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = math.min(size.width, size.height) * 0.45;
    final r = maxR * scale;

    _haloPaint.shader = RadialGradient(
      colors: [
        color.withValues(alpha: 0.34),
        color.withValues(alpha: 0.08),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: center, radius: r * 1.35));
    canvas.drawCircle(center, r * 1.35, _haloPaint);

    _corePaint.shader = RadialGradient(
      colors: [
        color.withValues(alpha: 0.42),
        AppColors.bgElevated.withValues(alpha: 0.92),
      ],
    ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r, _corePaint);

    _ringPaint.color = color.withValues(alpha: 0.85);
    canvas.drawCircle(center, r, _ringPaint);
  }

  @override
  bool shouldRepaint(_BreathingOrbPainter oldDelegate) =>
      oldDelegate.scale != scale || oldDelegate.color != color;
}
