import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/engine/recovery_algorithm.dart';
import '../../../../core/engine/rpg_juice_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/glass_card.dart';
import '../../sanctuary/domain/recovery_models.dart';

/// Card 1: Live Predictive Risk Forecast Gauge (0-100) + Risk Drivers.
class RiskForecastCard extends StatelessWidget {
  const RiskForecastCard({
    super.key,
    required this.assessment,
  });

  final LiveRiskAssessment assessment;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final color = assessment.isHighAlert
        ? AppColors.accentCrimson
        : (assessment.score >= 45 ? AppColors.accentGold : AppColors.accentEmeraldGlow);

    return ObsidianCard(
      borderColor: color.withValues(alpha: 0.45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 6,
            children: [
              Text('LIVE RISK FORECAST', style: AppTypography.microLabel(width, color: color)),
              Text(
                '${assessment.score} / 100',
                style: AppTypography.monoStat(fontSize: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RpgProgressBar(value: assessment.score / 100.0, fillColor: color, height: 10),
          const SizedBox(height: 10),
          Text(
            'Suggested Mirage Guard: ${assessment.suggestedBoss.name}',
            style: AppTypography.cardTitle(width),
          ),
          const SizedBox(height: 4),
          for (final d in assessment.drivers)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text('• $d', style: AppTypography.bodyCopy(width)),
            ),
        ],
      ),
    );
  }
}

/// Card 2: 7x4 Weekly Vulnerability Matrix (Mon-Sun x Morning/Afternoon/Evening/Night).
class WeeklySlotHeatmapCard extends StatelessWidget {
  const WeeklySlotHeatmapCard({super.key, required this.logs});
  final List<UrgeLog> logs;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final matrix = AnalyticsTelemetry.computeMatrix7x4(logs);
    var peak = 1;
    for (final row in matrix) {
      for (final c in row) {
        if (c > peak) peak = c;
      }
    }
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const slots = ['Morn', 'Aft', 'Eve', 'Night'];

    return ObsidianCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('7×4 WEEKLY VULNERABILITY MATRIX', style: AppTypography.microLabel(width, color: AppColors.accentCyan)),
          const SizedBox(height: 10),
          Row(
            children: [
              const SizedBox(width: 42),
              for (final s in slots)
                Expanded(
                  child: Text(
                    s,
                    textAlign: TextAlign.center,
                    style: AppTypography.monoStat(fontSize: 10, color: AppColors.textMuted),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          for (var d = 0; d < 7; d++) ...[
            Row(
              children: [
                SizedBox(
                  width: 42,
                  child: Text(
                    days[d],
                    style: AppTypography.monoStat(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ),
                for (var sl = 0; sl < 4; sl++)
                  Expanded(
                    child: Container(
                      height: 22,
                      margin: const EdgeInsets.all(2),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: matrix[d][sl] == 0
                            ? AppColors.bgElevated
                            : Color.lerp(
                                AppColors.accentGold.withValues(alpha: 0.25),
                                AppColors.accentCrimson.withValues(alpha: 0.85),
                                (matrix[d][sl] / peak).clamp(0.0, 1.0),
                              ),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: AppColors.borderSubtle, width: 0.5),
                      ),
                      child: Text(
                        matrix[d][sl] == 0 ? '' : '${matrix[d][sl]}',
                        style: AppTypography.monoStat(fontSize: 10, color: AppColors.textPrimary),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Card 3: Urge Intensity Decay Curve + Battle Survival Rate + Focus Correlation.
class IntensityDecayCard extends StatelessWidget {
  const IntensityDecayCard({
    super.key,
    required this.streakState,
    required this.logs,
  });

  final StreakState streakState;
  final List<UrgeLog> logs;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final trend = AnalyticsTelemetry.intensityTrend(logs);
    final survival = AnalyticsTelemetry.survivalRatePercent(logs);
    final focus = AnalyticsTelemetry.focusCorrelation(streakState, logs);

    return ObsidianCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            runSpacing: 6,
            children: [
              Text('INTENSITY DECAY & FOCUS CORRELATION', style: AppTypography.microLabel(width, color: AppColors.accentEmeraldGlow)),
              Text(
                'Survival: $survival% · Clean Focus: ${focus.cleanFocusSessions}/${focus.totalFocusSessions}',
                style: AppTypography.monoStat(fontSize: 11, color: AppColors.accentGold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 10,
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final idx = v.round();
                        if (idx < 0 || idx >= trend.length) return const SizedBox.shrink();
                        return Text(
                          trend[idx].label,
                          style: AppTypography.monoStat(fontSize: 10, color: AppColors.textMuted),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: AppColors.accentCyan,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.accentCyan.withValues(alpha: 0.14),
                    ),
                    spots: [
                      for (var i = 0; i < trend.length; i++)
                        FlSpot(i.toDouble(), trend[i].avgIntensity),
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
