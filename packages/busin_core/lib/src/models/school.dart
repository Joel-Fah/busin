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
  });

  factory School.fromJson(Map<String, dynamic> json) => School(
        id: reqString(json, 'id'),
        name: reqString(json, 'name'),
        shortName: optString(json, 'short_name'),
        timezone: reqString(json, 'timezone'),
        isActive: reqString(json, 'status') == 'active',
      );

  final String id;
  final String name;
  final String? shortName;

  /// IANA timezone name, for example `Africa/Douala`.
  final String timezone;
  final bool isActive;

  /// The same shape the API returns, so [School.fromJson] reads it back.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'short_name': shortName,
        'timezone': timezone,
        'status': isActive ? 'active' : 'inactive',
      };

  @override
  List<Object?> get props => [id, name, shortName, timezone, isActive];
}
