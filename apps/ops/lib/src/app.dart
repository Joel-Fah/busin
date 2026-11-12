import 'dart:async';

import 'package:busin_app/busin_app.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'access.dart';
import 'providers.dart';
import 'router.dart';

class OpsApp extends ConsumerWidget {
  const OpsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'BusIn Ops',
      debugShowCheckedModeBanner: false,
      theme: BusinTheme.light(),
      darkTheme: BusinTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      locale: ref.watch(localeProvider),
      localizationsDelegates: businLocalizationsDelegates,
      supportedLocales: businSupportedLocales,
      routerConfig: ref.watch(routerProvider),
      // While the app runs, an administrator suspending the account or changing the role takes effect at once.
      builder: (context, child) => Consumer(
        builder: (context, ref, _) {
          ref.listen<OpsAccess>(accessProvider, (previous, next) {
            // Access lost: the day keys (what checks codes offline) are no longer this phone's to keep. Position
            // sharing and the scan sync stop by themselves, since they only run for an allowed person.
            if (previous is OpsAllowed && next is! OpsAllowed) unawaited(ref.read(rosterStoreProvider).clear());
          });
          return AccountWatcher(
            userId: ref.watch(authUserIdProvider).value,
            watch: ref.read(profileRepositoryProvider).watchProfile,
            onChanged: () => unawaited(ref.read(accountRecheckProvider)()),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
