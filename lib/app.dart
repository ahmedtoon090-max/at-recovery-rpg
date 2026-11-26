import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class AtRecoveryRpgApp extends ConsumerWidget {
  const AtRecoveryRpgApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      title: 'ATP Pomodoro',
      debugShowCheckedModeBanner: false,
      theme: buildObsidianTheme(),
      routerConfig: router,
    );
  }
}
