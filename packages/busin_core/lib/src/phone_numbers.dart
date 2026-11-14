import 'package:phone_numbers_parser/phone_numbers_parser.dart' as pn;

/// Why a typed phone number cannot be used.
enum PhoneProblem { empty, invalid }

/// Phone numbers in one format (ADR 0024): stored as E.164 (`+` then the country code and the number, digits only, for
/// example `+237677123456`), typed in the country's own way, shown in international form with spaces.
class PhoneNumbers {
  const PhoneNumbers._();

  static final _e164 = RegExp(r'^\+[1-9][0-9]{6,14}$');
  static final _typed = RegExp(r'^\+?[0-9 .\-()]+$');

  /// Whether [value] is already in the stored form.
  static bool isE164(String? value) => value != null && _e164.hasMatch(value);

  static pn.IsoCode? _iso(String? country) {
    if (country == null) return null;
    for (final code in pn.IsoCode.values) {
      if (code.name == country.toUpperCase()) return code;
    }
    return null;
  }

  /// Reads what a person typed, for [country] (ISO 3166 two letters, for example `CM`). A number that starts with `+`
  /// keeps its own country. Gives the E.164 form, or why it cannot be used: empty, or not a real number for its country.
  static ({String? e164, PhoneProblem? problem}) parse(String? input, String country) {
    final value = (input ?? '').trim();
    if (value.isEmpty) return (e164: null, problem: PhoneProblem.empty);
    if (!_typed.hasMatch(value)) return (e164: null, problem: PhoneProblem.invalid);
    final iso = _iso(country);
    if (value.startsWith('+')) return _read(value, null);
    final first = _read(value, iso);
    if (first.e164 != null) return first;
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    // A national trunk 0 the library did not drop for this country (it does for some only): try once without it.
    final national = digits.startsWith('0') ? digits.substring(1) : digits;
    if (national != digits) {
      final again = _read(national, iso);
      if (again.e164 != null) return again;
    }
    // Countries can share a dialling code (+44: the UK, Guernsey, Jersey...): a number valid in any of them is kept.
    final code = callingCode(country);
    return code == null ? first : _read('+$code$national', null).e164 != null ? _read('+$code$national', null) : first;
  }

  static ({String? e164, PhoneProblem? problem}) _read(String value, pn.IsoCode? iso) {
    try {
      final number = iso == null ? pn.PhoneNumber.parse(value) : pn.PhoneNumber.parse(value, callerCountry: iso, destinationCountry: iso);
      if (!number.isValid()) return (e164: null, problem: PhoneProblem.invalid);
      return (e164: number.international, problem: null);
    } on pn.PhoneNumberException {
      return (e164: null, problem: PhoneProblem.invalid);
    }
  }

  /// A stored number as people read it: `+237 6 77 12 34 56`. Anything that cannot be read is shown as it is.
  static String display(String e164) {
    try {
      final number = pn.PhoneNumber.parse(e164);
      return '+${number.countryCode} ${number.formatNsn(format: pn.NsnFormat.international)}';
    } on pn.PhoneNumberException {
      return e164;
    }
  }

  /// The country of a stored number (two letters), or null.
  static String? countryOf(String? e164) {
    if (!isE164(e164)) return null;
    try {
      return pn.PhoneNumber.parse(e164!).isoCode.name;
    } on pn.PhoneNumberException {
      return null;
    }
  }

  /// The dialling code of a country, for example `237` for `CM`, or null for an unknown country.
  static String? callingCode(String country) {
    final iso = _iso(country);
    if (iso == null) return null;
    try {
      return pn.PhoneNumber(isoCode: iso, nsn: '').countryCode;
    } catch (_) {
      return null;
    }
  }

  /// A number written with its `+` and code (pasted, or a saved E.164) split into its country and its national digits,
  /// even before it is complete. Null when no country can be told from it.
  static ({String country, String national})? splitInternational(String text) {
    final value = text.trim();
    if (!value.startsWith('+')) return null;
    try {
      final number = pn.PhoneNumber.parse(value);
      return (country: number.isoCode.name, national: number.nsn);
    } on pn.PhoneNumberException {
      return null;
    }
  }

  /// [national] digits as the country writes them while they are typed (`6 77 12 34 56`).
  static String formatTyping(String national, String country) {
    final digits = national.replaceAll(RegExp(r'[^0-9]'), '');
    final iso = _iso(country);
    if (iso == null || digits.isEmpty) return digits;
    try {
      return pn.PhoneNumber(isoCode: iso, nsn: digits).formatNsn();
    } catch (_) {
      return digits;
    }
  }

  /// The country a phone field starts on, never one fixed in the code: the saved number's, else the school's own
  /// number's, else the device's region, else [fallback].
  static String defaultCountry({String? saved, String? schoolPhone, String? deviceRegion, String fallback = 'CM'}) {
    final fromSaved = countryOf(saved);
    if (fromSaved != null) return fromSaved;
    final fromSchool = countryOf(schoolPhone);
    if (fromSchool != null) return fromSchool;
    if (deviceRegion != null && _iso(deviceRegion) != null) return deviceRegion.toUpperCase();
    return fallback;
  }
}
