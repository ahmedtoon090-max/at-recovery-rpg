import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/glass_card.dart';

const List<String> kPhysicalResetChallenges = [
  'Drop and do 20 crisp pushups right now.',
  'Splash ice-cold water on your face for 20 seconds.',
  'Stand up and walk outside or around the room for 3 minutes.',
  'Hold a steady forearm plank for 60 seconds.',
  'Complete 25 deep bodyweight squats with slow breathing.',
  'Leave your phone in another room and drink a full glass of water.',
];

/// Shufflable 60-second physical reset challenge + Boss Battle Critical Strike.
class PhysicalResetCard extends StatefulWidget {
  const PhysicalResetCard({
    super.key,
    this.critDamage = 50,
    this.onCriticalStrike,
  });

  final int critDamage;
  final VoidCallback? onCriticalStrike;

  @override
  State<PhysicalResetCard> createState() => _PhysicalResetCardState();
}

class _PhysicalResetCardState extends State<PhysicalResetCard> {
  final _random = Random();
  late int _index;
  int _secondsLeft = 60;
  bool _running = false;
  bool _strikeUsed = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _index = _random.nextInt(kPhysicalResetChallenges.length);
  }

  void _shuffle() {
    _timer?.cancel();
    setState(() {
      _index = (_index + 1 + _random.nextInt(kPhysicalResetChallenges.length - 1)) %
          kPhysicalResetChallenges.length;
      _secondsLeft = 60;
      _running = false;
    });
  }

  void _toggleTimer() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    if (_secondsLeft <= 0) _secondsLeft = 60;
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        _timer?.cancel();
        setState(() {
          _secondsLeft = 0;
          _running = false;
        });
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return ObsidianCard(
      backgroundColor: AppColors.bgElevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.fitness_center_rounded,
                size: 16,
                color: AppColors.accentCyan,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ATTACK 2 · PHYSICAL CRITICAL STRIKE (-${widget.critDamage} HP)',
                  style: AppTypography.microLabel(
                    width,
                    color: AppColors.accentCyan,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: 'Shuffle challenge',
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: _shuffle,
                icon: const Icon(
                  Icons.shuffle_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            kPhysicalResetChallenges[_index],
            style: AppTypography.cardTitle(width),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.tonalIcon(
                onPressed: _toggleTimer,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accentCyan.withValues(alpha: 0.16),
                  foregroundColor: AppColors.accentCyan,
                ),
                icon: Icon(
                  _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
                label: Text(
                  _secondsLeft == 0
                      ? 'Timer Complete'
                      : (_running ? 'Pause 60s' : 'Start 60s Reset'),
                ),
              ),
              Text(
                '00:${_secondsLeft.toString().padLeft(2, '0')}',
                style: AppTypography.monoStat(
                  fontSize: 16,
                  color: _secondsLeft == 0
                      ? AppColors.accentEmeraldGlow
                      : AppColors.textPrimary,
                ),
              ),
              if (widget.onCriticalStrike != null)
                FilledButton.icon(
                  onPressed: _strikeUsed
                      ? null
                      : () {
                          setState(() => _strikeUsed = true);
                          widget.onCriticalStrike!();
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accentGold,
                    foregroundColor: AppColors.bgVoid,
                  ),
                  icon: const Icon(Icons.flash_on_rounded, size: 17),
                  label: Text(
                    _strikeUsed
                        ? 'CRIT Landed'
                        : 'Land CRIT (-${widget.critDamage} HP)',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
