import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../../core/engine/rpg_sfx_service.dart';
import '../../../core/security/app_lock_service.dart';
import '../../../core/security/crypto_service.dart';
import '../../../core/storage/recovery_storage.dart';
import '../../sync_profile/data/github_gist_sync.dart';
import '../../sync_profile/data/supabase_sync.dart';

/// Injected clock seam for deterministic unit and widget testing.
final clockProvider = Provider<Clock>((ref) => const Clock());

final uuidProvider = Provider<Uuid>((ref) => const Uuid());

/// Storage seam — overridden in main() and tests.
final storageProvider = Provider<RecoveryStorage>(
  (ref) => throw UnimplementedError('Override storageProvider in main()'),
);

/// Secure vault seam — overridden in main() and tests.
final vaultProvider = Provider<SecretVault>(
  (ref) => throw UnimplementedError('Override vaultProvider in main()'),
);

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final cryptoServiceProvider = Provider<CryptoService>((ref) => CryptoService());

final appLockServiceProvider = Provider<AppLockService>(
  (ref) => AppLockService(
    vault: ref.watch(vaultProvider),
    crypto: ref.watch(cryptoServiceProvider),
  ),
);

final githubGistClientProvider = Provider<GithubGistSyncClient>(
  (ref) => GithubGistSyncClient(
    httpClient: ref.watch(httpClientProvider),
    crypto: ref.watch(cryptoServiceProvider),
  ),
);

final supabaseAdapterProvider = Provider<SupabaseSyncAdapter>(
  (ref) => SupabaseSyncAdapter(),
);

final sfxServiceProvider = Provider<RpgSfxService>((ref) {
  final sfx = RpgSfxService();
  ref.onDispose(sfx.dispose);
  return sfx;
});

/// Emits the current UTC time every second for live tabular counters.
final liveClockStreamProvider = StreamProvider.autoDispose<DateTime>((ref) {
  final clock = ref.watch(clockProvider);
  return Stream<DateTime>.periodic(
    const Duration(seconds: 1),
    (_) => clock.now().toUtc(),
  );
});
