import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/security/crypto_service.dart';
import '../../sanctuary/domain/recovery_models.dart';
import '../domain/sync_engine.dart';

class GistSyncResult {
  const GistSyncResult({
    required this.snapshot,
    required this.gistId,
  });

  final RecoverySnapshot snapshot;
  final String gistId;
}

class GistSyncException implements Exception {
  const GistSyncException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Zero-server encrypted cross-device sync using a private GitHub Gist.
class GithubGistSyncClient {
  GithubGistSyncClient({
    required http.Client httpClient,
    required this._crypto,
  }) : _http = httpClient;

  static const String fileName = 'at_recovery_sync.enc.json';
  static const String _baseUrl = 'https://api.github.com';

  final http.Client _http;
  final CryptoService _crypto;

  Map<String, String> _headers(String pat) => {
        'Authorization': 'Bearer $pat',
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
        'Content-Type': 'application/json',
      };

  Future<GistSyncResult> sync({
    required String pat,
    required String passphrase,
    required RecoverySnapshot localSnapshot,
    String? existingGistId,
  }) async {
    var gistId = existingGistId;
    Map<String, dynamic>? gistObj;

    if (gistId != null && gistId.isNotEmpty) {
      final resp = await _http.get(
        Uri.parse('$_baseUrl/gists/$gistId'),
        headers: _headers(pat),
      );
      if (resp.statusCode == 200) {
        gistObj = jsonDecode(resp.body) as Map<String, dynamic>;
      } else if (resp.statusCode == 401 || resp.statusCode == 403) {
        throw const GistSyncException('GitHub token rejected or missing gist scope.');
      } else {
        gistId = null;
      }
    }

    if (gistObj == null) {
      final found = await _findExistingSyncGist(pat);
      if (found != null) {
        gistObj = found;
        gistId = found['id'] as String?;
      }
    }

    RecoverySnapshot merged = localSnapshot;
    if (gistObj != null) {
      final files = gistObj['files'] as Map<String, dynamic>? ?? const {};
      final fileMap = files[fileName] as Map<String, dynamic>?;
      final content = fileMap?['content'] as String?;
      if (content != null && content.trim().isNotEmpty) {
        final plain = await _crypto.decryptString(content, passphrase);
        final remote = RecoverySnapshot.fromJson(
          jsonDecode(plain) as Map<String, dynamic>,
        );
        merged = SyncEngine.mergeSnapshots(localSnapshot, remote);
      }
    }

    final encrypted = await _crypto.encryptString(
      jsonEncode(merged.toJson()),
      passphrase,
    );

    if (gistId != null && gistId.isNotEmpty) {
      final patch = await _http.patch(
        Uri.parse('$_baseUrl/gists/$gistId'),
        headers: _headers(pat),
        body: jsonEncode({
          'description': 'ATP Pomodoro Encrypted Sync Snapshot',
          'files': {
            fileName: {'content': encrypted},
          },
        }),
      );
      if (patch.statusCode < 200 || patch.statusCode >= 300) {
        throw GistSyncException(
          'Failed to update Gist (${patch.statusCode}).',
        );
      }
      return GistSyncResult(snapshot: merged, gistId: gistId);
    }

    final create = await _http.post(
      Uri.parse('$_baseUrl/gists'),
      headers: _headers(pat),
      body: jsonEncode({
        'description': 'ATP Pomodoro Encrypted Sync Snapshot',
        'public': false,
        'files': {
          fileName: {'content': encrypted},
        },
      }),
    );
    if (create.statusCode < 200 || create.statusCode >= 300) {
      throw GistSyncException(
        'Failed to create private Gist (${create.statusCode}).',
      );
    }
    final createdObj = jsonDecode(create.body) as Map<String, dynamic>;
    final newId = createdObj['id'] as String? ?? '';
    return GistSyncResult(snapshot: merged, gistId: newId);
  }

  Future<Map<String, dynamic>?> _findExistingSyncGist(String pat) async {
    final resp = await _http.get(
      Uri.parse('$_baseUrl/gists?per_page=50'),
      headers: _headers(pat),
    );
    if (resp.statusCode == 401 || resp.statusCode == 403) {
      throw const GistSyncException('GitHub token rejected or missing gist scope.');
    }
    if (resp.statusCode != 200) return null;

    final list = jsonDecode(resp.body) as List<dynamic>;
    for (final raw in list) {
      final map = raw as Map<String, dynamic>;
      final files = map['files'] as Map<String, dynamic>? ?? const {};
      if (files.containsKey(fileName)) {
        final id = map['id'] as String;
        final fullResp = await _http.get(
          Uri.parse('$_baseUrl/gists/$id'),
          headers: _headers(pat),
        );
        if (fullResp.statusCode == 200) {
          return jsonDecode(fullResp.body) as Map<String, dynamic>;
        }
      }
    }
    return null;
  }
}
