import '../geo_point.dart';
import '../json.dart';
import '../value_object.dart';

/// A pickup stop with a map position.
class Stop extends ValueObject {
  const Stop({
    required this.id,
    required this.schoolId,
    required this.name,
    required this.location,
    required this.active,
    this.photoPath,
  });

  factory Stop.fromJson(Map<String, dynamic> json) => Stop(
        id: reqString(json, 'id'),
        schoolId: reqString(json, 'school_id'),
        name: reqString(json, 'name'),
        location: GeoPoint.fromApi(json['location']),
        photoPath: optString(json, 'photo_path'),
        active: reqBool(json, 'active'),
      );

  final String id;
  final String schoolId;
  final String name;
  final GeoPoint location;

  /// Path in the private `stops` bucket; show it through a signed URL.
  final String? photoPath;
  final bool active;

  @override
  List<Object?> get props => [id, schoolId, name, location, photoPath, active];
}
