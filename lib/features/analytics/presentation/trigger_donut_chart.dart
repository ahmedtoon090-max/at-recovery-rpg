import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/glass_card.dart';
import '../../sanctuary/domain/recovery_models.dart';

/// Trigger frequency breakdown donut chart with high-contrast legend.
class TriggerDonutChartCard extends StatelessWidget {
  const TriggerDonutChartCard({
    super.key,
    required this.logs,
  });

  final List<UrgeLog> logs;

  static const List<Color> _palette = [
    AppColors.accentEmerald,
    AppColors.accentCyan,
    AppColors.accentGold,
    AppColors.accentIndigo,
    AppColors.accentEmeraldGlow,
    Color(0xFFF97316),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final counts = <String, int>{};
    for (final log in logs) {
      if (log.type == UrgeLogType.checkIn) continue;
      for (final t in log.triggers) {
        counts[t] = (counts[t] ?? 0) + 1;
      }
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<int>(0, (sum, e) => sum + e.value);

    return ObsidianCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Trigger Drivers',
            style: AppTypography.cardTitle(width),
          ),
          const SizedBox(height: 4),
          Text(
            total == 0
                ? 'Triggers appear here once you log an urge or slip.'
                : 'Share of triggers across $total logged trigger tags.',
            style: AppTypography.bodyCopy(width),
          ),
          const SizedBox(height: 16),
          if (entries.isEmpty)
            const SizedBox(
              height: 150,
              child: Center(
                child: Text(
                  'No trigger breakdown yet',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            Row(
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: PieChart(
                    PieChartData(
                      centerSpaceRadius: 34,
                      sectionsSpace: 3,
                      sections: [
                        for (var i = 0; i < entries.length && i < 6; i++)
                          PieChartSectionData(
                            value: entries[i].value.toDouble(),
                            color: _palette[i % _palette.length],
                            radius: 30,
                            showTitle: false,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < entries.length && i < 6; i++) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: _palette[i % _palette.length],
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  entries[i].key,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${((entries[i].value / total) * 100).round()}%',
                                style: AppTypography.monoStat(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
