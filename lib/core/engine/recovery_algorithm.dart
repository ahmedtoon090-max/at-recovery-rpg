import 'dart:math' as math;

import '../../features/sanctuary/domain/recovery_models.dart';

class DiagnosticBlueprint {
  const DiagnosticBlueprint({
    required this.profile,
    required this.projectedFreedomDateUtc,
    required this.starterQuests,
    required this.starterSpells,
    required this.recommendedWhy,
    required this.recommendedPomodoroMinutes,
    required this.bossPriority,
  });

  final DiagnosticProfile profile;
  final DateTime projectedFreedomDateUtc;
  final List<QuestItem> starterQuests;
  final List<CounterSpell> starterSpells;
  final String recommendedWhy;
  final int recommendedPomodoroMinutes;
  final UrgeBossSpec bossPriority;
}

class LiveRiskAssessment {
  const LiveRiskAssessment({
    required this.score,
    required this.drivers,
    required this.isHighAlert,
    required this.suggestedBoss,
    required this.primarySpell,
    required this.weakestHaltTag,
  });

  final int score;
  final List<String> drivers;
  final bool isHighAlert;
  final UrgeBossSpec suggestedBoss;
  final CounterSpell? primarySpell;
  final String? weakestHaltTag;
}

class DailyIntensityPoint {
  const DailyIntensityPoint({required this.label, required this.avgIntensity});
  final String label;
  final double avgIntensity;
}

/// Deterministic Recovery Intelligence & Adaptive RPG Engine.
abstract final class PersonalRecoveryAlgorithm {
  static DiagnosticBlueprint buildBlueprint({
    required String goal,
    required String dangerWindow,
    required String dominantTrigger,
    required int urgeIntensity,
    required String weeklyFrequency,
    required String slipPattern,
    required GuidingVow guidingVow,
    required String customWhy,
    required String preferredAction,
    required String lampbearerName,
    required int reminderHour,
    required int sleepCutoffHour,
    required bool discreetPreferred,
    required bool pinPreferred,
    required DateTime nowUtc,
  }) {
    final archetype = switch ((dangerWindow, dominantTrigger)) {
      ('late_night' || 'alone_room', _) => 'Nocturnal Sentinel',
      (_, 'stress') => 'Storm Breaker',
      (_, 'loneliness') => 'Solitude Warden',
      _ => 'Focus Reclaimer',
    };

    var baseRisk = urgeIntensity * 5;
    if (weeklyFrequency == 'daily') baseRisk += 25;
    if (weeklyFrequency == 'several_week') baseRisk += 16;
    if (weeklyFrequency == 'weekly') baseRisk += 8;
    if (slipPattern == 'post_slip_chaser') baseRisk += 10;
    final baselineRisk = baseRisk.clamp(15, 95);

    final actionText = switch (preferredAction) {
      'cold_water' => 'Splash ice-cold water for 20s & step outside 3 minutes.',
      'walk_outside' => 'Put shoes on immediately and walk briskly for 3 minutes.',
      'pomodoro_sprint' => 'Lock feeds and launch a 25-min Focus Pomodoro sprint.',
      _ => 'Drop right now for 20 crisp pushups + drink full water glass.',
    };

    final triggerLabel = switch (dominantTrigger) {
      'stress' => 'Overwhelmed or stressed after work',
      'loneliness' => 'Quiet isolation & disconnection',
      'social_media' => 'Doom-scrolling short feeds & reels',
      'fatigue' => 'Late exhaustion lowering self-control',
      _ => 'Boredom & restlessness',
    };

    final windowCue = switch (dangerWindow) {
      'late_night' => 'Late night (${sleepCutoffHour.toString().padLeft(2, '0')}:00+)',
      'alone_room' => 'Alone in bedroom with unlocked screen',
      'post_stress' => 'Decompressing immediately after heavy stress',
      'morning' => 'Slow morning waking hours in bed',
      _ => 'Midday boredom slump',
    };

    final profile = DiagnosticProfile(
      goal: goal,
      dangerWindow: dangerWindow,
      dominantTrigger: dominantTrigger,
      urgeIntensity: urgeIntensity,
      weeklyFrequency: weeklyFrequency,
      slipPattern: slipPattern,
      guidingVow: guidingVow,
      preferredAction: preferredAction,
      lampbearerName: lampbearerName.trim().isEmpty ? 'Warden' : lampbearerName.trim(),
      reminderHour: reminderHour,
      sleepCutoffHour: sleepCutoffHour,
      discreetPreferred: discreetPreferred,
      pinPreferred: pinPreferred,
      archetype: archetype,
      baselineRisk: baselineRisk,
      completedAtUtc: nowUtc.toUtc(),
    );

    final why = customWhy.trim().isEmpty
        ? '${guidingVow.title}: ${guidingVow.mantra}'
        : customWhy.trim();

    final spells = [
      CounterSpell(id: 'spell_primary_trigger', triggerCue: triggerLabel, actionPlan: actionText, updatedAtUtc: nowUtc),
      CounterSpell(id: 'spell_danger_window', triggerCue: windowCue, actionPlan: 'Dock phone outside sleeping area by ${sleepCutoffHour.toString().padLeft(2, '0')}:00.', updatedAtUtc: nowUtc),
      CounterSpell(id: 'spell_breath_anchor', triggerCue: 'Sudden urge spike >= $urgeIntensity/10 intensity', actionPlan: 'Run 1 Mirage Ambush Breath-Wave (4-7-8) + read Vow.', updatedAtUtc: nowUtc),
      CounterSpell(id: 'spell_chaser_shield', triggerCue: 'Slip chaser thought ("start Monday instead")', actionPlan: 'Log Campfire Post-Mortem immediately (+20 WIS).', updatedAtUtc: nowUtc),
    ];

    final pomoMin = preferredAction == 'pomodoro_sprint' ? 50 : 25;
    final quests = [
      QuestItem(id: 'quest_morning_pledge', title: 'Morning Anchor Pledge', description: 'Seal your daily vow before noon.', xpReward: 25, goldReward: 10, lastCompletedDate: null, streakCount: 0, updatedAtUtc: nowUtc),
      QuestItem(id: 'quest_deep_focus', title: '${pomoMin}m Focus Sprint', description: 'Complete one focused ATP Pomodoro session.', xpReward: 35, goldReward: 15, lastCompletedDate: null, streakCount: 0, updatedAtUtc: nowUtc),
      QuestItem(id: 'quest_device_curfew', title: 'Curfew Screen Boundary', description: 'Park devices outside the bedroom by ${sleepCutoffHour.toString().padLeft(2, '0')}:00.', xpReward: 30, goldReward: 12, lastCompletedDate: null, streakCount: 0, updatedAtUtc: nowUtc),
      QuestItem(id: 'quest_physical_vitality', title: 'Trigger Reset Strike', description: actionText, xpReward: 30, goldReward: 12, lastCompletedDate: null, streakCount: 0, updatedAtUtc: nowUtc),
    ];

    final boss = _bossForTrigger(dominantTrigger, sleepCutoffHour);
    return DiagnosticBlueprint(
      profile: profile,
      projectedFreedomDateUtc: nowUtc.toUtc().add(const Duration(days: 90)),
      starterQuests: quests,
      starterSpells: spells,
      recommendedWhy: why,
      recommendedPomodoroMinutes: pomoMin,
      bossPriority: boss,
    );
  }

