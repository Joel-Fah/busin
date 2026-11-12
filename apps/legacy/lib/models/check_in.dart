/// Check-in models for daily student attendance tracking.
///
/// When an admin/staff scans a student's QR code, the student is appended to
/// that day's [CheckInList]. Each individual scan becomes a [CheckInEntry].

// ─── Enums ───────────────────────────────────────────────────────────

/// The time-of-day period for the check-in.
enum CheckInPeriod {
  morning('morning'),
  evening('evening');

  final String value;
  const CheckInPeriod(this.value);

  static CheckInPeriod from(String value) {
    return CheckInPeriod.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CheckInPeriod.morning,
    );
  }

  String get labelEn {
    switch (this) {
      case CheckInPeriod.morning:
        return 'Morning';
      case CheckInPeriod.evening:
        return 'Evening';
    }
  }

  String get labelFr {
    switch (this) {
      case CheckInPeriod.morning:
        return 'Matin';
      case CheckInPeriod.evening:
        return 'Soir';
    }
  }

  String label(String languageCode) => languageCode == 'en' ? labelEn : labelFr;
}

// ─── Check-In Entry ──────────────────────────────────────────────────

/// A single student check-in record within a daily list.
class CheckInEntry {
  /// Unique ID for this entry.
  final String id;

  /// The student who was scanned.
  final String studentId;
  final String studentName;
  final String? studentPhotoUrl;

  /// Subscription active at scan time.
  final String subscriptionId;

  /// Admin/staff who performed the scan.
  final String scannedBy;
  final String scannedByName;

  /// Period of the day (morning / evening).
  final CheckInPeriod period;

  /// Arrival order within this list (1-based).
  final int arrivalOrder;

  /// Exact scan timestamp.
  final DateTime scannedAt;

  /// Optional notes from the scanner.
  final String? notes;

  // ── Metadata ──
  final DateTime createdAt;

  CheckInEntry({
    required this.id,
    required this.studentId,
    required this.studentName,
    this.studentPhotoUrl,
    required this.subscriptionId,
    required this.scannedBy,
    required this.scannedByName,
    required this.period,
    required this.arrivalOrder,
    required this.scannedAt,
    this.notes,
    required this.createdAt,
  });

  factory CheckInEntry.fromMap(Map<String, dynamic> map) {
    return CheckInEntry(
      id: map['id'] as String,
      studentId: map['studentId'] as String,
      studentName: map['studentName'] as String,
      studentPhotoUrl: map['studentPhotoUrl'] as String?,
      subscriptionId: map['subscriptionId'] as String,
      scannedBy: map['scannedBy'] as String,
      scannedByName: map['scannedByName'] as String,
      period: CheckInPeriod.from(map['period'] as String),
      arrivalOrder: map['arrivalOrder'] as int,
      scannedAt: DateTime.parse(map['scannedAt'] as String),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'studentPhotoUrl': studentPhotoUrl,
      'subscriptionId': subscriptionId,
      'scannedBy': scannedBy,
      'scannedByName': scannedByName,
      'period': period.value,
      'arrivalOrder': arrivalOrder,
      'scannedAt': scannedAt.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  CheckInEntry copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? studentPhotoUrl,
    String? subscriptionId,
    String? scannedBy,
    String? scannedByName,
    CheckInPeriod? period,
    int? arrivalOrder,
    DateTime? scannedAt,
    String? notes,
    DateTime? createdAt,
  }) {
    return CheckInEntry(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentPhotoUrl: studentPhotoUrl ?? this.studentPhotoUrl,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      scannedBy: scannedBy ?? this.scannedBy,
      scannedByName: scannedByName ?? this.scannedByName,
      period: period ?? this.period,
      arrivalOrder: arrivalOrder ?? this.arrivalOrder,
      scannedAt: scannedAt ?? this.scannedAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'CheckInEntry(id: $id, student: $studentName, order: $arrivalOrder, '
      'period: ${period.value}, scannedAt: $scannedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CheckInEntry && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// ─── Check-In List (daily aggregate) ─────────────────────────────────

/// Represents one day's check-in list. Each day can have multiple periods
/// (morning + evening). The list itself is stored as a Firestore document
/// with sub-entries in a nested collection or array.
class CheckInList {
  /// Document ID — formatted as `YYYY-MM-DD` for the date it represents.
  final String id;

  /// The calendar date this list belongs to.
  final DateTime date;

  /// All check-in entries for this day (both periods).
  final List<CheckInEntry> entries;

  /// Total unique students checked in.
  final int totalStudents;

  // ── Metadata ──
  final DateTime createdAt;
  final DateTime updatedAt;

  CheckInList({
    required this.id,
    required this.date,
    required this.entries,
    required this.totalStudents,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CheckInList.fromMap(Map<String, dynamic> map) {
    final entriesList =
        (map['entries'] as List<dynamic>?)
            ?.map((e) => CheckInEntry.fromMap(e as Map<String, dynamic>))
            .toList() ??
        [];

    return CheckInList(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      entries: entriesList,
      totalStudents: map['totalStudents'] as int? ?? entriesList.length,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': _dateOnly(date),
      'entries': entries.map((e) => e.toMap()).toList(),
      'totalStudents': totalStudents,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  CheckInList copyWith({
    String? id,
    DateTime? date,
    List<CheckInEntry>? entries,
    int? totalStudents,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CheckInList(
      id: id ?? this.id,
      date: date ?? this.date,
      entries: entries ?? this.entries,
      totalStudents: totalStudents ?? this.totalStudents,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ── Helpers ──

  /// Entries for a specific period.
  List<CheckInEntry> entriesForPeriod(CheckInPeriod period) =>
      entries.where((e) => e.period == period).toList();

  /// Morning entries count.
  int get morningCount => entriesForPeriod(CheckInPeriod.morning).length;

  /// Evening entries count.
  int get eveningCount => entriesForPeriod(CheckInPeriod.evening).length;

  /// Unique student IDs across all periods.
  Set<String> get uniqueStudentIds => entries.map((e) => e.studentId).toSet();

  /// Check if a student is already checked in for the given period.
  bool isStudentCheckedIn(String studentId, CheckInPeriod period) =>
      entries.any((e) => e.studentId == studentId && e.period == period);

  /// Format: "YYYY-MM-DD"
  static String _dateOnly(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

  /// Generate the document ID for a given date.
  static String idForDate(DateTime dt) => _dateOnly(dt);

  @override
  String toString() =>
      'CheckInList(id: $id, date: ${_dateOnly(date)}, '
      'entries: ${entries.length}, totalStudents: $totalStudents)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CheckInList && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
