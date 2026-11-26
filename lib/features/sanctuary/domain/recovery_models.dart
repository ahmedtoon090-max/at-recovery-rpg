import 'dart:math' as math;

import 'eclipse_catalog.dart';

export 'eclipse_catalog.dart';

String formatUtcDateKey(DateTime dt) {
  final local = dt.toLocal();
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Gollwitzer IF -> THEN implementation-intention spell usable in Mirage Ambush.
class CounterSpell {
  const CounterSpell({
    required this.id,
    required this.triggerCue,
    required this.actionPlan,
    this.rank = 1,
    this.casts = 0,
    this.equipped = true,
    required this.updatedAtUtc,
    this.isDeleted = false,
  });

  final String id;
  final String triggerCue;
  final String actionPlan;
  final int rank;
  final int casts;
  final bool equipped;
  final DateTime updatedAtUtc;
  final bool isDeleted;

  String get romanRank => switch (rank.clamp(1, 5)) {
        1 => 'I',
        2 => 'II',
        3 => 'III',
        4 => 'IV',
        _ => 'V',
      };

  CounterSpell copyWith({
    String? triggerCue,
    String? actionPlan,
    int? rank,
    int? casts,
    bool? equipped,
    DateTime? updatedAtUtc,
    bool? isDeleted,
  }) =>
      CounterSpell(
        id: id,
        triggerCue: triggerCue ?? this.triggerCue,
        actionPlan: actionPlan ?? this.actionPlan,
        rank: rank ?? this.rank,
        casts: casts ?? this.casts,
        equipped: equipped ?? this.equipped,
        updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
        isDeleted: isDeleted ?? this.isDeleted,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'triggerCue': triggerCue,
        'actionPlan': actionPlan,
        'rank': rank,
        'casts': casts,
        'equipped': equipped,
        'updatedAtUtc': updatedAtUtc.toUtc().toIso8601String(),
        'isDeleted': isDeleted,
      };

  factory CounterSpell.fromJson(Map<String, dynamic> json) => CounterSpell(
        id: json['id'] as String,
        triggerCue: json['triggerCue'] as String? ?? 'Late-night urge',
        actionPlan: json['actionPlan'] as String? ?? '20 pushups + cold water',
        rank: (json['rank'] as num?)?.toInt() ?? 1,
        casts: (json['casts'] as num?)?.toInt() ?? 0,
        equipped: json['equipped'] as bool? ?? true,
        updatedAtUtc: DateTime.parse(json['updatedAtUtc'] as String).toUtc(),
        isDeleted: json['isDeleted'] as bool? ?? false,
      );

  static List<CounterSpell> defaults(DateTime nowUtc) => [
        CounterSpell(
          id: 'spell_night_hallway',
          triggerCue: 'Alone late at night after 10 PM',
          actionPlan: 'Dock phone outside the bedroom & complete 20 pushups.',
          updatedAtUtc: nowUtc,
        ),
        CounterSpell(
          id: 'spell_bored_scroll',
          triggerCue: 'Boredom & aimless social scrolling',
          actionPlan: 'Lock phone, splash cold water & walk outside for 3 minutes.',
          updatedAtUtc: nowUtc,
        ),
        CounterSpell(
          id: 'spell_stress_tension',
          triggerCue: 'Overwhelmed or stressed after work',
          actionPlan: 'Two physiological sighs + 25m deep focus Pomodoro sprint.',
          updatedAtUtc: nowUtc,
        ),
        CounterSpell(
          id: 'spell_chaser_guard',
          triggerCue: 'Post-slip chaser illusion ("day already ruined")',
          actionPlan: 'Log Campfire lesson honestly (+20 WIS) and seal immediate reset.',
          updatedAtUtc: nowUtc,
        ),
      ];
}

/// Persisted answers & personalized blueprint from the 8-card Mirror of Truth wizard.
class DiagnosticProfile {
  const DiagnosticProfile({
    required this.goal,
    required this.dangerWindow,
    required this.dominantTrigger,
    required this.urgeIntensity,
    required this.weeklyFrequency,
    required this.slipPattern,
    required this.guidingVow,
    required this.preferredAction,
    required this.lampbearerName,
    required this.reminderHour,
    required this.sleepCutoffHour,
    required this.discreetPreferred,
    required this.pinPreferred,
    required this.archetype,
    required this.baselineRisk,
    required this.completedAtUtc,
  });

  final String goal;
  final String dangerWindow;
  final String dominantTrigger;
  final int urgeIntensity;
  final String weeklyFrequency;
  final String slipPattern;
  final GuidingVow guidingVow;
  final String preferredAction;
  final String lampbearerName;
  final int reminderHour;
  final int sleepCutoffHour;
  final bool discreetPreferred;
  final bool pinPreferred;
  final String archetype;
  final int baselineRisk;
  final DateTime completedAtUtc;

  Map<String, dynamic> toJson() => {
        'goal': goal,
        'dangerWindow': dangerWindow,
        'dominantTrigger': dominantTrigger,
        'urgeIntensity': urgeIntensity,
        'weeklyFrequency': weeklyFrequency,
        'slipPattern': slipPattern,
        'guidingVow': guidingVow.name,
        'preferredAction': preferredAction,
        'lampbearerName': lampbearerName,
        'reminderHour': reminderHour,
        'sleepCutoffHour': sleepCutoffHour,
        'discreetPreferred': discreetPreferred,
        'pinPreferred': pinPreferred,
        'archetype': archetype,
        'baselineRisk': baselineRisk,
        'completedAtUtc': completedAtUtc.toUtc().toIso8601String(),
      };

  factory DiagnosticProfile.fromJson(Map<String, dynamic> json) =>
      DiagnosticProfile(
        goal: json['goal'] as String? ?? 'quit_90',
        dangerWindow: json['dangerWindow'] as String? ?? 'late_night',
        dominantTrigger: json['dominantTrigger'] as String? ?? 'boredom',
        urgeIntensity: (json['urgeIntensity'] as num?)?.toInt() ?? 6,
        weeklyFrequency: json['weeklyFrequency'] as String? ?? 'several_week',
        slipPattern: json['slipPattern'] as String? ?? 'scroll_spiral',
        guidingVow: GuidingVow.fromName(json['guidingVow'] as String? ?? 'clarity'),
        preferredAction: json['preferredAction'] as String? ?? 'pushups',
        lampbearerName: json['lampbearerName'] as String? ?? 'Warden',
        reminderHour: (json['reminderHour'] as num?)?.toInt() ?? 21,
        sleepCutoffHour: (json['sleepCutoffHour'] as num?)?.toInt() ?? 23,
        discreetPreferred: json['discreetPreferred'] as bool? ?? false,
        pinPreferred: json['pinPreferred'] as bool? ?? false,
        archetype: json['archetype'] as String? ?? 'Nocturnal Sentinel',
        baselineRisk: (json['baselineRisk'] as num?)?.toInt() ?? 52,
        completedAtUtc: DateTime.parse(json['completedAtUtc'] as String).toUtc(),
      );
}

class CustomReward {
  const CustomReward({
    required this.id,
    required this.title,
    required this.costGold,
    this.timesClaimed = 0,
    required this.updatedAtUtc,
    this.isDeleted = false,
  });

  final String id;
  final String title;
  final int costGold;
  final int timesClaimed;
  final DateTime updatedAtUtc;
  final bool isDeleted;

  CustomReward copyWith({
    String? title,
    int? costGold,
    int? timesClaimed,
    DateTime? updatedAtUtc,
    bool? isDeleted,
  }) =>
      CustomReward(
        id: id,
        title: title ?? this.title,
        costGold: costGold ?? this.costGold,
        timesClaimed: timesClaimed ?? this.timesClaimed,
        updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
        isDeleted: isDeleted ?? this.isDeleted,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'costGold': costGold,
        'timesClaimed': timesClaimed,
        'updatedAtUtc': updatedAtUtc.toUtc().toIso8601String(),
        'isDeleted': isDeleted,
      };

  factory CustomReward.fromJson(Map<String, dynamic> json) => CustomReward(
        id: json['id'] as String,
        title: json['title'] as String,
        costGold: (json['costGold'] as num?)?.toInt() ?? 50,
        timesClaimed: (json['timesClaimed'] as num?)?.toInt() ?? 0,
        updatedAtUtc: DateTime.parse(json['updatedAtUtc'] as String).toUtc(),
        isDeleted: json['isDeleted'] as bool? ?? false,
      );

  static List<CustomReward> defaults(DateTime nowUtc) => [
        CustomReward(id: 'rew_gaming_hour', title: '1 Hour Guilt-Free Gaming', costGold: 80, updatedAtUtc: nowUtc),
        CustomReward(id: 'rew_specialty_coffee', title: 'Favorite Coffee or Treat', costGold: 40, updatedAtUtc: nowUtc),
      ];
}

class StreakRecord {
  const StreakRecord({
    required this.id,
    required this.startedAtUtc,
    required this.endedAtUtc,
    required this.durationSeconds,
    required this.triggers,
    required this.mood,
    required this.lessonNote,
    required this.updatedAtUtc,
  });

  final String id;
  final DateTime startedAtUtc;
  final DateTime endedAtUtc;
  final int durationSeconds;
  final List<String> triggers;
  final String mood;
  final String lessonNote;
  final DateTime updatedAtUtc;

  int get days => durationSeconds ~/ 86400;

  Map<String, dynamic> toJson() => {
        'id': id,
        'startedAtUtc': startedAtUtc.toUtc().toIso8601String(),
        'endedAtUtc': endedAtUtc.toUtc().toIso8601String(),
        'durationSeconds': durationSeconds,
        'triggers': triggers,
        'mood': mood,
        'lessonNote': lessonNote,
        'updatedAtUtc': updatedAtUtc.toUtc().toIso8601String(),
      };

  factory StreakRecord.fromJson(Map<String, dynamic> json) => StreakRecord(
        id: json['id'] as String,
        startedAtUtc: DateTime.parse(json['startedAtUtc'] as String).toUtc(),
        endedAtUtc: DateTime.parse(json['endedAtUtc'] as String).toUtc(),
        durationSeconds: (json['durationSeconds'] as num).toInt(),
        triggers: (json['triggers'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(),
        mood: json['mood'] as String? ?? '',
        lessonNote: json['lessonNote'] as String? ?? '',
        updatedAtUtc: DateTime.parse(json['updatedAtUtc'] as String).toUtc(),
      );
}

/// Core v3.0 "Eclipse Chronicle" state with backward-compatible v1/v2 migration.
class StreakState {
  const StreakState({
    required this.startTimeUtc,
    required this.bestStreakSeconds,
    required this.totalCleanDays,
    required this.lastPledgeDate,
    required this.xp,
    required this.gold,
    required this.whyIStarted,
    required this.streakHistory,
    required this.pledgeDates,
    required this.pomodoroSessionsCompleted,
    required this.updatedAtUtc,
    this.bossKills = 0,
    this.wilXp = 0,
    this.focXp = 0,
    this.vitXp = 0,
    this.wisXp = 0,
    this.castleStructures = const {},
    this.claimedJourneyNodes = const [],
    this.shieldChecks = const {},
    this.milestoneUnlocks = const {},
    this.unlockedSkills = const [],
    this.ownedCosmetics = const ['orb_obsidian_emerald', 'aura_ember'],
    this.equippedOrbId = 'orb_obsidian_emerald',
    this.equippedAuraId = 'aura_ember',
    this.customRewards = const [],
    this.claimedDailyChestDate,
    this.lampbearerName = 'Warden',
    this.guidingVow = GuidingVow.clarity,
    this.prologueCompleted = false,
    this.chronicleChoices = const {},
    this.counterSpells = const [],
    this.haltFlags = const {},
    this.pomodoroDates = const {},
    this.diagnosticProfile,
  });

  factory StreakState.initial(DateTime nowUtc) => StreakState(
        startTimeUtc: nowUtc.toUtc(),
        bestStreakSeconds: 0,
        totalCleanDays: 0,
        lastPledgeDate: null,
        xp: 0,
        gold: 0,
        whyIStarted: 'Protect my focus, clarity, and self-respect every day.',
        streakHistory: const [],
        pledgeDates: const [],
        pomodoroSessionsCompleted: 0,
        updatedAtUtc: nowUtc.toUtc(),
        customRewards: CustomReward.defaults(nowUtc.toUtc()),
        counterSpells: CounterSpell.defaults(nowUtc.toUtc()),
      );

  final DateTime startTimeUtc;
  final int bestStreakSeconds;
  final int totalCleanDays;
  final String? lastPledgeDate;
  final int xp;
  final int gold;
  final String whyIStarted;
  final List<StreakRecord> streakHistory;
  final List<String> pledgeDates;
  final int pomodoroSessionsCompleted;
  final DateTime updatedAtUtc;
  final int bossKills;
  final int wilXp;
  final int focXp;
  final int vitXp;
  final int wisXp;
  final Map<String, int> castleStructures;
  final List<String> claimedJourneyNodes;
  final Map<String, String> shieldChecks;
  final Map<String, String> milestoneUnlocks;
  final List<String> unlockedSkills;
  final List<String> ownedCosmetics;
  final String equippedOrbId;
  final String equippedAuraId;
  final List<CustomReward> customRewards;
  final String? claimedDailyChestDate;
  final String lampbearerName;
  final GuidingVow guidingVow;
  final bool prologueCompleted;
  final Map<String, String> chronicleChoices;
  final List<CounterSpell> counterSpells;
  final Map<String, bool> haltFlags;
  final Map<String, int> pomodoroDates;
  final DiagnosticProfile? diagnosticProfile;

  int get level => 1 + (xp ~/ 100);
  int get xpIntoLevel => xp % 100;
  int get xpToNextLevel => 100 - xpIntoLevel;
  int get availableSkillPoints => math.max(0, level - unlockedSkills.length);
  bool hasSkill(String id) => unlockedSkills.contains(id);
  int structureLevel(String id) => castleStructures[id] ?? 0;

  int get wilLevel => 1 + (wilXp ~/ 50);
  int get focLevel => 1 + (focXp ~/ 50);
  int get vitLevel => 1 + (vitXp ~/ 50);
  int get wisLevel => 1 + (wisXp ~/ 50);

  Duration currentStreak(DateTime nowUtc) {
    final diff = nowUtc.toUtc().difference(startTimeUtc);
    return diff.isNegative ? Duration.zero : diff;
  }

  int currentDays(DateTime nowUtc) => currentStreak(nowUtc).inDays;
  int effectiveBestSeconds(DateTime nowUtc) => math.max(bestStreakSeconds, currentStreak(nowUtc).inSeconds);
  int effectiveBestDays(DateTime nowUtc) => effectiveBestSeconds(nowUtc) ~/ 86400;
  RankTier rankAt(DateTime nowUtc) => RankTier.forDays(currentDays(nowUtc));
  CastleTier castleTierAt(DateTime nowUtc) => CastleTier.forDays(currentDays(nowUtc));

  /// Lifetime Sovereignty Mastery % (prevents Abstinence Violation Effect after slips).
  int sovereigntyRatioPercent(DateTime nowUtc) {
    final totalClean = math.max(totalCleanDays, currentDays(nowUtc));
    final totalDays = totalClean + streakHistory.length;
    if (totalDays == 0) return currentDays(nowUtc) > 0 ? 100 : 100;
    return ((totalClean / totalDays) * 100).round().clamp(0, 100);
  }

  double rewiringProgress(DateTime nowUtc) =>
      (currentStreak(nowUtc).inSeconds / (90 * 86400)).clamp(0.0, 1.0);

  bool hasPledgedOn(DateTime now) => lastPledgeDate == formatUtcDateKey(now);
  List<CounterSpell> get activeCounterSpells =>
      counterSpells.where((e) => !e.isDeleted).toList(growable: false);

  int consecutivePledgeStreak(DateTime nowLocal) {
    if (pledgeDates.isEmpty) return 0;
    final set = pledgeDates.toSet();
    var cursor = set.contains(formatUtcDateKey(nowLocal))
        ? nowLocal
        : nowLocal.subtract(const Duration(days: 1));
    var count = 0;
    while (set.contains(formatUtcDateKey(cursor))) {
      count++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return count;
  }

  double comboMultiplier(DateTime nowLocal) {
    final streak = consecutivePledgeStreak(nowLocal);
    if (streak >= 7) return 2.0;
    if (streak >= 3) return 1.5;
    return 1.0;
  }

  int shieldCountOn(DateTime nowLocal) {
    final today = formatUtcDateKey(nowLocal);
    return kTriggerShieldItems.where((i) => shieldChecks[i.id] == today).length;
  }

  double shieldIntegrity(DateTime nowLocal, {int questsDoneToday = 0}) {
    var score = hasPledgedOn(nowLocal) ? 0.25 : 0.0;
    score += shieldCountOn(nowLocal) * 0.20;
    score += math.min(2, questsDoneToday) * 0.10;
    score += structureLevel('guardian_statue') * 0.05;
    return score.clamp(0.0, 1.0);
  }

  StreakState copyWith({
    DateTime? startTimeUtc,
    int? bestStreakSeconds,
    int? totalCleanDays,
    String? lastPledgeDate,
    bool clearLastPledgeDate = false,
    int? xp,
    int? gold,
    String? whyIStarted,
    List<StreakRecord>? streakHistory,
    List<String>? pledgeDates,
    int? pomodoroSessionsCompleted,
    DateTime? updatedAtUtc,
    int? bossKills,
    int? wilXp,
    int? focXp,
    int? vitXp,
    int? wisXp,
    Map<String, int>? castleStructures,
    List<String>? claimedJourneyNodes,
    Map<String, String>? shieldChecks,
    Map<String, String>? milestoneUnlocks,
    List<String>? unlockedSkills,
    List<String>? ownedCosmetics,
    String? equippedOrbId,
    String? equippedAuraId,
    List<CustomReward>? customRewards,
    String? claimedDailyChestDate,
    String? lampbearerName,
    GuidingVow? guidingVow,
    bool? prologueCompleted,
    Map<String, String>? chronicleChoices,
    List<CounterSpell>? counterSpells,
    Map<String, bool>? haltFlags,
    Map<String, int>? pomodoroDates,
    DiagnosticProfile? diagnosticProfile,
  }) =>
      StreakState(
        startTimeUtc: startTimeUtc ?? this.startTimeUtc,
        bestStreakSeconds: bestStreakSeconds ?? this.bestStreakSeconds,
        totalCleanDays: totalCleanDays ?? this.totalCleanDays,
        lastPledgeDate: clearLastPledgeDate ? null : (lastPledgeDate ?? this.lastPledgeDate),
        xp: xp ?? this.xp,
        gold: gold ?? this.gold,
        whyIStarted: whyIStarted ?? this.whyIStarted,
        streakHistory: streakHistory ?? this.streakHistory,
        pledgeDates: pledgeDates ?? this.pledgeDates,
        pomodoroSessionsCompleted: pomodoroSessionsCompleted ?? this.pomodoroSessionsCompleted,
        updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
        bossKills: bossKills ?? this.bossKills,
        wilXp: wilXp ?? this.wilXp,
        focXp: focXp ?? this.focXp,
        vitXp: vitXp ?? this.vitXp,
        wisXp: wisXp ?? this.wisXp,
        castleStructures: castleStructures ?? this.castleStructures,
        claimedJourneyNodes: claimedJourneyNodes ?? this.claimedJourneyNodes,
        shieldChecks: shieldChecks ?? this.shieldChecks,
        milestoneUnlocks: milestoneUnlocks ?? this.milestoneUnlocks,
        unlockedSkills: unlockedSkills ?? this.unlockedSkills,
        ownedCosmetics: ownedCosmetics ?? this.ownedCosmetics,
        equippedOrbId: equippedOrbId ?? this.equippedOrbId,
        equippedAuraId: equippedAuraId ?? this.equippedAuraId,
        customRewards: customRewards ?? this.customRewards,
        claimedDailyChestDate: claimedDailyChestDate ?? this.claimedDailyChestDate,
        lampbearerName: lampbearerName ?? this.lampbearerName,
        guidingVow: guidingVow ?? this.guidingVow,
        prologueCompleted: prologueCompleted ?? this.prologueCompleted,
        chronicleChoices: chronicleChoices ?? this.chronicleChoices,
        counterSpells: counterSpells ?? this.counterSpells,
        haltFlags: haltFlags ?? this.haltFlags,
        pomodoroDates: pomodoroDates ?? this.pomodoroDates,
        diagnosticProfile: diagnosticProfile ?? this.diagnosticProfile,
      );

  Map<String, dynamic> toJson() => {
        'startTimeUtc': startTimeUtc.toUtc().toIso8601String(),
        'bestStreakSeconds': bestStreakSeconds,
        'totalCleanDays': totalCleanDays,
        'lastPledgeDate': lastPledgeDate,
        'xp': xp,
        'gold': gold,
        'whyIStarted': whyIStarted,
        'streakHistory': streakHistory.map((e) => e.toJson()).toList(),
        'pledgeDates': pledgeDates,
        'pomodoroSessionsCompleted': pomodoroSessionsCompleted,
        'updatedAtUtc': updatedAtUtc.toUtc().toIso8601String(),
        'bossKills': bossKills,
        'wilXp': wilXp,
        'focXp': focXp,
        'vitXp': vitXp,
        'wisXp': wisXp,
        'castleStructures': castleStructures,
        'claimedJourneyNodes': claimedJourneyNodes,
        'shieldChecks': shieldChecks,
        'milestoneUnlocks': milestoneUnlocks,
        'unlockedSkills': unlockedSkills,
        'ownedCosmetics': ownedCosmetics,
        'equippedOrbId': equippedOrbId,
        'equippedAuraId': equippedAuraId,
        'customRewards': customRewards.map((e) => e.toJson()).toList(),
        'claimedDailyChestDate': claimedDailyChestDate,
        'lampbearerName': lampbearerName,
        'guidingVow': guidingVow.name,
        'prologueCompleted': prologueCompleted,
        'chronicleChoices': chronicleChoices,
        'counterSpells': counterSpells.map((e) => e.toJson()).toList(),
        'haltFlags': haltFlags,
        'pomodoroDates': pomodoroDates,
        'diagnosticProfile': diagnosticProfile?.toJson(),
      };

  factory StreakState.fromJson(Map<String, dynamic> json) {
    final updated = DateTime.parse(json['updatedAtUtc'] as String).toUtc();
    final rawSpells = json['counterSpells'] as List<dynamic>?;
    final spells = rawSpells == null || rawSpells.isEmpty
        ? CounterSpell.defaults(updated)
        : rawSpells.map((e) => CounterSpell.fromJson(Map<String, dynamic>.from(e as Map))).toList();

    return StreakState(
      startTimeUtc: DateTime.parse(json['startTimeUtc'] as String).toUtc(),
      bestStreakSeconds: (json['bestStreakSeconds'] as num?)?.toInt() ?? 0,
      totalCleanDays: (json['totalCleanDays'] as num?)?.toInt() ?? 0,
      lastPledgeDate: json['lastPledgeDate'] as String?,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      gold: (json['gold'] as num?)?.toInt() ?? 0,
      whyIStarted: json['whyIStarted'] as String? ?? 'Protect my focus, clarity, and self-respect every day.',
      streakHistory: (json['streakHistory'] as List<dynamic>? ?? const [])
          .map((e) => StreakRecord.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      pledgeDates: (json['pledgeDates'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(),
      pomodoroSessionsCompleted: (json['pomodoroSessionsCompleted'] as num?)?.toInt() ?? 0,
      updatedAtUtc: updated,
      bossKills: (json['bossKills'] as num?)?.toInt() ?? 0,
      wilXp: (json['wilXp'] as num?)?.toInt() ?? 0,
      focXp: (json['focXp'] as num?)?.toInt() ?? 0,
      vitXp: (json['vitXp'] as num?)?.toInt() ?? 0,
      wisXp: (json['wisXp'] as num?)?.toInt() ?? 0,
      castleStructures: (json['castleStructures'] as Map<String, dynamic>? ?? const {})
          .map((k, v) => MapEntry(k, (v as num).toInt())),
      claimedJourneyNodes: (json['claimedJourneyNodes'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(),
      shieldChecks: (json['shieldChecks'] as Map<String, dynamic>? ?? const {})
          .map((k, v) => MapEntry(k, v.toString())),
      milestoneUnlocks: (json['milestoneUnlocks'] as Map<String, dynamic>? ?? const {})
          .map((k, v) => MapEntry(k, v.toString())),
      unlockedSkills: (json['unlockedSkills'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(),
      ownedCosmetics: (json['ownedCosmetics'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          const ['orb_obsidian_emerald', 'aura_ember'],
      equippedOrbId: json['equippedOrbId'] as String? ?? 'orb_obsidian_emerald',
      equippedAuraId: json['equippedAuraId'] as String? ?? 'aura_ember',
      customRewards: (json['customRewards'] as List<dynamic>? ?? const [])
          .map((e) => CustomReward.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      claimedDailyChestDate: json['claimedDailyChestDate'] as String?,
      lampbearerName: json['lampbearerName'] as String? ?? 'Warden',
      guidingVow: GuidingVow.fromName(json['guidingVow'] as String? ?? 'clarity'),
      prologueCompleted: json['prologueCompleted'] as bool? ?? false,
      chronicleChoices: (json['chronicleChoices'] as Map<String, dynamic>? ?? const {})
          .map((k, v) => MapEntry(k, v.toString())),
      counterSpells: spells,
      haltFlags: (json['haltFlags'] as Map<String, dynamic>? ?? const {})
          .map((k, v) => MapEntry(k, v == true)),
      pomodoroDates: (json['pomodoroDates'] as Map<String, dynamic>? ?? const {})
          .map((k, v) => MapEntry(k, (v as num).toInt())),
      diagnosticProfile: json['diagnosticProfile'] == null
          ? null
          : DiagnosticProfile.fromJson(Map<String, dynamic>.from(json['diagnosticProfile'] as Map)),
    );
  }
}

enum UrgeLogType {
  urgeDefeated('urgeDefeated'),
  relapse('relapse'),
  checkIn('checkIn');

  const UrgeLogType(this.wireValue);
  final String wireValue;

  static UrgeLogType fromWire(String raw) => UrgeLogType.values.firstWhere(
        (e) => e.wireValue == raw,
        orElse: () => UrgeLogType.checkIn,
      );
}

class UrgeLog {
  const UrgeLog({
    required this.id,
    required this.timestampUtc,
    required this.type,
    required this.intensity,
    required this.triggers,
    required this.mood,
    required this.note,
    required this.updatedAtUtc,
    this.isDeleted = false,
  });

  final String id;
  final DateTime timestampUtc;
  final UrgeLogType type;
  final int intensity;
  final List<String> triggers;
  final String mood;
  final String note;
  final DateTime updatedAtUtc;
  final bool isDeleted;

  UrgeLog copyWith({
    String? id,
    DateTime? timestampUtc,
    UrgeLogType? type,
    int? intensity,
    List<String>? triggers,
    String? mood,
    String? note,
    DateTime? updatedAtUtc,
    bool? isDeleted,
  }) =>
      UrgeLog(
        id: id ?? this.id,
        timestampUtc: timestampUtc ?? this.timestampUtc,
        type: type ?? this.type,
        intensity: intensity ?? this.intensity,
        triggers: triggers ?? this.triggers,
        mood: mood ?? this.mood,
        note: note ?? this.note,
        updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
        isDeleted: isDeleted ?? this.isDeleted,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestampUtc': timestampUtc.toUtc().toIso8601String(),
        'type': type.wireValue,
        'intensity': intensity,
        'triggers': triggers,
        'mood': mood,
        'note': note,
        'updatedAtUtc': updatedAtUtc.toUtc().toIso8601String(),
        'isDeleted': isDeleted,
      };

  factory UrgeLog.fromJson(Map<String, dynamic> json) => UrgeLog(
        id: json['id'] as String,
        timestampUtc: DateTime.parse(json['timestampUtc'] as String).toUtc(),
        type: UrgeLogType.fromWire(json['type'] as String? ?? 'checkIn'),
        intensity: (json['intensity'] as num?)?.toInt() ?? 5,
        triggers: (json['triggers'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(),
        mood: json['mood'] as String? ?? '',
        note: json['note'] as String? ?? '',
        updatedAtUtc: DateTime.parse(json['updatedAtUtc'] as String).toUtc(),
        isDeleted: json['isDeleted'] as bool? ?? false,
      );
}

class QuestItem {
  const QuestItem({
    required this.id,
    required this.title,
    required this.description,
    required this.xpReward,
    required this.goldReward,
    required this.lastCompletedDate,
    required this.streakCount,
    required this.updatedAtUtc,
    this.isDeleted = false,
  });

  final String id;
  final String title;
  final String description;
  final int xpReward;
  final int goldReward;
  final String? lastCompletedDate;
  final int streakCount;
  final DateTime updatedAtUtc;
  final bool isDeleted;

  bool isCompletedOn(DateTime now) => lastCompletedDate == formatUtcDateKey(now);

  QuestItem copyWith({
    String? id,
    String? title,
    String? description,
    int? xpReward,
    int? goldReward,
    String? lastCompletedDate,
    bool clearLastCompletedDate = false,
    int? streakCount,
    DateTime? updatedAtUtc,
    bool? isDeleted,
  }) =>
      QuestItem(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        xpReward: xpReward ?? this.xpReward,
        goldReward: goldReward ?? this.goldReward,
        lastCompletedDate: clearLastCompletedDate ? null : (lastCompletedDate ?? this.lastCompletedDate),
        streakCount: streakCount ?? this.streakCount,
        updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
        isDeleted: isDeleted ?? this.isDeleted,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'xpReward': xpReward,
        'goldReward': goldReward,
        'lastCompletedDate': lastCompletedDate,
        'streakCount': streakCount,
        'updatedAtUtc': updatedAtUtc.toUtc().toIso8601String(),
        'isDeleted': isDeleted,
      };

  factory QuestItem.fromJson(Map<String, dynamic> json) => QuestItem(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        xpReward: (json['xpReward'] as num?)?.toInt() ?? 25,
        goldReward: (json['goldReward'] as num?)?.toInt() ?? 10,
        lastCompletedDate: json['lastCompletedDate'] as String?,
        streakCount: (json['streakCount'] as num?)?.toInt() ?? 0,
        updatedAtUtc: DateTime.parse(json['updatedAtUtc'] as String).toUtc(),
        isDeleted: json['isDeleted'] as bool? ?? false,
      );

  static List<QuestItem> defaultQuests(DateTime nowUtc) => [
        QuestItem(id: 'quest_morning_pledge', title: 'Morning Anchor Pledge', description: 'Commit to one clean, intentional day before noon.', xpReward: 25, goldReward: 10, lastCompletedDate: null, streakCount: 0, updatedAtUtc: nowUtc),
        QuestItem(id: 'quest_deep_focus', title: 'Deep Work Pomodoro', description: 'Complete one focused 25-minute timer session.', xpReward: 35, goldReward: 15, lastCompletedDate: null, streakCount: 0, updatedAtUtc: nowUtc),
        QuestItem(id: 'quest_device_curfew', title: 'Night Device Boundary', description: 'Keep screens out of bed during late vulnerability hours.', xpReward: 30, goldReward: 12, lastCompletedDate: null, streakCount: 0, updatedAtUtc: nowUtc),
        QuestItem(id: 'quest_physical_vitality', title: 'Movement & Cold Reset', description: 'Train, walk briskly, or take a cold-finish shower.', xpReward: 30, goldReward: 12, lastCompletedDate: null, streakCount: 0, updatedAtUtc: nowUtc),
      ];
}

class RecoverySnapshot {
  const RecoverySnapshot({
    this.schemaVersion = 4,
    required this.streakState,
    required this.urgeLogs,
    required this.quests,
    required this.exportedAtUtc,
  });

  final int schemaVersion;
  final StreakState streakState;
  final List<UrgeLog> urgeLogs;
  final List<QuestItem> quests;
  final DateTime exportedAtUtc;

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'streakState': streakState.toJson(),
        'urgeLogs': urgeLogs.map((e) => e.toJson()).toList(),
        'quests': quests.map((e) => e.toJson()).toList(),
        'exportedAtUtc': exportedAtUtc.toUtc().toIso8601String(),
      };

  factory RecoverySnapshot.fromJson(Map<String, dynamic> json) => RecoverySnapshot(
        schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
        streakState: StreakState.fromJson(Map<String, dynamic>.from(json['streakState'] as Map)),
        urgeLogs: (json['urgeLogs'] as List<dynamic>? ?? const [])
            .map((e) => UrgeLog.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        quests: (json['quests'] as List<dynamic>? ?? const [])
            .map((e) => QuestItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        exportedAtUtc: DateTime.parse(json['exportedAtUtc'] as String).toUtc(),
      );
}
