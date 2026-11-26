import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/engine/recovery_algorithm.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/glass_card.dart';
import '../../sanctuary/application/app_providers.dart';
import '../../sanctuary/application/recovery_controller.dart';
import 'codex_telemetry_charts.dart';
import 'consistency_heatmap.dart';
import 'danger_hours_chart.dart';
import 'trigger_donut_chart.dart';

/// 6-Panel Predictive Recovery Telemetry Analytics Suite + Archived Streak History.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final desktop = AppTypography.isDesktopWidth(width);
    final asyncState = ref.watch(recoveryProvider);
    final nowLocal = ref.watch(clockProvider).now();
    final nowUtc = nowLocal.toUtc();

    return asyncState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: FilledButton(
          onPressed: () => ref.invalidate(recoveryProvider),
          child: const Text('Retry loading analytics'),
        ),
      ),
      data: (appState) {
        final logs = appState.urgeLogs;
        final history = appState.streakState.streakHistory;
        final risk = PersonalRecoveryAlgorithm.assessRisk(
          state: appState.streakState,
          logs: logs,
          nowUtc: nowUtc,
        );

        final body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!embedded) ...[
              Text('Predictive Recovery Telemetry', style: AppTypography.screenTitle(width)),
              const SizedBox(height: 16),
            ],
            RiskForecastCard(assessment: risk),
            const SizedBox(height: 14),
            if (desktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: DangerHoursChartCard(logs: logs)),
                  const SizedBox(width: 16),
                  Expanded(child: WeeklySlotHeatmapCard(logs: logs)),
                ],
              )
            else ...[
              DangerHoursChartCard(logs: logs),
              const SizedBox(height: 14),
              WeeklySlotHeatmapCard(logs: logs),
            ],
            const SizedBox(height: 14),
            if (desktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: IntensityDecayCard(
                      streakState: appState.streakState,
                      logs: logs,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: TriggerDonutChartCard(logs: logs)),
                ],
              )
            else ...[
              IntensityDecayCard(streakState: appState.streakState, logs: logs),
              const SizedBox(height: 14),
              TriggerDonutChartCard(logs: logs),
            ],
            const SizedBox(height: 14),
            ConsistencyHeatmapCard(
              streakState: appState.streakState,
              logs: logs,
              nowLocal: nowLocal,
            ),
            const SizedBox(height: 14),
            ObsidianCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Archived Fallen Runs', style: AppTypography.cardTitle(width)),
                  const SizedBox(height: 8),
                  if (history.isEmpty)
                    Text('Your active run is your first recorded streak.', style: AppTypography.bodyCopy(width))
                  else
                    for (final item in history) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.bgElevated,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.borderSubtle),
                              ),
                              child: Text(
                                '${item.days}d',
                                style: AppTypography.monoStat(fontSize: 13, color: AppColors.accentGold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${DateFormat('MMM d').format(item.startedAtUtc.toLocal())} to ${DateFormat('MMM d').format(item.endedAtUtc.toLocal())}',
                                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                  ),
                                  if (item.lessonNote.isNotEmpty)
                                    Text(item.lessonNote, style: AppTypography.bodyCopy(width)),
                                ],
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
        );

        if (embedded) return body;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, desktop ? 32 : 120),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: body,
            ),
          ),
        );
      },
    );
  }
}
