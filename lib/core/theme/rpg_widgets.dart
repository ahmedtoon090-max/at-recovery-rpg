import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:particles_flutter/engine.dart';

import 'app_colors.dart';
import 'app_typography.dart';

enum RpgButtonVariant { emerald, gold, crimson, twilight }

/// 1. Signature Ornate Dark-Fantasy Panel:
/// Twilight-obsidian gradient (#0C1020 -> #141A30 @ 86%), metallic 1.5px gradient
/// bevel border, subtle inner top rim highlight, and corner diamond filigree.
class OrnateRpgFrame extends StatelessWidget {
  const OrnateRpgFrame({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 18,
    this.accentColor = AppColors.moltenGold,
    this.fillOverride,
    this.enableBlur = false,
    this.showCornerDiamonds = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color accentColor;
  final Color? fillOverride;
  final bool enableBlur;
  final bool showCornerDiamonds;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final baseStart = fillOverride ?? AppColors.twilightDeep.withValues(alpha: 0.88);
    final baseEnd = fillOverride != null
        ? Color.lerp(fillOverride, AppColors.twilightMid, 0.35)!
        : AppColors.twilightMid.withValues(alpha: 0.86);

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: 0.65),
            AppColors.borderHighlight,
            accentColor.withValues(alpha: 0.35),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.bgVoid.withValues(alpha: 0.55),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(1.4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(math.max(4, borderRadius - 1.4)),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [baseStart, baseEnd],
                  ),
                ),
              ),
            ),
            if (showCornerDiamonds)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _CornerFiligreePainter(color: accentColor),
                  ),
                ),
              ),
            Material(
              color: Colors.transparent,
              child: Padding(padding: padding, child: child),
            ),
          ],
        ),
      ),
    );
  }
}

class _CornerFiligreePainter extends CustomPainter {
  const _CornerFiligreePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color.withValues(alpha: 0.65);
    const pad = 9.0;
    const r = 3.0;
    for (final pt in [
      const Offset(pad, pad),
      Offset(size.width - pad, pad),
      Offset(pad, size.height - pad),
      Offset(size.width - pad, size.height - pad),
    ]) {
      final path = Path()
        ..moveTo(pt.dx, pt.dy - r)
        ..lineTo(pt.dx + r, pt.dy)
        ..lineTo(pt.dx, pt.dy + r)
        ..lineTo(pt.dx - r, pt.dy)
        ..close();
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(_CornerFiligreePainter old) => old.color != color;
}

/// 2. Tactile Metallic Bevel RPG Button with 0.96 spring press-scale and glow.
class RpgBevelButton extends StatefulWidget {
  const RpgBevelButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = RpgButtonVariant.emerald,
    this.compact = false,
    this.badgeText,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final RpgButtonVariant variant;
  final bool compact;
  final String? badgeText;

