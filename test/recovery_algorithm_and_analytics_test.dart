import 'package:flutter_test/flutter_test.dart';

import 'package:at_recovery_rpg/core/engine/recovery_algorithm.dart';
import 'package:at_recovery_rpg/features/sanctuary/domain/recovery_models.dart';

void main() {
  group('PersonalRecoveryAlgorithm & AnalyticsTelemetry', () {
    test('buildBlueprint derives tailored archetype, quests, spells & high baseline risk', () {
      final now = DateTime.utc(2026, 8, 10, 12, 0);
      final bp = PersonalRecoveryAlgorithm.buildBlueprint(
        goal: 'quit_90',
        dangerWindow: 'midday_boredom',
        dominantTrigger: 'stress',
        urgeIntensity: 9,
        weeklyFrequency: 'daily',
        slipPattern: 'post_slip_chaser',
        guidingVow: GuidingVow.discipline,
        customWhy: '',
        preferredAction: 'cold_water',
        lampbearerName: 'Arden',
        reminderHour: 20,
        sleepCutoffHour: 23,
        discreetPreferred: false,
        pinPreferred: false,
        nowUtc: now,
      );

      expect(bp.profile.archetype, 'Storm Breaker');
      expect(bp.profile.baselineRisk, greaterThanOrEqualTo(75));
      expect(bp.recommendedWhy, contains('Discipline'));
      expect(bp.starterSpells.length, 4);
      expect(bp.starterQuests.length, 4);
      expect(bp.bossPriority.name, 'Storm Wraith');
    });

    test('assessRisk spikes during active HALT flags + recent high-intensity urges', () {
      final base = DateTime.utc(2026, 8, 10, 22, 30);
      final state = StreakState.initial(base.subtract(const Duration(days: 1))).copyWith(
        haltFlags: const {'lonely': true, 'tired': true},
        diagnosticProfile: DiagnosticProfile(
          goal: 'quit_90',
          dangerWindow: 'late_night',
          dominantTrigger: 'loneliness',
          urgeIntensity: 7,
          weeklyFrequency: 'several_week',
          slipPattern: 'scroll_spiral',
          guidingVow: GuidingVow.presence,
          preferredAction: 'walk_outside',
          lampbearerName: 'Warden',
          reminderHour: 21,
          sleepCutoffHour: 23,
          discreetPreferred: false,
          pinPreferred: false,
          archetype: 'Solitude Warden',
          baselineRisk: 60,
          completedAtUtc: base,
        ),
      );
      final logs = [
        UrgeLog(
          id: 'u1',
          timestampUtc: base.subtract(const Duration(hours: 4)),
          type: UrgeLogType.urgeDefeated,
          intensity: 8,
          triggers: const ['Loneliness'],
          mood: 'Restless',
          note: 'Resisted wave',
          updatedAtUtc: base,
        ),
      ];

      final risk = PersonalRecoveryAlgorithm.assessRisk(
        state: state,
        logs: logs,
        nowUtc: base,
      );
      expect(risk.score, greaterThanOrEqualTo(70));
      expect(risk.isHighAlert, isTrue);
      expect(risk.suggestedBoss.name, 'Lone Shade');
      expect(risk.weakestHaltTag, 'lonely');
    });

    test('AnalyticsTelemetry computes 7x4 matrix, survival rate, intensity trend & focus correlation', () {
      final t1 = DateTime.utc(2026, 8, 3, 12, 0); // Day 1
      final t2 = DateTime.utc(2026, 8, 4, 12, 0); // Day 2
      final t3 = DateTime.utc(2026, 8, 5, 12, 0); // Day 3 (slip)
      final logs = [
        UrgeLog(
          id: 'w1',
          timestampUtc: t1,
          type: UrgeLogType.urgeDefeated,
          intensity: 8,
          triggers: const ['Late Night'],
          mood: 'Restless',
          note: '',
          updatedAtUtc: t1,
        ),
        UrgeLog(
          id: 'w2',
          timestampUtc: t2,
          type: UrgeLogType.urgeDefeated,
          intensity: 5,
          triggers: const ['Boredom'],
          mood: 'Calm',
          note: '',
          updatedAtUtc: t2,
        ),
        UrgeLog(
          id: 'r1',
          timestampUtc: t3,
          type: UrgeLogType.relapse,
          intensity: 9,
          triggers: const ['Fatigue'],
          mood: 'Drained',
          note: '',
          updatedAtUtc: t3,
        ),
      ];

      final state = StreakState.initial(t1).copyWith(
        pomodoroSessionsCompleted: 4,
        pomodoroDates: {
          formatUtcDateKey(t1): 2,
          formatUtcDateKey(t2): 1,
          formatUtcDateKey(t3): 1,
        },
      );

      final matrix = AnalyticsTelemetry.computeMatrix7x4(logs);
      expect(matrix.length, 7);
      expect(matrix[0].length, 4);
      expect(AnalyticsTelemetry.survivalRatePercent(logs), 67);
      expect(AnalyticsTelemetry.intensityTrend(logs).length, 3);

      final focus = AnalyticsTelemetry.focusCorrelation(state, logs);
      expect(focus.cleanFocusSessions, 3);
      expect(focus.totalFocusSessions, 4);
    });
  });
}
