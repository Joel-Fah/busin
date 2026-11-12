import '../json.dart';
import '../value_object.dart';

/// A bus. At least two exist and sometimes only one is in service.
class Bus extends ValueObject {
  const Bus({
    required this.id,
    required this.schoolId,
    required this.plate,
    required this.capacity,
    required this.inService,
    this.name,
  });

  factory Bus.fromJson(Map<String, dynamic> json) => Bus(
        id: reqString(json, 'id'),
        schoolId: reqString(json, 'school_id'),
        plate: reqString(json, 'plate'),
        name: optString(json, 'name'),
        capacity: reqInt(json, 'capacity'),
        inService: reqBool(json, 'in_service'),
      );

  final String id;
  final String schoolId;
  final String plate;

  /// What the school calls the bus, when it has a name.
  final String? name;
  final int capacity;
  final bool inService;

  /// What the bus is called wherever it is shown: its name when it has one, otherwise its plate.
  String get label {
    final named = name?.trim() ?? '';
    return named.isEmpty ? plate : named;
  }

  @override
  List<Object?> get props => [id, schoolId, plate, name, capacity, inService];
}
