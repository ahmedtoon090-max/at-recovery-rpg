import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart' as flame_p;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/engine/rpg_juice_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/rpg_widgets.dart';
import '../../application/recovery_controller.dart';
import '../../domain/recovery_models.dart';

/// Full-bleed atmospheric 2D world layer: crossfading citadel_tier_1..4.png,
/// slow breathing camera zoom, drifting embers, and interactive +5 G Ember Wisps.
class CitadelWorldBackdrop extends StatefulWidget {
  const CitadelWorldBackdrop({
    super.key,
    required this.assetPath,
    required this.highAlert,
    required this.onTapWisp,
  });

  final String assetPath;
  final bool highAlert;
  final VoidCallback onTapWisp;

  @override
  State<CitadelWorldBackdrop> createState() => _CitadelWorldBackdropState();
}

class _CitadelWorldBackdropState extends State<CitadelWorldBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _zoomCtrl;
  int _wispSeed = 0;
  bool _wispVisible = true;
  String? _goldPopup;

  @override
  void initState() {
    super.initState();
    _zoomCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disable = MediaQuery.disableAnimationsOf(context);
    if (disable && _zoomCtrl.isAnimating) {
      _zoomCtrl.stop();
    } else if (!disable && !_zoomCtrl.isAnimating) {
      _zoomCtrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _zoomCtrl.dispose();
    super.dispose();
  }

  void _harvestWisp() {
    if (!_wispVisible) return;
    HapticFeedback.lightImpact();
    widget.onTapWisp();
    setState(() {
      _wispVisible = false;
      _goldPopup = '+5 G';
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _goldPopup = null);
    });
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _wispSeed++;
          _wispVisible = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final disableMotion = MediaQuery.disableAnimationsOf(context);
    final rng = math.Random(_wispSeed + 7);
    final wispAlign = Alignment(
      (rng.nextDouble() * 1.4 - 0.7).clamp(-0.75, 0.75),
      (-0.55 + rng.nextDouble() * 0.4).clamp(-0.65, -0.15),
    );

    final bgImage = AnimatedSwitcher(
      duration: disableMotion ? Duration.zero : const Duration(milliseconds: 650),
      child: Image.asset(
        widget.assetPath,
        key: ValueKey(widget.assetPath),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
      ),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        if (disableMotion)
          bgImage
        else
          AnimatedBuilder(
            animation: _zoomCtrl,
            builder: (_, child) => Transform.scale(
              scale: 1.0 + _zoomCtrl.value * 0.032,
              child: child,
            ),
            child: bgImage,
          ),
        // Warm atmospheric vignette + HUD readability gradient
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.bgVoid.withValues(alpha: 0.62),
                Colors.transparent,
                (widget.highAlert ? AppColors.accentCrimson : AppColors.bgVoid)
                    .withValues(alpha: widget.highAlert ? 0.24 : 0.35),
                AppColors.bgVoid.withValues(alpha: 0.90),
              ],
              stops: const [0.0, 0.28, 0.68, 1.0],
            ),
          ),
        ),
        const EmberParticlesBackdrop(count: 28),
        if (!disableMotion)
          IgnorePointer(
            child: GameWidget(
              game: _CitadelStarlightFlameGame(),
            ),
          ),
        if (_wispVisible)
          Align(
            alignment: wispAlign,
            child: Semantics(
              button: true,
              label: 'Collect Ember Wisp (+5 Gold)',
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: _harvestWisp,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [
                        Color(0xFFFDE68A),
                        AppColors.arcaneEmerald,
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.arcaneEmerald.withValues(alpha: 0.55),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.auto_awesome, size: 16, color: AppColors.bgVoid),
                ),
              ),
            ),
          ),
        if (_goldPopup != null)
          Align(
            alignment: wispAlign,
            child: RpgFloatingBanner(text: _goldPopup!, color: AppColors.moltenGold),
          ),
      ],
    );
  }
}

/// Top floating Game HUD Strip with portrait, LVL, Hades XP bar, Gold, SFX & Mask.
class CitadelTopGameHud extends StatelessWidget {
  const CitadelTopGameHud({
    super.key,
    required this.lampbearerName,
    required this.level,
    required this.xpIntoLevel,
    required this.gold,
    required this.syncStatus,
    required this.sfxEnabled,
    required this.onSyncTap,
    required this.onToggleSfx,
    required this.onToggleDiscreet,
  });

