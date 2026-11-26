import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/recovery_models.dart';
import 'cascading_bars.dart';

/// Bold tabular day counter paired with live H:M:S pill and toggleable
/// cascading time bars.
class StreakTimerDisplay extends StatefulWidget {
  const StreakTimerDisplay({
    super.key,
    required this.elapsed,
    required this.rankTier,
  });

  final Duration elapsed;
  final RankTier rankTier;

  @override
  State<StreakTimerDisplay> createState() => _StreakTimerDisplayState();
}

class _StreakTimerDisplayState extends State<StreakTimerDisplay> {
  bool _showCascadingBars = true;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final days = widget.elapsed.inDays;
    final hours = (widget.elapsed.inHours % 24).toString().padLeft(2, '0');
    final mins = (widget.elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final secs = (widget.elapsed.inSeconds % 60).toString().padLeft(2, '0');
    final nextDays = widget.rankTier.nextTier?.minDays ?? 90;

    return Column(
      children: [
        Semantics(
          label: '$days days, $hours hours, $mins minutes, $secs seconds clean',
          child: Column(
            children: [
              Text(
                days == 1 ? '1 DAY' : '$days DAYS',
                style: AppTypography.heroDays(width),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () =>
                    setState(() => _showCascadingBars = !_showCascadingBars),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.bgElevated,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${hours}h ${mins}m ${secs}s',
                        style: AppTypography.liveSubCounter(width),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _showCascadingBars
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_showCascadingBars) ...[
          const SizedBox(height: 18),
          CascadingTimeBars(
            elapsed: widget.elapsed,
            nextMilestoneDays: nextDays,
          ),
        ],
      ],
    );
  }
}
