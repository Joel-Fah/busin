/// Semester of a subscription. Kept simple for school project.
enum Semester {
  fall,
  spring,
  summer;

  String get nameLower => name;

  String get label => switch (this) {
    Semester.fall => 'Fall',
    Semester.spring => 'Spring',
    Semester.summer => 'Summer',
  };

  static Semester from(String value) {
    final v = value.trim().toLowerCase();
    switch (v) {
      case 'fall':
        return Semester.fall;
      case 'spring':
        return Semester.spring;
      case 'summer':
        return Semester.summer;
      default:
        throw ArgumentError('Unknown semester: $value');
    }
  }

  /// Returns a default [DateSpan] for a given calendar [year].
  /// - Fall: Sep 1 - Dec 31
  /// - Spring: Jan 1 - May 31
  /// - Summer: Jun 1 - Aug 31
  DateSpan defaultSpanForYear(int year) {
    switch (this) {
      case Semester.fall:
        return DateSpan(
          DateTime(year, 9, 1),
          DateTime(year, 12, 31, 23, 59, 59, 999),
        );
      case Semester.spring:
        return DateSpan(
          DateTime(year, 1, 1),
          DateTime(year, 5, 31, 23, 59, 59, 999),
        );
      case Semester.summer:
        return DateSpan(
          DateTime(year, 6, 1),
          DateTime(year, 8, 31, 23, 59, 59, 999),
        );
    }
  }
}

/// Status of a subscription during its review lifecycle.
enum SubscriptionStatus {
  pending,
  approved,
  rejected,
  expired;

  String get nameLower => name;

  String get label => switch (this) {
    SubscriptionStatus.pending => 'Pending',
    SubscriptionStatus.approved => 'Approved',
    SubscriptionStatus.rejected => 'Rejected',
    SubscriptionStatus.expired => 'Expired',
  };

  bool get isPending => this == SubscriptionStatus.pending;

  bool get isApproved => this == SubscriptionStatus.approved;

  bool get isRejected => this == SubscriptionStatus.rejected;

  bool get isExpired => this == SubscriptionStatus.expired;

  static SubscriptionStatus from(String value) {
    final v = value.trim().toLowerCase();
    switch (v) {
      case 'pending':
        return SubscriptionStatus.pending;
      case 'approved':
        return SubscriptionStatus.approved;
      case 'rejected':
        return SubscriptionStatus.rejected;
      case 'expired':
        return SubscriptionStatus.expired;
      default:
        throw ArgumentError('Unknown subscription status: $value');
    }
  }
}

/// Simple start-end interval holder that serializes to ISO strings.
class DateSpan {
  final DateTime start;
  final DateTime end;

  DateSpan(this.start, this.end) {
    if (start.isAfter(end)) {
      throw ArgumentError('start must be <= end');
    }
  }

  bool contains(DateTime t) => !t.isBefore(start) && !t.isAfter(end);

  Map<String, dynamic> toMap() => {
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
  };

  factory DateSpan.fromMap(Map<String, dynamic> map) => DateSpan(
    DateTime.parse(map['start'] as String),
    DateTime.parse(map['end'] as String),
  );
}

/// A weekly schedule preference for a subscription.
/// Stores weekday as 1-6 (Mon-Sat) and times in HH:mm (24h) strings.
class SubscriptionSchedule {
  final int weekday; // 1 (Mon) .. 6 (Sat)
  final String morningTime; // HH:mm
  final String closingTime; // HH:mm

  const SubscriptionSchedule({
    required this.weekday,
    required this.morningTime,
    required this.closingTime,
  }) : assert(weekday >= 1 && weekday <= 6, 'weekday must be 1..6');

  static final RegExp _hhmm = RegExp(r'^\d{2}:\d{2}$');

  bool get isValidTimes =>
      _isValidTime(morningTime) && _isValidTime(closingTime);

  static bool _isValidTime(String t) {
    if (!_hhmm.hasMatch(t)) return false;
    final parts = t.split(':');
    final h = int.tryParse(parts[0]) ?? -1;
    final m = int.tryParse(parts[1]) ?? -1;
    return h >= 0 && h < 24 && m >= 0 && m < 60;
  }

  Map<String, dynamic> toMap() => {
    'weekday': weekday,
    'morningTime': morningTime,
    'closingTime': closingTime,
  };

  factory SubscriptionSchedule.fromMap(Map<String, dynamic> map) =>
      SubscriptionSchedule(
        weekday: (map['weekday'] as num).toInt(),
        morningTime: map['morningTime'] as String,
        closingTime: map['closingTime'] as String,
      );
}

/// Subscription model tying a student to a semester and preferences.
class Subscription {
  final String id;
  final String studentId;
  final Semester semester;
  final int year; // calendar year for the term (e.g., 2025 for Fall 2025)

  final SubscriptionStatus status;
  final String? proofOfPaymentUrl;

  final DateTime createdAt;
  final DateTime updatedAt;

  // Validity window; admin/staff can override from defaults
  final DateTime startDate;
  final DateTime endDate;

  // Review info (both approve/reject)
  final String? reviewedByUserId; // admin/staff id
  final DateTime? reviewedAt;
  final String? rejectionReason;

  // Boarding preference
  final String? stopId; // chosen stop from predefined catalog
  final String? stopName; // denormalized label for convenience
  final SubscriptionSchedule? schedule; // weekly preference

