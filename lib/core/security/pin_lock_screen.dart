import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/sanctuary/application/recovery_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Privacy PIN and optional biometric gate shown on cold launch when configured.
class PinLockScreen extends ConsumerStatefulWidget {
  const PinLockScreen({
    super.key,
    required this.biometricsEnabled,
  });

  final bool biometricsEnabled;

  @override
  ConsumerState<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<PinLockScreen> {
  String _pin = '';
  String? _error;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    if (widget.biometricsEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometrics());
    }
  }

  Future<void> _tryBiometrics() async {
    await ref.read(recoveryProvider.notifier).unlockWithBiometrics();
  }

  Future<void> _appendDigit(String d) async {
    if (_checking || _pin.length >= 4) return;
    HapticFeedback.selectionClick();
    setState(() {
      _pin += d;
      _error = null;
    });
    if (_pin.length == 4) {
      setState(() => _checking = true);
      final ok = await ref.read(recoveryProvider.notifier).unlockWithPin(_pin);
      if (!mounted) return;
      if (!ok) {
        HapticFeedback.lightImpact();
        setState(() {
          _pin = '';
          _checking = false;
          _error = 'Incorrect PIN. Try again.';
        });
      }
    }
  }

  void _backspace() {
    if (_pin.isEmpty || _checking) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Scaffold(
      backgroundColor: AppColors.bgVoid,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 36,
                    color: AppColors.accentEmeraldGlow,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'ATP Pomodoro Locked',
                    style: AppTypography.screenTitle(width),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error ?? 'Enter your 4-digit PIN to continue.',
                    style: AppTypography.bodyCopy(
                      width,
                      color: _error != null
                          ? AppColors.accentGold
                          : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < 4; i++)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < _pin.length
                                ? AppColors.accentEmeraldGlow
                                : AppColors.bgElevated,
                            border: Border.all(
                              color: i < _pin.length
                                  ? AppColors.accentEmerald
                                  : AppColors.borderHighlight,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  for (final row in const [
                    ['1', '2', '3'],
                    ['4', '5', '6'],
                    ['7', '8', '9'],
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (final d in row)
                            _PinKey(label: d, onTap: () => _appendDigit(d)),
                        ],
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (widget.biometricsEnabled)
                        IconButton(
                          tooltip: 'Unlock with biometrics',
                          constraints: const BoxConstraints(
                            minWidth: 64,
                            minHeight: 64,
                          ),
                          onPressed: _tryBiometrics,
                          icon: const Icon(
                            Icons.fingerprint_rounded,
                            size: 28,
                            color: AppColors.accentCyan,
                          ),
                        )
                      else
                        const SizedBox(width: 64, height: 64),
                      _PinKey(label: '0', onTap: () => _appendDigit('0')),
                      IconButton(
                        tooltip: 'Backspace',
                        constraints: const BoxConstraints(
                          minWidth: 64,
                          minHeight: 64,
                        ),
                        onPressed: _backspace,
                        icon: const Icon(
                          Icons.backspace_outlined,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PinKey extends StatelessWidget {
  const _PinKey({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(32),
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.bgObsidian,
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Text(
          label,
          style: AppTypography.monoStat(
            fontSize: 22,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
