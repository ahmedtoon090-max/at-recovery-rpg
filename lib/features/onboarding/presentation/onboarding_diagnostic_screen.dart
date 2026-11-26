import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/engine/recovery_algorithm.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/rpg_widgets.dart';
import '../../sanctuary/application/app_providers.dart';
import '../../sanctuary/application/recovery_controller.dart';
import '../../sanctuary/domain/recovery_models.dart';
import 'onboarding_seal_and_forge.dart';

enum _OnboardingStage { quiz, seal, forging, reveal }

/// 8-Card Full-Screen "Mirror of Truth" Interactive Onboarding & Auto-Configurator.
class OnboardingDiagnosticScreen extends ConsumerStatefulWidget {
  const OnboardingDiagnosticScreen({super.key});

  @override
  ConsumerState<OnboardingDiagnosticScreen> createState() =>
      _OnboardingDiagnosticScreenState();
}

class _OnboardingDiagnosticScreenState
    extends ConsumerState<OnboardingDiagnosticScreen> {
  final _pageCtrl = PageController();
  final _whyCtrl = TextEditingController();
  final _nameCtrl = TextEditingController(text: 'Warden');
  final _pinCtrl = TextEditingController();

  _OnboardingStage _stage = _OnboardingStage.quiz;
  int _page = 0;

  String _goal = 'quit_90';
  String _dangerWindow = 'late_night';
  String _trigger = 'boredom';
  int _intensity = 6;
  String _frequency = 'several_week';
  String _slipPattern = 'scroll_spiral';
  GuidingVow _vow = GuidingVow.clarity;
  String _preferredAction = 'pushups';
  int _reminderHour = 21;
  int _sleepCutoff = 23;
  bool _discreetDefault = false;
  bool _enablePin = false;

  DiagnosticBlueprint? _blueprint;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _whyCtrl.dispose();
    _nameCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  void _nextQuestion() {
    HapticFeedback.selectionClick();
    if (_page < 7) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    } else {
      setState(() => _stage = _OnboardingStage.seal);
    }
  }

  void _onVowSealed() {
    final nowUtc = ref.read(clockProvider).now().toUtc();
    _blueprint = PersonalRecoveryAlgorithm.buildBlueprint(
      goal: _goal,
      dangerWindow: _dangerWindow,
      dominantTrigger: _trigger,
      urgeIntensity: _intensity,
      weeklyFrequency: _frequency,
      slipPattern: _slipPattern,
      guidingVow: _vow,
      customWhy: _whyCtrl.text,
      preferredAction: _preferredAction,
      lampbearerName: _nameCtrl.text,
      reminderHour: _reminderHour,
      sleepCutoffHour: _sleepCutoff,
      discreetPreferred: _discreetDefault,
      pinPreferred: _enablePin,
      nowUtc: nowUtc,
    );
    setState(() => _stage = _OnboardingStage.forging);
  }

  Future<void> _finishAndEnterCitadel() async {
    final bp = _blueprint;
    if (bp == null) return;
    final pin = _enablePin && _pinCtrl.text.trim().length == 4
        ? _pinCtrl.text.trim()
        : null;
    await ref
        .read(recoveryProvider.notifier)
        .applyDiagnosticBlueprint(bp, customPin: pin);
    if (!mounted) return;
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.go('/sanctuary');
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _skip() async {
    await ref.read(recoveryProvider.notifier).skipOnboardingPrologue(
          lampbearerName: _nameCtrl.text.trim().isEmpty ? 'Warden' : _nameCtrl.text.trim(),
          vow: _vow,
        );
    if (!mounted) return;
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.go('/sanctuary');
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Widget _choiceOption({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accentEmerald.withValues(alpha: 0.16)
                : AppColors.bgElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.accentEmeraldGlow : AppColors.borderSubtle,
              width: selected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? AppColors.accentEmeraldGlow : AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildQuizPages(double width) => [
        _QuestionStep(
          tag: 'STEP 1 OF 8 · CAMPAIGN GOAL',
          title: 'What is your primary objective?',
          child: Column(
            children: [
              _choiceOption(label: 'Quit Completely (90-Day Rewire)', subtitle: 'Full dopamine reset & Citadel completion', selected: _goal == 'quit_90', onTap: () => setState(() => _goal = 'quit_90')),
              _choiceOption(label: 'Break Late-Night Compulsion', subtitle: 'Fortify 10 PM–2 AM vulnerability hours', selected: _goal == 'night_control', onTap: () => setState(() => _goal = 'night_control')),
              _choiceOption(label: 'Reclaim Deep Focus & Energy', subtitle: 'Replace mindless scrolling with Pomodoro mastery', selected: _goal == 'focus_reclaim', onTap: () => setState(() => _goal = 'focus_reclaim')),
            ],
          ),
        ),
        _QuestionStep(
          tag: 'STEP 2 OF 8 · PEAK DANGER WINDOW',
          title: 'When do urges strike hardest?',
          child: Column(
            children: [
              _choiceOption(label: 'Late Night (10 PM–2 AM)', selected: _dangerWindow == 'late_night', onTap: () => setState(() => _dangerWindow = 'late_night')),
              _choiceOption(label: 'Alone in Room', selected: _dangerWindow == 'alone_room', onTap: () => setState(() => _dangerWindow = 'alone_room')),
              _choiceOption(label: 'Post-Stress Decompression', selected: _dangerWindow == 'post_stress', onTap: () => setState(() => _dangerWindow = 'post_stress')),
              _choiceOption(label: 'Waking Morning / Midday Boredom', selected: _dangerWindow == 'morning' || _dangerWindow == 'midday_boredom', onTap: () => setState(() => _dangerWindow = 'midday_boredom')),
            ],
          ),
        ),
        _QuestionStep(
          tag: 'STEP 3 OF 8 · MIRAGE TRIGGER',
          title: 'Which trigger spawns most waves?',
          child: Column(
            children: [
              _choiceOption(label: 'Boredom & Restlessness', selected: _trigger == 'boredom', onTap: () => setState(() => _trigger = 'boredom')),
              _choiceOption(label: 'Stress / Anxiety', selected: _trigger == 'stress', onTap: () => setState(() => _trigger = 'stress')),
              _choiceOption(label: 'Loneliness / Isolation', selected: _trigger == 'loneliness', onTap: () => setState(() => _trigger = 'loneliness')),
              _choiceOption(label: 'Social Media / Short Reels', selected: _trigger == 'social_media', onTap: () => setState(() => _trigger = 'social_media')),
              _choiceOption(label: 'Fatigue / Sleep Deprivation', selected: _trigger == 'fatigue', onTap: () => setState(() => _trigger = 'fatigue')),
            ],
          ),
        ),
        _QuestionStep(
          tag: 'STEP 4 OF 8 · INTENSITY & FREQUENCY',
          title: 'Gauge typical urge strength',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Typical Wave Intensity: $_intensity / 10', style: AppTypography.monoStat(fontSize: 14, color: AppColors.accentGold)),
              Slider(
                value: _intensity.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                onChanged: (v) => setState(() => _intensity = v.round()),
              ),
              const SizedBox(height: 8),
              _choiceOption(label: 'Daily waves', selected: _frequency == 'daily', onTap: () => setState(() => _frequency = 'daily')),
              _choiceOption(label: 'Several times a week', selected: _frequency == 'several_week', onTap: () => setState(() => _frequency = 'several_week')),
              _choiceOption(label: 'Weekly or occasional', selected: _frequency == 'weekly', onTap: () => setState(() => _frequency = 'weekly')),
            ],
          ),
        ),
        _QuestionStep(
          tag: 'STEP 5 OF 8 · SLIP & CHASER PATTERN',
          title: 'How do setbacks usually unfold?',
          child: Column(
            children: [
              _choiceOption(label: 'Quick 30-Second Impulse', selected: _slipPattern == 'quick_impulse', onTap: () => setState(() => _slipPattern = 'quick_impulse')),
              _choiceOption(label: 'Endless Scrolling Spiral', selected: _slipPattern == 'scroll_spiral', onTap: () => setState(() => _slipPattern = 'scroll_spiral')),
              _choiceOption(label: 'Post-Slip Chaser Effect', subtitle: 'One slip triggers multiple back-to-back relapses', selected: _slipPattern == 'post_slip_chaser', onTap: () => setState(() => _slipPattern = 'post_slip_chaser')),
            ],
          ),
        ),
        _QuestionStep(
          tag: 'STEP 6 OF 8 · ACT GUIDING VOW',
          title: 'Choose your Guiding Vow & anchor',
          child: Column(
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final v in GuidingVow.values)
                    ChoiceChip(
                      label: Text(v.title),
                      selected: _vow == v,
                      onSelected: (_) => setState(() => _vow = v),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(_vow.mantra, style: AppTypography.bodyCopy(width, color: AppColors.accentEmeraldGlow)),
              const SizedBox(height: 12),
              TextField(
                controller: _whyCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Personal "Why I Started" (optional)'),
              ),
            ],
          ),
        ),
        _QuestionStep(
          tag: 'STEP 7 OF 8 · PREFERRED COUNTER-ACTION',
          title: 'Pick your #1 physical override',
          child: Column(
            children: [
              _choiceOption(label: '20 Crisp Pushups & Water', selected: _preferredAction == 'pushups', onTap: () => setState(() => _preferredAction = 'pushups')),
              _choiceOption(label: 'Ice-Cold Water Reset (20s)', selected: _preferredAction == 'cold_water', onTap: () => setState(() => _preferredAction = 'cold_water')),
              _choiceOption(label: '3-Minute Brisk Walk Outside', selected: _preferredAction == 'walk_outside', onTap: () => setState(() => _preferredAction = 'walk_outside')),
              _choiceOption(label: '50-Min Focus Pomodoro Sprint', selected: _preferredAction == 'pomodoro_sprint', onTap: () => setState(() => _preferredAction = 'pomodoro_sprint')),
            ],
          ),
        ),
        _QuestionStep(
          tag: 'STEP 8 OF 8 · AUTO-SETUP PREFERENCES',
          title: 'Personalize your Sanctuary & Shield',
          child: Column(
            children: [
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Lampbearer Name'),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  DropdownButton<int>(
                    value: _reminderHour,
                    dropdownColor: AppColors.bgElevated,
                    items: const [
                      DropdownMenuItem(value: 8, child: Text('Check-In: 08:00')),
                      DropdownMenuItem(value: 13, child: Text('Check-In: 13:00')),
                      DropdownMenuItem(value: 21, child: Text('Check-In: 21:00')),
                    ],
                    onChanged: (v) => setState(() => _reminderHour = v ?? 21),
                  ),
                  DropdownButton<int>(
                    value: _sleepCutoff,
                    dropdownColor: AppColors.bgElevated,
                    items: const [
                      DropdownMenuItem(value: 22, child: Text('Screen Cutoff: 22:00')),
                      DropdownMenuItem(value: 23, child: Text('Screen Cutoff: 23:00')),
                      DropdownMenuItem(value: 0, child: Text('Screen Cutoff: 00:00')),
                    ],
                    onChanged: (v) => setState(() => _sleepCutoff = v ?? 23),
                  ),
                ],
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Start in Discreet Mode (ATP Pomodoro)'),
                value: _discreetDefault,
                onChanged: (v) => setState(() => _discreetDefault = v),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enable 4-Digit Sanctuary PIN'),
                value: _enablePin,
                onChanged: (v) => setState(() => _enablePin = v),
              ),
              if (_enablePin)
                TextField(
                  controller: _pinCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: '4-Digit PIN'),
                ),
            ],
          ),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Scaffold(
      backgroundColor: AppColors.twilightDeep,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            GameArtAssets.realmMapBg,
            fit: BoxFit.cover,
            color: AppColors.bgVoid.withValues(alpha: 0.65),
            colorBlendMode: BlendMode.darken,
            gaplessPlayback: true,
          ),
          const EmberParticlesBackdrop(count: 16, color: AppColors.moltenGold),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 660),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text('THE MIRROR OF TRUTH', style: AppTypography.microLabel(width, color: AppColors.moltenGold)),
                          TextButton(onPressed: _skip, child: const Text('Skip Setup')),
                        ],
                      ),
                      if (_stage == _OnboardingStage.quiz) ...[
                        const SizedBox(height: 6),
                        HadesProgressBar(value: (_page + 1) / 8, fillColor: AppColors.arcaneEmerald),
                      ],
                      const SizedBox(height: 16),
                      Expanded(
                        child: switch (_stage) {
                          _OnboardingStage.quiz => PageView(
                              controller: _pageCtrl,
                              physics: const NeverScrollableScrollPhysics(),
                              onPageChanged: (i) => setState(() => _page = i),
                              children: _buildQuizPages(width),
                            ),
                          _OnboardingStage.seal => SealYourVowView(
                              lampbearerName: _nameCtrl.text,
                              vowTitle: _vow.title,
                              onSealed: _onVowSealed,
                            ),
                          _OnboardingStage.forging => ForgingCalibrationView(
                              onFinished: () => setState(() => _stage = _OnboardingStage.reveal),
                            ),
                          _OnboardingStage.reveal => BlueprintRevealView(
                              blueprint: _blueprint!,
                              onEnterCitadel: _finishAndEnterCitadel,
                            ),
                        },
                      ),
                      if (_stage == _OnboardingStage.quiz) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (_page > 0)
                              RpgBevelButton(
                                compact: true,
                                variant: RpgButtonVariant.twilight,
                                label: 'Back',
                                onPressed: () => _pageCtrl.previousPage(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOutCubic,
                                ),
                              ),
                            if (_page > 0) const SizedBox(width: 12),
                            Expanded(
                              child: RpgBevelButton(
                                variant: RpgButtonVariant.emerald,
                                label: _page == 7 ? 'Proceed to Vow Seal' : 'Continue',
                                onPressed: _nextQuestion,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionStep extends StatelessWidget {
  const _QuestionStep({
    required this.tag,
    required this.title,
    required this.child,
  });

  final String tag;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(tag, style: AppTypography.microLabel(width, color: AppColors.accentGold)),
          const SizedBox(height: 6),
          Text(title, style: AppTypography.screenTitle(width)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
