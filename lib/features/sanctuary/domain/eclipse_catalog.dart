import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

abstract final class GameArtAssets {
  static const citadelTier1 = 'assets/art/citadel_tier_1.png';
  static const citadelTier2 = 'assets/art/citadel_tier_2.png';
  static const citadelTier3 = 'assets/art/citadel_tier_3.png';
  static const citadelTier4 = 'assets/art/citadel_tier_4.png';
  static const guardianKnight = 'assets/art/guardian_knight.png';
  static const mirageBoss = 'assets/art/mirage_boss.png';
  static const lootChest = 'assets/art/loot_chest.png';
  static const relicEmblem = 'assets/art/relic_emblem.png';
  static const realmMapBg = 'assets/art/realm_map_bg.png';

  static String citadelForDays(int days) {
    if (days >= 60) return citadelTier4;
    if (days >= 14) return citadelTier3;
    if (days >= 3) return citadelTier2;
    return citadelTier1;
  }
}

/// ACT Guiding Core Vows chosen during the interactive Mirror of Truth Prologue.
enum GuidingVow {
  clarity(title: 'Clarity', mantra: 'Clean focus reveals what noise conceals.'),
  strength(title: 'Strength', mantra: 'I outlast discomfort until mastery becomes natural.'),
  discipline(title: 'Discipline', mantra: 'Small kept promises forge an unbreakable shield.'),
  presence(title: 'Presence', mantra: 'I meet each hour awake rather than scrolling numb.'),
  peace(title: 'Peace', mantra: 'Calm attention heals what impulse tries to escape.');

  const GuidingVow({required this.title, required this.mantra});
  final String title;
  final String mantra;

  static GuidingVow fromName(String raw) => GuidingVow.values.firstWhere(
        (v) => v.name == raw,
        orElse: () => GuidingVow.clarity,
      );
}

enum RankTier {
  novice(minDays: 0, title: 'Novice', companionName: 'Ember Lantern', stageIndex: 0, subtitle: 'First spark in the eclipse'),
  seeker(minDays: 3, title: 'Seeker', companionName: 'Sprouting Warden', stageIndex: 1, subtitle: '72-hour static cleared'),
  sentinel(minDays: 7, title: 'Sentinel', companionName: 'Verdant Guard', stageIndex: 2, subtitle: 'First Citadel watch completed'),
  vanguard(minDays: 14, title: 'Vanguard', companionName: 'Flame Sentinel', stageIndex: 3, subtitle: 'Neural pathways fortifying'),
  warden(minDays: 30, title: 'Warden', companionName: 'Astral Keeper', stageIndex: 4, subtitle: 'Thirty days of sovereign calm'),
  sovereign(minDays: 60, title: 'Sovereign', companionName: 'Sovereign Phoenix', stageIndex: 5, subtitle: 'Aurora Citadel awakened'),
  titan(minDays: 90, title: 'Titan', companionName: 'Celestial Titan', stageIndex: 6, subtitle: 'Eclipse broken · Dawn earned');

  const RankTier({
    required this.minDays,
    required this.title,
    required this.companionName,
    required this.stageIndex,
    required this.subtitle,
  });

  final int minDays;
  final String title;
  final String companionName;
  final int stageIndex;
  final String subtitle;

  static RankTier forDays(int days) {
    for (final t in RankTier.values.reversed) {
      if (days >= t.minDays) return t;
    }
    return RankTier.novice;
  }

  RankTier? get nextTier {
    final idx = RankTier.values.indexOf(this);
    return idx + 1 >= RankTier.values.length ? null : RankTier.values[idx + 1];
  }
}

enum CastleTier {
  camp(tierIndex: 0, minDays: 0, title: 'Ruined Campfire & Ember Stones'),
  watchpost(tierIndex: 1, minDays: 1, title: 'Timber Watchpost'),
  keep(tierIndex: 2, minDays: 3, title: 'Stone Keep & Gatehouse'),
  battlements(tierIndex: 3, minDays: 7, title: 'Twin Battlement Towers'),
  citadel(tierIndex: 4, minDays: 14, title: 'Fortified Inner Citadel'),
  spire(tierIndex: 5, minDays: 30, title: 'Grand Arcane Spire'),
  fortress(tierIndex: 6, minDays: 60, title: 'Sovereign Obsidian Fortress'),
  celestial(tierIndex: 7, minDays: 90, title: 'Celestial Titan Citadel');

