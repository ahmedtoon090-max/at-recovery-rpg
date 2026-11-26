import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/glass_card.dart';
import '../../domain/recovery_models.dart';

/// Mindful Guard daily trigger-shield checklist (charges Guardian Shield Integrity).
class TriggerShieldCard extends StatelessWidget {
  const TriggerShieldCard({
    super.key,
    required this.shieldChecks,
    required this.nowLocal,
    required this.onToggle,
  });

  final Map<String, String> shieldChecks;
  final DateTime nowLocal;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final today = formatUtcDateKey(nowLocal);
    final activeCount =
        kTriggerShieldItems.where((i) => shieldChecks[i.id] == today).length;

    return ObsidianCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_user_outlined,
                size: 16,
                color: AppColors.accentCyan,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'TRIGGER SHIELD CHECKLIST',
                  style: AppTypography.microLabel(
                    width,
                    color: AppColors.accentCyan,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$activeCount/${kTriggerShieldItems.length}',
                style: AppTypography.monoStat(
                  fontSize: 12,
                  color: activeCount == kTriggerShieldItems.length
                      ? AppColors.accentEmeraldGlow
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Fortify all 3 boundaries daily (+20 XP) to charge Shield Integrity.',
            style: AppTypography.bodyCopy(width),
          ),
          const SizedBox(height: 8),
          for (final item in kTriggerShieldItems)
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.accentEmerald,
              value: shieldChecks[item.id] == today,
              onChanged: (_) => onToggle(item.id),
              title: Text(
                item.label,
                style: TextStyle(
                  fontSize: 13,
                  color: shieldChecks[item.id] == today
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
