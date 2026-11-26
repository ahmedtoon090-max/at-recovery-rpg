import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart' as dart_crypto;
import 'package:cryptography/cryptography.dart';

class CryptoException implements Exception {
  const CryptoException(this.message);
  final String message;

  @override
  String toString() => 'CryptoException: $message';
}

/// Authenticated encryption (PBKDF2-HMAC-SHA256 + AES-256-GCM) and
/// salted SHA-256 PIN hashing.
class CryptoService {
  CryptoService({
    this._iterations = 100000,
    Random? random,
  }) : _random = random ?? Random.secure();

  final int _iterations;
  final Random _random;

  final AesGcm _aesGcm = AesGcm.with256bits();

  List<int> _randomBytes(int length) =>
      List<int>.generate(length, (_) => _random.nextInt(256));

  Future<SecretKey> _deriveKey(String passphrase, List<int> salt) async {
    final kdf = Pbkdf2.hmacSha256(iterations: _iterations, bits: 256);
    return kdf.deriveKeyFromPassword(password: passphrase, nonce: salt);
  }

  Future<String> encryptString(String plaintext, String passphrase) async {
    if (passphrase.isEmpty) {
      throw const CryptoException('Passphrase must not be empty.');
    }
    final salt = _randomBytes(16);
    final nonce = _randomBytes(12);
    final key = await _deriveKey(passphrase, salt);
    final box = await _aesGcm.encrypt(
      utf8.encode(plaintext),
      secretKey: key,
      nonce: nonce,
    );

    final envelope = <String, dynamic>{
      'v': 1,
      'alg': 'PBKDF2-HMAC-SHA256+AES-256-GCM',
      'iter': _iterations,
      'salt': base64Encode(salt),
      'nonce': base64Encode(box.nonce),
      'mac': base64Encode(box.mac.bytes),
      'ct': base64Encode(box.cipherText),
    };
    return jsonEncode(envelope);
  }

  Future<String> decryptString(String encodedEnvelope, String passphrase) async {
    if (passphrase.isEmpty) {
      throw const CryptoException('Passphrase must not be empty.');
    }
    try {
      final decoded = jsonDecode(encodedEnvelope) as Map<String, dynamic>;
      final version = (decoded['v'] as num?)?.toInt();
      if (version != 1) {
        throw const CryptoException('Unsupported encryption envelope version.');
      }
      final iter = (decoded['iter'] as num?)?.toInt() ?? _iterations;
      final salt = base64Decode(decoded['salt'] as String);
      final nonce = base64Decode(decoded['nonce'] as String);
      final macBytes = base64Decode(decoded['mac'] as String);
      final ctBytes = base64Decode(decoded['ct'] as String);

      final kdf = Pbkdf2.hmacSha256(iterations: iter, bits: 256);
      final key = await kdf.deriveKeyFromPassword(
        password: passphrase,
        nonce: salt,
      );
      final box = SecretBox(ctBytes, nonce: nonce, mac: Mac(macBytes));
      final clear = await _aesGcm.decrypt(box, secretKey: key);
      return utf8.decode(clear);
    } on SecretBoxAuthenticationError {
      throw const CryptoException('Invalid passphrase or corrupted payload.');
    } catch (e) {
      if (e is CryptoException) rethrow;
      throw CryptoException('Unable to decrypt payload: $e');
    }
  }

  String generateSaltHex() {
    final bytes = _randomBytes(16);
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  String hashPin(String pin, String saltHex) {
    final digest = dart_crypto.sha256.convert(utf8.encode('$saltHex:$pin'));
    return digest.toString();
  }

  bool verifyPin(String pin, String saltHex, String expectedHash) {
    final candidate = hashPin(pin, saltHex);
    if (candidate.length != expectedHash.length) return false;
    var diff = 0;
    for (var i = 0; i < candidate.length; i++) {
      diff |= candidate.codeUnitAt(i) ^ expectedHash.codeUnitAt(i);
    }
    return diff == 0;
  }
}