  const CastleTier({required this.tierIndex, required this.minDays, required this.title});
  final int tierIndex;
  final int minDays;
  final String title;

  static CastleTier forDays(int days) {
    for (final t in CastleTier.values.reversed) {
      if (days >= t.minDays) return t;
    }
    return CastleTier.camp;
  }
}

const List<int> kMilestoneDays = [1, 3, 7, 14, 30, 60, 90];

class CastleStructureDef {
  const CastleStructureDef({
    required this.id,
    required this.name,
    required this.bonusSummary,
    required this.baseCost,
    required this.maxLevel,
    required this.accent,
  });

  final String id;
  final String name;
  final String bonusSummary;
  final int baseCost;
  final int maxLevel;
  final Color accent;

  int costForLevel(int currentLevel, {bool architectDiscount = false}) {
    final raw = (baseCost * (currentLevel + 1) * 0.85).round();
    final scaled = math.max(baseCost, raw);
    return architectDiscount ? (scaled * 0.85).round() : scaled;
  }
}

const List<CastleStructureDef> kCastleStructures = [
  CastleStructureDef(id: 'watchtower', name: 'Watchtower', bonusSummary: '+5 XP per pledge per level', baseCost: 40, maxLevel: 3, accent: AppColors.accentEmeraldGlow),
  CastleStructureDef(id: 'arcane_forge', name: 'Arcane Forge', bonusSummary: '+5 Gold on quest clears per level', baseCost: 55, maxLevel: 3, accent: AppColors.accentGold),
  CastleStructureDef(id: 'mana_fountain', name: 'Mana Fountain', bonusSummary: '+15% Breath-Wave strike per level', baseCost: 50, maxLevel: 3, accent: AppColors.accentCyan),
  CastleStructureDef(id: 'guardian_statue', name: 'Guardian Statue', bonusSummary: '+10% Shield Integrity per level', baseCost: 60, maxLevel: 3, accent: AppColors.accentEmerald),
  CastleStructureDef(id: 'golden_gate', name: 'Golden Gate', bonusSummary: '+5% XP/Gold synergy per level', baseCost: 75, maxLevel: 3, accent: AppColors.accentGold),
];

class ActChoiceSpec {
  const ActChoiceSpec({required this.id, required this.label, required this.statTag, required this.wilDelta, required this.wisDelta});
  final String id;
  final String label;
  final String statTag;
  final int wilDelta;
  final int wisDelta;
}

class ChronicleActSpec {
  const ChronicleActSpec({
    required this.id,
    required this.actNumber,
    required this.title,
    required this.dayRange,
    required this.minDay,
    required this.storyLines,
    required this.choiceA,
    required this.choiceB,
    required this.chestNodeId,
    required this.bossGateId,
    required this.bossName,
    required this.rewardXp,
    required this.rewardGold,
  });

  final String id;
  final int actNumber;
  final String title;
  final String dayRange;
  final int minDay;
  final List<String> storyLines;
  final ActChoiceSpec choiceA;
  final ActChoiceSpec choiceB;
  final String chestNodeId;
  final String bossGateId;
  final String bossName;
  final int rewardXp;
  final int rewardGold;

  int get bossDayRequired => switch (actNumber) {
        1 => 3,
        2 => 7,
        3 => 14,
        4 => 30,
        5 => 60,
        6 => 89,
        _ => 90,
      };
}

