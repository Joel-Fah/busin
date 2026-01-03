import 'package:busin/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'semester_config.dart';
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

  String getDisplayLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return switch (this) {
      BusSubscriptionStatus.pending => l10n.subscriptionPending,
      BusSubscriptionStatus.approved => l10n.subscriptionApproved,
      BusSubscriptionStatus.rejected => l10n.subscriptionRejected,
      BusSubscriptionStatus.expired => l10n.subscriptionExpired,
    };
  }

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
  final SemesterConfig semesterConfig; // Embedded semester configuration

  final BusSubscriptionStatus status;
  final String? proofOfPaymentUrl;

  final DateTime createdAt;
  final DateTime updatedAt;

  // Boarding preference
  final BusStop? stop;

  // Weekly preferences (multiple days)
  final List<BusSubscriptionSchedule> schedules;

  // Review observation (contains reviewer info and message)
  final ReviewObservation? observation;

  const BusSubscription({
    required this.id,
    required this.studentId,
    required this.semesterConfig,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.proofOfPaymentUrl,
    this.stop,
    this.observation,
    this.schedules = const [],
  });

  // Convenience getters for backward compatibility
  Semester get semester => semesterConfig.semester;

  int get year => semesterConfig.year;

  DateTime get startDate => semesterConfig.startDate;

  DateTime get endDate => semesterConfig.endDate;

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
    'semester': semesterConfig.toMap(), // Embedded semester configuration
    'status': status.nameLower,
    'proofOfPaymentUrl': proofOfPaymentUrl,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
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

    // Parse semester configuration
    SemesterConfig semesterConfig;

    if (map['semester'] is Map<String, dynamic>) {
      // New format: embedded semester configuration
      semesterConfig = SemesterConfig.fromMap(
        map['semester'] as Map<String, dynamic>,
      );
    } else {
      // Legacy format: parse from semesterId or separate fields
      Semester semester;
      int year;
      DateTime startDate;
      DateTime endDate;

      if (map['semesterId'] is String) {
        // Parse semesterId = "fall_2025"
        final parts = (map['semesterId'] as String).split('_');
        if (parts.length == 2) {
          semester = Semester.from(parts[0]);
          year = int.parse(parts[1]);
        } else {
          // Fallback
          semester = Semester.from(map['semester'] as String);
          year = (map['year'] as num).toInt();
        }
      } else {
        // Very old legacy format
        semester = Semester.from(map['semester'] as String);
        year = (map['year'] as num).toInt();
      }

      // Try to get dates
      if (map['startDate'] != null && map['endDate'] != null) {
        startDate = _parseDateTime(map['startDate']);
        endDate = _parseDateTime(map['endDate']);
      } else {
        // Default dates
        startDate = DateTime(year, 1, 1);
        endDate = DateTime(year, 12, 31, 23, 59, 59, 999);
      }

      // Create a temporary SemesterConfig for backward compatibility
      semesterConfig = SemesterConfig(
        id: '${semester.nameLower}_$year',
        semester: semester,
        year: year,
        startDate: startDate,
        endDate: endDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'legacy',
      );
    }

    return BusSubscription(
      id: map['id'] as String,
      studentId: map['studentId'] as String,
      semesterConfig: semesterConfig,
      status: BusSubscriptionStatus.from(map['status'] as String),
      proofOfPaymentUrl: map['proofOfPaymentUrl'] as String?,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
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
    if (map['review'] is Map<String, dynamic>) {
      return ReviewObservation.fromMap(map['review'] as Map<String, dynamic>);
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
    SemesterConfig? semesterConfig,
    BusSubscriptionStatus? status,
    String? proofOfPaymentUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    BusStop? stop,
    ReviewObservation? observation,
    List<BusSubscriptionSchedule>? schedules,
  }) => BusSubscription(
    id: id ?? this.id,
    studentId: studentId ?? this.studentId,
    semesterConfig: semesterConfig ?? this.semesterConfig,
    status: status ?? this.status,
    proofOfPaymentUrl: proofOfPaymentUrl ?? this.proofOfPaymentUrl,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
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
    String? observationMessage,
  }) => copyWith(
    status: BusSubscriptionStatus.approved,
    observation: ReviewObservation(
      reviewerUserId: reviewerUserId,
      observedAt: DateTime.now(),
      message: observationMessage,
    ),
    updatedAt: DateTime.now(),
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
      'review: ${observation != null ? observation.toString() : "null"}, '
      'isWithinWindow: $isWithinWindow, '
      'isCurrentlyActive: $isCurrentlyActive'
      ']';
}
