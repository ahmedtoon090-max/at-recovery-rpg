import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/glass_card.dart';
import '../../analytics/presentation/analytics_screen.dart';
import '../../sanctuary/application/recovery_controller.dart';
import '../../sanctuary/domain/recovery_models.dart';
import 'log_urge_sheet.dart';

/// Filterable Urge, Victory, Check-in, and Post-Mortem reflection journal + Analytics toggle.
class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  UrgeLogType? _filter;
  bool _showAnalytics = false;

  Future<void> _openLogger() async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const LogUrgeSheet(),
    );
  }

  Future<void> _deleteWithUndo(UrgeLog log) async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(recoveryProvider.notifier).softDeleteLog(log.id);
    if (!mounted) return;
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Journal entry archived.'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () =>
              ref.read(recoveryProvider.notifier).restoreLog(log.id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final asyncState = ref.watch(recoveryProvider);

    return asyncState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: FilledButton(
          onPressed: () => ref.invalidate(recoveryProvider),
          child: const Text('Retry loading journal'),
        ),
      ),
      data: (appState) {
        final allLogs = appState.urgeLogs;
        final filtered = _filter == null
            ? allLogs
            : allLogs.where((e) => e.type == _filter).toList(growable: false);

        final bodyContent = _showAnalytics
            ? AnalyticsScreen(embedded: widget.embedded)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: _filter == null,
                        onSelected: (_) => setState(() => _filter = null),
                      ),
                      ChoiceChip(
                        label: const Text('Urge Won'),
                        selected: _filter == UrgeLogType.urgeDefeated,
                        onSelected: (_) => setState(() => _filter = UrgeLogType.urgeDefeated),
                      ),
                      ChoiceChip(
                        label: const Text('Check-ins'),
                        selected: _filter == UrgeLogType.checkIn,
                        onSelected: (_) => setState(() => _filter = UrgeLogType.checkIn),
                      ),
                      ChoiceChip(
                        label: const Text('Post-Mortem'),
                        selected: _filter == UrgeLogType.relapse,
                        onSelected: (_) => setState(() => _filter = UrgeLogType.relapse),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (allLogs.isEmpty)
                    ObsidianCard(
                      child: Column(
                        children: [
                          Text('No journal entries yet', style: AppTypography.cardTitle(width)),
                          const SizedBox(height: 6),
                          Text(
                            'Log urges you defeated, daily check-ins, or honest reflections to unlock pattern analytics.',
                            style: AppTypography.bodyCopy(width),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 14),
                          FilledButton(onPressed: _openLogger, child: const Text('Log First Entry')),
                        ],
                      ),
                    )
                  else if (filtered.isEmpty)
                    ObsidianCard(
                      child: Column(
                        children: [
                          Text('No entries match this filter', style: AppTypography.cardTitle(width)),
                          const SizedBox(height: 10),
                          OutlinedButton(
                            onPressed: () => setState(() => _filter = null),
                            child: const Text('Clear Filter'),
                          ),
                        ],
                      ),
                    )
                  else
                    for (final log in filtered) ...[
                      _JournalTile(log: log, onDelete: () => _deleteWithUndo(log)),
                      const SizedBox(height: 10),
                    ],
                ],
              );

        final headerBar = Padding(
          padding: EdgeInsets.fromLTRB(widget.embedded ? 0 : 16, 8, widget.embedded ? 0 : 16, 4),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  if (!widget.embedded)
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Trigger Journal'),
                          selected: !_showAnalytics,
                          onSelected: (_) => setState(() => _showAnalytics = false),
                        ),
                        ChoiceChip(
                          label: const Text('Analytics'),
                          selected: _showAnalytics,
                          onSelected: (_) => setState(() => _showAnalytics = true),
                        ),
                      ],
                    ),
                  if (!_showAnalytics)
                    FilledButton.icon(
                      onPressed: _openLogger,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Log Event'),
                    ),
                ],
              ),
            ),
          ),
        );

        if (widget.embedded) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              headerBar,
              const SizedBox(height: 10),
              bodyContent,
            ],
          );
        }

        return Column(
          children: [
            headerBar,
            Expanded(
              child: _showAnalytics
                  ? bodyContent
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 980),
                          child: bodyContent,
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _JournalTile extends StatelessWidget {
  const _JournalTile({
    required this.log,
    required this.onDelete,
  });

  final UrgeLog log;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final (badgeLabel, badgeColor) = switch (log.type) {
      UrgeLogType.urgeDefeated => ('URGE WON', AppColors.accentEmeraldGlow),
      UrgeLogType.checkIn => ('CHECK-IN', AppColors.accentCyan),
      UrgeLogType.relapse => ('POST-MORTEM', AppColors.accentGold),
    };
    final dateFmt = DateFormat('MMM d · HH:mm').format(log.timestampUtc.toLocal());

    return ObsidianCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: badgeColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        badgeLabel,
                        style: AppTypography.microLabel(
                          width,
                          color: badgeColor,
                        ),
                      ),
                    ),
                    Text(
                      'Intensity ${log.intensity}/10',
                      style: AppTypography.monoStat(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      dateFmt,
                      style: AppTypography.monoStat(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Delete entry',
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (log.triggers.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final t in log.triggers)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.bgElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Text(
                      t,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                if (log.mood.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.bgElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Text(
                      'Mood: ${log.mood}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (log.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              log.note,
              style: AppTypography.bodyCopy(
                width,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
