import 'package:busin/controllers/controllers.dart';
import 'package:busin/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;


// Globals
final GlobalKey<ScaffoldMessengerState> snackBarKey =
    GlobalKey<ScaffoldMessengerState>();

ThemeController get themeController => Get.find<ThemeController>();

LocaleController get localeController => Get.find<LocaleController>();

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
  return localeController.locale.languageCode == 'en'
      ? DateFormat(
          'MMM dd, yyyy',
          localeController.locale.languageCode,
        ).format(date)
      : DateFormat(
          'dd MMM yyyy',
          localeController.locale.languageCode,
        ).format(date);
}

String dateTimeFormatter(DateTime date) {
  return localeController.locale.languageCode == 'en'
      ? DateFormat(
          'MMM dd, yyyy \'at\' HH:mm a',
          localeController.locale.languageCode,
        ).format(date)
      : DateFormat(
          'dd MMM yyyy \'à\' HH:mm',
          localeController.locale.languageCode,
        ).format(date);
}

// Format date time relative to now (for metadata display)
/// Uses timeago package for relative dates with locale support
/// Falls back to dateFormatter for dates older than 7 days
///
/// Examples:
/// - `formatRelativeDateTime(DateTime.now())` → "a moment ago"
/// - `formatRelativeDateTime(DateTime.now().subtract(Duration(hours: 2)))` → "2 hours ago"
/// - `formatRelativeDateTime(DateTime.now().subtract(Duration(hours: 2)), locale: 'fr')` → "il y a 2 heures"
/// - `formatRelativeDateTime(DateTime.now().subtract(Duration(days: 10)))` → "Dec 20, 2025" (formatted date)
///
/// Supported locales: 'en', 'fr', 'es', 'de', 'it', 'pt', 'ar', 'zh', 'ja', and many more.
/// See: https://pub.dev/packages/timeago for full list
String formatRelativeDateTime(DateTime dateTime, {String? locale}) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  // If more than 7 days ago, show the actual date using dateFormatter
  if (difference.inDays >= 7) {
    return dateFormatter(dateTime);
  }

  // Otherwise, use timeago for relative formatting with locale support
  // Locale can be set (e.g., 'en', 'fr'), defaults to 'en'
  return timeago.format(dateTime, locale: locale ?? 'en');
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

// Validation methods
String? validatePhone(String? value) {
  if (value == null || value.trim().isEmpty) {
    return localeController.locale.languageCode == 'en'
        ? 'Phone number is required'
        : 'Le numéro de téléphone est requis';
  }

  // Remove spaces and special characters
  final cleanedPhone = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

  // Cameroon phone number validation
  // Format: +237XXXXXXXXX or 237XXXXXXXXX or 6XXXXXXXX or 2XXXXXXXX
  final RegExp cameroonPhoneRegex = RegExp(r'^(\+?237|237)?[26]\d{8}$');

  if (!cameroonPhoneRegex.hasMatch(cleanedPhone)) {
    return localeController.locale.languageCode == 'en'
        ? 'Please enter a valid Cameroon phone number'
        : 'Veuillez entrer un numéro de téléphone camerounais valide';
  }

  return null;
}

String? validateMatricule(String? value) {
  final bool isEnLocale = localeController.locale.languageCode == 'en';

  if (value == null || value.trim().isEmpty) {
    return isEnLocale
        ? 'Student ID is required'
        : 'Le matricule étudiant est requis';
  }

  final matricule = value.trim().toUpperCase();

  // Format: ICTU<year><4digits> = 12 characters
  if (matricule.length != 12) {
    return isEnLocale
        ? 'Student ID must be 12 characters long'
        : 'Le matricule étudiant doit contenir 12 caractères';
  }

  if (!matricule.startsWith('ICTU')) {
    return isEnLocale
        ? 'Student ID must start with ICTU'
        : 'Le matricule étudiant doit commencer par ICTU';
  }

  // Extract year (characters 4-7)
  final yearPart = matricule.substring(4, 8);
  final year = int.tryParse(yearPart);
  if (year == null || year < 2000 || year > DateTime.now().year + 1) {
    return isEnLocale
        ? 'Invalid year in Student ID'
        : 'Année invalide dans le matricule étudiant';
  }

  // Extract digits (characters 8-11)
  final digitsPart = matricule.substring(8, 12);
  if (int.tryParse(digitsPart) == null) {
    return isEnLocale
        ? 'Last 4 characters must be digits'
        : 'Les 4 derniers caractères doivent être des chiffres';
  }

  return null;
}
