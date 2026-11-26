import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/glass_card.dart';
import '../../sanctuary/application/recovery_controller.dart';
import '../application/pomodoro_notifier.dart';

/// Clean Pomodoro Focus Timer powering both Discreet Mask Mode (`ATP Pomodoro`)
/// and Focus Quests.
class PomodoroDiscreetScreen extends ConsumerWidget {
  const PomodoroDiscreetScreen({
    super.key,
    this.isDiscreetShell = true,
  });

  final bool isDiscreetShell;

  Future<void> _openCustomDialog(
    BuildContext context,
    WidgetRef ref,
    PomodoroState current,
  ) async {
    final focusCtrl =
        TextEditingController(text: current.focusMinutes.toString());
    final breakCtrl =
        TextEditingController(text: current.breakMinutes.toString());

    final applied = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Custom Focus Interval'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: focusCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Focus minutes'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: breakCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Break minutes'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Apply'),
          ),
        ],
      ),
    );

    if (applied == true) {
      final f = (int.tryParse(focusCtrl.text.trim()) ?? 25).clamp(1, 180);
      final b = (int.tryParse(breakCtrl.text.trim()) ?? 5).clamp(1, 60);
      ref
          .read(pomodoroProvider.notifier)
          .selectPreset(focusMinutes: f, breakMinutes: b);
    }
    focusCtrl.dispose();
    breakCtrl.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final pomo = ref.watch(pomodoroProvider);
    final sessions = ref.watch(
      recoveryProvider.select(
        (v) => v.value?.streakState.pomodoroSessionsCompleted ?? 0,
      ),
    );

    final mins = (pomo.remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (pomo.remainingSeconds % 60).toString().padLeft(2, '0');
    final accent =
        pomo.isBreakPhase ? AppColors.accentCyan : AppColors.accentEmerald;

    return Scaffold(
      backgroundColor: AppColors.bgVoid,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        color: AppColors.accentEmerald,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ATP Pomodoro',
                        style: AppTypography.cardTitle(width),
                      ),
                      const Spacer(),
                      if (isDiscreetShell)
                        IconButton(
                          tooltip: 'Exit Focus Mask',
                          constraints: const BoxConstraints(
                            minWidth: 44,
                            minHeight: 44,
                          ),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            ref
                                .read(recoveryProvider.notifier)
                                .toggleDiscreetMode();
                          },
                          icon: const Icon(
                            Icons.visibility_outlined,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ObsidianCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Column(
                      children: [
                        Text(
                          pomo.isBreakPhase ? 'RECOVERY BREAK' : 'DEEP FOCUS',
                          style: AppTypography.microLabel(width, color: accent),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: 210,
                          height: 210,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 210,
                                height: 210,
                                child: CircularProgressIndicator(
                                  value: pomo.progress,
                                  strokeWidth: 8,
                                  backgroundColor: AppColors.bgElevated,
                                  valueColor: AlwaysStoppedAnimation(accent),
                                ),
                              ),
                              Text(
                                '$mins:$secs',
                                style: AppTypography.monoStat(
                                  fontSize: 44,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.center,
                          children: [
                            _PresetChip(
                              label: '25 / 5',
                              selected: pomo.focusMinutes == 25 &&
                                  pomo.breakMinutes == 5,
                              onTap: () => ref
                                  .read(pomodoroProvider.notifier)
                                  .selectPreset(
                                    focusMinutes: 25,
                                    breakMinutes: 5,
                                  ),
                            ),
                            _PresetChip(
                              label: '50 / 10',
                              selected: pomo.focusMinutes == 50 &&
                                  pomo.breakMinutes == 10,
                              onTap: () => ref
                                  .read(pomodoroProvider.notifier)
                                  .selectPreset(
                                    focusMinutes: 50,
                                    breakMinutes: 10,
                                  ),
                            ),
                            _PresetChip(
                              label: 'Custom',
                              selected: !(pomo.focusMinutes == 25 &&
                                      pomo.breakMinutes == 5) &&
                                  !(pomo.focusMinutes == 50 &&
                                      pomo.breakMinutes == 10),
                              onTap: () => _openCustomDialog(context, ref, pomo),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 10,
                          children: [
                            FilledButton.icon(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                ref
                                    .read(pomodoroProvider.notifier)
                                    .toggleRunning();
                              },
                              icon: Icon(
                                pomo.isRunning
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                              ),
                              label: Text(pomo.isRunning ? 'Pause' : 'Start'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  ref.read(pomodoroProvider.notifier).reset(),
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Reset'),
                            ),
                          ],
                        ),
                        if (!pomo.isBreakPhase) ...[
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              ref
                                  .read(pomodoroProvider.notifier)
                                  .completeNowForFocusReward();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Focus session logged. +35 XP and +15 Gold.',
                                  ),
                                ),
                              );
                            },
                            child: const Text('Complete Session Early'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ObsidianCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Completed Focus Blocks',
                            style: AppTypography.bodyCopy(
                              width,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '$sessions',
                          style: AppTypography.monoStat(
                            fontSize: 18,
                            color: AppColors.accentEmeraldGlow,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.accentEmerald.withValues(alpha: 0.2),
      backgroundColor: AppColors.bgElevated,
      labelStyle: TextStyle(
        color: selected ? AppColors.accentEmeraldGlow : AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(
        color: selected ? AppColors.accentEmerald : AppColors.borderSubtle,
      ),
    );
  }
}
