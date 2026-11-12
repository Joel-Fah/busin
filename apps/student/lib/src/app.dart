import 'dart:async';

import 'package:busin_app/busin_app.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import 'router.dart';

class StudentApp extends ConsumerWidget {
  const StudentApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      onGenerateTitle: (context) => BusinL10n.of(context).appName,
      theme: BusinTheme.light(),
      darkTheme: BusinTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      // Null follows the phone.
      locale: ref.watch(localeProvider),
      localizationsDelegates: businLocalizationsDelegates,
      supportedLocales: businSupportedLocales,
      routerConfig: ref.watch(routerProvider),
      // While the app runs, a school suspending the account takes effect at once, without waiting for a restart.
      builder: (context, child) => Consumer(
        builder: (context, ref, _) => AccountWatcher(
          userId: ref.watch(authUserIdProvider).value,
          watch: ref.read(profileRepositoryProvider).watchProfile,
          onChanged: () => unawaited(ref.read(accountRecheckProvider)()),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
