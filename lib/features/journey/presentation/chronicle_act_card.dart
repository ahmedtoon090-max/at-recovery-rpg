import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/rpg_widgets.dart';
import '../../sanctuary/domain/recovery_models.dart';

/// Interactive Story Act Card backed by ornate twilight framing, painted
/// Relic Chest & Boss badges, multi-scene lore, and 2-option moral choices.
class ChronicleActCard extends StatefulWidget {
  const ChronicleActCard({
    super.key,
    required this.act,
    required this.daysClean,
    required this.chosenId,
    required this.chestClaimed,
    required this.bossClaimed,
    required this.onChoose,
    required this.onClaimChest,
    required this.onClaimBoss,
  });

  final ChronicleActSpec act;
  final int daysClean;
  final String? chosenId;
  final bool chestClaimed;
  final bool bossClaimed;
  final ValueChanged<ActChoiceSpec> onChoose;
  final VoidCallback onClaimChest;
  final VoidCallback onClaimBoss;

  @override
  State<ChronicleActCard> createState() => _ChronicleActCardState();
}

class _ChronicleActCardState extends State<ChronicleActCard> {
  int _sceneIndex = 0;

  void _openStoryVignetteModal(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    var localScene = _sceneIndex;
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Dialog(
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: OrnateRpgFrame(
              accentColor: AppColors.moltenGold,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: Image.asset(
                          GameArtAssets.guardianKnight,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ACT ${widget.act.actNumber} CHRONICLE',
                              style: AppTypography.microLabel(width, color: AppColors.moltenGold),
                            ),
                            Text(
                              widget.act.title,
                              style: AppTypography.cinzelTitle(width, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  OrnateRpgFrame(
                    accentColor: AppColors.arcaneEmerald,
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      widget.act.storyLines[localScene.clamp(0, widget.act.storyLines.length - 1)],
                      style: AppTypography.bodyCopy(width, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Scene ${localScene + 1} / ${widget.act.storyLines.length}',
                        style: AppTypography.monoStat(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      TextButton(
                        onPressed: () {
                          final next = (localScene + 1) % widget.act.storyLines.length;
                          setLocal(() => localScene = next);
                          setState(() => _sceneIndex = next);
                        },
                        child: const Text('Next Scene →'),
                      ),
                    ],
                  ),
                  if (widget.chosenId == null) ...[
                    const SizedBox(height: 8),
                    RpgBevelButton(
                      compact: true,
                      variant: RpgButtonVariant.emerald,
                      label: widget.act.choiceA.label,
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        widget.onChoose(widget.act.choiceA);
                      },
                    ),
                    const SizedBox(height: 8),
                    RpgBevelButton(
                      compact: true,
                      variant: RpgButtonVariant.gold,
                      label: widget.act.choiceB.label,
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        widget.onChoose(widget.act.choiceB);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final act = widget.act;
    final unlocked = widget.daysClean >= act.minDay;
    final bossReady = widget.daysClean >= act.bossDayRequired;
    final lines = act.storyLines;
    final currentLine = lines[_sceneIndex.clamp(0, lines.length - 1)];

    return OrnateRpgFrame(
      accentColor: widget.bossClaimed
          ? AppColors.arcaneEmerald
          : (unlocked ? AppColors.moltenGold : AppColors.borderHighlight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Text(
                'ACT ${act.actNumber} · ${act.title.toUpperCase()}',
                style: AppTypography.cinzelDisplay(
                  width,
                  size: 15,
                  color: unlocked ? AppColors.moltenGold : AppColors.textMuted,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (unlocked ? AppColors.arcaneEmerald : AppColors.bgVoid).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: unlocked
                        ? AppColors.arcaneEmerald.withValues(alpha: 0.45)
                        : AppColors.borderSubtle,
                  ),
                ),
                child: Text(
                  widget.bossClaimed
                      ? '${act.dayRange} · Cleared'
                      : (unlocked ? act.dayRange : 'Unlocks Day ${act.minDay}'),
                  style: AppTypography.monoStat(
                    fontSize: 11,
                    color: unlocked ? AppColors.arcaneEmerald : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgVoid.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unlocked
                      ? currentLine
                      : 'Keep lighting your Citadel lantern to unlock ${act.title}.',
                  style: AppTypography.bodyCopy(width).copyWith(
                    color: unlocked ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
                if (unlocked) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        'Scene ${_sceneIndex + 1} / ${lines.length}',
                        style: AppTypography.monoStat(fontSize: 11, color: AppColors.textMuted),
                      ),
                      Wrap(
                        spacing: 6,
                        children: [
                          TextButton(
                            onPressed: () => _openStoryVignetteModal(context),
                            child: const Text('Read Vignette'),
                          ),
                          TextButton(
                            onPressed: () => setState(
                              () => _sceneIndex = (_sceneIndex + 1) % lines.length,
                            ),
                            child: Text(
                              _sceneIndex + 1 < lines.length ? 'Next Scene →' : 'Replay Scene',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (unlocked) ...[
            const SizedBox(height: 12),
            Text(
              'MORAL CROSSROADS (+25 XP · +15 G)',
              style: AppTypography.microLabel(width, color: AppColors.accentCyan),
            ),
            const SizedBox(height: 8),
            if (widget.chosenId != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.arcaneEmerald.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.arcaneEmerald.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_rounded, size: 17, color: AppColors.arcaneEmerald),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Choice Sealed: ${widget.chosenId == act.choiceA.id ? act.choiceA.label : act.choiceB.label}',
                        style: AppTypography.bodyCopy(width, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  RpgBevelButton(
                    compact: true,
                    variant: RpgButtonVariant.twilight,
                    label: act.choiceA.label,
                    onPressed: () => widget.onChoose(act.choiceA),
                  ),
                  RpgBevelButton(
                    compact: true,
                    variant: RpgButtonVariant.twilight,
                    label: act.choiceB.label,
                    onPressed: () => widget.onChoose(act.choiceB),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                RpgBevelButton(
                  compact: true,
                  icon: widget.chestClaimed ? Icons.check_rounded : Icons.inventory_2_rounded,
                  variant: widget.chestClaimed ? RpgButtonVariant.twilight : RpgButtonVariant.emerald,
                  label: widget.chestClaimed
                      ? 'Chest Claimed'
                      : 'Open Relic Chest (+${act.rewardXp ~/ 2} XP)',
                  onPressed: widget.chestClaimed ? null : widget.onClaimChest,
                ),
                RpgBevelButton(
                  compact: true,
                  icon: widget.bossClaimed ? Icons.workspace_premium_rounded : Icons.shield_moon_rounded,
                  variant: (bossReady && !widget.bossClaimed)
                      ? RpgButtonVariant.gold
                      : RpgButtonVariant.twilight,
                  label: widget.bossClaimed
                      ? '${act.bossName} Cleared'
                      : (bossReady
                          ? 'Claim ${act.bossName} (+${act.rewardXp} XP)'
                          : '${act.bossName} · Day ${act.bossDayRequired}'),
                  onPressed: (!bossReady || widget.bossClaimed) ? null : widget.onClaimBoss,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
