import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/rpg_widgets.dart';
import '../../../journal/presentation/log_urge_sheet.dart';
import '../../../quests/presentation/pomodoro_discreet_screen.dart';
import '../../application/recovery_controller.dart';
import '../../domain/recovery_models.dart';
import 'trigger_shield_card.dart';

/// Slide-up Campfire Vitality Drawer featuring circular glowing HALT VitalityOrbs
/// and proactive 2-minute restoration mini-quests.
Future<void> showCampfireVitalityDrawer(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.twilightDeep,
    builder: (_) => Consumer(
      builder: (ctx, ref, _) {
        final s = ref.watch(recoveryProvider).value?.streakState;
        if (s == null) return const SizedBox.shrink();
        final width = MediaQuery.sizeOf(ctx).width;
        final activeOrbs = kHaltOrbs.where((o) => s.haltFlags[o.id] == true).toList();

        IconData iconFor(String id) => switch (id) {
              'hungry' => Icons.restaurant_rounded,
              'angry' => Icons.whatshot_rounded,
              'lonely' => Icons.people_outline_rounded,
              _ => Icons.bedtime_outlined,
            };

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded, color: AppColors.torchAmber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Campfire HALT Vitality',
                        style: AppTypography.cinzelTitle(width, color: AppColors.moltenGold),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Tap any vulnerability orb draining your Shield to receive an instant Guardian restoration quest.',
                  style: AppTypography.bodyCopy(width),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (final orb in kHaltOrbs)
                      VitalityOrbButton(
                        label: orb.id == 'angry' ? 'Angry' : orb.label,
                        icon: iconFor(orb.id),
                        active: s.haltFlags[orb.id] == true,
                        accent: AppColors.torchAmber,
                        onTap: () => ref.read(recoveryProvider.notifier).toggleHaltOrb(orb.id),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                if (activeOrbs.isEmpty)
                  OrnateRpgFrame(
                    accentColor: AppColors.arcaneEmerald,
                    child: Text(
                      'All four HALT reserves steady. Keep lighting your Citadel lantern cleanly.',
                      style: AppTypography.bodyCopy(width, color: AppColors.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  for (final orb in activeOrbs) ...[
                    OrnateRpgFrame(
                      accentColor: AppColors.torchAmber,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'RESTORE ${orb.label.toUpperCase()}',
                            style: AppTypography.microLabel(width, color: AppColors.torchAmber),
                          ),
                          const SizedBox(height: 6),
                          Text(orb.restorationQuest, style: AppTypography.bodyCopy(width, color: AppColors.textPrimary)),
                          const SizedBox(height: 10),
                          RpgBevelButton(
                            label: 'Complete Restoration (+10 XP)',
                            icon: Icons.verified_rounded,
                            variant: RpgButtonVariant.emerald,
                            compact: true,
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              ref.read(recoveryProvider.notifier).completeHaltRestoration(orb.id);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
              ],
            ),
          ),
        );
      },
    ),
  );
}

/// Slide-up Citadel Forge, Trigger Shield & Deep Focus Drawer.
Future<void> showForgeAndShieldDrawer(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.twilightDeep,
    builder: (_) => Consumer(
      builder: (ctx, ref, _) {
        final appState = ref.watch(recoveryProvider).value;
        if (appState == null) return const SizedBox.shrink();
        final s = appState.streakState;
        final width = MediaQuery.sizeOf(ctx).width;
        final nowLocal = DateTime.now();

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.castle_outlined, color: AppColors.moltenGold),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Citadel Forge & Shield',
                        style: AppTypography.cinzelTitle(width, color: AppColors.moltenGold),
                      ),
                    ),
                    Text('${s.gold}G', style: AppTypography.monoStat(fontSize: 13, color: AppColors.moltenGold)),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final st in kCastleStructures)
                      Builder(
                        builder: (_) {
                          final lvl = s.structureLevel(st.id);
                          final maxed = lvl >= st.maxLevel;
                          final cost = st.costForLevel(
                            lvl,
                            architectDiscount: s.hasSkill('citadel_architect'),
                          );
                          final canAfford = !maxed && s.gold >= cost;
                          return RpgBevelButton(
                            compact: true,
                            variant: canAfford ? RpgButtonVariant.gold : RpgButtonVariant.twilight,
                            label: '${st.name} Lv.$lvl ${maxed ? "MAX" : "(${cost}G)"}',
                            onPressed: canAfford
                                ? () => ref.read(recoveryProvider.notifier).upgradeCastleStructure(st.id)
                                : null,
                          );
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                TriggerShieldCard(
                  shieldChecks: s.shieldChecks,
                  nowLocal: nowLocal,
                  onToggle: (id) => ref.read(recoveryProvider.notifier).toggleTriggerShield(id),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: RpgBevelButton(
                        compact: true,
                        icon: Icons.edit_note_rounded,
                        variant: RpgButtonVariant.twilight,
                        label: 'Log Urge',
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          showModalBottomSheet<bool>(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => const LogUrgeSheet(),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RpgBevelButton(
                        compact: true,
                        icon: Icons.timer_outlined,
                        variant: RpgButtonVariant.emerald,
                        label: 'Focus Timer',
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const PomodoroDiscreetScreen(isDiscreetShell: false),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.go('/journal');
                  },
                  icon: const Icon(Icons.book_outlined, size: 16),
                  label: const Text('Open Full Trigger Journal'),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
