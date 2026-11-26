import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/glass_card.dart';
import '../../sanctuary/domain/recovery_models.dart';

/// 24-hour bar chart highlighting peak vulnerability windows across logs.
class DangerHoursChartCard extends StatelessWidget {
  const DangerHoursChartCard({
    super.key,
    required this.logs,
  });

  final List<UrgeLog> logs;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final buckets = List<int>.filled(24, 0);
    for (final log in logs) {
      if (log.type == UrgeLogType.urgeDefeated ||
          log.type == UrgeLogType.relapse) {
        final hour = log.timestampUtc.toLocal().hour;
        buckets[hour]++;
      }
    }
    final maxCount = buckets.fold<int>(0, (a, b) => a > b ? a : b);

    return ObsidianCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'When Do Urges Peak (24h)?',
            style: AppTypography.cardTitle(width),
          ),
          const SizedBox(height: 4),
          Text(
            maxCount == 0
                ? 'Log urges or slips to map your vulnerable hours.'
                : 'Hourly distribution of logged urges and slips (local time).',
            style: AppTypography.bodyCopy(width),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: maxCount == 0
                ? const Center(
                    child: Text(
                      'No hourly trigger data yet',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      maxY: (maxCount + 1).toDouble(),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (_) => const FlLine(
                          color: AppColors.borderSubtle,
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(),
                        rightTitles: const AxisTitles(),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 26,
                            interval: 1,
                            getTitlesWidget: (v, _) => Text(
                              v.toInt().toString(),
                              style: AppTypography.monoStat(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 6,
                            getTitlesWidget: (v, _) {
                              final h = v.toInt();
                              if (h % 6 != 0) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  '${h.toString().padLeft(2, '0')}h',
                                  style: AppTypography.monoStat(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: [
                        for (var h = 0; h < 24; h++)
                          BarChartGroupData(
                            x: h,
                            barRods: [
                              BarChartRodData(
                                toY: buckets[h].toDouble(),
                                width: 6,
                                borderRadius: BorderRadius.circular(4),
                                color: buckets[h] == maxCount && maxCount > 0
                                    ? AppColors.accentGold
                                    : AppColors.accentCyan,
                              ),
                            ],
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
