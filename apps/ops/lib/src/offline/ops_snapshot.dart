import 'dart:async';
import 'dart:convert';

import 'package:busin_core/busin_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// What the phone keeps so the ops app can open without a connection: who the staff member is, the school (its time zone
/// decides what "today" is), and the day's trips with their buses. The server is always asked first; this is used only
/// when it cannot be reached. Each snapshot belongs to one person and is never shown to another; it is wiped when that
/// person loses access or signs out.
class OpsSnapshot {
  const OpsSnapshot({required this.userId, required this.savedAt, this.profile, this.school, this.tripsDay, this.trips, this.buses});

  /// The saved form's version. A different one is ignored rather than guessed at.
  static const version = 1;

  final String userId;
  final DateTime savedAt;
  final Profile? profile;
  final School? school;

  /// The school day the [trips] are for (`yyyy-mm-dd`): another day's list is never shown as today's.
  final String? tripsDay;
  final List<Trip>? trips;
  final List<Bus>? buses;

  OpsSnapshot copyWith({DateTime? savedAt, Profile? profile, School? school, String? tripsDay, List<Trip>? trips, List<Bus>? buses}) => OpsSnapshot(
        userId: userId,
        savedAt: savedAt ?? this.savedAt,
        profile: profile ?? this.profile,
        school: school ?? this.school,
        tripsDay: tripsDay ?? this.tripsDay,
        trips: trips ?? this.trips,
        buses: buses ?? this.buses,
      );

  Map<String, dynamic> toJson() => {
        'version': version,
        'user_id': userId,
        'saved_at': savedAt.toUtc().toIso8601String(),
        'profile': profile?.toJson(),
        'school': school?.toJson(),
        'trips_day': tripsDay,
        'trips': trips?.map((t) => t.toJson()).toList(),
        'buses': buses?.map((b) => b.toJson()).toList(),
      };

  /// Null for anything unreadable or from another version.
  static OpsSnapshot? tryParse(Object? raw) {
    try {
      if (raw is! Map<String, dynamic> || raw['version'] != version) return null;
      final profile = raw['profile'];
      final school = raw['school'];
      final trips = raw['trips'];
      final buses = raw['buses'];
      return OpsSnapshot(
        userId: raw['user_id'] as String,
        savedAt: DateTime.parse(raw['saved_at'] as String),
        profile: profile is Map<String, dynamic> ? Profile.fromJson(profile) : null,
        school: school is Map<String, dynamic> ? School.fromJson(school) : null,
        tripsDay: raw['trips_day'] as String?,
        trips: trips is List ? [for (final t in trips) Trip.fromJson(t as Map<String, dynamic>)] : null,
        buses: buses is List ? [for (final b in buses) Bus.fromJson(b as Map<String, dynamic>)] : null,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Where snapshots live. Tests use a memory one.
abstract interface class OpsSnapshotStore {
  Future<OpsSnapshot?> read(String userId);

  Future<void> write(OpsSnapshot snapshot);

  Future<void> delete(String userId);

  /// Every snapshot on the phone (signing out, or an access lost before the person was known).
  Future<void> deleteAll();
}

/// In the phone's secure storage: the profile holds personal data.
class SecureOpsSnapshotStore implements OpsSnapshotStore {
  SecureOpsSnapshotStore([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  static const _prefix = 'busin.ops.snapshot.';
  final FlutterSecureStorage _storage;

  @override
  Future<OpsSnapshot?> read(String userId) async {
    final value = await _storage.read(key: '$_prefix$userId');
    if (value == null) return null;
    try {
      final snapshot = OpsSnapshot.tryParse(jsonDecode(value));
      return snapshot?.userId == userId ? snapshot : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(OpsSnapshot snapshot) => _storage.write(key: '$_prefix${snapshot.userId}', value: jsonEncode(snapshot.toJson()));

  @override
  Future<void> delete(String userId) => _storage.delete(key: '$_prefix$userId');

  @override
  Future<void> deleteAll() async {
    final all = await _storage.readAll();
    for (final key in all.keys.where((k) => k.startsWith(_prefix))) {
      await _storage.delete(key: key);
    }
  }
}

/// Kept in memory, for tests.
class MemoryOpsSnapshotStore implements OpsSnapshotStore {
  final Map<String, OpsSnapshot> byUser = {};

  @override
  Future<OpsSnapshot?> read(String userId) async => byUser[userId];

  @override
  Future<void> write(OpsSnapshot snapshot) async => byUser[snapshot.userId] = snapshot;

  @override
  Future<void> delete(String userId) async => byUser.remove(userId);

  @override
  Future<void> deleteAll() async => byUser.clear();
}

/// The snapshot in use: loaded once per person, updated piece by piece as the server answers, written one change at a
/// time so two answers arriving together cannot overwrite each other.
class OpsSnapshotKeeper {
  OpsSnapshotKeeper(this._store, this._now);

  final OpsSnapshotStore _store;
  final DateTime Function() _now;

  OpsSnapshot? _current;
  Future<void> _writes = Future.value();

  /// The saved snapshot of [userId], or null. Never another person's.
  Future<OpsSnapshot?> load(String userId) async {
    final current = _current;
    if (current != null && current.userId == userId) return current;
    final stored = await _store.read(userId);
    _current = stored;
    return stored;
  }

  Future<void> _update(String userId, OpsSnapshot Function(OpsSnapshot base) change) async {
    final base = await load(userId) ?? OpsSnapshot(userId: userId, savedAt: _now());
    final next = change(base).copyWith(savedAt: _now());
    _current = next;
    _writes = _writes.then((_) => _store.write(next)).catchError((Object _) {
      // Not being able to save a copy must never break the screen that has the real answer.
    });
    await _writes;
  }

  Future<void> saveProfile(String userId, Profile profile) => _update(userId, (s) => s.copyWith(profile: profile));

  Future<void> saveSchool(String userId, School school) => _update(userId, (s) => s.copyWith(school: school));

  Future<void> saveTrips(String userId, String day, List<Trip> trips) => _update(userId, (s) => s.copyWith(tripsDay: day, trips: trips));

  Future<void> saveBuses(String userId, List<Bus> buses) => _update(userId, (s) => s.copyWith(buses: buses));

  /// Forgets [userId]'s snapshot (the account was blocked).
  Future<void> clear(String userId) async {
    if (_current?.userId == userId) _current = null;
    _writes = _writes.then((_) => _store.delete(userId)).catchError((Object _) {});
    await _writes;
  }

  /// Forgets every snapshot on the phone (signing out, or access lost).
  Future<void> clearAll() async {
    _current = null;
    _writes = _writes.then((_) => _store.deleteAll()).catchError((Object _) {});
    await _writes;
  }
}
