import '../json.dart';
import '../value_object.dart';

/// The address of a logo in the public `school-logos` bucket.
String? schoolLogoUrl(String? path, String supabaseUrl) {
  if (path == null || path.isEmpty) return null;
  final base = supabaseUrl.endsWith('/') ? supabaseUrl.substring(0, supabaseUrl.length - 1) : supabaseUrl;
  return '$base/storage/v1/object/public/school-logos/${path.split('/').map(Uri.encodeComponent).join('/')}';
}

/// A school a student without a school email may ask to join (ADR 0012): only what is needed to choose it.
class OpenSchool extends ValueObject {
  const OpenSchool({required this.id, required this.name, this.shortName, this.city, this.country, this.logoPath});

  factory OpenSchool.fromJson(Map<String, dynamic> json) => OpenSchool(
        id: reqString(json, 'id'),
        name: reqString(json, 'name'),
        shortName: optString(json, 'short_name'),
        city: optString(json, 'city'),
        country: optString(json, 'country'),
        logoPath: optString(json, 'logo_path'),
      );

  final String id;
  final String name;
  final String? shortName;
  final String? city;
  final String? country;
  final String? logoPath;

  String? logoUrl(String supabaseUrl) => schoolLogoUrl(logoPath, supabaseUrl);

  /// "Yaounde, Cameroon", or whichever of the two is known.
  String? get place => [city, country].whereType<String>().where((s) => s.trim().isNotEmpty).join(', ').ifEmpty();

  @override
  List<Object?> get props => [id, name, shortName, city, country, logoPath];
}

/// The student's own request to join a school: the school asked (if any), when, and the last decline, if there was one.
/// A staff access request (ADR 0026) has the same shape, plus how many requests the account may still send.
class JoinRequest extends ValueObject {
  const JoinRequest({
    this.schoolId,
    this.schoolName,
    this.schoolLogoPath,
    this.requestedAt,
    this.declinedAt,
    this.declinedSchoolName,
    this.declineNote,
    this.requestsLeft,
  });

  factory JoinRequest.fromJson(Map<String, dynamic> json) => JoinRequest(
        schoolId: optString(json, 'school_id'),
        schoolName: optString(json, 'school_name'),
        schoolLogoPath: optString(json, 'school_logo_path'),
        requestedAt: optTimestamp(json, 'requested_at'),
        declinedAt: optTimestamp(json, 'declined_at'),
        declinedSchoolName: optString(json, 'declined_school_name'),
        declineNote: optString(json, 'decline_note'),
        requestsLeft: optInt(json, 'requests_left'),
      );

  /// How many staff requests an account may send in all (issue #543). The server holds the rule
  /// (`private.staff_request_limit()`); the app only uses it to tell an account that never asked from one that did.
  static const staffRequestLimit = 3;

  final String? schoolId;
  final String? schoolName;
  final String? schoolLogoPath;
  final DateTime? requestedAt;
  final DateTime? declinedAt;
  final String? declinedSchoolName;
  final String? declineNote;

  /// Staff requests only: how many more the account may send (0 when only an administrator can let it in), or null
  /// when the server did not say (a join request).
  final int? requestsLeft;

  bool get isWaiting => schoolId != null;
  bool get wasDeclined => declinedAt != null;

  /// No staff request may be sent any more: only an administrator lets the account in (an invite of the email, or the
  /// approval of a request still waiting).
  bool get requestsUsedUp => requestsLeft != null && requestsLeft! <= 0;

  String? logoUrl(String supabaseUrl) => schoolLogoUrl(schoolLogoPath, supabaseUrl);

  @override
  List<Object?> get props => [schoolId, schoolName, schoolLogoPath, requestedAt, declinedAt, declinedSchoolName, declineNote, requestsLeft];
}

extension on String {
  String? ifEmpty() => isEmpty ? null : this;
}
