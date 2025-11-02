import 'package:busin/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/theme_controller.dart';

// Globals
final GlobalKey<ScaffoldMessengerState> snackBarKey =
    GlobalKey<ScaffoldMessengerState>();

ThemeController get themeController => Get.find<ThemeController>();

// Remove leading slash from route name
String removeLeadingSlash(String route) {
  if (route.startsWith('/')) {
    return route.substring(1);
  }
  return route;
}

// Media Query Size
// width
double mediaWidth(BuildContext context) {
  return MediaQuery.of(context).size.width;
}

// height
double mediaHeight(BuildContext context) {
  return MediaQuery.of(context).size.height;
}

String addThousandSeparator(String price) {
  /// Add a thousand separator to a given number
  return price.replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  );
}

// Date & Time Formatters
String dateFormatter(DateTime date) {
  return DateFormat('dd-MM-yyyy').format(date);
}

String dateTimeFormatter(DateTime date) {
  return DateFormat('dd-MM-yyyy \'at\' HH:mm a').format(date);
}

// Validators
// email regex that allows abc@domain.com, abc+def@domain.com, abc.def@sub.domain.com
const String emailRegex = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
const String phoneRegex = r'^[62]\d{8}$';

// Weekdays
List<String> weekdays(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return [
    l10n.weekday_monday,
    l10n.weekday_tuesday,
    l10n.weekday_wednesday,
    l10n.weekday_thursday,
    l10n.weekday_friday,
    l10n.weekday_saturday,
    l10n.weekday_sunday,
  ];
}
