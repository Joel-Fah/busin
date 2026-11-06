import '../json.dart';
import '../value_object.dart';

/// A faculty of the school, which groups departments. The school manages these; a student only picks.
class Faculty extends ValueObject {
  const Faculty({required this.id, required this.name, this.code});

  factory Faculty.fromJson(Map<String, dynamic> json) =>
      Faculty(id: reqString(json, 'id'), name: reqString(json, 'name'), code: optString(json, 'code'));

  final String id;
  final String name;
  final String? code;

  @override
  List<Object?> get props => [id, name, code];
}

class Department extends ValueObject {
  const Department({required this.id, required this.facultyId, required this.name, this.code});

  factory Department.fromJson(Map<String, dynamic> json) => Department(
        id: reqString(json, 'id'),
        facultyId: reqString(json, 'faculty_id'),
        name: reqString(json, 'name'),
        code: optString(json, 'code'),
      );

  final String id;
  final String facultyId;
  final String name;
  final String? code;

  @override
  List<Object?> get props => [id, facultyId, name, code];
}

/// A degree level of the school (Bachelor, Master, ...).
class Program extends ValueObject {
  const Program({required this.id, required this.name});

  factory Program.fromJson(Map<String, dynamic> json) => Program(id: reqString(json, 'id'), name: reqString(json, 'name'));

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

/// Everything a student chooses from on their profile, as the school has set it up.
class AcademicUnits extends ValueObject {
  const AcademicUnits({this.faculties = const [], this.departments = const [], this.programs = const []});

  final List<Faculty> faculties;
  final List<Department> departments;
  final List<Program> programs;

  /// Only the departments of one faculty: choosing a faculty narrows the list.
  List<Department> departmentsOf(String? facultyId) =>
      facultyId == null ? const [] : departments.where((d) => d.facultyId == facultyId).toList();

  Department? department(String? id) => id == null ? null : departments.cast<Department?>().firstWhere((d) => d!.id == id, orElse: () => null);

  Faculty? facultyOfDepartment(String? departmentId) {
    final d = department(departmentId);
    if (d == null) return null;
    return faculties.cast<Faculty?>().firstWhere((f) => f!.id == d.facultyId, orElse: () => null);
  }

  Program? program(String? id) => id == null ? null : programs.cast<Program?>().firstWhere((p) => p!.id == id, orElse: () => null);

  /// Nothing set up yet: the profile then simply has no academic section to choose from.
  bool get isEmpty => faculties.isEmpty && departments.isEmpty && programs.isEmpty;

  @override
  List<Object?> get props => [faculties, departments, programs];
}

/// What a person picked: both are written together, and null clears.
class AcademicChoice extends ValueObject {
  const AcademicChoice({this.departmentId, this.programId});

  final String? departmentId;
  final String? programId;

  @override
  List<Object?> get props => [departmentId, programId];
}
