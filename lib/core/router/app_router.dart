import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/hero/presentation/hero_screen.dart';
import '../../features/journal/presentation/journal_screen.dart';
import '../../features/journey/presentation/journey_screen.dart';
import '../../features/onboarding/presentation/onboarding_diagnostic_screen.dart';
import '../../features/panic/presentation/panic_screen.dart';
import '../../features/quests/presentation/pomodoro_discreet_screen.dart';
import '../../features/quests/presentation/quests_screen.dart';
import '../../features/sanctuary/application/recovery_controller.dart';
import '../../features/sanctuary/presentation/sanctuary_screen.dart';
import '../../features/sync_profile/presentation/profile_sync_screen.dart';
import '../platform/platform_bootstrap.dart';
import '../security/pin_lock_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/rpg_widgets.dart';

final _rootNavKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavKey,
    initialLocation: '/sanctuary',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _AdaptiveSanctuaryShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/sanctuary', builder: (_, _) => const SanctuaryScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/journey', builder: (_, _) => const JourneyScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/hero', builder: (_, _) => const HeroScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/quests', builder: (_, _) => const QuestsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/journal', builder: (_, _) => const JournalScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (_, _) => const ProfileSyncScreen())]),
        ],
      ),
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: _rootNavKey,
        builder: (_, _) => const OnboardingDiagnosticScreen(),
      ),
      GoRoute(
        path: '/panic',
        parentNavigatorKey: _rootNavKey,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 140),
          child: const PanicScreen(),
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
    ],
  );
});

