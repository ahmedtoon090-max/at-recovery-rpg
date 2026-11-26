import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Hades-inspired animated HP / Shield / XP progress bar with delayed white/gold
/// trailing damage-flash fill and crisp 1px specular bevel border.
class RpgProgressBar extends StatefulWidget {
  const RpgProgressBar({
    super.key,
    required this.value,
    required this.fillColor,
    this.trailColor = Colors.white,
    this.height = 10,
    this.borderRadius = 999,
  });

  final double value;
  final Color fillColor;
  final Color trailColor;
  final double height;
  final double borderRadius;

  @override
  State<RpgProgressBar> createState() => _RpgProgressBarState();
}

class _RpgProgressBarState extends State<RpgProgressBar> {
  double _trailValue = 0.0;
  Timer? _trailTimer;

  @override
  void initState() {
    super.initState();
    _trailValue = widget.value.clamp(0.0, 1.0);
  }

  @override
  void didUpdateWidget(RpgProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.value.clamp(0.0, 1.0);
    if (next < oldWidget.value) {
      // Delay trailing drop so player clearly sees chunk damaged cleanly
      _trailValue = oldWidget.value.clamp(0.0, 1.0);
      _trailTimer?.cancel();
      _trailTimer = Timer(const Duration(milliseconds: 280), () {
        if (mounted) setState(() => _trailValue = next);
      });
    } else if (next > _trailValue) {
      _trailValue = next;
    }
  }

  @override
  void dispose() {
    _trailTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.value.clamp(0.0, 1.0);
    final reduced = MediaQuery.disableAnimationsOf(context);
    final dur = reduced ? Duration.zero : const Duration(milliseconds: 220);

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.bgVoid,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(color: AppColors.borderHighlight),
        ),
        child: LayoutBuilder(
          builder: (_, box) {
            final w = box.maxWidth;
            return Stack(
              children: [
                AnimatedContainer(
                  duration: reduced ? Duration.zero : const Duration(milliseconds: 360),
                  curve: Curves.easeOutCubic,
                  width: w * _trailValue,
                  height: widget.height,
                  color: widget.trailColor.withValues(alpha: 0.72),
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
                        Color.lerp(widget.fillColor, Colors.white, 0.25) ?? widget.fillColor,
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

/// Tactile spring 0.96 press-scale wrapper with optional haptic pulse.
class RpgPressScale extends StatefulWidget {
  const RpgPressScale({
    super.key,
    required this.child,
    this.onTap,
    this.hapticsEnabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool hapticsEnabled;

  @override
  State<RpgPressScale> createState() => _RpgPressScaleState();
}

class _RpgPressScaleState extends State<RpgPressScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return GestureDetector(
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
      onTapUp: widget.onTap == null
          ? null
          : (_) {
              setState(() => _down = false);
              if (widget.hapticsEnabled) HapticFeedback.selectionClick();
              widget.onTap?.call();
            },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: (!reduced && _down) ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// Damped 120ms micro-shake controller + wrapper for hit-impacts and rewards.
class RpgShakeController extends ChangeNotifier {
  double _trauma = 0.0;
  double get trauma => _trauma;

  void trigger([double amount = 1.0]) {
    _trauma = amount.clamp(0.0, 1.0);
    notifyListeners();
  }
}

class RpgScreenShake extends StatefulWidget {
  const RpgScreenShake({
    super.key,
    required this.controller,
    required this.child,
    this.maxOffset = 7.0,
  });

  final RpgShakeController controller;
  final Widget child;
  final double maxOffset;

  @override
  State<RpgScreenShake> createState() => _RpgScreenShakeState();
}

class _RpgScreenShakeState extends State<RpgScreenShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    widget.controller.addListener(_onShake);
  }

  void _onShake() {
    if (!mounted || MediaQuery.disableAnimationsOf(context)) return;
    _anim.forward(from: 0.0);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onShake);
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) {
        if (!_anim.isAnimating) return child!;
        final decay = (1.0 - _anim.value) * widget.controller.trauma;
        final dx = math.sin(_anim.value * math.pi * 6) * widget.maxOffset * decay;
        final dy = math.cos(_anim.value * math.pi * 4) * (widget.maxOffset * 0.45) * decay;
        return Transform.translate(offset: Offset(dx, dy), child: child);
      },
      child: widget.child,
    );
  }
}

/// Upward-drifting floating combat / loot number pill (-25, -50 CRIT!, +75 XP).
class RpgFloatingBanner extends StatelessWidget {
  const RpgFloatingBanner({
    super.key,
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(text),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(
        opacity: (1.2 - v * 0.6).clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, -14 * v),
          child: child,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.65)),
        ),
        child: Text(
          text,
          style: AppTypography.monoStat(fontSize: 13, color: color),
        ),
      ),
    );
  }
}
