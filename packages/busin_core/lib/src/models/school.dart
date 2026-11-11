import '../json.dart';
import '../value_object.dart';

/// A school (tenant). Every other record belongs to exactly one school.
class School extends ValueObject {
  const School({
    required this.id,
    required this.name,
    required this.timezone,
    required this.isActive,
    this.shortName,
    this.logoPath,
    this.city,
    this.country,
    this.website,
    this.contactEmail,
    this.phone,
    this.about,
  });

  factory School.fromJson(Map<String, dynamic> json) => School(
        id: reqString(json, 'id'),
        name: reqString(json, 'name'),
        shortName: optString(json, 'short_name'),
        timezone: reqString(json, 'timezone'),
        isActive: reqString(json, 'status') == 'active',
        logoPath: optString(json, 'logo_path'),
        city: optString(json, 'city'),
        country: optString(json, 'country'),
        website: optString(json, 'website'),
        contactEmail: optString(json, 'contact_email'),
        phone: optString(json, 'phone'),
        about: optString(json, 'about'),
      );

  final String id;
  final String name;
  final String? shortName;

  /// IANA timezone name, for example `Africa/Douala`.
  final String timezone;
  final bool isActive;

  /// The logo's path in the public `school-logos` bucket, when the school has one (see [logoUrl]).
  final String? logoPath;
  final String? city;
  final String? country;
  final String? website;
  final String? contactEmail;
  final String? phone;

  /// One or two sentences the school writes for its students.
  final String? about;

  /// The public address of the logo, given the backend's base URL.
  String? logoUrl(String supabaseUrl) {
    final path = logoPath;
    if (path == null || path.isEmpty) return null;
    final base = supabaseUrl.endsWith('/') ? supabaseUrl.substring(0, supabaseUrl.length - 1) : supabaseUrl;
    return '$base/storage/v1/object/public/school-logos/${path.split('/').map(Uri.encodeComponent).join('/')}';
  }

  /// The same shape the API returns, so [School.fromJson] reads it back.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'short_name': shortName,
        'timezone': timezone,
        'status': isActive ? 'active' : 'inactive',
        'logo_path': logoPath,
        'city': city,
        'country': country,
        'website': website,
        'contact_email': contactEmail,
        'phone': phone,
        'about': about,
      };

  @override
  List<Object?> get props => [id, name, shortName, timezone, isActive, logoPath, city, country, website, contactEmail, phone, about];
}