  static LiveRiskAssessment assessRisk({
    required StreakState state,
    required List<UrgeLog> logs,
    required DateTime nowUtc,
  }) {
    final local = nowUtc.toLocal();
    final hour = local.hour;
    final drivers = <String>[];
    var score = 12;

    // 1. Circadian proximity to learned peak urge hour OR user danger window
    final profile = state.diagnosticProfile;
    final inDangerWindow = _isHourInWindow(hour, profile?.dangerWindow ?? 'late_night');
    final learnedPeakHour = _learnedPeakHour(logs);
    if (inDangerWindow) {
      score += 30;
      drivers.add('Active danger window (${hour.toString().padLeft(2, '0')}:00)');
    } else if (learnedPeakHour != null && (learnedPeakHour - hour).abs() <= 1) {
      score += 24;
      drivers.add('Near historical peak urge hour (${learnedPeakHour.toString().padLeft(2, '0')}:00)');
    }

    // 2. Active HALT flags
    final activeHalts = kHaltOrbs.where((h) => state.haltFlags[h.id] == true).toList();
    if (activeHalts.isNotEmpty) {
      score += math.min(35, activeHalts.length * 14);
      drivers.add('HALT alert: ${activeHalts.map((h) => h.label).join(', ')}');
    }

    // 3. Recent 48h urge intensity velocity
    final cutoff = nowUtc.subtract(const Duration(hours: 48));
    final recentHigh = logs
        .where((l) => !l.isDeleted && l.timestampUtc.isAfter(cutoff) && l.intensity >= 6)
        .length;
    if (recentHigh > 0) {
      score += math.min(20, recentHigh * 8);
      drivers.add('$recentHigh high-intensity urges in past 48h');
    }

    // 4. Early-arc vulnerability (< 7 days)
    final days = state.currentDays(nowUtc);
    if (days < 3) {
      score += 15;
      drivers.add('Early 72h neuro-recalibration phase');
    } else if (days < 7) {
      score += 8;
    }

    final clamped = score.clamp(5, 98);
    if (drivers.isEmpty) {
      drivers.add('Circadian & HALT indicators steady');
    }

    final boss = profile != null
        ? _bossForTrigger(profile.dominantTrigger, hour)
        : _bossForHour(hour);
    final activeSpells = state.activeCounterSpells;
    return LiveRiskAssessment(
      score: clamped,
      drivers: drivers,
      isHighAlert: clamped >= 70,
      suggestedBoss: boss,
      primarySpell: activeSpells.isNotEmpty ? activeSpells.first : null,
      weakestHaltTag: activeHalts.isNotEmpty ? activeHalts.first.id : null,
    );
  }

