import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/platform/platform_bootstrap.dart';
import 'core/security/app_lock_service.dart';
import 'core/storage/storage_factory.dart';
import 'features/sanctuary/application/app_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PlatformBootstrap.initialize();

  final storage = createPlatformStorage();
  await storage.init();

  runApp(
    ProviderScope(
      overrides: [
        storageProvider.overrideWithValue(storage),
        vaultProvider.overrideWithValue(const SecureStorageVault()),
      ],
      child: const AtRecoveryRpgApp(),
    ),
  );
}
