import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../quests/presentation/relapse_postmortem_sheet.dart';
import '../../sanctuary/application/recovery_controller.dart';
import '../../sanctuary/domain/recovery_models.dart';

/// Fast 10-second urge victory, check-in, or calm post-mortem log sheet.
class LogUrgeSheet extends ConsumerStatefulWidget {
  const LogUrgeSheet({super.key});

  @override
  ConsumerState<LogUrgeSheet> createState() => _LogUrgeSheetState();
}

class _LogUrgeSheetState extends ConsumerState<LogUrgeSheet> {
  UrgeLogType _type = UrgeLogType.urgeDefeated;
  double _intensity = 6;
  final Set<String> _triggers = {'Stress'};
  String _mood = 'Restless';
  final TextEditingController _noteCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    await ref.read(recoveryProvider.notifier).addJournalLog(
          type: _type,
          intensity: _intensity.round(),
          triggers: _triggers.isEmpty ? const ['Unspecified'] : _triggers.toList(),
          mood: _mood,
          note: _noteCtrl.text.trim(),
        );

    if (!mounted) return;
    navigator.pop(true);
    messenger.clearSnackBars();
    final msg = switch (_type) {
      UrgeLogType.urgeDefeated => 'Urge victory logged. +50 XP and +20 Gold.',
      UrgeLogType.checkIn => 'Check-in logged. +15 XP and +5 Gold.',
      UrgeLogType.relapse =>
        'Post-mortem archived. +15 Wisdom XP for honest reflection.',
    };
    messenger.showSnackBar(SnackBar(content: Text(msg)));
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
            Text('Log Recovery Event', style: AppTypography.screenTitle(width)),
            const SizedBox(height: 12),
            SegmentedButton<UrgeLogType>(
              segments: const [
                ButtonSegment(
                  value: UrgeLogType.urgeDefeated,
                  label: Text('Urge Won'),
                ),
                ButtonSegment(
                  value: UrgeLogType.checkIn,
                  label: Text('Check-in'),
                ),
                ButtonSegment(
                  value: UrgeLogType.relapse,
                  label: Text('Slip Reset'),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (sel) => setState(() => _type = sel.first),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Urge Intensity', style: AppTypography.cardTitle(width)),
                Text(
                  '${_intensity.round()} / 10',
                  style: AppTypography.monoStat(
                    fontSize: 15,
                    color: AppColors.accentGold,
                  ),
                ),
              ],
            ),
            Slider(
              value: _intensity,
              min: 1,
              max: 10,
              divisions: 9,
              activeColor: AppColors.accentEmerald,
              onChanged: (v) => setState(() => _intensity = v),
            ),
            const SizedBox(height: 8),
            Text('Triggers', style: AppTypography.cardTitle(width)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in kCampfireTriggerChips)
                  FilterChip(
                    label: Text(t),
                    selected: _triggers.contains(t),
                    onSelected: (v) => setState(() {
                      if (v) {
                        _triggers.add(t);
                      } else {
                        _triggers.remove(t);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Mood', style: AppTypography.cardTitle(width)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in kCampfireMoodChips)
                  ChoiceChip(
                    label: Text(m),
                    selected: _mood == m,
                    onSelected: (_) => setState(() => _mood = m),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Private note (optional)',
                hintText: 'What shifted your focus or what triggered this?',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: Text(
                _type == UrgeLogType.relapse
                    ? 'Archive Streak & Save (+15 Wisdom XP)'
                    : 'Save Entry',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
