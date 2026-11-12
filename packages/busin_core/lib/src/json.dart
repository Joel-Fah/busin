/// Small helpers for reading API maps with clear errors.
library;

Never _bad(String key, String expected, Object? value) =>
    throw FormatException('Field "$key" must be $expected, got: $value');

String reqString(Map<String, dynamic> json, String key) {
  final v = json[key];
  return v is String ? v : _bad(key, 'a string', v);
}

String? optString(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v == null) return null;
  return v is String ? v : _bad(key, 'a string or null', v);
}

int reqInt(Map<String, dynamic> json, String key) {
  final v = json[key];
  return v is int ? v : _bad(key, 'an integer', v);
}

bool reqBool(Map<String, dynamic> json, String key) {
  final v = json[key];
  return v is bool ? v : _bad(key, 'a boolean', v);
}

double? optDouble(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v == null) return null;
  return v is num ? v.toDouble() : _bad(key, 'a number or null', v);
}

/// Parses a timestamp such as `2026-10-30T16:15:42.123+00:00`.
DateTime reqTimestamp(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v is String) {
    final parsed = DateTime.tryParse(v);
    if (parsed != null) return parsed;
  }
  return _bad(key, 'an ISO 8601 timestamp', v);
}

DateTime? optTimestamp(Map<String, dynamic> json, String key) {
  if (json[key] == null) return null;
  return reqTimestamp(json, key);
}

/// Parses a date-only value such as `2026-09-07` as midnight UTC.
DateTime reqDate(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v is String && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v)) {
    final parsed = DateTime.tryParse('${v}T00:00:00Z');
    if (parsed != null) return parsed;
  }
  return _bad(key, 'a date (YYYY-MM-DD)', v);
}

/// Formats a date-only value for the API.
String formatDate(DateTime date) {
  final d = date.toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}';
}
