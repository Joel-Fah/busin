import 'package:cloud_firestore/cloud_firestore.dart';
import 'subscription.dart';

/// Configuration model for semester date ranges.
/// Admins can define custom start/end dates for each semester in each year.
class SemesterConfig {
  final String id; // e.g., "fall_2024", "spring_2025"
  final Semester semester;
  final int year;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final List<String> updatedBy;

  const SemesterConfig({
    required this.id,
    required this.semester,
    required this.year,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.updatedBy = const [],
  });

  /// Generate a unique ID for a semester config
  static String generateId(Semester semester, int year) {
    return '${semester.nameLower}_$year';
  }

  /// Check if the config is currently active
  bool get isActive {
    final now = DateTime.now();
    return !now.isBefore(startDate) && !now.isAfter(endDate);
  }

  /// Get duration in days
  int get durationInDays => endDate.difference(startDate).inDays;

  Map<String, dynamic> toMap() => {
        'id': id,
        'semester': semester.nameLower,
        'year': year,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'createdBy': createdBy,
        'updatedBy': updatedBy,
      };

  factory SemesterConfig.fromMap(Map<String, dynamic> map) {
    return SemesterConfig(
      id: map['id'] as String,
      semester: Semester.from(map['semester'] as String),
      year: (map['year'] as num).toInt(),
      startDate: _parseDateTime(map['startDate']),
      endDate: _parseDateTime(map['endDate']),
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
      createdBy: map['createdBy'] as String? ?? '',
      updatedBy: (map['updatedBy'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  /// Helper method to parse DateTime from Firestore Timestamp or String
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is String) {
      return DateTime.parse(value);
    }
    throw ArgumentError('Cannot parse DateTime from type ${value.runtimeType}');
  }

  SemesterConfig copyWith({
    String? id,
    Semester? semester,
    int? year,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    List<String>? updatedBy,
  }) =>
      SemesterConfig(
        id: id ?? this.id,
        semester: semester ?? this.semester,
        year: year ?? this.year,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        createdBy: createdBy ?? this.createdBy,
        updatedBy: updatedBy ?? this.updatedBy,
      );

  @override
  String toString() =>
      'SemesterConfig[id: $id, semester: ${semester.label}, year: $year, '
      'startDate: $startDate, endDate: $endDate, duration: $durationInDays days, '
      'isActive: $isActive]';
}