  static bool _isHourInWindow(int hour, String window) => switch (window) {
        'late_night' => hour >= 21 || hour <= 3,
        'alone_room' => hour >= 20 || hour <= 6,
        'post_stress' => hour >= 17 && hour <= 21,
        'morning' => hour >= 6 && hour <= 10,
        'midday_boredom' => hour >= 12 && hour <= 16,
        _ => hour >= 22 || hour <= 2,
      };

  static int? _learnedPeakHour(List<UrgeLog> logs) {
    final counts = List<int>.filled(24, 0);
    for (final l in logs) {
      if (l.isDeleted || l.type == UrgeLogType.checkIn) continue;
      counts[l.timestampUtc.toLocal().hour]++;
    }
    var bestHour = -1;
    var bestCount = 0;
    for (var h = 0; h < 24; h++) {
      if (counts[h] > bestCount) {
        bestCount = counts[h];
        bestHour = h;
      }
    }
    return bestCount > 0 ? bestHour : null;
  }

  static UrgeBossSpec _bossForTrigger(String trigger, int hour) => switch (trigger) {
        'stress' => kUrgeBosses[2], // Storm Wraith
        'loneliness' => kUrgeBosses[3], // Lone Shade
        'social_media' => kUrgeBosses[4], // Fog Weaver
        'fatigue' => hour >= 20 || hour <= 5 ? kUrgeBosses[0] : kUrgeBosses[1],
        _ => hour >= 21 || hour <= 4 ? kUrgeBosses[0] : kUrgeBosses[1],
      };

  static UrgeBossSpec _bossForHour(int hour) {
    if (hour >= 22 || hour < 5) return kUrgeBosses[0];
    if (hour < 11) return kUrgeBosses[4];
    if (hour < 16) return kUrgeBosses[1];
    if (hour < 19) return kUrgeBosses[2];
    return kUrgeBosses[3];
  }
}

/// Telemetry & predictive chart aggregators for the Codex Analytics dashboard.
abstract final class AnalyticsTelemetry {
  /// Returns 7 weekdays (0=Mon..6=Sun) x 4 slots (Morning, Afternoon, Evening, Night).
  static List<List<int>> computeMatrix7x4(List<UrgeLog> logs) {
    final matrix = List.generate(7, (_) => List<int>.filled(4, 0));
    for (final l in logs) {
      if (l.isDeleted || l.type == UrgeLogType.checkIn) continue;
      final local = l.timestampUtc.toLocal();
      final dayIdx = (local.weekday - 1).clamp(0, 6);
      final h = local.hour;
      final slot = (h >= 6 && h < 12)
          ? 0
          : (h >= 12 && h < 18)
              ? 1
              : (h >= 18 && h < 22)
                  ? 2
                  : 3;
      matrix[dayIdx][slot]++;
    }
    return matrix;
  }

  static int survivalRatePercent(List<UrgeLog> logs) {
    var won = 0;
    var slips = 0;
    for (final l in logs) {
      if (l.isDeleted) continue;
      if (l.type == UrgeLogType.urgeDefeated) won++;
      if (l.type == UrgeLogType.relapse) slips++;
    }
    final total = won + slips;
    return total == 0 ? 100 : ((won / total) * 100).round();
  }

  static List<DailyIntensityPoint> intensityTrend(List<UrgeLog> logs) {
    final events = logs
        .where((l) => !l.isDeleted && l.type != UrgeLogType.checkIn)
        .toList()
      ..sort((a, b) => a.timestampUtc.compareTo(b.timestampUtc));
    if (events.isEmpty) {
      return const [
        DailyIntensityPoint(label: 'Start', avgIntensity: 0),
      ];
    }
    final recent = events.length > 8 ? events.sublist(events.length - 8) : events;
    return [
      for (var i = 0; i < recent.length; i++)
        DailyIntensityPoint(
          label: '#${i + 1}',
          avgIntensity: recent[i].intensity.toDouble(),
        ),
    ];
  }

  static ({int cleanFocusSessions, int totalFocusSessions}) focusCorrelation(
    StreakState state,
    List<UrgeLog> logs,
  ) {
    final slipDays = logs
        .where((l) => !l.isDeleted && l.type == UrgeLogType.relapse)
        .map((l) => formatUtcDateKey(l.timestampUtc))
        .toSet();
    var cleanFocus = 0;
    state.pomodoroDates.forEach((dateKey, count) {
      if (!slipDays.contains(dateKey)) cleanFocus += count;
    });
    final total = math.max(state.pomodoroSessionsCompleted, cleanFocus);
    return (cleanFocusSessions: cleanFocus, totalFocusSessions: total);
  }
}
