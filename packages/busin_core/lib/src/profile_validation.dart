import 'phone_numbers.dart';

/// What a student may type about themselves, checked the same way in every app. The server is the final judge (these
/// are for kind, early messages), and nothing here is trusted for access.
enum ProfileFieldProblem { empty, tooShort, tooLong, invalid }

class ProfileValidation {
  const ProfileValidation._();

  static const nameMin = 2;
  static const nameMax = 80;
  static const matriculeMin = 3;
  static const matriculeMax = 32;
  static const textMax = 80;

  /// A real name: letters, spaces and the usual punctuation of names.
  static ProfileFieldProblem? fullName(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return ProfileFieldProblem.empty;
    if (v.length < nameMin) return ProfileFieldProblem.tooShort;
    if (v.length > nameMax) return ProfileFieldProblem.tooLong;
    return null;
  }

  /// A student number: letters, digits, dashes, slashes and dots.
  static ProfileFieldProblem? matricule(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return ProfileFieldProblem.empty;
    if (v.length < matriculeMin) return ProfileFieldProblem.tooShort;
    if (v.length > matriculeMax) return ProfileFieldProblem.tooLong;
    if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9._/\- ]*$').hasMatch(v)) return ProfileFieldProblem.invalid;
    return null;
  }

  /// A real phone number for [country] (two letters; ADR 0024): empty, or not one that exists there, is refused.
  static ProfileFieldProblem? phone(String? value, String country) => switch (PhoneNumbers.parse(value, country).problem) {
        PhoneProblem.empty => ProfileFieldProblem.empty,
        PhoneProblem.invalid => ProfileFieldProblem.invalid,
        null => null,
      };

  /// An optional free text (department, program): empty is fine.
  static ProfileFieldProblem? optionalText(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return null;
    return v.length > textMax ? ProfileFieldProblem.tooLong : null;
  }

  /// A phone number as it is stored: E.164, for example `+237677123456` (ADR 0024). Empty when it cannot be read.
  static String normalizePhone(String value, String country) => PhoneNumbers.parse(value, country).e164 ?? '';
}