const List<ChronicleActSpec> kChronicleActs = [
  ChronicleActSpec(
    id: 'act_1_ember_wastes',
    actNumber: 1,
    title: 'Ember Wastes',
    dayRange: 'Days 1–3',
    minDay: 1,
    storyLines: [
      'Ash settles across the broken road where old compulsions used to hunt unchallenged.',
      'Your Lantern flickers green in the fog, casting sharp shadows off the Hollow Whisper ahead.',
      'At the ruined shrine, a traveler offers half-spent tinder.',
    ],
    choiceA: ActChoiceSpec(id: 'share_ember', label: 'Stand Guard (+30 WIL)', statTag: 'WIL', wilDelta: 30, wisDelta: 0),
    choiceB: ActChoiceSpec(id: 'study_tracks', label: 'Map Mirage Tracks (+30 WIS)', statTag: 'WIS', wilDelta: 0, wisDelta: 30),
    chestNodeId: 'j_ch1_start',
    bossGateId: 'j_ch1_boss',
    bossName: 'Hollow Whisper',
    rewardXp: 40,
    rewardGold: 25,
  ),
  ChronicleActSpec(
    id: 'act_2_whispering_woods',
    actNumber: 2,
    title: 'Whispering Woods',
    dayRange: 'Days 4–7',
    minDay: 4,
    storyLines: [
      'Pale pines echo false promises whenever midnight wind threads the canopy.',
      'The first 72-hour haze has thinned, exposing clean stone beneath the moss.',
      'Between two forked trails, the Siren’s lantern mimics a safe harbor.',
    ],
    choiceA: ActChoiceSpec(id: 'march_dark', label: 'March Straight Through (+35 WIL)', statTag: 'WIL', wilDelta: 35, wisDelta: 0),
    choiceB: ActChoiceSpec(id: 'log_lure', label: 'Record the Deception (+35 WIS)', statTag: 'WIS', wilDelta: 0, wisDelta: 35),
    chestNodeId: 'j_ch2_chest',
    bossGateId: 'j_ch2_boss',
    bossName: 'Day 7 Gatekeeper',
    rewardXp: 60,
    rewardGold: 45,
  ),
  ChronicleActSpec(
    id: 'act_3_iron_bastion',
    actNumber: 3,
    title: 'Iron Bastion',
    dayRange: 'Days 8–14',
    minDay: 8,
    storyLines: [
      'Rain hammers the basalt ramparts while your Citadel towers rise behind the ridge.',
      'Fatigue tests quiet discipline far harder than dramatic battles ever could.',
      'Inside the armory yard, you decide how to temper the second week.',
    ],
    choiceA: ActChoiceSpec(id: 'temper_blade', label: 'Temper Iron Shield (+40 WIL)', statTag: 'WIL', wilDelta: 40, wisDelta: 0),
    choiceB: ActChoiceSpec(id: 'read_chronicle', label: 'Study Trigger Patterns (+40 WIS)', statTag: 'WIS', wilDelta: 0, wisDelta: 40),
    chestNodeId: 'j_ch3_chest',
    bossGateId: 'j_ch3_boss',
    bossName: 'Vanguard Keep Warden',
    rewardXp: 75,
    rewardGold: 55,
  ),
  ChronicleActSpec(
    id: 'act_4_crystal_peaks',
    actNumber: 4,
    title: 'Crystal Peaks',
    dayRange: 'Days 15–30',
    minDay: 15,
    storyLines: [
      'Above the cloud deck, thin alpine air sharpens every morning intention.',
      'Dopamine phantoms still shimmer near cliffs of boredom, but they carry less weight.',
      'Before the thirty-day summit gate, one final vow anchors your ascent.',
    ],
    choiceA: ActChoiceSpec(id: 'oath_endurance', label: 'Swear Summit Oath (+45 WIL)', statTag: 'WIL', wilDelta: 45, wisDelta: 0),
    choiceB: ActChoiceSpec(id: 'crystal_mirror', label: 'Audit Weak Windows (+45 WIS)', statTag: 'WIS', wilDelta: 0, wisDelta: 45),
    chestNodeId: 'j_ch4_chest',
    bossGateId: 'j_ch4_boss',
    bossName: 'Day 30 Shadow Lord',
    rewardXp: 120,
    rewardGold: 90,
  ),
  ChronicleActSpec(
    id: 'act_5_astral_citadel',
    actNumber: 5,
    title: 'Astral Citadel',
    dayRange: 'Days 31–60',
    minDay: 31,
    storyLines: [
      'Emerald runes orbit the outer spire as steady focus turns effort into identity.',
      'You no longer flee waves—you surf them cleanly without bargaining.',
      'The Storm Wraith challenges your discipline at dusk.',
    ],
    choiceA: ActChoiceSpec(id: 'hold_wall', label: 'Hold Astral Gate (+55 WIL)', statTag: 'WIL', wilDelta: 55, wisDelta: 0),
    choiceB: ActChoiceSpec(id: 'calm_eye', label: 'Anchor Calm Breath (+55 WIS)', statTag: 'WIS', wilDelta: 0, wisDelta: 55),
    chestNodeId: 'j_ch5_chest',
    bossGateId: 'j_ch5_boss',
    bossName: 'Sovereign Sanctum Sentinel',
    rewardXp: 150,
    rewardGold: 120,
  ),
  ChronicleActSpec(
    id: 'act_6_sovereign_crown',
    actNumber: 6,
    title: 'Sovereign Crown',
    dayRange: 'Days 61–89',
    minDay: 61,
    storyLines: [
      'Green aurora ribbons crown your obsidian fortress across clear nocturnal skies.',
      'What once felt impossible now moves on calm habit and clear boundaries.',
      'Only the Lone Shade lingers before dawn breaks across the valley.',
    ],
    choiceA: ActChoiceSpec(id: 'sovereign_stance', label: 'Command the Watch (+65 WIL)', statTag: 'WIL', wilDelta: 65, wisDelta: 0),
    choiceB: ActChoiceSpec(id: 'mentor_code', label: 'Inscribe Codex Wisdom (+65 WIS)', statTag: 'WIS', wilDelta: 0, wisDelta: 65),
    chestNodeId: 'j_ch6_chest',
    bossGateId: 'j_ch6_boss',
    bossName: 'Lone Shade Regent',
    rewardXp: 160,
    rewardGold: 130,
  ),
  ChronicleActSpec(
    id: 'act_7_titans_dawn',
    actNumber: 7,
    title: "Titan's Dawn",
    dayRange: 'Day 90+',
    minDay: 90,
    storyLines: [
      'Golden light strikes the floating Crown Crystal high above the Celestial Citadel.',
      'Ninety days of rewiring stand permanent in your nervous system and Sovereignty Ratio.',
      'Step forward as the Eclipse ends and the true chronicle continues.',
    ],
    choiceA: ActChoiceSpec(id: 'eternal_guard', label: 'Light the Dawn Beacon (+80 WIL)', statTag: 'WIL', wilDelta: 80, wisDelta: 0),
    choiceB: ActChoiceSpec(id: 'architect_legacy', label: 'Preserve Living Wisdom (+80 WIS)', statTag: 'WIS', wilDelta: 0, wisDelta: 80),
    chestNodeId: 'j_ch7_chest',
    bossGateId: 'j_ch7_boss',
    bossName: 'Day 90 Obsidian Dragon',
    rewardXp: 250,
    rewardGold: 200,
  ),
];

