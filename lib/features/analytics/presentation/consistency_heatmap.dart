import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/glass_card.dart';
import '../../sanctuary/domain/recovery_models.dart';

/// 90-day GitHub-style clean consistency heatmap grid.
class ConsistencyHeatmapCard extends StatelessWidget {
  const ConsistencyHeatmapCard({
    super.key,
    required this.streakState,
    required this.logs,
    required this.nowLocal,
  });

  final StreakState streakState;
  final List<UrgeLog> logs;
  final DateTime nowLocal;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final pledgeSet = streakState.pledgeDates.toSet();
    final relapseDates = <String>{
      for (final log in logs)
        if (log.type == UrgeLogType.relapse) formatUtcDateKey(log.timestampUtc),
    };
    final streakStartLocal = streakState.startTimeUtc.toLocal();
    final todayMidnight = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);

    final cells = <Color>[];
    for (var offset = 89; offset >= 0; offset--) {
      final day = todayMidnight.subtract(Duration(days: offset));
      final key = formatUtcDateKey(day);
      final isAfterStreakStart = !day.isBefore(
        DateTime(
          streakStartLocal.year,
          streakStartLocal.month,
          streakStartLocal.day,
        ),
      );

      if (relapseDates.contains(key)) {
        cells.add(AppColors.accentGold.withValues(alpha: 0.7));
      } else if (pledgeSet.contains(key)) {
        cells.add(AppColors.accentEmeraldGlow);
      } else if (isAfterStreakStart) {
        cells.add(AppColors.accentEmerald.withValues(alpha: 0.55));
      } else {
        cells.add(AppColors.bgElevated);
      }
    }

    return ObsidianCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '90-Day Clean Consistency',
                  style: AppTypography.cardTitle(width),
                ),
              ),
              Text(
                '${streakState.pledgeDates.length} pledges',
                style: AppTypography.monoStat(
                  fontSize: 12,
                  color: AppColors.accentEmeraldGlow,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              const cols = 15;
              const spacing = 4.0;
              final tileSize =
                  ((constraints.maxWidth - (cols - 1) * spacing) / cols)
                      .clamp(10.0, 24.0);
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final color in cells)
                    Container(
                      width: tileSize,
                      height: tileSize,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppColors.borderSubtle,
                          width: 0.5,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _LegendDot(color: AppColors.bgElevated, label: 'Inactive'),
              _LegendDot(
                color: AppColors.accentEmerald,
                label: 'Clean Day',
              ),
              _LegendDot(
                color: AppColors.accentEmeraldGlow,
                label: 'Pledged',
              ),
              _LegendDot(color: AppColors.accentGold, label: 'Reflection'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: AppColors.borderSubtle),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
