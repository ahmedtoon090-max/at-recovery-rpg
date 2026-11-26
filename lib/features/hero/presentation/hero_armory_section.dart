import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/glass_card.dart';
import '../../sanctuary/application/recovery_controller.dart';
import '../../sanctuary/domain/recovery_models.dart';

/// RPG Armory Shop: Orb Shaders, Guardian Auras, Castle Buildings, and Custom Rewards.
class HeroArmorySection extends ConsumerWidget {
  const HeroArmorySection({
    super.key,
    required this.streakState,
    required this.hapticsEnabled,
  });

  final StreakState streakState;
  final bool hapticsEnabled;

  Future<void> _showAddRewardDialog(BuildContext context, WidgetRef ref) async {
    final titleCtrl = TextEditingController();
    final costCtrl = TextEditingController(text: '60');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Real-Life Gold Reward'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Reward Title',
                hintText: 'Watch a movie or order favorite meal',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: costCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Gold Cost'),
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
            child: const Text('Create Reward'),
          ),
        ],
      ),
    );
    if (ok == true && titleCtrl.text.trim().isNotEmpty) {
      final parsedCost = int.tryParse(costCtrl.text.trim()) ?? 60;
      await ref.read(recoveryProvider.notifier).addCustomReward(
            title: titleCtrl.text.trim(),
            costGold: parsedCost,
          );
    }
    titleCtrl.dispose();
    costCtrl.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final orbs = kArmoryCosmetics.where((c) => c.slot == CosmeticSlot.orb);
    final auras = kArmoryCosmetics.where((c) => c.slot == CosmeticSlot.aura);
    final rewards = streakState.customRewards.where((r) => !r.isDeleted).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CosmeticCardGroup(
          title: 'ORB SHADERS',
          items: orbs.toList(),
          ownedIds: streakState.ownedCosmetics,
          equippedId: streakState.equippedOrbId,
          gold: streakState.gold,
          onSelect: (id) {
            if (hapticsEnabled) HapticFeedback.mediumImpact();
            ref.read(recoveryProvider.notifier).buyOrEquipCosmetic(id);
          },
        ),
        const SizedBox(height: 14),
        _CosmeticCardGroup(
          title: 'GUARDIAN AURAS',
          items: auras.toList(),
          ownedIds: streakState.ownedCosmetics,
          equippedId: streakState.equippedAuraId,
          gold: streakState.gold,
          onSelect: (id) {
            if (hapticsEnabled) HapticFeedback.mediumImpact();
            ref.read(recoveryProvider.notifier).buyOrEquipCosmetic(id);
          },
        ),
        const SizedBox(height: 14),
        ObsidianCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CITADEL STRUCTURES',
                style: AppTypography.microLabel(width, color: AppColors.accentGold),
              ),
              const SizedBox(height: 10),
              for (final st in kCastleStructures) ...[
                _CastleBuildTile(
                  def: st,
                  level: streakState.structureLevel(st.id),
                  gold: streakState.gold,
                  discount: streakState.hasSkill('citadel_architect'),
                  onUpgrade: () {
                    if (hapticsEnabled) HapticFeedback.mediumImpact();
                    ref.read(recoveryProvider.notifier).upgradeCastleStructure(st.id);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        ObsidianCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'REAL-LIFE GOLD REWARDS',
                      style: AppTypography.microLabel(
                        width,
                        color: AppColors.accentEmeraldGlow,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showAddRewardDialog(context, ref),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              for (final r in rewards)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.bgVoid,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Claimed ${r.timesClaimed}x',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        FilledButton.tonal(
                          onPressed: streakState.gold >= r.costGold
                              ? () async {
                                  if (hapticsEnabled) HapticFeedback.mediumImpact();
                                  await ref
                                      .read(recoveryProvider.notifier)
                                      .claimCustomReward(r.id);
                                  if (context.mounted) {
                                    try {
                                      Confetti.launch(
                                        context,
                                        options: const ConfettiOptions(
                                          particleCount: 28,
                                          spread: 50,
                                          y: 0.6,
                                        ),
                                      );
                                    } catch (_) {}
                                  }
                                }
                              : null,
                          child: Text('${r.costGold} G'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CosmeticCardGroup extends StatelessWidget {
  const _CosmeticCardGroup({
    required this.title,
    required this.items,
    required this.ownedIds,
    required this.equippedId,
    required this.gold,
    required this.onSelect,
  });

  final String title;
  final List<ArmoryCosmeticDef> items;
  final List<String> ownedIds;
  final String equippedId;
  final int gold;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return ObsidianCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.microLabel(width, color: AppColors.accentCyan)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final item in items)
                Builder(
                  builder: (_) {
                    final owned = ownedIds.contains(item.id);
                    final equipped = equippedId == item.id;
                    final canAct = owned || gold >= item.costGold;
                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: canAct ? () => onSelect(item.id) : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: equipped
                              ? item.colors.first.withValues(alpha: 0.16)
                              : AppColors.bgVoid,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: equipped
                                ? item.colors.first
                                : AppColors.borderSubtle,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: item.colors),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                item.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              equipped
                                  ? 'Equipped'
                                  : (owned ? 'Equip' : '${item.costGold} G'),
                              style: AppTypography.monoStat(
                                fontSize: 11,
                                color: equipped
                                    ? AppColors.accentEmeraldGlow
                                    : (canAct
                                        ? AppColors.accentGold
                                        : AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CastleBuildTile extends StatelessWidget {
  const _CastleBuildTile({
    required this.def,
    required this.level,
    required this.gold,
    required this.discount,
    required this.onUpgrade,
  });

  final CastleStructureDef def;
  final int level;
  final int gold;
  final bool discount;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final maxed = level >= def.maxLevel;
    final cost = def.costForLevel(level, architectDiscount: discount);
    final canAfford = !maxed && gold >= cost;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgVoid,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${def.name} (Lv.$level/${def.maxLevel})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  def.bonusSummary,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: canAfford ? onUpgrade : null,
            child: Text(maxed ? 'MAX' : '${cost}G'),
          ),
        ],
      ),
    );
  }
}
