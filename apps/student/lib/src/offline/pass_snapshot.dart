import 'dart:async';
import 'dart:convert';

import 'package:busin_core/busin_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// What the phone keeps so the app can open and show the boarding pass without a connection: who the student is, the school,
/// and where the subscription stands. The server is always asked first; this is used only when it cannot be reached.
/// Each snapshot belongs to one user and is never shown to another.
class PassSnapshot {
  const PassSnapshot({required this.userId, required this.savedAt, this.profile, this.school, this.overview});

  /// The saved form's version. A different one is ignored rather than guessed at.
  static const version = 1;

  final String userId;
  final DateTime savedAt;
  final Profile? profile;
  final School? school;

  /// The subscription overview as the server last gave it (the same shape [SubscriptionOverview.toJson] writes).
  final Map<String, dynamic>? overview;

  PassSnapshot copyWith({DateTime? savedAt, Profile? profile, School? school, Map<String, dynamic>? overview}) => PassSnapshot(
        userId: userId,
        savedAt: savedAt ?? this.savedAt,
        profile: profile ?? this.profile,
        school: school ?? this.school,
        overview: overview ?? this.overview,
      );

  Map<String, dynamic> toJson() => {
        'version': version,
        'user_id': userId,
        'saved_at': savedAt.toUtc().toIso8601String(),
        'profile': profile?.toJson(),
        'school': school?.toJson(),
        'overview': overview,
      };

  /// Null for anything unreadable or from another version.
  static PassSnapshot? tryParse(Object? raw) {
    try {
      if (raw is! Map<String, dynamic> || raw['version'] != version) return null;
      final profile = raw['profile'];
      final school = raw['school'];
      final overview = raw['overview'];
      return PassSnapshot(
        userId: raw['user_id'] as String,
        savedAt: DateTime.parse(raw['saved_at'] as String),
        profile: profile is Map<String, dynamic> ? Profile.fromJson(profile) : null,
        school: school is Map<String, dynamic> ? School.fromJson(school) : null,
        overview: overview is Map<String, dynamic> ? overview : null,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Where snapshots are kept. The phone's secure storage in the app, memory in tests.
abstract interface class SnapshotStore {
  Future<PassSnapshot?> read(String userId);

  Future<void> write(PassSnapshot snapshot);

  Future<void> delete(String userId);

  /// Forgets every snapshot. Called on sign-out.
  Future<void> deleteAll();
}

class SecureSnapshotStore implements SnapshotStore {
  SecureSnapshotStore([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  static const _prefix = 'busin.snapshot.';
  final FlutterSecureStorage _storage;

  @override
  Future<PassSnapshot?> read(String userId) async {
    final value = await _storage.read(key: '$_prefix$userId');
    if (value == null) return null;
    try {
      final snapshot = PassSnapshot.tryParse(jsonDecode(value));
      if (snapshot != null && snapshot.userId == userId) return snapshot;
    } catch (_) {
      // Unreadable: treated as nothing saved.
    }
    await delete(userId);
    return null;
  }

  @override
  Future<void> write(PassSnapshot snapshot) => _storage.write(key: '$_prefix${snapshot.userId}', value: jsonEncode(snapshot.toJson()));

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

/// The snapshot in use: loaded once per user, updated piece by piece as the server answers, written one change at a time.
class SnapshotKeeper {
  SnapshotKeeper(this._store, this._now);

  final SnapshotStore _store;
  final DateTime Function() _now;

  PassSnapshot? _current;
  Future<void> _writes = Future.value();

  /// The saved snapshot of [userId], or null. Never another user's.
  Future<PassSnapshot?> load(String userId) async {
    final current = _current;
    if (current != null && current.userId == userId) return current;
    final stored = await _store.read(userId);
    _current = stored;
    return stored;
  }

  /// In memory only: what [load] already brought in.
  PassSnapshot? peek(String userId) => _current?.userId == userId ? _current : null;

  Future<void> _update(String userId, PassSnapshot Function(PassSnapshot base) change) async {
    final base = await load(userId) ?? PassSnapshot(userId: userId, savedAt: _now());
    final next = change(base).copyWith(savedAt: _now());
    _current = next;
    _writes = _writes.then((_) => _store.write(next)).catchError((Object _) {
      // Not being able to save a copy must never break the screen that has the real answer.
    });
    await _writes;
  }

  Future<void> saveProfile(String userId, Profile profile) => _update(userId, (s) => s.copyWith(profile: profile));

  Future<void> saveSchool(String userId, School school) => _update(userId, (s) => s.copyWith(school: school));

  Future<void> saveOverview(String userId, Map<String, dynamic> overview) => _update(userId, (s) => s.copyWith(overview: overview));

  /// Forgets [userId]'s snapshot (the account was blocked, or they signed out).
  Future<void> clear(String userId) async {
    if (_current?.userId == userId) _current = null;
    _writes = _writes.then((_) => _store.delete(userId)).catchError((Object _) {});
    await _writes;
  }

  Future<void> clearAll() async {
    _current = null;
    _writes = _writes.then((_) => _store.deleteAll()).catchError((Object _) {});
    await _writes;
  }
}
