import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';
import '../l10n/l10n.dart';

class LocaleController extends GetxController {
  static const String _localeKey = 'locale';
  final GetStorage _storage = GetStorage();

  // Default locale is fr
  final Rx<Locale> _locale = const Locale('en', 'US').obs;

  Locale get locale => _locale.value;
  List<Locale> get supportedLocales => L10n.all;

  @override
  void onInit() {
    super.onInit();
    _loadLocale();
  }

  void _loadLocale() {
    final String? localeString = _storage.read<String>(_localeKey);
    if (localeString != null) {
      final parts = localeString.split('_');
      if (parts.length == 2) {
        final loadedLocale = Locale(parts[0], parts[1]);
        if (supportedLocales.contains(loadedLocale)) {
          _locale.value = loadedLocale;
        }
      }
    }
  }

  void setLocale(Locale locale) {
    if (!supportedLocales.contains(locale)) return;
    _locale.value = locale;
    _storage.write(_localeKey, '${locale.languageCode}_${locale.countryCode}');
    Get.updateLocale(locale);
  }

  void resetLocale() {
    _locale.value = const Locale('en', 'US');
    _storage.remove(_localeKey);
    Get.updateLocale(_locale.value);
  }

  bool isDefaultLocale() => _locale.value == const Locale('en', 'US');
}
