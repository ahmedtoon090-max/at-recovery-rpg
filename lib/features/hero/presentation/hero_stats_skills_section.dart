import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/glass_card.dart';
import '../../sanctuary/application/recovery_controller.dart';
import '../../sanctuary/domain/recovery_models.dart';

/// Hero 4-Attribute Radar Chart (WIL/FOC/VIT/WIS) and 5-Perk Skill Tree.
class HeroStatsSkillsSection extends ConsumerWidget {
  const HeroStatsSkillsSection({
    super.key,
    required this.streakState,
    required this.hapticsEnabled,
  });

  final StreakState streakState;
  final bool hapticsEnabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final maxStat = [
      streakState.wilLevel,
      streakState.focLevel,
      streakState.vitLevel,
      streakState.wisLevel,
      5,
    ].reduce(math.max).toDouble();

    final stats = [
      (label: 'WIL', full: 'Willpower', lvl: streakState.wilLevel, xp: streakState.wilXp, source: 'Clean days & pledges', color: AppColors.accentEmeraldGlow),
      (label: 'FOC', full: 'Focus', lvl: streakState.focLevel, xp: streakState.focXp, source: 'Pomodoro sessions', color: AppColors.accentCyan),
      (label: 'VIT', full: 'Vitality', lvl: streakState.vitLevel, xp: streakState.vitXp, source: 'Physical resets & Bosses', color: AppColors.accentGold),
      (label: 'WIS', full: 'Wisdom', lvl: streakState.wisLevel, xp: streakState.wisXp, source: 'Journal & Post-Mortems', color: AppColors.accentIndigo),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ObsidianCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HERO ATTRIBUTES',
                style: AppTypography.microLabel(
                  width,
                  color: AppColors.accentCyan,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 210,
                child: RadarChart(
                  RadarChartData(
                    radarShape: RadarShape.polygon,
                    radarBackgroundColor: AppColors.bgVoid.withValues(alpha: 0.45),
                    radarBorderData: const BorderSide(color: AppColors.borderSubtle),
                    gridBorderData: const BorderSide(color: AppColors.borderSubtle),
                    tickCount: 3,
                    ticksTextStyle: const TextStyle(fontSize: 0, color: Colors.transparent),
                    tickBorderData: const BorderSide(color: AppColors.borderSubtle),
                    titleTextStyle: AppTypography.monoStat(fontSize: 12, color: AppColors.textPrimary),
                    getTitle: (idx, _) => RadarChartTitle(text: stats[idx].label),
                    dataSets: [
                      RadarDataSet(
                        fillColor: Colors.transparent,
                        borderColor: Colors.transparent,
                        entryRadius: 0,
                        dataEntries: List.generate(4, (_) => RadarEntry(value: maxStat)),
                      ),
                      RadarDataSet(
                        fillColor: AppColors.accentEmerald.withValues(alpha: 0.25),
                        borderColor: AppColors.accentEmeraldGlow,
                        borderWidth: 2,
                        entryRadius: 4,
                        dataEntries: [
                          for (final st in stats) RadarEntry(value: st.lvl.toDouble()),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              for (final st in stats) ...[
                Row(
                  children: [
                    SizedBox(
                      width: 82,
                      child: Text(
                        st.full,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 7,
                          value: (st.xp % 50) / 50.0,
                          backgroundColor: AppColors.bgVoid,
                          valueColor: AlwaysStoppedAnimation(st.color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Lv.${st.lvl}',
                      style: AppTypography.monoStat(fontSize: 12, color: st.color),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 2),
                  child: Text(
                    '${st.source} · ${st.xp} XP',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        ObsidianCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Text(
                    'SKILL TREE PERKS',
                    style: AppTypography.microLabel(
                      width,
                      color: AppColors.accentGold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${streakState.availableSkillPoints} SP Available',
                      style: AppTypography.monoStat(
                        fontSize: 12,
                        color: AppColors.accentGold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              for (final perk in kSkillPerks) ...[
                _SkillPerkTile(
                  perk: perk,
                  unlocked: streakState.hasSkill(perk.id),
                  canUnlock: !streakState.hasSkill(perk.id) &&
                      streakState.availableSkillPoints > 0,
                  onUnlock: () {
                    if (hapticsEnabled) HapticFeedback.mediumImpact();
                    ref.read(recoveryProvider.notifier).unlockSkillPerk(perk.id);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SkillPerkTile extends StatelessWidget {
  const _SkillPerkTile({
    required this.perk,
    required this.unlocked,
    required this.canUnlock,
    required this.onUnlock,
  });

  final SkillPerkDef perk;
  final bool unlocked;
  final bool canUnlock;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: unlocked
            ? AppColors.accentEmerald.withValues(alpha: 0.12)
            : AppColors.bgVoid,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: unlocked
              ? AppColors.accentEmerald.withValues(alpha: 0.5)
              : AppColors.borderSubtle,
        ),
      ),
      child: Row(
        children: [
          Icon(
            perk.icon,
            color: unlocked ? AppColors.accentEmeraldGlow : AppColors.accentGold,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  perk.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  perk.effect,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (unlocked)
            const Chip(
              label: Text('Active'),
              visualDensity: VisualDensity.compact,
            )
          else
            FilledButton.tonal(
              onPressed: canUnlock ? onUnlock : null,
              child: const Text('Unlock'),
            ),
        ],
      ),
    );
  }
}
