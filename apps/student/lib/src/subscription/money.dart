import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// An amount in whole units, as the student's language writes it: "30,000 XAF", "30 000 XAF".
String money(BuildContext context, int amount, [String currency = 'XAF']) =>
    '${NumberFormat.decimalPattern(Localizations.localeOf(context).toLanguageTag()).format(amount)} $currency';

/// A month and its year, as the student's language writes it: "November 2026", "novembre 2026".
String monthName(BuildContext context, DateTime month) =>
    DateFormat.yMMMM(Localizations.localeOf(context).toLanguageTag()).format(DateTime(month.year, month.month));
