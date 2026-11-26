import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/recovery_models.dart';

/// 60fps evolving plasma-gradient orb across all 7 RPG mastery stages & Armory shaders.
class LivingOrbWidget extends StatefulWidget {
  const LivingOrbWidget({
    super.key,
    required this.rankTier,
    this.equippedOrbId = 'orb_obsidian_emerald',
    this.size = 188,
  });

  final RankTier rankTier;
  final String equippedOrbId;
  final double size;

  @override
  State<LivingOrbWidget> createState() => _LivingOrbWidgetState();
}

class _LivingOrbWidgetState extends State<LivingOrbWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (disableAnimations && _controller.isAnimating) {
      _controller.stop();
    } else if (!disableAnimations && !_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final basePalette = _OrbPalette.forStage(widget.rankTier.stageIndex);
    final palette = widget.equippedOrbId == 'orb_obsidian_emerald'
        ? basePalette
        : _OrbPalette.fromCosmetic(
            cosmeticById(widget.equippedOrbId, CosmeticSlot.orb),
          );
    return Semantics(
      label:
          'Living sanctuary orb at stage ${widget.rankTier.title}: ${widget.rankTier.companionName}',
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _LivingOrbPainter(
                animation: _controller,
                palette: palette,
                stageIndex: widget.rankTier.stageIndex,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbPalette {
  const _OrbPalette({
    required this.core,
    required this.mid,
    required this.rim,
    required this.spark,
  });

  final Color core;
  final Color mid;
  final Color rim;
  final Color spark;

  factory _OrbPalette.fromCosmetic(ArmoryCosmeticDef cosmetic) => _OrbPalette(
        core: cosmetic.colors[0],
        mid: cosmetic.colors[1],
        rim: cosmetic.colors[0],
        spark: cosmetic.colors.length > 2 ? cosmetic.colors[2] : cosmetic.colors[0],
      );

  static _OrbPalette forStage(int stage) => switch (stage) {
        0 => const _OrbPalette(
            core: Color(0xFF475569),
            mid: Color(0xFF1E293B),
            rim: AppColors.accentGold,
            spark: Color(0xFFFBBF24),
          ),
        1 => const _OrbPalette(
            core: Color(0xFF0D9488),
            mid: Color(0xFF134E4A),
            rim: AppColors.accentEmerald,
            spark: AppColors.accentEmeraldGlow,
          ),
        2 => const _OrbPalette(
            core: AppColors.accentCyan,
            mid: Color(0xFF0E7490),
            rim: AppColors.accentEmeraldGlow,
            spark: Color(0xFF67E8F9),
          ),
        3 => const _OrbPalette(
            core: AppColors.accentEmeraldGlow,
            mid: AppColors.accentEmerald,
            rim: AppColors.accentCyan,
            spark: AppColors.accentGold,
          ),
        4 => const _OrbPalette(
            core: Color(0xFF6EE7B7),
            mid: Color(0xFF059669),
            rim: AppColors.accentCyan,
            spark: Color(0xFFFDE68A),
          ),
        5 => const _OrbPalette(
            core: AppColors.accentGold,
            mid: AppColors.accentEmerald,
            rim: AppColors.accentEmeraldGlow,
            spark: Color(0xFFFEF3C7),
          ),
        _ => const _OrbPalette(
            core: Color(0xFFFEF08A),
            mid: AppColors.accentEmeraldGlow,
            rim: AppColors.accentCyan,
            spark: AppColors.accentGold,
          ),
      };
}

class _LivingOrbPainter extends CustomPainter {
  _LivingOrbPainter({
    required this.animation,
    required this.palette,
    required this.stageIndex,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final _OrbPalette palette;
  final int stageIndex;

  final Paint _ambientPaint = Paint();
  final Paint _spherePaint = Paint();
  final Paint _blobPaint = Paint();
  final Paint _rimPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4;
  final Paint _sparkPaint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    final theta = t * math.pi * 2;
    final breathe = 0.94 + 0.06 * math.sin(theta);
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = (math.min(size.width, size.height) * 0.36) * breathe;

    // Subtle ambient halo behind the centerpiece orb
    _ambientPaint.shader = RadialGradient(
      colors: [
        palette.rim.withValues(alpha: 0.28),
        palette.mid.withValues(alpha: 0.08),
        Colors.transparent,
      ],
      stops: const [0.0, 0.55, 1.0],
    ).createShader(
      Rect.fromCircle(center: center, radius: baseRadius * 1.65),
    );
    canvas.drawCircle(center, baseRadius * 1.65, _ambientPaint);

    // Base obsidian-core sphere
    final sphereRect = Rect.fromCircle(center: center, radius: baseRadius);
    _spherePaint.shader = RadialGradient(
      center: const Alignment(-0.28, -0.32),
      radius: 0.95,
      colors: [
        palette.core,
        palette.mid,
        AppColors.bgVoid,
      ],
      stops: const [0.0, 0.58, 1.0],
    ).createShader(sphereRect);
    canvas.drawCircle(center, baseRadius, _spherePaint);

    // Fluid orbiting plasma layer clipped inside the sphere
    canvas.save();
    canvas.clipPath(Path()..addOval(sphereRect));

    final blob1Center = center +
        Offset(
          math.cos(theta) * baseRadius * 0.32,
          math.sin(theta * 1.0) * baseRadius * 0.24,
        );
    _blobPaint.shader = RadialGradient(
      colors: [
        palette.spark.withValues(alpha: 0.42),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: blob1Center, radius: baseRadius * 0.72));
    canvas.drawCircle(blob1Center, baseRadius * 0.72, _blobPaint);

    final blob2Center = center +
        Offset(
          math.cos(theta + 2.2) * baseRadius * 0.35,
          math.sin(theta + 1.4) * baseRadius * 0.35,
        );
    _blobPaint.shader = RadialGradient(
      colors: [
        palette.rim.withValues(alpha: 0.36),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: blob2Center, radius: baseRadius * 0.68));
    canvas.drawCircle(blob2Center, baseRadius * 0.68, _blobPaint);

    // Top specular crescent
    _blobPaint.shader = RadialGradient(
      center: const Alignment(-0.4, -0.55),
      radius: 0.55,
      colors: [
        Colors.white.withValues(alpha: 0.26),
        Colors.transparent,
      ],
    ).createShader(sphereRect);
    canvas.drawCircle(center, baseRadius, _blobPaint);
    canvas.restore();

    // Crisp rim hairline
    _rimPaint.color = palette.rim.withValues(alpha: 0.55);
    canvas.drawCircle(center, baseRadius, _rimPaint);

    // Orbiting stage embers (scale cleanly with rank tier)
    final emberCount = 2 + stageIndex;
    for (var i = 0; i < emberCount; i++) {
      final a = theta + (i * math.pi * 2 / emberCount);
      final orbitR = baseRadius * (1.16 + (i % 2) * 0.08);
      final pos = center +
          Offset(
            math.cos(a) * orbitR,
            math.sin(a) * orbitR * 0.62,
          );
      final dotR = i == 0 ? 3.2 : 2.1;
      _sparkPaint.color =
          (i.isEven ? palette.spark : palette.rim).withValues(alpha: 0.85);
      canvas.drawCircle(pos, dotR, _sparkPaint);
    }
  }

  @override
  bool shouldRepaint(_LivingOrbPainter oldDelegate) =>
      oldDelegate.palette != palette || oldDelegate.stageIndex != stageIndex;
}