class TrophyCardSpec {
  const TrophyCardSpec({required this.id, required this.badge, required this.title, required this.minDays, required this.lore, required this.foilPrimary, required this.foilSecondary});
  final String id;
  final String badge;
  final String title;
  final int minDays;
  final String lore;
  final Color foilPrimary;
  final Color foilSecondary;
}

const List<TrophyCardSpec> kTrophyCards = [
  TrophyCardSpec(id: 'trophy_24h', badge: '24H', title: 'First Spark', minDays: 1, lore: 'Twenty-four clean hours forged from intent.', foilPrimary: AppColors.accentEmerald, foilSecondary: AppColors.accentCyan),
  TrophyCardSpec(id: 'trophy_3d', badge: '3D', title: 'Iron Will', minDays: 3, lore: 'Initial dopamine static cleared after 72 hours.', foilPrimary: AppColors.accentCyan, foilSecondary: AppColors.accentEmeraldGlow),
  TrophyCardSpec(id: 'trophy_7d', badge: '7D', title: 'Sentinel', minDays: 7, lore: 'One unshakeable week standing watch.', foilPrimary: AppColors.accentEmeraldGlow, foilSecondary: AppColors.accentGold),
  TrophyCardSpec(id: 'trophy_14d', badge: '14D', title: 'Vanguard', minDays: 14, lore: 'Calm pathways replace impulsive reflexes.', foilPrimary: Color(0xFF38BDF8), foilSecondary: AppColors.accentIndigo),
  TrophyCardSpec(id: 'trophy_30d', badge: '30D', title: 'Warden', minDays: 30, lore: 'Thirty days of sovereign self-command.', foilPrimary: AppColors.accentGold, foilSecondary: AppColors.accentEmerald),
  TrophyCardSpec(id: 'trophy_60d', badge: '60D', title: 'Sovereign', minDays: 60, lore: 'Two months etched in obsidian steel.', foilPrimary: Color(0xFFFBBF24), foilSecondary: Color(0xFFF97316)),
  TrophyCardSpec(id: 'trophy_90d', badge: '90D', title: 'Titan', minDays: 90, lore: 'Full 90-day neural rewiring complete.', foilPrimary: AppColors.accentGold, foilSecondary: AppColors.accentCyan),
  TrophyCardSpec(id: 'trophy_180d', badge: '180D', title: 'Legend', minDays: 180, lore: 'Half a year of unbroken clarity.', foilPrimary: Color(0xFFA78BFA), foilSecondary: AppColors.accentGold),
  TrophyCardSpec(id: 'trophy_365d', badge: '365D', title: 'Immortal', minDays: 365, lore: 'One solar orbit of unyielding mastery.', foilPrimary: Color(0xFFFDE68A), foilSecondary: AppColors.accentEmeraldGlow),
];