class _AdaptiveSanctuaryShell extends ConsumerStatefulWidget {
  const _AdaptiveSanctuaryShell({required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<_AdaptiveSanctuaryShell> createState() => _AdaptiveSanctuaryShellState();
}

class _AdaptiveSanctuaryShellState extends ConsumerState<_AdaptiveSanctuaryShell> {
  // Compact 84px sleek icon-rail on Desktop by default so the 2D Citadel gets full real estate.
  bool _railExpanded = false;

  static const _destinations = [
    (label: 'World', icon: Icons.castle_outlined, active: Icons.castle),
    (label: 'Journey', icon: Icons.auto_stories_outlined, active: Icons.auto_stories),
    (label: 'Hero', icon: Icons.auto_awesome_outlined, active: Icons.auto_awesome),
    (label: 'Spells', icon: Icons.auto_fix_high_outlined, active: Icons.auto_fix_high),
    (label: 'Journal', icon: Icons.book_outlined, active: Icons.book),
    (label: 'Stats', icon: Icons.insights_outlined, active: Icons.insights),
  ];

  // 5-Tab Obsidian-Gold Mobile Dock: World (0), Journey (1), Spells (3), Hero (2), Stats (5).
  static const List<int> _mobileBranchOrder = [0, 1, 3, 2, 5];

  void _onSelectTab(int index, bool hapticsEnabled) {
    if (hapticsEnabled) HapticFeedback.selectionClick();
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  void _openPanic(bool hapticsEnabled) {
    if (hapticsEnabled) HapticFeedback.heavyImpact();
    context.push('/panic');
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final desktop = AppTypography.isDesktopWidth(width);
    final appState = ref.watch(recoveryProvider).value;
    final hapticsEnabled = appState?.hapticsEnabled ?? true;
    final currentBranch = widget.navigationShell.currentIndex;

    Widget content;
    if (appState?.isLocked == true) {
      content = PinLockScreen(biometricsEnabled: appState?.biometricsEnabled ?? false);
    } else if (appState?.discreetMode == true) {
      content = const PomodoroDiscreetScreen(isDiscreetShell: true);
    } else if (appState != null && !appState.streakState.prologueCompleted) {
      content = const OnboardingDiagnosticScreen();
    } else if (desktop) {
      content = Scaffold(
        backgroundColor: AppColors.twilightDeep,
        body: Row(
          children: [
            _DesktopNavRail(
              expanded: _railExpanded,
              currentIndex: currentBranch,
              destinations: _destinations,
              onToggleExpand: () => setState(() => _railExpanded = !_railExpanded),
              onSelect: (idx) => _onSelectTab(idx, hapticsEnabled),
              onPanic: () => _openPanic(hapticsEnabled),
            ),
            Expanded(child: widget.navigationShell),
          ],
        ),
      );
    } else {
      content = Scaffold(
        backgroundColor: AppColors.twilightDeep,
        body: Stack(
          children: [
            Positioned.fill(child: widget.navigationShell),
            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // On non-World tabs, keep quick crimson Mirage Ambush reachable above dock
                    if (currentBranch != 0) ...[
                      RpgBevelButton(
                        compact: true,
                        variant: RpgButtonVariant.crimson,
                        icon: Icons.shield_moon_rounded,
                        label: 'Mirage Ambush',
                        onPressed: () => _openPanic(hapticsEnabled),
                      ),
                      const SizedBox(height: 8),
                    ],
                    _MobileObsidianGoldDock(
                      currentIndex: currentBranch,
                      destinations: _destinations,
                      branchOrder: _mobileBranchOrder,
                      onSelect: (idx) => _onSelectTab(idx, hapticsEnabled),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return PlatformBootstrap.wrapDesktopFrame(
      child: content,
      discreetMode: appState?.discreetMode ?? false,
    );
  }
}

class _DesktopNavRail extends StatelessWidget {
  const _DesktopNavRail({
    required this.expanded,
    required this.currentIndex,
    required this.destinations,
    required this.onToggleExpand,
    required this.onSelect,
    required this.onPanic,
  });

  final bool expanded;
  final int currentIndex;
  final List<({String label, IconData icon, IconData active})> destinations;
  final VoidCallback onToggleExpand;
  final ValueChanged<int> onSelect;
  final VoidCallback onPanic;

  @override
  Widget build(BuildContext context) {
    final railWidth = expanded ? 232.0 : 84.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: railWidth,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.twilightDeep, AppColors.bgVoid],
        ),
        border: Border(right: BorderSide(color: AppColors.moltenGold.withValues(alpha: 0.3))),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: expanded ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
                children: [
                  if (expanded)
                    const Flexible(
                      child: Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Text(
                          'ATP Pomodoro',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.moltenGold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  IconButton(
                    tooltip: expanded ? 'Collapse rail' : 'Expand rail',
                    onPressed: onToggleExpand,
                    icon: Icon(
                      expanded ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < destinations.length; i++) ...[
                _RailItem(
                  label: destinations[i].label,
                  icon: currentIndex == i ? destinations[i].active : destinations[i].icon,
                  selected: currentIndex == i,
                  expanded: expanded,
                  onTap: () => onSelect(i),
                ),
                const SizedBox(height: 6),
              ],
              const Spacer(),
              _RailPanicButton(compact: !expanded, onPressed: onPanic),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: 50,
        padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 4),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [
                    AppColors.moltenGold.withValues(alpha: 0.22),
                    AppColors.arcaneEmerald.withValues(alpha: 0.14),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.moltenGold.withValues(alpha: 0.65) : Colors.transparent,
          ),
        ),
        child: expanded
            ? Row(
                children: [
                  Icon(icon, size: 20, color: selected ? AppColors.moltenGold : AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20, color: selected ? AppColors.moltenGold : AppColors.textSecondary),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? AppColors.moltenGold : AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
      ),
    );
  }
}

class _MobileObsidianGoldDock extends StatelessWidget {
  const _MobileObsidianGoldDock({
    required this.currentIndex,
    required this.destinations,
    required this.branchOrder,
    required this.onSelect,
  });

  final int currentIndex;
  final List<({String label, IconData icon, IconData active})> destinations;
  final List<int> branchOrder;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.twilightDeep.withValues(alpha: 0.94),
                AppColors.twilightMid.withValues(alpha: 0.92),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.moltenGold.withValues(alpha: 0.55), width: 1.3),
            boxShadow: [
              BoxShadow(
                color: AppColors.bgVoid.withValues(alpha: 0.65),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              for (final branchIdx in branchOrder)
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => onSelect(branchIdx),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
                      decoration: currentIndex == branchIdx
                          ? BoxDecoration(
                              color: AppColors.moltenGold.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.moltenGold.withValues(alpha: 0.45)),
                            )
                          : null,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            currentIndex == branchIdx ? destinations[branchIdx].active : destinations[branchIdx].icon,
                            size: 20,
                            color: currentIndex == branchIdx ? AppColors.moltenGold : AppColors.textSecondary,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            destinations[branchIdx].label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: currentIndex == branchIdx ? FontWeight.w700 : FontWeight.w500,
                              color: currentIndex == branchIdx ? AppColors.moltenGold : AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailPanicButton extends StatelessWidget {
  const _RailPanicButton({required this.compact, required this.onPressed});
  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return IconButton(
        tooltip: 'Mirage Ambush',
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.accentCrimson,
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(48, 48),
        ),
        icon: const Icon(Icons.shield_moon_rounded, size: 20),
      );
    }
    return RpgBevelButton(
      compact: true,
      variant: RpgButtonVariant.crimson,
      icon: Icons.shield_moon_rounded,
      label: 'Mirage Ambush',
      onPressed: onPressed,
    );
  }
}
