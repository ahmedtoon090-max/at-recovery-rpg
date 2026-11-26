import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import 'crypto_service.dart';

/// Abstraction over secret storage so unit/widget tests never require native channels.
abstract interface class SecretVault {
  Future<String?> read(String key);
  Future<void> write(String key, String? value);
}

class SecureStorageVault implements SecretVault {
  const SecureStorageVault([this._storage = const FlutterSecureStorage()]);
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String key, String? value) async {
    if (value == null || value.isEmpty) {
      await _storage.delete(key: key);
    } else {
      await _storage.write(key: key, value: value);
    }
  }
}

class InMemorySecretVault implements SecretVault {
  final Map<String, String> _data = {};

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String? value) async {
    if (value == null || value.isEmpty) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }
}

abstract final class SecretKeys {
  static const pinSalt = 'atp_pin_salt';
  static const pinHash = 'atp_pin_hash';
  static const biometricsEnabled = 'atp_biometrics_enabled';
  static const syncPassphrase = 'atp_sync_passphrase';
  static const githubPat = 'atp_github_pat';
  static const githubGistId = 'atp_github_gist_id';
  static const supabaseUrl = 'atp_supabase_url';
  static const supabaseAnonKey = 'atp_supabase_anon_key';
}

/// Manages 4-digit salted SHA-256 PIN lock and optional platform biometric auth.
class AppLockService {
  AppLockService({
    required this._vault,
    required this._crypto,
    LocalAuthentication? localAuth,
  }) : _localAuth = localAuth ?? LocalAuthentication();

  final SecretVault _vault;
  final CryptoService _crypto;
  final LocalAuthentication _localAuth;

  Future<bool> hasPinConfigured() async {
    final hash = await _vault.read(SecretKeys.pinHash);
    final salt = await _vault.read(SecretKeys.pinSalt);
    return hash != null && hash.isNotEmpty && salt != null && salt.isNotEmpty;
  }

  Future<void> setPin(String pin) async {
    final salt = _crypto.generateSaltHex();
    final hash = _crypto.hashPin(pin, salt);
    await _vault.write(SecretKeys.pinSalt, salt);
    await _vault.write(SecretKeys.pinHash, hash);
  }

  Future<void> clearPin() async {
    await _vault.write(SecretKeys.pinSalt, null);
    await _vault.write(SecretKeys.pinHash, null);
    await _vault.write(SecretKeys.biometricsEnabled, 'false');
  }

  Future<bool> verifyPin(String pin) async {
    final salt = await _vault.read(SecretKeys.pinSalt);
    final hash = await _vault.read(SecretKeys.pinHash);
    if (salt == null || hash == null) return false;
    return _crypto.verifyPin(pin, salt, hash);
  }

  Future<bool> isBiometricsEnabled() async =>
      (await _vault.read(SecretKeys.biometricsEnabled)) == 'true';

  Future<void> setBiometricsEnabled(bool enabled) =>
      _vault.write(SecretKeys.biometricsEnabled, enabled ? 'true' : 'false');

  Future<bool> canUseBiometrics() async {
    if (kIsWeb) return false;
    try {
      final supported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      return supported && canCheck;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    if (kIsWeb) return false;
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Unlock your ATP Pomodoro sanctuary',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}
