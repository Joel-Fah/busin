import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

/// Where a queued scan stands.
enum QueuedState {
  /// Checked on the phone, not yet confirmed by the server.
  pending,

  /// The server recorded it (or already had it).
  accepted,

  /// The server refused it after the phone accepted it (revoked, suspended, trip not running). Staff should know.
  refused,
}

/// One scan kept on the phone until the server has it. Holds no secret: the code is the one the student showed.
class QueuedScan {
  const QueuedScan({
    required this.clientId,
    required this.tripId,
    required this.code,
    required this.studentId,
    required this.scannedAt,
    this.stopId,
    this.lat,
    this.lng,
    this.accuracy,
    this.state = QueuedState.pending,
    this.reason,
    this.attempts = 0,
  });

  final String clientId;
  final String tripId;
  final String code;
  final String studentId;
  final DateTime scannedAt;
  final String? stopId;
  final double? lat;
  final double? lng;
  final double? accuracy;
  final QueuedState state;

  /// Why the server refused it.
  final String? reason;
  final int attempts;
}

/// The scans made on this phone, kept until the server confirms them (ADR 0014). Survives restarts.
abstract interface class ScanQueue {
  Future<void> add(QueuedScan scan);

  /// Scans still waiting for the server, oldest first.
  Future<List<QueuedScan>> pending({int limit = 50});

  /// Every scan of a trip on this phone, newest first.
  Future<List<QueuedScan>> forTrip(String tripId);

  Future<void> markAccepted(String clientId);
  Future<void> markRefused(String clientId, String reason);

  /// A send that failed for a reason worth retrying (not offline): counted, so a broken scan stops being retried.
  Future<void> markAttempt(String clientId);

  /// How many scans are waiting, as it changes.
  Stream<int> watchPendingCount();
}

/// The queue in SQLite through drift, with plain SQL (no code generation).
class DriftScanQueue extends GeneratedDatabase implements ScanQueue {
  DriftScanQueue([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'busin_ops_queue'));

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await customStatement('''
            create table queued_scans (
              client_id text primary key,
              trip_id text not null,
              code text not null,
              student_id text not null,
              scanned_at integer not null,
              stop_id text,
              lat real,
              lng real,
              accuracy real,
              state text not null default 'pending',
              reason text,
              attempts integer not null default 0
            )''');
          await customStatement('create index queued_scans_state on queued_scans (state, scanned_at)');
          await customStatement('create index queued_scans_trip on queued_scans (trip_id, scanned_at)');
        },
      );

  final _changes = StreamController<void>.broadcast();

  @override
  Future<void> add(QueuedScan scan) async {
    await customInsert(
      'insert or ignore into queued_scans (client_id, trip_id, code, student_id, scanned_at, stop_id, lat, lng, accuracy) '
      'values (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      variables: [
        Variable(scan.clientId),
        Variable(scan.tripId),
        Variable(scan.code),
        Variable(scan.studentId),
        Variable(scan.scannedAt.millisecondsSinceEpoch),
        Variable(scan.stopId),
        Variable(scan.lat),
        Variable(scan.lng),
        Variable(scan.accuracy),
      ],
    );
    _changes.add(null);
  }

  QueuedScan _row(QueryRow row) => QueuedScan(
        clientId: row.read<String>('client_id'),
        tripId: row.read<String>('trip_id'),
        code: row.read<String>('code'),
        studentId: row.read<String>('student_id'),
        scannedAt: DateTime.fromMillisecondsSinceEpoch(row.read<int>('scanned_at'), isUtc: true),
        stopId: row.readNullable<String>('stop_id'),
        lat: row.readNullable<double>('lat'),
        lng: row.readNullable<double>('lng'),
        accuracy: row.readNullable<double>('accuracy'),
        state: QueuedState.values.byName(row.read<String>('state')),
        reason: row.readNullable<String>('reason'),
        attempts: row.read<int>('attempts'),
      );

  @override
  Future<List<QueuedScan>> pending({int limit = 50}) async {
    final rows = await customSelect(
      "select * from queued_scans where state = 'pending' and attempts < 5 order by scanned_at limit ?",
      variables: [Variable(limit)],
    ).get();
    return rows.map(_row).toList();
  }

  @override
  Future<List<QueuedScan>> forTrip(String tripId) async {
    final rows = await customSelect(
      'select * from queued_scans where trip_id = ? order by scanned_at desc',
      variables: [Variable(tripId)],
    ).get();
    return rows.map(_row).toList();
  }

  @override
  Future<void> markAccepted(String clientId) => _update("state = 'accepted'", clientId);

  @override
  Future<void> markRefused(String clientId, String reason) => _update("state = 'refused', reason = ?", clientId, [Variable(reason)]);

  @override
  Future<void> markAttempt(String clientId) => _update('attempts = attempts + 1', clientId);

  Future<void> _update(String set, String clientId, [List<Variable> extra = const []]) async {
    await customUpdate('update queued_scans set $set where client_id = ?', variables: [...extra, Variable(clientId)]);
    _changes.add(null);
  }

  @override
  Stream<int> watchPendingCount() async* {
    Future<int> count() async {
      final row = await customSelect("select count(*) as n from queued_scans where state = 'pending'").getSingle();
      return row.read<int>('n');
    }

    yield await count();
    await for (final _ in _changes.stream) {
      yield await count();
    }
  }
}

/// The same queue in memory, for tests and previews.
class MemoryScanQueue implements ScanQueue {
  final Map<String, QueuedScan> _rows = {};
  final _changes = StreamController<void>.broadcast();

  List<QueuedScan> get all => _rows.values.toList();

  @override
  Future<void> add(QueuedScan scan) async {
    _rows.putIfAbsent(scan.clientId, () => scan);
    _changes.add(null);
  }

  @override
  Future<List<QueuedScan>> pending({int limit = 50}) async =>
      (_rows.values.where((s) => s.state == QueuedState.pending && s.attempts < 5).toList()..sort((a, b) => a.scannedAt.compareTo(b.scannedAt)))
          .take(limit)
          .toList();

  @override
  Future<List<QueuedScan>> forTrip(String tripId) async =>
      _rows.values.where((s) => s.tripId == tripId).toList()..sort((a, b) => b.scannedAt.compareTo(a.scannedAt));

  QueuedScan _copy(QueuedScan s, {QueuedState? state, String? reason, int? attempts}) => QueuedScan(
        clientId: s.clientId,
        tripId: s.tripId,
        code: s.code,
        studentId: s.studentId,
        scannedAt: s.scannedAt,
        stopId: s.stopId,
        lat: s.lat,
        lng: s.lng,
        accuracy: s.accuracy,
        state: state ?? s.state,
        reason: reason ?? s.reason,
        attempts: attempts ?? s.attempts,
      );

  @override
  Future<void> markAccepted(String clientId) async {
    _rows[clientId] = _copy(_rows[clientId]!, state: QueuedState.accepted);
    _changes.add(null);
  }

  @override
  Future<void> markRefused(String clientId, String reason) async {
    _rows[clientId] = _copy(_rows[clientId]!, state: QueuedState.refused, reason: reason);
    _changes.add(null);
  }

  @override
  Future<void> markAttempt(String clientId) async {
    final s = _rows[clientId]!;
    _rows[clientId] = _copy(s, attempts: s.attempts + 1);
    _changes.add(null);
  }

  @override
  Stream<int> watchPendingCount() async* {
    int count() => _rows.values.where((s) => s.state == QueuedState.pending).length;
    yield count();
    await for (final _ in _changes.stream) {
      yield count();
    }
  }
}
