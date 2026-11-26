import 'package:flutter/material.dart';
import 'package:flutter_tilt/flutter_tilt.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/rpg_widgets.dart';
import '../../sanctuary/domain/recovery_models.dart';

/// Collectible 3D-Tilt Holographic Milestone Relics Vault (24h to 365d)
/// using painted dark-obsidian & gold relic_emblem.png with foil glare.
class TrophyVaultSection extends StatelessWidget {
  const TrophyVaultSection({
    super.key,
    required this.bestDays,
    required this.milestoneUnlocks,
  });

  final int bestDays;
  final Map<String, String> milestoneUnlocks;

  void _openInspectModal(
    BuildContext context,
    TrophyCardSpec card,
    String? unlockIso,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HolographicFoilCard(
                card: card,
                unlocked: true,
                bestDays: bestDays,
                unlockIso: unlockIso,
                height: 310,
                onTap: () => Navigator.of(ctx).pop(),
              ),
              const SizedBox(height: 12),
              RpgBevelButton(
                compact: true,
                variant: RpgButtonVariant.twilight,
                label: 'Close 3D Inspect',
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unlockedCount = kTrophyCards
        .where((c) => bestDays >= c.minDays || milestoneUnlocks.containsKey(c.id))
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Collected $unlockedCount / ${kTrophyCards.length} Foil Crest Relics · Drag or tilt any card',
          style: AppTypography.bodyCopy(MediaQuery.sizeOf(context).width),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth >= 720
                ? 3
                : (constraints.maxWidth >= 460 ? 2 : 1);
            final cardW = (constraints.maxWidth - (cols - 1) * 12) / cols;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final card in kTrophyCards)
                  SizedBox(
                    width: cardW,
                    child: _HolographicFoilCard(
                      card: card,
                      unlocked: bestDays >= card.minDays ||
                          milestoneUnlocks.containsKey(card.id),
                      bestDays: bestDays,
                      unlockIso: milestoneUnlocks[card.id],
                      height: 204,
                      onTap: (bestDays >= card.minDays ||
                              milestoneUnlocks.containsKey(card.id))
                          ? () => _openInspectModal(
                                context,
                                card,
                                milestoneUnlocks[card.id],
                              )
                          : null,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _HolographicFoilCard extends StatelessWidget {
  const _HolographicFoilCard({
    required this.card,
    required this.unlocked,
    required this.bestDays,
    required this.unlockIso,
    required this.height,
    this.onTap,
  });

  final TrophyCardSpec card;
  final bool unlocked;
  final int bestDays;
  final String? unlockIso;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disableMotion = MediaQuery.disableAnimationsOf(context);
    final progress = (bestDays / card.minDays).clamp(0.0, 1.0);
    final formattedDate = unlockIso != null
        ? DateFormat('MMM d, y').format(DateTime.parse(unlockIso!).toLocal())
        : null;

    final emblem = SizedBox(
      width: 68,
      height: 68,
      child: Opacity(
        opacity: unlocked ? 1.0 : 0.35,
        child: ColorFiltered(
          colorFilter: unlocked
              ? ColorFilter.mode(card.foilPrimary.withValues(alpha: 0.16), BlendMode.srcATop)
              : const ColorFilter.mode(Color(0xFF475569), BlendMode.saturation),
          child: Image.asset(
            GameArtAssets.relicEmblem,
            fit: BoxFit.contain,
            gaplessPlayback: true,
          ),
        ),
      ),
    );

    final cardBody = GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: height),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: unlocked
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    card.foilPrimary.withValues(alpha: 0.28),
                    AppColors.twilightDeep,
                    card.foilSecondary.withValues(alpha: 0.24),
                  ],
                )
              : const LinearGradient(
                  colors: [AppColors.twilightDeep, AppColors.bgVoid],
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            width: unlocked ? 1.6 : 1.0,
            color: unlocked
                ? card.foilPrimary.withValues(alpha: 0.78)
                : AppColors.borderSubtle,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                emblem,
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (unlocked ? card.foilPrimary : AppColors.textMuted).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    card.badge,
                    style: AppTypography.monoStat(
                      fontSize: 12,
                      color: unlocked ? card.foilPrimary : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              card.title,
              style: AppTypography.cinzelDisplay(
                MediaQuery.sizeOf(context).width,
                size: 17,
                color: unlocked ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              card.lore,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            if (unlocked)
              Text(
                formattedDate != null
                    ? 'Forged $formattedDate · Tap for 3D Inspect'
                    : 'Unlocked · Tap for 3D Inspect',
                style: AppTypography.monoStat(fontSize: 11, color: card.foilPrimary),
              )
            else ...[
              HadesProgressBar(value: progress, fillColor: card.foilPrimary, height: 6),
              const SizedBox(height: 4),
              Text(
                '$bestDays / ${card.minDays} days to unlock',
                style: AppTypography.monoStat(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );

    if (disableMotion) return cardBody;

    return Tilt.base(
      tiltConfig: const TiltConfig(angle: 14, enableGestureSensors: true),
      lightConfig: LightConfig(
        color: unlocked ? card.foilPrimary : AppColors.textSecondary,
        minIntensity: 0.05,
        maxIntensity: unlocked ? 0.42 : 0.12,
      ),
      borderRadius: BorderRadius.circular(20),
      child: cardBody,
    );
  }
}
