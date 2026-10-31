/// Enums mirror the Postgres enum types. Parsing is strict: an unknown value
/// throws a [FormatException] instead of silently becoming a default. A silent
/// default for a role or status could grant the wrong access.
library;

T _parse<T extends Enum>(List<T> values, Object? raw, String type) {
  if (raw is String) {
    for (final value in values) {
      if (value.name == raw) return value;
    }
  }
  throw FormatException('Unknown $type: $raw');
}

enum UserRole {
  student,
  staff,
  admin;

  static UserRole parse(Object? raw) => _parse(values, raw, 'user role');

  bool get isStaffOrAdmin => this == staff || this == admin;
}

enum AccountStatus {
  pending,
  verified,
  suspended;

  static AccountStatus parse(Object? raw) =>
      _parse(values, raw, 'account status');
}

enum SubscriptionStatus {
  pending,
  approved,
  rejected,
  expired;

  static SubscriptionStatus parse(Object? raw) =>
      _parse(values, raw, 'subscription status');
}

enum SemesterName {
  fall,
  spring,
  summer;

  static SemesterName parse(Object? raw) =>
      _parse(values, raw, 'semester name');
}

enum TripDirection {
  inbound,
  outbound;

  static TripDirection parse(Object? raw) =>
      _parse(values, raw, 'trip direction');
}

enum TripStatus {
  scheduled,
  active,
  completed,
  cancelled;

  static TripStatus parse(Object? raw) => _parse(values, raw, 'trip status');
}

/// Where a live bus position came from.
enum PositionSource {
  phone,
  staff,
  device,
  scan;

  static PositionSource parse(Object? raw) =>
      _parse(values, raw, 'position source');
}

/// Why a scan was refused. Values match the `reason` strings returned by the
/// `record_qr_scan` database function.
enum ScanFailure {
  invalidCode('invalid_code'),
  expiredCode('expired_code'),
  studentNotFound('student_not_found'),
  accountNotVerified('account_not_verified'),
  noActiveSubscription('no_active_subscription');

  const ScanFailure(this.wire);

  /// The string used by the API.
  final String wire;

  static ScanFailure parse(Object? raw) {
    if (raw is String) {
      for (final value in values) {
        if (value.wire == raw) return value;
      }
    }
    throw FormatException('Unknown scan failure: $raw');
  }
}
