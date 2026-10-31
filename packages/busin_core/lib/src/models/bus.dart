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
  });

  factory Bus.fromJson(Map<String, dynamic> json) => Bus(
        id: reqString(json, 'id'),
        schoolId: reqString(json, 'school_id'),
        plate: reqString(json, 'plate'),
        capacity: reqInt(json, 'capacity'),
        inService: reqBool(json, 'in_service'),
      );

  final String id;
  final String schoolId;
  final String plate;
  final int capacity;
  final bool inService;

  @override
  List<Object?> get props => [id, schoolId, plate, capacity, inService];
}
