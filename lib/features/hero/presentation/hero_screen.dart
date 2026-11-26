import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/rpg_widgets.dart';
import '../../sanctuary/application/app_providers.dart';
import '../../sanctuary/application/recovery_controller.dart';
import '../../sanctuary/domain/recovery_models.dart';
import 'hero_armory_section.dart';
import 'hero_stats_skills_section.dart';
import 'trophy_vault_section.dart';

enum HeroSubTab { stats, armory, vault }

/// Tab 4 — HERO VAULT: Painted Lantern Guardian character banner, 4-Stat Radar
/// & 5-Perk Skill Tree, Gold Armory Shop, and 3D-Tilt Foil Relic Vault.
class HeroScreen extends ConsumerStatefulWidget {
  const HeroScreen({super.key});

  @override
  ConsumerState<HeroScreen> createState() => _HeroScreenState();
}

class _HeroScreenState extends ConsumerState<HeroScreen> {
  HeroSubTab _tab = HeroSubTab.stats;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final desktop = AppTypography.isDesktopWidth(width);
    final asyncState = ref.watch(recoveryProvider);
    final liveNow = ref.watch(liveClockStreamProvider).value ??
        ref.read(clockProvider).now().toUtc();

    return asyncState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: FilledButton(
          onPressed: () => ref.invalidate(recoveryProvider),
          child: const Text('Retry loading hero vault'),
        ),
      ),
      data: (appState) {
        final s = appState.streakState;
        final rank = s.rankAt(liveNow);
        final bestDays = s.effectiveBestDays(liveNow);

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, desktop ? 32 : 136),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1020),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OrnateRpgFrame(
                    accentColor: AppColors.moltenGold,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.bgVoid,
                                border: Border.all(color: AppColors.moltenGold, width: 1.8),
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  GameArtAssets.guardianKnight,
                                  fit: BoxFit.cover,
                                  gaplessPlayback: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${s.lampbearerName.toUpperCase()} · ${rank.title.toUpperCase()}',
                                    style: AppTypography.microLabel(width, color: AppColors.moltenGold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Level ${s.level} Sovereign Knight',
                                    style: AppTypography.cinzelDisplay(width, size: desktop ? 24 : 18),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${s.xpIntoLevel}/100 XP · ${s.gold} Gold · ${s.bossKills} Bosses Slain',
                                    style: AppTypography.monoStat(fontSize: 12, color: AppColors.arcaneEmerald),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('Stats & Skills'),
                              selected: _tab == HeroSubTab.stats,
                              onSelected: (_) => setState(() => _tab = HeroSubTab.stats),
                            ),
                            ChoiceChip(
                              label: const Text('Armory Shop'),
                              selected: _tab == HeroSubTab.armory,
                              onSelected: (_) => setState(() => _tab = HeroSubTab.armory),
                            ),
                            ChoiceChip(
                              label: const Text('3D Vault'),
                              selected: _tab == HeroSubTab.vault,
                              onSelected: (_) => setState(() => _tab = HeroSubTab.vault),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  switch (_tab) {
                    HeroSubTab.stats => HeroStatsSkillsSection(
                        streakState: s,
                        hapticsEnabled: appState.hapticsEnabled,
                      ),
                    HeroSubTab.armory => HeroArmorySection(
                        streakState: s,
                        hapticsEnabled: appState.hapticsEnabled,
                      ),
                    HeroSubTab.vault => TrophyVaultSection(
                        bestDays: bestDays,
                        milestoneUnlocks: s.milestoneUnlocks,
                      ),
                  },
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
