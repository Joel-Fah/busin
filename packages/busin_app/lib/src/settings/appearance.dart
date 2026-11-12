import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where the phone remembers harmless choices (theme, language). Nothing secret is ever kept here. The app gives the real
/// store at start; without one (a test, a preview) a choice simply lasts until the app closes.
final appPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

const _themeKey = 'theme_mode';
const _localeKey = 'locale';

/// Light, dark, or whatever the phone is set to. Chosen on the profile, kept on the phone.
class ThemeModeChoice extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => switch (ref.read(appPreferencesProvider)?.getString(_themeKey)) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  void choose(ThemeMode mode) {
    state = mode;
    final prefs = ref.read(appPreferencesProvider);
    if (mode == ThemeMode.system) {
      prefs?.remove(_themeKey);
    } else {
      prefs?.setString(_themeKey, mode.name);
    }
  }
}

final themeModeProvider = NotifierProvider<ThemeModeChoice, ThemeMode>(ThemeModeChoice.new);

/// The language the student chose, or null to follow the phone. Only the languages the app speaks are accepted.
class LocaleChoice extends Notifier<Locale?> {
  @override
  Locale? build() {
    final code = ref.read(appPreferencesProvider)?.getString(_localeKey);
    return businSupportedLocales.where((l) => l.languageCode == code).firstOrNull;
  }

  void choose(Locale? locale) {
    state = locale;
    final prefs = ref.read(appPreferencesProvider);
    if (locale == null) {
      prefs?.remove(_localeKey);
    } else {
      prefs?.setString(_localeKey, locale.languageCode);
    }
  }
}

final localeProvider = NotifierProvider<LocaleChoice, Locale?>(LocaleChoice.new);
