import 'package:cloud_firestore/cloud_firestore.dart';
import 'value_objects/bus_stop_selection.dart';
import 'value_objects/review_observation.dart';

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
enum BusSubscriptionStatus {
  pending,
  approved,
  rejected,
  expired;

  String get nameLower => name;

  String get label => switch (this) {
    BusSubscriptionStatus.pending => 'Pending',
    BusSubscriptionStatus.approved => 'Approved',
    BusSubscriptionStatus.rejected => 'Rejected',
    BusSubscriptionStatus.expired => 'Expired',
  };

  bool get isPending => this == BusSubscriptionStatus.pending;

  bool get isApproved => this == BusSubscriptionStatus.approved;

  bool get isRejected => this == BusSubscriptionStatus.rejected;

  bool get isExpired => this == BusSubscriptionStatus.expired;

  static BusSubscriptionStatus from(String value) {
    final v = value.trim().toLowerCase();
    switch (v) {
      case 'pending':
        return BusSubscriptionStatus.pending;
      case 'approved':
        return BusSubscriptionStatus.approved;
      case 'rejected':
        return BusSubscriptionStatus.rejected;
      case 'expired':
        return BusSubscriptionStatus.expired;
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
class BusSubscriptionSchedule {
  final int weekday; // 1 (Mon) .. 6 (Sat)
  final String morningTime; // HH:mm
  final String closingTime; // HH:mm

  const BusSubscriptionSchedule({
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

  factory BusSubscriptionSchedule.fromMap(Map<String, dynamic> map) =>
      BusSubscriptionSchedule(
        weekday: (map['weekday'] as num).toInt(),
        morningTime: map['morningTime'] as String,
        closingTime: map['closingTime'] as String,
      );
}

/// Subscription model tying a student to a semester and preferences.
class BusSubscription {
  final String id;
  final String studentId;
  final Semester semester;
  final int year; // calendar year for the term (e.g., 2025 for Fall 2025)

  final BusSubscriptionStatus status;
  final String? proofOfPaymentUrl;

  final DateTime createdAt;
  final DateTime updatedAt;

  // Validity window; admin/staff can override from defaults
  final DateTime startDate;
  final DateTime endDate;

  // Boarding preference
  final BusStop? stop;

  // Weekly preferences (multiple days)
  final List<BusSubscriptionSchedule> schedules;

  // Review observation (contains reviewer info and message)
  final ReviewObservation? observation;

  const BusSubscription({
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
    this.stop,
    this.observation,
    this.schedules = const [],
  });

  factory BusSubscription.pending({
    required String id,
    required String studentId,
    required Semester semester,
    required int year,
    String? proofOfPaymentUrl,
    BusStop? stop,
    List<BusSubscriptionSchedule>? schedules,
  }) {
    final now = DateTime.now();
    final span = semester.defaultSpanForYear(year);
    return BusSubscription(
      id: id,
      studentId: studentId,
      semester: semester,
      year: year,
      status: BusSubscriptionStatus.pending,
      createdAt: now,
      updatedAt: now,
      startDate: span.start,
      endDate: span.end,
      proofOfPaymentUrl: proofOfPaymentUrl,
      stop: stop,
      schedules: schedules ?? const [],
      observation: null,
    );
  }

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

  bool get hasStop => stop != null && stop!.isValid;

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
    if (observation != null) 'review': observation!.toMap(),
    if (stop != null) 'stop': stop!.toMap(),
    'schedules': schedules.map((s) => s.toMap()).toList(),
  };

  factory BusSubscription.fromMap(Map<String, dynamic> map) {
    // Backward compatibility: accept legacy single `schedule`
    List<BusSubscriptionSchedule> parsedSchedules = const [];
    final raw = map['schedules'];
    if (raw is List) {
      parsedSchedules = raw
          .whereType<Map<String, dynamic>>()
          .map(BusSubscriptionSchedule.fromMap)
          .toList();
    } else if (map['schedule'] is Map<String, dynamic>) {
      parsedSchedules = [
        BusSubscriptionSchedule.fromMap(
          map['schedule'] as Map<String, dynamic>,
        ),
      ];
    }

    return BusSubscription(
      id: map['id'] as String,
      studentId: map['studentId'] as String,
      semester: Semester.from(map['semester'] as String),
      year: (map['year'] as num).toInt(),
      status: BusSubscriptionStatus.from(map['status'] as String),
      proofOfPaymentUrl: map['proofOfPaymentUrl'] as String?,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
      startDate: _parseDateTime(map['startDate']),
      endDate: _parseDateTime(map['endDate']),
      stop: _parseStop(map),
      schedules: parsedSchedules,
      observation: _parseObservation(map),
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

  static ReviewObservation? _parseObservation(Map<String, dynamic> map) {
    // Try to parse from nested 'observation' object first
    if (map['observation'] is Map<String, dynamic>) {
      return ReviewObservation.fromMap(map['observation'] as Map<String, dynamic>);
    }

    // Backward compatibility: parse from top-level fields
    final reviewerId = map['reviewedByUserId'] as String?;
    final reviewedAt = map['reviewedAt'];
    final message = map['rejectionReason'] as String?;
    if (reviewerId == null || reviewedAt == null) return null;
    return ReviewObservation(
      reviewerUserId: reviewerId,
      observedAt: _parseDateTime(reviewedAt),
      message: message,
    );
  }

  static BusStop? _parseStop(Map<String, dynamic> map) {
    // Try to parse from nested 'stop' object first
    if (map['stop'] is Map<String, dynamic>) {
      return BusStop.maybeFromMap(map['stop'] as Map<String, dynamic>);
    }

    // Backward compatibility: parse from top-level stopId/stopName fields
    final stopId = map['stopId'] as String?;
    final stopName = map['stopName'] as String?;
    if (stopId == null || stopName == null) return null;
    if (stopId.isEmpty || stopName.isEmpty) return null;

    // Use maybeFromMap for proper parsing with defaults
    return BusStop.maybeFromMap({
      'stopId': stopId,
      'stopName': stopName,
      'pickupImageUrl': map['pickupImageUrl'],
      'mapEmbedUrl': map['mapEmbedUrl'],
      'createdAt': map['createdAt'],
      'updatedAt': map['updatedAt'],
      'createdBy': map['createdBy'] ?? '',
      'updatedBy': map['updatedBy'],
    });
  }

  BusSubscription copyWith({
    String? id,
    String? studentId,
    Semester? semester,
    int? year,
    BusSubscriptionStatus? status,
    String? proofOfPaymentUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startDate,
    DateTime? endDate,
    BusStop? stop,
    ReviewObservation? observation,
    List<BusSubscriptionSchedule>? schedules,
  }) => BusSubscription(
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
    stop: stop ?? this.stop,
    observation: observation ?? this.observation,
    schedules: schedules ?? this.schedules,
  );

  BusSubscription withProof(String url) => copyWith(
    proofOfPaymentUrl: url,
    status: BusSubscriptionStatus.pending,
    updatedAt: DateTime.now(),
  );

  BusSubscription approve({
    required String reviewerUserId,
    DateTime? startDate,
    DateTime? endDate,
    String? observationMessage,
  }) => copyWith(
    status: BusSubscriptionStatus.approved,
    observation: ReviewObservation(
      reviewerUserId: reviewerUserId,
      observedAt: DateTime.now(),
      message: observationMessage,
    ),
    updatedAt: DateTime.now(),
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
  );

  BusSubscription reject({
    required String reviewerUserId,
    required String reason,
  }) => copyWith(
    status: BusSubscriptionStatus.rejected,
    observation: ReviewObservation(
      reviewerUserId: reviewerUserId,
      observedAt: DateTime.now(),
      message: reason,
    ),
    updatedAt: DateTime.now(),
  );

  BusSubscription expireIfPast([DateTime? now]) {
    final t = now ?? DateTime.now();
    if (status.isApproved && t.isAfter(endDate)) {
      return copyWith(status: BusSubscriptionStatus.expired, updatedAt: t);
    }
    return this;
  }

  // Get semester year
  String get semesterYear => '${semester.label} $year'.toUpperCase();

  @override
  String toString() =>
      'BusSubscription['
      'id: $id, '
      'studentId: $studentId, '
      'semester: ${semester.label}, '
      'year: $year, '
      'status: ${status.label}, '
      'proofOfPaymentUrl: $proofOfPaymentUrl, '
      'createdAt: $createdAt, '
      'updatedAt: $updatedAt, '
      'startDate: $startDate, '
      'endDate: $endDate, '
      'stop: ${stop != null ? "${stop!.name} (${stop!.id})" : "null"}, '
      'schedules: ${schedules.length}, '
      'observation: ${observation != null ? "present (reviewedBy: ${observation!.reviewerUserId}, at: ${observation!.observedAt})" : "null"}, '
      'isWithinWindow: $isWithinWindow, '
      'isCurrentlyActive: $isCurrentlyActive'
      ']';
}

// Dummy data for subscriptions
List<BusSubscription> dummySubscriptions = [
  BusSubscription.pending(
    id: 'sub_001',
    studentId: 'stu_001',
    semester: Semester.fall,
    year: 2024,
    proofOfPaymentUrl: 'https://example.com/proof1.jpg',
    stop: BusStop(
      id: 'stop_01',
      name: 'Main Gate',
      createdAt: DateTime(2024, 1, 15),
      updatedAt: DateTime(2024, 1, 15),
      createdBy: 'admin_001',
    ),
    schedules: [
      BusSubscriptionSchedule(
        weekday: 1,
        morningTime: '07:30',
        closingTime: '08:00',
      ),
      BusSubscriptionSchedule(
        weekday: 3,
        morningTime: '07:30',
        closingTime: '08:00',
      ),
    ],
  ),
  BusSubscription.pending(
    id: 'sub_002',
    studentId: 'stu_002',
    semester: Semester.spring,
    year: 2025,
    proofOfPaymentUrl: 'https://example.com/proof2.jpg',
    stop: BusStop(
      id: 'stop_02',
      name: 'Library Stop',
      createdAt: DateTime(2024, 2, 10),
      updatedAt: DateTime(2024, 2, 10),
      createdBy: 'admin_001',
    ),
    schedules: [
      BusSubscriptionSchedule(
        weekday: 2,
        morningTime: '08:00',
        closingTime: '08:30',
      ),
      BusSubscriptionSchedule(
        weekday: 4,
        morningTime: '08:00',
        closingTime: '08:30',
      ),
      BusSubscriptionSchedule(
        weekday: 6,
        morningTime: '09:00',
        closingTime: '09:30',
      ),
    ],
  ),
];