  const Subscription({
    required this.id,
    required this.studentId,
    required this.semester,
    required this.year,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.startDate,
    required this.endDate,
    this.proofOfPaymentUrl,
    this.reviewedByUserId,
    this.reviewedAt,
    this.rejectionReason,
    this.stopId,
    this.stopName,
    this.schedule,
  });

  /// Create a new pending subscription, optionally deriving default dates.
  factory Subscription.pending({
    required String id,
    required String studentId,
    required Semester semester,
    required int year,
    String? proofOfPaymentUrl,
    String? stopId,
    String? stopName,
    SubscriptionSchedule? schedule,
  }) {
    final now = DateTime.now();
    final span = semester.defaultSpanForYear(year);
    return Subscription(
      id: id,
      studentId: studentId,
      semester: semester,
      year: year,
      status: SubscriptionStatus.pending,
      createdAt: now,
      updatedAt: now,
      startDate: span.start,
      endDate: span.end,
      proofOfPaymentUrl: proofOfPaymentUrl,
      stopId: stopId,
      stopName: stopName,
      schedule: schedule,
    );
  }

  // --- derived ---
  bool get isWithinWindow =>
      DateSpan(startDate, endDate).contains(DateTime.now());

  bool get isCurrentlyActive => status.isApproved && isWithinWindow;

  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return Duration.zero;
    return endDate.difference(now);
  }

  bool get hasProof =>
      (proofOfPaymentUrl != null && proofOfPaymentUrl!.isNotEmpty);

  bool get hasStop => (stopId != null && stopId!.isNotEmpty);

  // --- mapping ---
  Map<String, dynamic> toMap() => {
    'id': id,
    'studentId': studentId,
    'semester': semester.nameLower,
    'year': year,
    'status': status.nameLower,
    'proofOfPaymentUrl': proofOfPaymentUrl,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'reviewedByUserId': reviewedByUserId,
    'reviewedAt': reviewedAt?.toIso8601String(),
    'rejectionReason': rejectionReason,
    'stopId': stopId,
    'stopName': stopName,
    'schedule': schedule?.toMap(),
  };

  factory Subscription.fromMap(Map<String, dynamic> map) => Subscription(
    id: map['id'] as String,
    studentId: map['studentId'] as String,
    semester: Semester.from(map['semester'] as String),
    year: (map['year'] as num).toInt(),
    status: SubscriptionStatus.from(map['status'] as String),
    proofOfPaymentUrl: map['proofOfPaymentUrl'] as String?,
    createdAt: DateTime.parse(map['createdAt'] as String),
    updatedAt: DateTime.parse(map['updatedAt'] as String),
    startDate: DateTime.parse(map['startDate'] as String),
    endDate: DateTime.parse(map['endDate'] as String),
    reviewedByUserId: map['reviewedByUserId'] as String?,
    reviewedAt: (map['reviewedAt'] as String?) != null
        ? DateTime.parse(map['reviewedAt'] as String)
        : null,
    rejectionReason: map['rejectionReason'] as String?,
    stopId: map['stopId'] as String?,
    stopName: map['stopName'] as String?,
    schedule: (map['schedule'] is Map<String, dynamic>)
        ? SubscriptionSchedule.fromMap(map['schedule'] as Map<String, dynamic>)
        : null,
  );

  // --- state transitions ---
  Subscription copyWith({
    String? id,
    String? studentId,
    Semester? semester,
    int? year,
    SubscriptionStatus? status,
    String? proofOfPaymentUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startDate,
    DateTime? endDate,
    String? reviewedByUserId,
    DateTime? reviewedAt,
    String? rejectionReason,
    String? stopId,
    String? stopName,
    SubscriptionSchedule? schedule,
  }) => Subscription(
    id: id ?? this.id,
    studentId: studentId ?? this.studentId,
    semester: semester ?? this.semester,
    year: year ?? this.year,
    status: status ?? this.status,
    proofOfPaymentUrl: proofOfPaymentUrl ?? this.proofOfPaymentUrl,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    reviewedByUserId: reviewedByUserId ?? this.reviewedByUserId,
    reviewedAt: reviewedAt ?? this.reviewedAt,
    rejectionReason: rejectionReason ?? this.rejectionReason,
    stopId: stopId ?? this.stopId,
    stopName: stopName ?? this.stopName,
    schedule: schedule ?? this.schedule,
  );

  Subscription withProof(String url) => copyWith(
    proofOfPaymentUrl: url,
    status: SubscriptionStatus.pending,
    updatedAt: DateTime.now(),
  );

  Subscription approve({
    required String reviewerUserId,
    DateTime? startDate,
    DateTime? endDate,
  }) => copyWith(
    status: SubscriptionStatus.approved,
    reviewedByUserId: reviewerUserId,
    reviewedAt: DateTime.now(),
    updatedAt: DateTime.now(),
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    rejectionReason: null,
  );

  Subscription reject({
    required String reviewerUserId,
    required String reason,
  }) => copyWith(
    status: SubscriptionStatus.rejected,
    reviewedByUserId: reviewerUserId,
    reviewedAt: DateTime.now(),
    updatedAt: DateTime.now(),
    rejectionReason: reason,
  );

  Subscription expireIfPast([DateTime? now]) {
    final t = now ?? DateTime.now();
    if (status.isApproved && t.isAfter(endDate)) {
      return copyWith(status: SubscriptionStatus.expired, updatedAt: t);
    }
    return this;
  }

  @override
  String toString() =>
      'Subscription(id: $id, studentId: $studentId, sem: ${semester.label} $year, status: ${status.label}, stop: $stopName, start: $startDate, end: $endDate)';
}
