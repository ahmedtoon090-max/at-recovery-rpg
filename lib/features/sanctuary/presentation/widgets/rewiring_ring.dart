import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/glass_card.dart';

/// 90-day brain rewiring circular sweep arc card.
class RewiringRingCard extends StatelessWidget {
  const RewiringRingCard({
    super.key,
    required this.progress,
    required this.daysClean,
    required this.bestDays,
  });

  final double progress;
  final int daysClean;
  final int bestDays;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final pct = (progress * 100).clamp(0.0, 100.0);
    final daysRemaining = (90 - daysClean).clamp(0, 90);

    return ObsidianCard(
      child: Row(
        children: [
          Semantics(
            label: '90-day neural rewiring ${pct.toStringAsFixed(1)} percent',
            child: ExcludeSemantics(
              child: SizedBox(
                width: 92,
                height: 92,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(92, 92),
                      painter: _RewiringRingPainter(progress: progress),
                    ),
                    Text(
                      '${pct.toStringAsFixed(1)}%',
                      style: AppTypography.monoStat(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '90-Day Neural Reset',
                  style: AppTypography.cardTitle(width),
                ),
                const SizedBox(height: 6),
                Text(
                  daysRemaining == 0
                      ? 'Baseline dopamine pathways restored.'
                      : '$daysRemaining days remaining in this 90-day arc.',
                  style: AppTypography.bodyCopy(width),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _MiniMetricChip(
                      label: 'CURRENT',
                      value: '${daysClean}d',
                      color: AppColors.accentEmeraldGlow,
                    ),
                    _MiniMetricChip(
                      label: 'BEST',
                      value: '${bestDays}d',
                      color: AppColors.accentGold,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetricChip extends StatelessWidget {
  const _MiniMetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.6,
            ),
          ),
          Text(
            value,
            style: AppTypography.monoStat(fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }
}

class _RewiringRingPainter extends CustomPainter {
  _RewiringRingPainter({required this.progress});
  final double progress;

  final Paint _trackPaint = Paint()
    ..color = AppColors.bgElevated
    ..style = PaintingStyle.stroke
    ..strokeWidth = 9
    ..strokeCap = StrokeCap.round;

  final Paint _arcPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 9
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - 12) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(center, radius, _trackPaint);

    final sweep = (progress.clamp(0.015, 1.0)) * math.pi * 2;
    _arcPaint.shader = const SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: math.pi * 1.5,
      colors: [
        AppColors.accentCyan,
        AppColors.accentEmerald,
        AppColors.accentEmeraldGlow,
        AppColors.accentGold,
      ],
    ).createShader(rect);

    canvas.drawArc(rect, -math.pi / 2, sweep, false, _arcPaint);
  }

  @override
  bool shouldRepaint(_RewiringRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
