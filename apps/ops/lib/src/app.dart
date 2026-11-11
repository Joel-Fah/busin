import 'package:busin_app/busin_app.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    );
  }
}