class SkillPerkDef {
  const SkillPerkDef({required this.id, required this.title, required this.effect, required this.icon});
  final String id;
  final String title;
  final String effect;
  final IconData icon;
}

const List<SkillPerkDef> kSkillPerks = [
  SkillPerkDef(id: 'iron_shield', title: 'Iron Shield', effect: '+25% Boss Battle attack damage', icon: Icons.shield_outlined),
  SkillPerkDef(id: 'golden_forge', title: 'Golden Forge', effect: '+20% Gold earned from quests', icon: Icons.auto_awesome_outlined),
  SkillPerkDef(id: 'focus_mastery', title: 'Focus Mastery', effect: '+30% Pomodoro session XP', icon: Icons.center_focus_strong_outlined),
  SkillPerkDef(id: 'citadel_architect', title: 'Citadel Architect', effect: '-15% Castle upgrade Gold cost', icon: Icons.castle_outlined),
  SkillPerkDef(id: 'ember_ward', title: 'Ember Ward', effect: 'HALT mini-quests recharge +10% bonus Shield', icon: Icons.local_fire_department_outlined),
];

enum CosmeticSlot { orb, aura }

class ArmoryCosmeticDef {
  const ArmoryCosmeticDef({required this.id, required this.slot, required this.name, required this.costGold, required this.colors});
  final String id;
  final CosmeticSlot slot;
  final String name;
  final int costGold;
  final List<Color> colors;
}

const List<ArmoryCosmeticDef> kArmoryCosmetics = [
  ArmoryCosmeticDef(id: 'orb_obsidian_emerald', slot: CosmeticSlot.orb, name: 'Obsidian Emerald', costGold: 0, colors: [AppColors.accentEmeraldGlow, AppColors.accentEmerald, Color(0xFF064E3B)]),
  ArmoryCosmeticDef(id: 'orb_solar_gold', slot: CosmeticSlot.orb, name: 'Solar Gold', costGold: 50, colors: [Color(0xFFFDE68A), AppColors.accentGold, Color(0xFF92400E)]),
  ArmoryCosmeticDef(id: 'orb_arctic_cyan', slot: CosmeticSlot.orb, name: 'Arctic Cyan', costGold: 60, colors: [Color(0xFF67E8F9), AppColors.accentCyan, Color(0xFF155E75)]),
  ArmoryCosmeticDef(id: 'orb_crimson_phoenix', slot: CosmeticSlot.orb, name: 'Crimson Phoenix', costGold: 80, colors: [Color(0xFFFCA5A5), Color(0xFFF97316), Color(0xFF7F1D1D)]),
  ArmoryCosmeticDef(id: 'orb_astral_violet', slot: CosmeticSlot.orb, name: 'Astral Violet', costGold: 100, colors: [Color(0xFFC4B5FD), AppColors.accentIndigo, Color(0xFF312E81)]),
  ArmoryCosmeticDef(id: 'aura_ember', slot: CosmeticSlot.aura, name: 'Ember Halo', costGold: 0, colors: [AppColors.accentEmeraldGlow, AppColors.accentCyan]),
  ArmoryCosmeticDef(id: 'aura_emerald_runes', slot: CosmeticSlot.aura, name: 'Emerald Runes', costGold: 45, colors: [AppColors.accentEmeraldGlow, AppColors.accentEmerald]),
  ArmoryCosmeticDef(id: 'aura_sovereign_halo', slot: CosmeticSlot.aura, name: 'Sovereign Halo', costGold: 85, colors: [Color(0xFFFDE68A), AppColors.accentGold]),
  ArmoryCosmeticDef(id: 'aura_titan_storm', slot: CosmeticSlot.aura, name: 'Titan Storm', costGold: 120, colors: [AppColors.accentCyan, Color(0xFFA78BFA)]),
];

