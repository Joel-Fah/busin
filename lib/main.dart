import 'package:busin/utils/routes.dart';
import 'package:busin/utils/theme.dart';
import 'package:busin/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'l10n/app_localizations.dart';
import 'l10n/l10n.dart';
import 'controllers/controllers.dart';

Future<void> main() async {
  // Ensure that the app is initialized before running
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize GetStorage
  await GetStorage.init();

  // Set default locale for intl
  initializeDateFormatting('en_US', null);
  Intl.defaultLocale = 'en_US';

  // Set color of status bar to scaffold bg
  // SystemChrome.setSystemUIOverlayStyle(
  //   const SystemUiOverlayStyle(
  //     statusBarColor: lightColor,
  //     statusBarIconBrightness: Brightness.dark,
  //     systemNavigationBarColor: lightColor,
  //     systemNavigationBarIconBrightness: Brightness.dark,
  //   ),
  // );

  // Initialize GetX controllers
  Get.put(LocaleController());

  // locked orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp.router(
      title: 'Material App',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: snackBarKey,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      locale: Get.find<LocaleController>().locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: L10n.all,
      fallbackLocale: const Locale('en', 'US'),
      routerDelegate: router.routerDelegate,
      routeInformationParser: router.routeInformationParser,
      routeInformationProvider: router.routeInformationProvider,
    );
  }
}
