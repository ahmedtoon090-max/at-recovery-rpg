import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/rpg_widgets.dart';
import '../../sanctuary/application/app_providers.dart';
import '../../sanctuary/application/recovery_controller.dart';
import '../../sanctuary/domain/recovery_models.dart';
import '../../sanctuary/presentation/widgets/trigger_shield_card.dart';
import 'pomodoro_discreet_screen.dart';
import 'relapse_postmortem_sheet.dart';

/// Tab 3 — SPELLBOOK OF VOWS:
/// Gollwitzer IF->THEN Counter-Spells (Rank I-V), Painted Daily Tribute Chest,
/// Daily Citadel Vows, Trigger Shield, Focus Timer, and Fallen Run Campfire.
class QuestsScreen extends ConsumerWidget {
  const QuestsScreen({super.key});

  Future<void> _showAddSpellDialog(BuildContext context, WidgetRef ref) async {
    final ifCtrl = TextEditingController();
    final thenCtrl = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Forge IF -> THEN Counter-Spell'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ifCtrl,
              decoration: const InputDecoration(
                labelText: 'IF (Trigger Cue)',
                hintText: 'Restless alone past 10 PM',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: thenCtrl,
              decoration: const InputDecoration(
                labelText: 'THEN (Physical Reset)',
                hintText: 'Dock phone outside & do 20 pushups',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Forge Spell')),
        ],
      ),
    );
    if (created == true && ifCtrl.text.trim().isNotEmpty && thenCtrl.text.trim().isNotEmpty) {
      await ref.read(recoveryProvider.notifier).addCounterSpell(
            triggerCue: ifCtrl.text.trim(),
            actionPlan: thenCtrl.text.trim(),
          );
    }
    ifCtrl.dispose();
    thenCtrl.dispose();
  }

  Future<void> _showAddQuestDialog(BuildContext context, WidgetRef ref) async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Citadel Vow'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Vow title',
                hintText: 'Evening reading for 20 minutes',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: 'Details (optional)',
                hintText: 'Replace late scrolling with a chapter',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Add Vow')),
        ],
      ),
    );
    if (created == true && titleCtrl.text.trim().isNotEmpty) {
      await ref.read(recoveryProvider.notifier).addCustomQuest(
            title: titleCtrl.text.trim(),
            description: descCtrl.text.trim(),
          );
    }
    titleCtrl.dispose();
    descCtrl.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final desktop = AppTypography.isDesktopWidth(width);
    final asyncState = ref.watch(recoveryProvider);
    final nowLocal = ref.watch(clockProvider).now();
    final todayKey = formatUtcDateKey(nowLocal);

    return asyncState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: FilledButton(
          onPressed: () => ref.invalidate(recoveryProvider),
          child: const Text('Retry loading spellbook'),
        ),
      ),
      data: (appState) {
        final s = appState.streakState;
        final doneToday = appState.countQuestsCompletedOn(nowLocal);
        final chestReady = doneToday >= 3 && s.claimedDailyChestDate != todayKey;
        final chestClaimed = s.claimedDailyChestDate == todayKey;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, desktop ? 32 : 136),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      Text('Spellbook & Vows', style: AppTypography.screenTitle(width)),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          RpgBevelButton(
                            compact: true,
                            icon: Icons.auto_fix_high_rounded,
                            variant: RpgButtonVariant.twilight,
                            label: 'Forge Spell',
                            onPressed: () => _showAddSpellDialog(context, ref),
                          ),
                          RpgBevelButton(
                            compact: true,
                            icon: Icons.add_rounded,
                            variant: RpgButtonVariant.emerald,
                            label: 'New Vow',
                            onPressed: () => _showAddQuestDialog(context, ref),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OrnateRpgFrame(
                    accentColor: chestReady ? AppColors.moltenGold : AppColors.arcaneEmerald,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 58,
                              height: 58,
                              child: Image.asset(
                                GameArtAssets.lootChest,
                                fit: BoxFit.contain,
                                gaplessPlayback: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Level ${s.level} · Daily Tribute Chest',
                                    style: AppTypography.cinzelDisplay(width, size: 16, color: AppColors.moltenGold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${s.xpIntoLevel} / 100 XP · ${s.gold} Gold',
                                    style: AppTypography.monoStat(fontSize: 12, color: AppColors.arcaneEmerald),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        HadesProgressBar(value: s.xpIntoLevel / 100.0, fillColor: AppColors.moltenGold, height: 9),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              chestClaimed
                                  ? 'Daily Tribute Chest claimed today!'
                                  : 'Complete 3 daily vows ($doneToday/3) to unlock Chest (+45 XP · +25 G)',
                              style: AppTypography.bodyCopy(width),
                            ),
                            RpgBevelButton(
                              compact: true,
                              icon: Icons.inventory_2_rounded,
                              variant: chestReady ? RpgButtonVariant.gold : RpgButtonVariant.twilight,
                              label: chestClaimed ? 'Chest Opened' : (chestReady ? 'Open Chest' : '$doneToday / 3 Ready'),
                              onPressed: chestReady
                                  ? () async {
                                      if (appState.hapticsEnabled) HapticFeedback.mediumImpact();
                                      final ok = await ref.read(recoveryProvider.notifier).claimDailyQuestChest();
                                      if (ok && context.mounted) {
                                        try {
                                          Confetti.launch(context, options: const ConfettiOptions(particleCount: 40, spread: 60, y: 0.55));
                                        } catch (_) {}
                                      }
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  OrnateRpgFrame(
                    accentColor: AppColors.accentCyan,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('GOLLWITZER IF -> THEN COUNTER-SPELLS', style: AppTypography.microLabel(width, color: AppColors.accentCyan)),
                        const SizedBox(height: 4),
                        Text(
                          'Equipped spells fire directly inside Mirage Ambush for -50 CRIT & advance Ranks I–V.',
                          style: AppTypography.bodyCopy(width),
                        ),
                        const SizedBox(height: 12),
                        for (final sp in s.counterSpells.where((c) => !c.isDeleted)) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.bgVoid.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: sp.equipped
                                    ? AppColors.accentCyan.withValues(alpha: 0.55)
                                    : AppColors.borderSubtle,
                              ),
                            ),
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
                                      'RANK ${sp.romanRank} · ${sp.casts} CASTS',
                                      style: AppTypography.monoStat(fontSize: 11, color: AppColors.accentCyan),
                                    ),
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        FilterChip(
                                          label: Text(sp.equipped ? 'Equipped' : 'Equip'),
                                          selected: sp.equipped,
                                          onSelected: (_) => ref.read(recoveryProvider.notifier).toggleSpellEquipped(sp.id),
                                        ),
                                        RpgBevelButton(
                                          compact: true,
                                          variant: RpgButtonVariant.twilight,
                                          label: 'Practice (+15 VIT)',
                                          onPressed: () {
                                            if (appState.hapticsEnabled) HapticFeedback.lightImpact();
                                            ref.read(recoveryProvider.notifier).castCounterSpell(sp.id);
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text('IF: ${sp.triggerCue}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                const SizedBox(height: 3),
                                Text('THEN: ${sp.actionPlan}', style: AppTypography.bodyCopy(width)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TriggerShieldCard(
                    shieldChecks: s.shieldChecks,
                    nowLocal: nowLocal,
                    onToggle: (id) {
                      if (appState.hapticsEnabled) HapticFeedback.selectionClick();
                      ref.read(recoveryProvider.notifier).toggleTriggerShield(id);
                    },
                  ),
                  const SizedBox(height: 14),
                  OrnateRpgFrame(
                    accentColor: AppColors.accentCyan,
                    child: LayoutBuilder(
                      builder: (_, box) {
                        final compact = box.maxWidth < 460;
                        final info = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ATP POMODORO FOCUS', style: AppTypography.microLabel(width, color: AppColors.accentCyan)),
                            const SizedBox(height: 4),
                            Text('Deep Focus Timer', style: AppTypography.cardTitle(width)),
                            const SizedBox(height: 4),
                            Text('Complete a 25m or 50m sprint for +35 XP & +30 FOC.', style: AppTypography.bodyCopy(width)),
                          ],
                        );
                        final cta = RpgBevelButton(
                          compact: true,
                          variant: RpgButtonVariant.emerald,
                          icon: Icons.timer_outlined,
                          label: 'Open Timer',
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => const PomodoroDiscreetScreen(isDiscreetShell: false)),
                          ),
                        );
                        return compact
                            ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [info, const SizedBox(height: 12), cta])
                            : Row(children: [Expanded(child: info), const SizedBox(width: 12), cta]);
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  for (final quest in appState.quests) ...[
                    _QuestRowCard(
                      quest: quest,
                      doneToday: quest.isCompletedOn(nowLocal),
                      onComplete: () {
                        if (appState.hapticsEnabled) HapticFeedback.mediumImpact();
                        ref.read(recoveryProvider.notifier).completeQuest(quest.id);
                      },
                      onDelete: () => ref.read(recoveryProvider.notifier).deleteQuest(quest.id),
                    ),
                    const SizedBox(height: 10),
                  ],
                  OrnateRpgFrame(
                    accentColor: AppColors.torchAmber,
                    child: LayoutBuilder(
                      builder: (_, box) {
                        final compact = box.maxWidth < 460;
                        final info = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Fallen Run · Campfire Reflection', style: AppTypography.cardTitle(width)),
                            const SizedBox(height: 4),
                            Text('Citadel & Relics stay intact. Capture trigger honestly for +20 WIS XP.', style: AppTypography.bodyCopy(width)),
                          ],
                        );
                        final btn = RpgBevelButton(
                          compact: true,
                          variant: RpgButtonVariant.gold,
                          label: 'Open Campfire',
                          onPressed: () => showModalBottomSheet<bool>(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => const RelapsePostMortemSheet(),
                          ),
                        );
                        return compact
                            ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [info, const SizedBox(height: 12), btn])
                            : Row(children: [Expanded(child: info), const SizedBox(width: 12), btn]);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _QuestRowCard extends StatelessWidget {
  const _QuestRowCard({
    required this.quest,
    required this.doneToday,
    required this.onComplete,
    required this.onDelete,
  });

  final QuestItem quest;
  final bool doneToday;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return OrnateRpgFrame(
      padding: const EdgeInsets.all(14),
      accentColor: doneToday ? AppColors.arcaneEmerald : AppColors.borderHighlight,
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: doneToday ? null : onComplete,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: doneToday ? AppColors.arcaneEmerald : AppColors.bgVoid,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: doneToday ? AppColors.arcaneEmerald : AppColors.borderHighlight),
              ),
              child: Icon(doneToday ? Icons.check_rounded : Icons.circle_outlined, color: doneToday ? AppColors.bgVoid : AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quest.title,
                  style: AppTypography.cardTitle(width).copyWith(
                    decoration: doneToday ? TextDecoration.lineThrough : null,
                    color: doneToday ? AppColors.textSecondary : AppColors.textPrimary,
                  ),
                ),
                if (quest.description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(quest.description, style: AppTypography.bodyCopy(width)),
                ],
                const SizedBox(height: 6),
                Text(
                  '+${quest.xpReward} XP · +${quest.goldReward} Gold · ${quest.streakCount}d streak',
                  style: AppTypography.monoStat(fontSize: 12, color: AppColors.moltenGold),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove vow',
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
