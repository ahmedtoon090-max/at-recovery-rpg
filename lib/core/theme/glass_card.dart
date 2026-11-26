import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'rpg_widgets.dart';

/// Twilight-obsidian gradient RPG panel wrapping secondary screens cleanly
/// with subtle bevel borders and corner diamonds (zero flat grey boxes).
class ObsidianCard extends StatelessWidget {
  const ObsidianCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderRadius = 20,
    this.backgroundColor,
    this.borderColor = AppColors.borderGold,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final accent = borderColor == AppColors.borderSubtle
        ? AppColors.moltenGold.withValues(alpha: 0.45)
        : borderColor;

    return OrnateRpgFrame(
      padding: padding,
      borderRadius: borderRadius,
      accentColor: accent,
      fillOverride: backgroundColor,
      showCornerDiamonds: true,
      child: child,
    );
  }
}

/// Frosted twilight glass surface matching Dark-Fantasy Obsidian Sanctuary tokens.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderRadius = 20,
    this.enableBlur = true,
    this.accentColor = AppColors.arcaneEmerald,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool enableBlur;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final content = OrnateRpgFrame(
      padding: padding,
      borderRadius: borderRadius,
      accentColor: accentColor.withValues(alpha: 0.65),
      enableBlur: enableBlur,
      child: child,
    );
    if (!enableBlur) return content;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: content,
      ),
    );
  }
}