class HaltOrbDef {
  const HaltOrbDef({required this.id, required this.label, required this.restorationQuest});
  final String id;
  final String label;
  final String restorationQuest;
}

const List<HaltOrbDef> kHaltOrbs = [
  HaltOrbDef(id: 'hungry', label: 'Hungry', restorationQuest: 'Eat real protein/fruit + drink a full glass of water.'),
  HaltOrbDef(id: 'angry', label: 'Angry / Stressed', restorationQuest: 'Do 2 physiological sighs + shake tension out for 90s.'),
  HaltOrbDef(id: 'lonely', label: 'Lonely', restorationQuest: 'Message a trusted friend or read your Guiding Vow aloud.'),
  HaltOrbDef(id: 'tired', label: 'Tired', restorationQuest: 'Dock phone outside the bedroom & close your eyes for 120s.'),
];

class TriggerShieldDef {
  const TriggerShieldDef({required this.id, required this.label});
  final String id;
  final String label;
}

const List<TriggerShieldDef> kTriggerShieldItems = [
  TriggerShieldDef(id: 'safesearch', label: 'Browser SafeSearch & DNS guard active'),
  TriggerShieldDef(id: 'social_limit', label: 'Short-form feeds / triggers blocked or capped'),
  TriggerShieldDef(id: 'phone_hallway', label: 'Phone charging outside bedroom at night'),
];

class UrgeBossSpec {
  const UrgeBossSpec({
    required this.name,
    required this.subtitle,
    required this.illusionWhisper,
    required this.defusionMantra,
    required this.accent,
  });

  final String name;
  final String subtitle;
  final String illusionWhisper;
  final String defusionMantra;
  final Color accent;
}

const List<UrgeBossSpec> kUrgeBosses = [
  UrgeBossSpec(
    name: 'Midnight Siren',
    subtitle: 'Late-hour impulse phantom',
    illusionWhisper: '"Nobody will ever know if you take just one peek right now."',
    defusionMantra: 'My brain is noticing a temporary late-night thought—a passing signal, not an order.',
    accent: AppColors.accentCrimson,
  ),
  UrgeBossSpec(
    name: 'Hollow Whisper',
    subtitle: 'Numbed-boredom mirage',
    illusionWhisper: '"You are bored anyway; only cheap novelty can fix tonight."',
    defusionMantra: 'Restlessness peaks and fades in 15 minutes when I move my body instead of scrolling.',
    accent: AppColors.accentIndigo,
  ),
  UrgeBossSpec(
    name: 'Storm Wraith',
    subtitle: 'Stress & tension elemental',
    illusionWhisper: '"Today drained you—numbing out is the fastest relief."',
    defusionMantra: 'A real 60s reset restores actual calm; a relapse multiplies tomorrow’s fatigue.',
    accent: Color(0xFFF97316),
  ),
  UrgeBossSpec(
    name: 'Lone Shade',
    subtitle: 'Isolation & disconnection specter',
    illusionWhisper: '"No one gets it; retreat back into old comfort."',
    defusionMantra: 'Isolation feeds the mirage. Real connection and self-respect break it cleanly.',
    accent: AppColors.accentCyan,
  ),
  UrgeBossSpec(
    name: 'Fog Weaver',
    subtitle: 'Endless-feed trance spirit',
    illusionWhisper: '"Keep scrolling a bit longer—nothing matters tonight."',
    defusionMantra: 'Clarity returns the instant the screen locks and boots hit the floor.',
    accent: AppColors.accentGold,
  ),
];

ArmoryCosmeticDef cosmeticById(String id, CosmeticSlot fallbackSlot) {
  for (final c in kArmoryCosmetics) {
    if (c.id == id) return c;
  }
  return kArmoryCosmetics.firstWhere((c) => c.slot == fallbackSlot);
}
