import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Four I Am Sober-style real-time cascading time-unit progress bars.
class CascadingTimeBars extends StatelessWidget {
  const CascadingTimeBars({
    super.key,
    required this.elapsed,
    required this.nextMilestoneDays,
  });

  final Duration elapsed;
  final int nextMilestoneDays;

  @override
  Widget build(BuildContext context) {
    final days = elapsed.inDays;
    final hours = elapsed.inHours % 24;
    final minutes = elapsed.inMinutes % 60;
    final seconds = elapsed.inSeconds % 60;

    final dayTarget = nextMilestoneDays <= 0 ? 90 : nextMilestoneDays;
    final dayRatio = (days / dayTarget).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _UnitBar(
          label: 'DAYS',
          valueText: '$days / ${dayTarget}d',
          ratio: dayRatio,
          color: AppColors.accentEmerald,
        ),
        const SizedBox(height: 8),
        _UnitBar(
          label: 'HOURS',
          valueText: '${hours.toString().padLeft(2, '0')} / 24h',
          ratio: hours / 24.0,
          color: AppColors.accentCyan,
        ),
        const SizedBox(height: 8),
        _UnitBar(
          label: 'MINUTES',
          valueText: '${minutes.toString().padLeft(2, '0')} / 60m',
          ratio: minutes / 60.0,
          color: AppColors.accentIndigo,
        ),
        const SizedBox(height: 8),
        _UnitBar(
          label: 'SECONDS',
          valueText: '${seconds.toString().padLeft(2, '0')} / 60s',
          ratio: seconds / 60.0,
          color: AppColors.accentGold,
        ),
      ],
    );
  }
}

class _UnitBar extends StatelessWidget {
  const _UnitBar({
    required this.label,
    required this.valueText,
    required this.ratio,
    required this.color,
  });

  final String label;
  final String valueText;
  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final clamped = ratio.clamp(0.02, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTypography.microLabel(
                MediaQuery.sizeOf(context).width,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              valueText,
              style: AppTypography.monoStat(
                fontSize: 12,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 7,
            color: AppColors.bgElevated,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: clamped,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
