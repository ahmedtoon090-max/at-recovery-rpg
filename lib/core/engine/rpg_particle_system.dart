import 'package:flutter/material.dart' hide Velocity;
import 'package:flutter_shaders_ui/flutter_shaders_ui.dart';
import 'package:newton_particles/newton_particles.dart';

import '../theme/app_colors.dart';

enum RpgParticlePreset {
  driftingEmbers,
  twinklingStars,
  combatSparks,
  goldLootBurst,
}

/// 60fps shader aurora + particle backdrop powered by flutter_shaders_ui and newton_particles.
class RpgParticleSystem extends StatelessWidget {
  const RpgParticleSystem({
    super.key,
    required this.preset,
    this.child,
  });

  final RpgParticlePreset preset;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced) {
      return child ?? const SizedBox.shrink();
    }

    final (color1, color2) = switch (preset) {
      RpgParticlePreset.driftingEmbers => (AppColors.accentGold, AppColors.accentEmeraldGlow),
      RpgParticlePreset.twinklingStars => (AppColors.accentCyan, AppColors.accentIndigo),
      RpgParticlePreset.combatSparks => (AppColors.accentCrimson, AppColors.accentGold),
      RpgParticlePreset.goldLootBurst => (AppColors.accentGold, AppColors.accentEmeraldGlow),
    };

    final effect = switch (preset) {
      RpgParticlePreset.goldLootBurst => ConfettiPreset(
          colors: const [AppColors.accentGold, AppColors.accentEmeraldGlow, AppColors.accentCyan],
          particleCount: 36,
          particlesPerEmit: 12,
        ).toConfiguration(),
      RpgParticlePreset.combatSparks => ConfettiPreset(
          colors: const [AppColors.accentCrimson, AppColors.accentGold, Colors.white],
          particleCount: 24,
          particlesPerEmit: 8,
          origin: const Offset(0.5, 0.35),
        ).toConfiguration(),
      RpgParticlePreset.driftingEmbers => SnowPreset(
          color: AppColors.accentGold.withValues(alpha: 0.45),
          particleCount: 0,
          particlesPerEmit: 1,
          emitDuration: const Duration(milliseconds: 520),
          windStrength: 0.4,
        ).toConfiguration(),
      RpgParticlePreset.twinklingStars => SnowPreset(
          color: AppColors.accentCyan.withValues(alpha: 0.35),
          particleCount: 0,
          particlesPerEmit: 1,
          emitDuration: const Duration(milliseconds: 650),
          windStrength: -0.2,
        ).toConfiguration(),
    };

    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: AuroraEffect(
              color1: color1,
              color2: color2,
              intensity: 0.24,
              speed: 0.6,
              enabled: true,
              child: Newton(
                effectConfigurations: [effect],
              ),
            ),
          ),
        ),
        ?child,
      ],
    );
  }
}

/// Luminous animated GLSL border card wrapper with reduced-motion fallback.
class LuminousBorderFrame extends StatelessWidget {
  const LuminousBorderFrame({
    super.key,
    required this.child,
    this.colors = const [AppColors.accentEmeraldGlow, AppColors.accentCyan, AppColors.accentGold],
    this.borderRadius = 20,
    this.borderWidth = 1.6,
    this.enabled = true,
  });

  final Widget child;
  final List<Color> colors;
  final double borderRadius;
  final double borderWidth;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced || !enabled) return child;
    return AnimatedGradientBorder(
      colors: colors,
      borderRadius: borderRadius,
      borderWidth: borderWidth,
      speed: 0.65,
      glow: 0.25,
      child: child,
    );
  }
}
