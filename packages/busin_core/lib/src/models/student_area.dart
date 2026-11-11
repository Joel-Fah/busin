import '../json.dart';
import '../value_object.dart';

/// How a student gave their area (ADR 0013): one approximate reading of the phone, or a place they searched.
enum AreaSource {
  device,
  search;

  static AreaSource parse(Object? value) => switch (value) {
        'device' => device,
        'search' => search,
        _ => throw FormatException('Unknown area source: $value'),
      };
}

/// Roughly where a student lives: the centre of a cell of about 500 m, as the server stored it, and its name.
class StudentArea extends ValueObject {
  const StudentArea({required this.label, required this.lat, required this.lng, required this.source, required this.updatedAt});

  factory StudentArea.fromJson(Map<String, dynamic> json) => StudentArea(
        label: reqString(json, 'label'),
        lat: _reqDouble(json, 'lat'),
        lng: _reqDouble(json, 'lng'),
        source: AreaSource.parse(json['source']),
        updatedAt: reqTimestamp(json, 'updated_at'),
      );

  final String label;
  final double lat;
  final double lng;
  final AreaSource source;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [label, lat, lng, source, updatedAt];
}

/// One result of a place search: a short name, where it is, and a point.
class PlaceResult extends ValueObject {
  const PlaceResult({required this.label, required this.detail, required this.lat, required this.lng});

  factory PlaceResult.fromJson(Map<String, dynamic> json) => PlaceResult(
        label: reqString(json, 'label'),
        detail: optString(json, 'detail') ?? '',
        lat: _reqDouble(json, 'lat'),
        lng: _reqDouble(json, 'lng'),
      );

  final String label;
  final String detail;
  final double lat;
  final double lng;

  @override
  List<Object?> get props => [label, detail, lat, lng];
}

double _reqDouble(Map<String, dynamic> json, String key) =>
    optDouble(json, key) ?? (throw FormatException('Expected a number for $key'));

/// Rounds a point to about 1 km of precision (two decimals) before it leaves the phone. The server snaps it again to
/// its own 500 m grid; this only keeps the exact reading off the network.
({double lat, double lng}) roundForArea(double lat, double lng) =>
    (lat: (lat * 100).roundToDouble() / 100, lng: (lng * 100).roundToDouble() / 100);
