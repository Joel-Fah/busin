import '../json.dart';
import '../value_object.dart';

/// What a staff member is on a trip they start in the field: the driver or the assistant (ADR 0020).
enum CrewRole {
  driver,
  assistant;

  /// The word the database function takes.
  String get wire => name;
}

/// A bus a staff member may start a field trip on: in service and not on a trip right now.
class FieldTripBus extends ValueObject {
  const FieldTripBus({required this.id, required this.plate, this.name});

  factory FieldTripBus.fromJson(Map<String, dynamic> json) =>
      FieldTripBus(id: reqString(json, 'id'), plate: reqString(json, 'plate'), name: optString(json, 'name'));

  final String id;
  final String plate;
  final String? name;

  /// What the bus is called wherever it is shown: its name when it has one, otherwise its plate.
  String get label {
    final named = name?.trim() ?? '';
    return named.isEmpty ? plate : named;
  }

  @override
  List<Object?> get props => [id, plate, name];
}

/// A colleague who could be on the crew of a trip: a name, nothing else.
class StaffOption extends ValueObject {
  const StaffOption({required this.id, required this.name});

  factory StaffOption.fromJson(Map<String, dynamic> json) => StaffOption(id: reqString(json, 'id'), name: optString(json, 'name') ?? '');

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

/// What the app needs to start a trip that is not on the list, from `field_trip_options`: whether the school allows it,
/// and the buses and colleagues to choose from.
class FieldTripOptions extends ValueObject {
  const FieldTripOptions({required this.allowed, this.buses = const [], this.staff = const []});

  factory FieldTripOptions.fromJson(Map<String, dynamic> json) => FieldTripOptions(
        allowed: json['allowed'] == true,
        buses: [for (final row in (json['buses'] as List<dynamic>? ?? const [])) FieldTripBus.fromJson(Map<String, dynamic>.from(row as Map))],
        staff: [for (final row in (json['staff'] as List<dynamic>? ?? const [])) StaffOption.fromJson(Map<String, dynamic>.from(row as Map))],
      );

  final bool allowed;
  final List<FieldTripBus> buses;
  final List<StaffOption> staff;

  @override
  List<Object?> get props => [allowed, buses, staff];
}