  final String lampbearerName;
  final int level;
  final int xpIntoLevel;
  final int gold;
  final SyncStatus syncStatus;
  final bool sfxEnabled;
  final VoidCallback onSyncTap;
  final VoidCallback onToggleSfx;
  final VoidCallback onToggleDiscreet;

  @override
  Widget build(BuildContext context) {
    final (syncColor, syncLabel) = switch (syncStatus) {
      SyncStatus.synced => (AppColors.arcaneEmerald, 'Synced'),
      SyncStatus.syncing => (AppColors.accentCyan, 'Syncing'),
      SyncStatus.error => (AppColors.moltenGold, 'Retry'),
      SyncStatus.idle => (AppColors.textSecondary, 'Local'),
    };

    return OrnateRpgFrame(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      borderRadius: 16,
      showCornerDiamonds: false,
      accentColor: AppColors.moltenGold,
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.moltenGold, width: 1.5),
                  color: AppColors.bgVoid,
                ),
                child: ClipOval(
                  child: Image.asset(
                    GameArtAssets.guardianKnight,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'LVL $level',
                        style: AppTypography.monoStat(fontSize: 11.5, color: AppColors.moltenGold),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        lampbearerName,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  SizedBox(
                    width: 112,
                    child: HadesProgressBar(
                      value: (xpIntoLevel / 100.0).clamp(0.0, 1.0),
                      fillColor: AppColors.arcaneEmerald,
                      height: 6,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _HudPill(
                icon: Icons.monetization_on_rounded,
                iconColor: AppColors.moltenGold,
                label: '${gold}G',
              ),
              _HudPill(
                icon: Icons.cloud_done_outlined,
                iconColor: syncColor,
                label: syncLabel,
                onTap: onSyncTap,
              ),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onToggleSfx,
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Icon(
                    sfxEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                    size: 16,
                    color: sfxEnabled ? AppColors.arcaneEmerald : AppColors.textMuted,
                  ),
                ),
              ),
              _HudPill(
                icon: Icons.visibility_off_outlined,
                iconColor: AppColors.accentCyan,
                label: 'Mask',
                onTap: onToggleDiscreet,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HudPill extends StatelessWidget {
  const _HudPill({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.bgVoid.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderHighlight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.5, color: iconColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.monoStat(fontSize: 11, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
    return onTap == null ? child : InkWell(borderRadius: BorderRadius.circular(10), onTap: onTap, child: child);
  }
}

/// Center-top floating Cinzel Streak Medallion over the sky (zero clipping).
class CitadelHeroMedallion extends StatelessWidget {
  const CitadelHeroMedallion({
    super.key,
    required this.rank,
    required this.castle,
    required this.elapsed,
    required this.sovereigntyPercent,
    required this.rewiringProgress,
    required this.builtCount,
    required this.onTapForge,
  });

  final RankTier rank;
  final CastleTier castle;
  final Duration elapsed;
  final int sovereigntyPercent;
  final double rewiringProgress;
  final int builtCount;
  final VoidCallback onTapForge;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final days = elapsed.inDays;
    final hrs = (elapsed.inHours % 24).toString().padLeft(2, '0');
    final mins = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final secs = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    final rewirePct = (rewiringProgress * 100).round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'THE ECLIPSE CITADEL',
          textAlign: TextAlign.center,
          style: AppTypography.cinzelDisplay(
            width,
            size: AppTypography.isDesktopWidth(width) ? 20 : 16,
            color: AppColors.moltenGold,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${rank.title.toUpperCase()} · ${castle.title.toUpperCase()}',
          textAlign: TextAlign.center,
          style: AppTypography.microLabel(width, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 196,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.arcaneEmerald.withValues(alpha: 0.22),
                    blurRadius: 48,
                    spreadRadius: 12,
                  ),
                ],
              ),
            ),
            Text(
              days == 1 ? '1 DAY' : '$days DAYS',
              style: AppTypography.heroDays(width),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.twilightDeep.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.arcaneEmerald.withValues(alpha: 0.55)),
          ),
          child: Text(
            '${hrs}h : ${mins}m : ${secs}s',
            style: AppTypography.liveSubCounter(width, color: AppColors.arcaneEmerald),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.twilightDeep.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderHighlight),
              ),
              child: Text(
                '$sovereigntyPercent% Sovereignty · $rewirePct% Rewired',
                style: AppTypography.monoStat(fontSize: 11, color: AppColors.textPrimary),
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onTapForge,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.moltenGold.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.moltenGold.withValues(alpha: 0.65)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.castle_outlined, size: 13.5, color: AppColors.moltenGold),
                    const SizedBox(width: 5),
                    Text(
                      'Tier ${castle.tierIndex + 1} Forge ($builtCount/15)',
                      style: AppTypography.monoStat(fontSize: 11, color: AppColors.moltenGold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Interactive painted Guardian Knight sprite standing in foreground with bob + Hades Speech Bubble.
class CitadelGuardianForeground extends StatefulWidget {
  const CitadelGuardianForeground({
    super.key,
    required this.dialogueLines,
    required this.shieldPct,
    required this.highAlert,
  });

  final List<String> dialogueLines;
  final int shieldPct;
  final bool highAlert;

  @override
  State<CitadelGuardianForeground> createState() => _CitadelGuardianForegroundState();
}

class _CitadelGuardianForegroundState extends State<CitadelGuardianForeground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bobCtrl;
  int _quoteIndex = 0;

  @override
  void initState() {
    super.initState();
    _bobCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disable = MediaQuery.disableAnimationsOf(context);
    if (disable && _bobCtrl.isAnimating) {
      _bobCtrl.stop();
    } else if (!disable && !_bobCtrl.isAnimating) {
      _bobCtrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _bobCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final disableMotion = MediaQuery.disableAnimationsOf(context);
    final spriteSize = AppTypography.isDesktopWidth(width) ? 142.0 : 108.0;
    final line = widget.dialogueLines[_quoteIndex % widget.dialogueLines.length];

    final sprite = GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _quoteIndex++);
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: spriteSize * 0.78,
            height: spriteSize * 0.78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (widget.highAlert ? AppColors.accentCrimson : AppColors.arcaneEmerald)
                      .withValues(alpha: 0.30),
                  blurRadius: 28,
                ),
              ],
            ),
          ),
          SizedBox(
            width: spriteSize,
            height: spriteSize,
            child: Image.asset(
              GameArtAssets.guardianKnight,
              fit: BoxFit.contain,
              gaplessPlayback: true,
            ),
          ),
        ],
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (disableMotion)
          sprite
        else
          AnimatedBuilder(
            animation: _bobCtrl,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, math.sin(_bobCtrl.value * math.pi) * -5.0),
              child: child,
            ),
            child: sprite,
          ),
        const SizedBox(width: 10),
        Expanded(
          child: OrnateRpgFrame(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            borderRadius: 16,
            accentColor: widget.highAlert ? AppColors.accentCrimson : AppColors.arcaneEmerald,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.highAlert ? 'HIGH ALERT WATCH' : 'LANTERN GUARDIAN',
                        style: AppTypography.microLabel(
                          width,
                          color: widget.highAlert ? AppColors.accentCrimson : AppColors.arcaneEmerald,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${widget.shieldPct}% Shield',
                      style: AppTypography.monoStat(fontSize: 10.5, color: AppColors.moltenGold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '"$line"',
                  style: AppTypography.bodyCopy(width, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CitadelStarlightFlameGame extends FlameGame {
  final math.Random _rng = math.Random();
  double _accum = 0;

  @override
  Color backgroundColor() => Colors.transparent;

  @override
  void update(double dt) {
    super.update(dt);
    _accum += dt;
    if (_accum >= 0.45 && size.x > 0 && size.y > 0) {
      _accum = 0;
      add(
        ParticleSystemComponent(
          position: Vector2(_rng.nextDouble() * size.x, size.y * (0.2 + _rng.nextDouble() * 0.7)),
          particle: flame_p.Particle.generate(
            count: 2,
            lifespan: 2.0,
            generator: (_) => flame_p.AcceleratedParticle(
              speed: Vector2((_rng.nextDouble() - 0.5) * 14, -18 - _rng.nextDouble() * 20),
              child: flame_p.CircleParticle(
                radius: 1.5,
                paint: Paint()
                  ..color = (_rng.nextBool() ? AppColors.arcaneEmerald : AppColors.moltenGold)
                      .withValues(alpha: 0.45),
              ),
            ),
          ),
        ),
      );
    }
  }
}
