import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../sanctuary/application/recovery_controller.dart';

class PomodoroState {
  const PomodoroState({
    required this.focusMinutes,
    required this.breakMinutes,
    required this.remainingSeconds,
    required this.isRunning,
    required this.isBreakPhase,
  });

  factory PomodoroState.initial() => const PomodoroState(
        focusMinutes: 25,
        breakMinutes: 5,
        remainingSeconds: 25 * 60,
        isRunning: false,
        isBreakPhase: false,
      );

  final int focusMinutes;
  final int breakMinutes;
  final int remainingSeconds;
  final bool isRunning;
  final bool isBreakPhase;

  int get totalPhaseSeconds =>
      (isBreakPhase ? breakMinutes : focusMinutes) * 60;

  double get progress {
    if (totalPhaseSeconds <= 0) return 0;
    return (1.0 - (remainingSeconds / totalPhaseSeconds)).clamp(0.0, 1.0);
  }

  PomodoroState copyWith({
    int? focusMinutes,
    int? breakMinutes,
    int? remainingSeconds,
    bool? isRunning,
    bool? isBreakPhase,
  }) {
    return PomodoroState(
      focusMinutes: focusMinutes ?? this.focusMinutes,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
      isBreakPhase: isBreakPhase ?? this.isBreakPhase,
    );
  }
}

/// Persistent Pomodoro focus timer backing both Quests and Discreet Mask Mode.
class PomodoroNotifier extends Notifier<PomodoroState> {
  Timer? _timer;

  @override
  PomodoroState build() {
    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
    });
    return PomodoroState.initial();
  }

  void selectPreset({required int focusMinutes, required int breakMinutes}) {
    _timer?.cancel();
    state = PomodoroState(
      focusMinutes: focusMinutes,
      breakMinutes: breakMinutes,
      remainingSeconds: focusMinutes * 60,
      isRunning: false,
      isBreakPhase: false,
    );
  }

  void toggleRunning() {
    if (state.isRunning) {
      _timer?.cancel();
      state = state.copyWith(isRunning: false);
      return;
    }
    state = state.copyWith(isRunning: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void reset() {
    _timer?.cancel();
    state = state.copyWith(
      isRunning: false,
      remainingSeconds:
          (state.isBreakPhase ? state.breakMinutes : state.focusMinutes) * 60,
    );
  }

  void completeNowForFocusReward() {
    _timer?.cancel();
    final wasBreak = state.isBreakPhase;
    if (!wasBreak) {
      unawaited(ref.read(recoveryProvider.notifier).completePomodoroFocus());
    }
    final nextBreak = !wasBreak;
    state = state.copyWith(
      isRunning: false,
      isBreakPhase: nextBreak,
      remainingSeconds:
          (nextBreak ? state.breakMinutes : state.focusMinutes) * 60,
    );
  }

  void _onTick() {
    if (state.remainingSeconds > 1) {
      state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      return;
    }
    completeNowForFocusReward();
  }
}

final pomodoroProvider = NotifierProvider<PomodoroNotifier, PomodoroState>(
  PomodoroNotifier.new,
);
