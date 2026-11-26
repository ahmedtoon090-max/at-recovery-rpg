import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/engine/recovery_algorithm.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/rpg_widgets.dart';
import '../../sanctuary/domain/recovery_models.dart';

/// Step B: Tactile 3-Second Hold "Seal Your Vow" Lantern Commitment.
class SealYourVowView extends StatefulWidget {
  const SealYourVowView({
    super.key,
    required this.lampbearerName,
    required this.vowTitle,
    required this.onSealed,
  });

  final String lampbearerName;
  final String vowTitle;
  final VoidCallback onSealed;

  @override
  State<SealYourVowView> createState() => _SealYourVowViewState();
}

class _SealYourVowViewState extends State<SealYourVowView> {
  double _holdProgress = 0.0;
  Timer? _timer;
  bool _completed = false;

  void _startHold() {
    if (_completed) return;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _holdProgress = (_holdProgress + (1 / 30)).clamp(0.0, 1.0));
      if ((_holdProgress * 10).round() % 3 == 0) {
        HapticFeedback.selectionClick();
      }
      if (_holdProgress >= 1.0) {
        t.cancel();
        _completed = true;
        HapticFeedback.heavyImpact();
        widget.onSealed();
      }
    });
  }

  void _cancelHold() {
    _timer?.cancel();
    if (!_completed && mounted) setState(() => _holdProgress = 0.0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('THE SEAL OF ${widget.vowTitle.toUpperCase()}', style: AppTypography.microLabel(width, color: AppColors.moltenGold)),
        const SizedBox(height: 10),
        Text(
          'Seal Day 1, ${widget.lampbearerName.isEmpty ? 'Warden' : widget.lampbearerName}',
          style: AppTypography.screenTitle(width),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Hold the Lantern Seal for 3 seconds to forge your Citadel world and custom Counter-Spells.',
          style: AppTypography.bodyCopy(width),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 26),
        GestureDetector(
          onTapDown: (_) => _startHold(),
          onTapUp: (_) => _cancelHold(),
          onTapCancel: _cancelHold,
          child: SizedBox(
            width: 158,
            height: 158,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 158,
                  height: 158,
                  child: CircularProgressIndicator(
                    value: _holdProgress,
                    strokeWidth: 7,
                    backgroundColor: AppColors.twilightMid,
                    valueColor: const AlwaysStoppedAnimation(AppColors.arcaneEmerald),
                  ),
                ),
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.arcaneEmerald.withValues(alpha: 0.12 + _holdProgress * 0.25),
                    border: Border.all(color: AppColors.arcaneEmerald, width: 1.5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 58,
                        height: 58,
                        child: Image.asset(
                          GameArtAssets.relicEmblem,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(_holdProgress * 100).round()}%',
                        style: AppTypography.monoStat(fontSize: 13, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        TextButton(
          onPressed: widget.onSealed,
          child: const Text('Tap to Seal Immediately'),
        ),
      ],
    );
  }
}

/// Step C: 3.5s Calibration Ring stepping through live setup milestones.
class ForgingCalibrationView extends StatefulWidget {
  const ForgingCalibrationView({super.key, required this.onFinished});
  final VoidCallback onFinished;

  @override
  State<ForgingCalibrationView> createState() => _ForgingCalibrationViewState();
}

class _ForgingCalibrationViewState extends State<ForgingCalibrationView> {
  static const _steps = [
    'Analyzing your trigger & circadian risk profile…',
    'Calculating your 90-day neural rewiring forecast…',
    'Auto-forging your custom If-Then Counter-Spells & Vows…',
    'Awakening your Citadel Guardian & Discreet Shield…',
  ];

  int _stepIdx = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        widget.onFinished();
        return;
      }
      _timer = Timer.periodic(const Duration(milliseconds: 850), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        if (_stepIdx + 1 >= _steps.length) {
          t.cancel();
          widget.onFinished();
        } else {
          setState(() => _stepIdx++);
        }
      });
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 88,
          height: 88,
          child: CircularProgressIndicator(strokeWidth: 5, color: AppColors.moltenGold),
        ),
        const SizedBox(height: 22),
        Text('FORGING YOUR ECLIPSE BLUEPRINT', style: AppTypography.microLabel(width, color: AppColors.moltenGold)),
        const SizedBox(height: 10),
        Text(_steps[_stepIdx], style: AppTypography.cardTitle(width), textAlign: TextAlign.center),
        const SizedBox(height: 18),
        HadesProgressBar(value: (_stepIdx + 1) / _steps.length, fillColor: AppColors.arcaneEmerald),
      ],
    );
  }
}

/// Step D: Personalized Archetype & Auto-Forged Blueprint Reveal.
class BlueprintRevealView extends StatelessWidget {
  const BlueprintRevealView({
    super.key,
    required this.blueprint,
    required this.onEnterCitadel,
  });

  final DiagnosticBlueprint blueprint;
  final VoidCallback onEnterCitadel;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final dateFmt = DateFormat('MMM d, y').format(blueprint.projectedFreedomDateUtc.toLocal());

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OrnateRpgFrame(
            accentColor: AppColors.moltenGold,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: Image.asset(
                        GameArtAssets.guardianKnight,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('BLUEPRINT READY', style: AppTypography.microLabel(width, color: AppColors.moltenGold)),
                          const SizedBox(height: 4),
                          Text(blueprint.profile.archetype, style: AppTypography.screenTitle(width)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text('Baseline Risk: ${blueprint.profile.baselineRisk}/100')),
                    Chip(label: Text('Day 90 Target: $dateFmt')),
                    Chip(label: Text('Focus Default: ${blueprint.recommendedPomodoroMinutes}m')),
                    Chip(label: Text('Nemesis: ${blueprint.bossPriority.name}')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OrnateRpgFrame(
            accentColor: AppColors.arcaneEmerald,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AUTO-FORGED DAILY VOWS (${blueprint.starterQuests.length})',
                  style: AppTypography.microLabel(width, color: AppColors.arcaneEmerald),
                ),
                const SizedBox(height: 6),
                for (final q in blueprint.starterQuests)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• ${q.title}', style: AppTypography.bodyCopy(width, color: AppColors.textPrimary)),
                  ),
                const SizedBox(height: 10),
                Text(
                  'AUTO-FORGED IF-THEN COUNTER-SPELLS (${blueprint.starterSpells.length})',
                  style: AppTypography.microLabel(width, color: AppColors.accentCyan),
                ),
                const SizedBox(height: 6),
                for (final sp in blueprint.starterSpells.take(3))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• IF ${sp.triggerCue} → ${sp.actionPlan}', style: AppTypography.bodyCopy(width)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          RpgBevelButton(
            variant: RpgButtonVariant.gold,
            icon: Icons.castle_outlined,
            label: 'Enter My Citadel (+25 XP · +15 Gold)',
            onPressed: onEnterCitadel,
          ),
        ],
      ),
    );
  }
}
