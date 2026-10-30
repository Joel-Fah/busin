import '../enums.dart';
import '../json.dart';
import '../value_object.dart';

/// An academic period with exact dates. It can span two calendar years.
class Semester extends ValueObject {
  const Semester({
    required this.id,
    required this.schoolId,
    required this.name,
    required this.year,
    required this.startDate,
    required this.endDate,
  });

  factory Semester.fromJson(Map<String, dynamic> json) => Semester(
        id: reqString(json, 'id'),
        schoolId: reqString(json, 'school_id'),
        name: SemesterName.parse(json['name']),
        year: reqInt(json, 'year'),
        startDate: reqDate(json, 'start_date'),
        endDate: reqDate(json, 'end_date'),
      );

  final String id;
  final String schoolId;
  final SemesterName name;
  final int year;

  /// First day, as midnight UTC.
  final DateTime startDate;

  /// Last day (inclusive), as midnight UTC.
  final DateTime endDate;

  /// True when [day]'s calendar date, in the school's local calendar, is
  /// within the semester. Pass the school's local date, not an instant.
  bool includes(DateTime day) {
    final d = DateTime.utc(day.year, day.month, day.day);
    return !d.isBefore(startDate) && !d.isAfter(endDate);
  }

  @override
  List<Object?> get props => [id, schoolId, name, year, startDate, endDate];
}