  @override
  State<RpgBevelButton> createState() => _RpgBevelButtonState();
}

class _RpgBevelButtonState extends State<RpgBevelButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final disabled = widget.onPressed == null;
    final (cTop, cBot, border, fg) = switch (widget.variant) {
      RpgButtonVariant.emerald => (
          const Color(0xFF14B882),
          const Color(0xFF0A6E4E),
          AppColors.arcaneEmerald,
          AppColors.bgVoid,
        ),
      RpgButtonVariant.gold => (
          const Color(0xFFF6C453),
          const Color(0xFFA86A14),
          const Color(0xFFFDE68A),
          AppColors.bgVoid,
        ),
      RpgButtonVariant.crimson => (
          const Color(0xFFE04848),
          const Color(0xFF8C1D1D),
          const Color(0xFFFCA5A5),
          AppColors.textPrimary,
        ),
      RpgButtonVariant.twilight => (
          const Color(0xFF1D2644),
          const Color(0xFF101528),
          AppColors.moltenGold.withValues(alpha: 0.65),
          AppColors.textPrimary,
        ),
    };

    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _down = true),
      onTapUp: disabled
          ? null
          : (_) {
              setState(() => _down = false);
              HapticFeedback.selectionClick();
              widget.onPressed?.call();
            },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: (!reduced && _down) ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOutCubic,
        child: Opacity(
          opacity: disabled ? 0.5 : 1.0,
          child: Container(
            constraints: BoxConstraints(minHeight: widget.compact ? 42 : 48),
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 11 : 14,
              vertical: widget.compact ? 8 : 10,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [cTop, cBot],
              ),
              border: Border.all(color: border.withValues(alpha: 0.8), width: 1.25),
              boxShadow: disabled
                  ? null
                  : [
                      BoxShadow(
                        color: border.withValues(alpha: 0.24),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: widget.compact ? 16 : 18, color: fg),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: widget.compact ? 12.5 : 13.5,
                          fontWeight: FontWeight.w800,
                          color: fg,
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.badgeText != null)
                  Positioned(
                    right: -6,
                    top: -12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.accentCrimson,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.bgVoid),
                      ),
                      child: Text(
                        widget.badgeText!,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 3. Hades-Inspired Progress Bar with delayed white/gold damage/gain trail.
class HadesProgressBar extends StatefulWidget {
  const HadesProgressBar({
    super.key,
    required this.value,
    required this.fillColor,
    this.trailColor = Colors.white,
    this.height = 10,
  });

  final double value;
  final Color fillColor;
  final Color trailColor;
  final double height;

  @override
  State<HadesProgressBar> createState() => _HadesProgressBarState();
}

class _HadesProgressBarState extends State<HadesProgressBar> {
  double _trail = 0.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _trail = widget.value.clamp(0.0, 1.0);
  }

  @override
  void didUpdateWidget(HadesProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.value.clamp(0.0, 1.0);
    if (next < oldWidget.value) {
      _trail = oldWidget.value.clamp(0.0, 1.0);
      _timer?.cancel();
      _timer = Timer(const Duration(milliseconds: 280), () {
        if (mounted) setState(() => _trail = next);
      });
    } else {
      _trail = next;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.value.clamp(0.0, 1.0);
    final reduced = MediaQuery.disableAnimationsOf(context);
    final dur = reduced ? Duration.zero : const Duration(milliseconds: 220);

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.bgVoid.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.moltenGold.withValues(alpha: 0.45)),
        ),
        child: LayoutBuilder(
          builder: (_, box) {
            final w = box.maxWidth;
            return Stack(
              children: [
                AnimatedContainer(
                  duration: reduced ? Duration.zero : const Duration(milliseconds: 360),
                  curve: Curves.easeOutCubic,
                  width: w * _trail,
                  height: widget.height,
                  color: widget.trailColor.withValues(alpha: 0.78),
                ),
                AnimatedContainer(
                  duration: dur,
                  curve: Curves.easeOutCubic,
                  width: w * target,
                  height: widget.height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.fillColor,
                        Color.lerp(widget.fillColor, AppColors.moltenGold, 0.35)!,
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 4. Circular Stained-Glass Vitality Orb for HALT status states (never rectangular).
class VitalityOrbButton extends StatelessWidget {
  const VitalityOrbButton({
    super.key,
    required this.label,
    required this.icon,
    required this.active,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: active
                    ? [accent.withValues(alpha: 0.65), AppColors.accentCrimson.withValues(alpha: 0.28)]
                    : [AppColors.twilightMid, AppColors.bgVoid],
              ),
              border: Border.all(
                width: active ? 2.0 : 1.2,
                color: active ? accent : AppColors.borderHighlight,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.42),
                        blurRadius: 16,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              size: 26,
              color: active ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.monoStat(
              fontSize: 11,
              color: active ? accent : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Atmospheric drifting ember particles rendered via particles_flutter with
/// automatic reduced-motion safety for tests & accessibility settings.
class EmberParticlesBackdrop extends StatelessWidget {
  const EmberParticlesBackdrop({
    super.key,
    this.count = 28,
    this.color = AppColors.torchAmber,
  });

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (_, box) {
        final w = box.maxWidth.isFinite ? box.maxWidth : 400.0;
        final h = box.maxHeight.isFinite ? box.maxHeight : 400.0;
        final rng = math.Random(42);
        final list = [
          for (var i = 0; i < count; i++)
            CircularParticle(
              radius: 1.4 + rng.nextDouble() * 2.2,
              color: i.isEven
                  ? color.withValues(alpha: 0.55)
                  : AppColors.arcaneEmerald.withValues(alpha: 0.45),
              velocity: Offset(
                (rng.nextDouble() - 0.5) * 14,
                -10 - rng.nextDouble() * 18,
              ),
            ),
        ];
        return IgnorePointer(
          child: Particles(
            width: w,
            height: h,
            particles: list,
            boundType: BoundType.WrapAround,
          ),
        );
      },
    );
  }
}
