import 'dart:ui';

import '../utils/constants.dart';

class L10n {
  static final all = [const Locale('en', 'US'), const Locale('fr', 'FR')];

  static String getFlag(String code) {
    switch (code) {
      case 'en':
        return usaFlag;
      case 'fr':
        return franceFlag;
      default:
        return usaFlag;
    }
  }
}
