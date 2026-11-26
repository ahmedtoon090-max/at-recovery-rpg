import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../sanctuary/application/recovery_controller.dart';
import '../../sanctuary/domain/recovery_models.dart';

const List<String> kCampfireTriggerChips = [
  'Boredom',
  'Late Night',
  'Stress',
  'Social Media',
  'Loneliness',
  'Fatigue',
];

const List<String> kCampfireMoodChips = [
  'Restless',
  'Anxious',
  'Drained',
  'Overwhelmed',
  'Calm',
];

/// Roguelite Harm-Reduction Campfire Post-Mortem:
/// NEVER wipes Citadel tiers, Chronicle Acts, Spellbook ranks, Stats, or Foil Relics.
/// Resets active arc timer so the chaser effect stops, and awards +20 WIS XP.
class RelapsePostMortemSheet extends ConsumerStatefulWidget {
  const RelapsePostMortemSheet({super.key});

  @override
  ConsumerState<RelapsePostMortemSheet> createState() =>
      _RelapsePostMortemSheetState();
}

class _RelapsePostMortemSheetState
    extends ConsumerState<RelapsePostMortemSheet> {
  final Set<String> _selectedTriggers = {'Late Night'};
  String _selectedMood = 'Restless';
  double _intensity = 6;
  final TextEditingController _lessonCtrl = TextEditingController();
  final TextEditingController _spellIfCtrl = TextEditingController();
  final TextEditingController _spellThenCtrl = TextEditingController();
  bool _forgeSpell = false;
  bool _saving = false;

  @override
  void dispose() {
    _lessonCtrl.dispose();
    _spellIfCtrl.dispose();
    _spellThenCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final notifier = ref.read(recoveryProvider.notifier);

    await notifier.recordRelapsePostMortem(
      triggers: _selectedTriggers.isEmpty
          ? const ['Unspecified']
          : _selectedTriggers.toList(),
      mood: _selectedMood,
      intensity: _intensity.round(),
      lessonNote: _lessonCtrl.text.trim().isEmpty
          ? 'Campfire reflection sealed. Chaser stopped cleanly.'
          : _lessonCtrl.text.trim(),
    );

    if (_forgeSpell &&
        _spellIfCtrl.text.trim().isNotEmpty &&
        _spellThenCtrl.text.trim().isNotEmpty) {
      await notifier.addCounterSpell(
        triggerCue: _spellIfCtrl.text.trim(),
        actionPlan: _spellThenCtrl.text.trim(),
      );
    }

    if (!mounted) return;
    navigator.pop(true);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Campfire reflection logged. Citadel & Relics preserved. +20 WIS XP.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  color: AppColors.accentGold,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'FALLEN RUN · CAMPFIRE REFLECTION',
                  style: AppTypography.microLabel(width, color: AppColors.accentGold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Stand Up Without Shame', style: AppTypography.screenTitle(width)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentGold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.35)),
              ),
              child: Text(
                'Roguelite Anti-Wipe Pact: Your Citadel tiers, Chronicle acts, Counter-Spell ranks, stats, and Foil Relics stay 100% intact. Only the active arc clock restarts (+20 WIS XP).',
                style: AppTypography.bodyCopy(width),
              ),
            ),
            const SizedBox(height: 16),
            Text('HALT & Context Triggers', style: AppTypography.cardTitle(width)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in [...kHaltOrbs.map((h) => h.label), ...kCampfireTriggerChips])
                  FilterChip(
                    label: Text(t),
                    selected: _selectedTriggers.contains(t),
                    onSelected: (v) => setState(() {
                      if (v) {
                        _selectedTriggers.add(t);
                      } else {
                        _selectedTriggers.remove(t);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Urge Intensity', style: AppTypography.cardTitle(width)),
                Text(
                  '${_intensity.round()} / 10',
                  style: AppTypography.monoStat(fontSize: 13, color: AppColors.accentGold),
                ),
              ],
            ),
            Slider(
              value: _intensity,
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (v) => setState(() => _intensity = v),
            ),
            Text('State of Mind', style: AppTypography.cardTitle(width)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in kCampfireMoodChips)
                  ChoiceChip(
                    label: Text(m),
                    selected: _selectedMood == m,
                    onSelected: (_) => setState(() => _selectedMood = m),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _lessonCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'One-line boundary to guard tomorrow',
                hintText: 'Dock phone outside the bedroom after 23:00',
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Forge IF -> THEN Counter-Spell from this slip'),
              value: _forgeSpell,
              onChanged: (v) => setState(() => _forgeSpell = v),
            ),
            if (_forgeSpell) ...[
              TextField(
                controller: _spellIfCtrl,
                decoration: const InputDecoration(
                  labelText: 'IF trigger happens...',
                  hintText: 'Alone with phone after 22:30',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _spellThenCtrl,
                decoration: const InputDecoration(
                  labelText: 'THEN immediately execute...',
                  hintText: 'Drop phone on hallway stand & do 20 pushups',
                ),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _saving ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accentGold,
                      foregroundColor: AppColors.bgVoid,
                    ),
                    child: const Text('Seal Campfire (+20 WIS XP)'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
