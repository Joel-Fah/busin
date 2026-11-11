import 'dart:typed_data';

import 'package:busin_core/busin_core.dart';
import 'package:busin_ops/src/keys/roster.dart';
import 'package:busin_ops/src/queue/scan_queue.dart';
import 'package:busin_ops/src/queue/scan_sync.dart';
import 'package:busin_ops/src/scan/scan_decision.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const ada = 'a1000000-0000-4000-8000-000000000001';
const ben = 'a1000000-0000-4000-8000-000000000002';

Uint8List secretOf(int seed) => Uint8List.fromList(List<int>.generate(32, (i) => (i + seed) % 256));

/// Douala, UTC+1 all year.
DateTime douala(DateTime instant) {
  final local = instant.toUtc().add(const Duration(hours: 1));
  return DateTime(local.year, local.month, local.day);
}

final now = DateTime.utc(2026, 11, 12, 6, 30);
final today = DateTime(2026, 11, 12);

RiderKey rider(String id, int seed, {DateTime? day}) => RiderKey(
      studentId: id,
      dayKey: QrCodeGenerator.dayKey(secret: secretOf(seed), date: day ?? today),
      fullName: id == ada ? 'Ada Lovelace' : 'Ben Okafor',
      matricule: 'M$seed',
      day: day ?? today,
    );

String codeOf(String id, int seed, {DateTime? at}) =>
    QrCodeGenerator.generate(secret: secretOf(seed), studentId: id, now: at ?? now, schoolDate: douala);

Roster roster() => Roster(day: today, downloadedAt: now, riders: [rider(ada, 1)]);

ScanDecision decide(String code, {Roster? list, bool online = false, Set<String> boarded = const {}, DateTime? at}) =>
    decideScan(code: code, now: at ?? now, roster: list, schoolDate: douala, boarded: boarded, online: online);

class FakeScans implements ScansRepository {
  final List<({String clientId, DateTime? at})> sent = [];
  ScanOutcome Function(String code) answer = (_) => const ScanAccepted(student: StudentSummary(fullName: 'Ada'), duplicate: false, scanId: 's');
  Object? error;
  int failAfter = 1 << 30;

  @override
  Future<ScanOutcome> recordScan({
    required String tripId,
    required String code,
    String? stopId,
    GeoPoint? location,
    double? accuracyMeters,
    DateTime? scannedAt,
    String? clientId,
  }) async {
    if (sent.length >= failAfter) throw const Offline('no connection');
    if (error != null) throw error!;
    sent.add((clientId: clientId!, at: scannedAt));
    return answer(code);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

QueuedScan queued(String id, {int minutes = 0, String student = ada}) =>
    QueuedScan(clientId: id, tripId: 't1', code: 'busin2.x', studentId: student, scannedAt: now.add(Duration(minutes: minutes)));

void main() {
  group('the decision at the door, offline', () {
    test('a current code of a rider on today\'s list is let on', () {
      final decision = decide(codeOf(ada, 1), list: roster());
      expect(decision, isA<Admit>());
      expect((decision as Admit).rider.fullName, 'Ada Lovelace');
    });

    test('the same student twice on a trip is already on board', () {
      expect(decide(codeOf(ada, 1), list: roster(), boarded: {ada}), isA<AlreadyOnBoard>());
    });

    test('a forged, old or foreign code is refused', () {
      expect((decide(codeOf(ada, 99), list: roster()) as Refuse).kind, RefusalKind.invalid, reason: 'made with another secret');
      expect((decide(codeOf(ada, 1, at: now.subtract(const Duration(minutes: 2))), list: roster()) as Refuse).kind, RefusalKind.expired);
      expect((decide('https://example.com', list: roster()) as Refuse).kind, RefusalKind.invalid);
    });

    test('a student not on the list is refused offline, and asked about online', () {
      expect((decide(codeOf(ben, 2), list: roster()) as Refuse).kind, RefusalKind.notOnList);
      expect(decide(codeOf(ben, 2), list: roster(), online: true), isA<AskServer>());
    });

    test('without today\'s list the phone cannot decide: the server does, or staff are told to connect', () {
      expect((decide(codeOf(ada, 1)) as Refuse).kind, RefusalKind.noKeys);
      expect(decide(codeOf(ada, 1), online: true), isA<AskServer>());
      final yesterday = Roster(day: DateTime(2026, 11, 11), downloadedAt: now, riders: [rider(ada, 1, day: DateTime(2026, 11, 11))]);
      expect((decide(codeOf(ada, 1), list: yesterday) as Refuse).kind, RefusalKind.noKeys, reason: 'yesterday\'s keys never count');
    });
  });

  group('the roster', () {
    test('keeps its keys through a save and a load', () {
      final saved = Roster.fromJson(roster().toJson());
      expect(saved.day, today);
      expect(saved.keyFor(ada, today), rider(ada, 1).dayKey);
      expect(saved.keyFor(ada, DateTime(2026, 11, 13)), isNull);
    });
  });

  group('the nearest stop', () {
    final stops = [
      Stop(id: 'near', schoolId: 's', name: 'Near', location: GeoPoint(3.8500, 11.5000), active: true),
      Stop(id: 'far', schoolId: 's', name: 'Far', location: GeoPoint(3.8600, 11.5000), active: true),
    ];
    test('is the closest one within 300 m', () {
      expect(nearestStop(stops, GeoPoint(3.8505, 11.5001))?.id, 'near');
      expect(nearestStop(stops, GeoPoint(3.9000, 11.5000)), isNull);
    });
  });

  for (final kind in ['memory', 'sqlite']) {
    group('the scan queue ($kind)', () {
      late ScanQueue queue;
      setUp(() => queue = kind == 'memory' ? MemoryScanQueue() : DriftScanQueue(NativeDatabase.memory()));
      tearDown(() async {
        if (queue is DriftScanQueue) await (queue as DriftScanQueue).close();
      });

      test('keeps scans until the server has them, oldest first, once each', () async {
        await queue.add(queued('c2', minutes: 2));
        await queue.add(queued('c1', minutes: 1));
        await queue.add(queued('c1', minutes: 1));
        expect((await queue.pending()).map((s) => s.clientId), ['c1', 'c2']);
        await queue.markAccepted('c1');
        await queue.markRefused('c2', 'account_not_verified');
        expect(await queue.pending(), isEmpty);
        final trip = await queue.forTrip('t1');
        expect(trip.firstWhere((s) => s.clientId == 'c2').reason, 'account_not_verified');
      });

      test('a scan that keeps failing stops being retried after five tries', () async {
        await queue.add(queued('c1'));
        for (var i = 0; i < 5; i++) {
          await queue.markAttempt('c1');
        }
        expect(await queue.pending(), isEmpty);
      });
    });
  }

  group('sync', () {
    test('sends each scan with its time and id, and records the answers', () async {
      final queue = MemoryScanQueue();
      final scans = FakeScans()..answer = (code) => code == 'busin2.refused' ? const ScanRefused(ScanFailure.accountNotVerified) : const ScanAccepted(student: StudentSummary(fullName: 'Ada'), duplicate: false, scanId: 's');
      await queue.add(queued('c1'));
      await queue.add(QueuedScan(clientId: 'c2', tripId: 't1', code: 'busin2.refused', studentId: ben, scannedAt: now.add(const Duration(minutes: 1))));
      final report = await ScanSyncer(queue: queue, scans: scans).run();
      expect(report.accepted, 1);
      expect(report.refused, 1);
      expect(scans.sent.map((s) => s.clientId), ['c1', 'c2']);
      expect(scans.sent.first.at, now, reason: 'the time it was made, not the time it was sent');
      expect(await queue.pending(), isEmpty);
    });

    test('stops at the first sign of no connection and keeps the rest', () async {
      final queue = MemoryScanQueue();
      final scans = FakeScans()..failAfter = 1;
      await queue.add(queued('c1'));
      await queue.add(queued('c2', minutes: 1));
      final report = await ScanSyncer(queue: queue, scans: scans).run();
      expect(report.offline, isTrue);
      expect((await queue.pending()).map((s) => s.clientId), ['c2']);
    });

    test('a scan the server will never take (trip not running) is marked, not retried', () async {
      final queue = MemoryScanQueue();
      final scans = FakeScans()..error = const Conflict('database 55000');
      await queue.add(queued('c1'));
      await ScanSyncer(queue: queue, scans: scans).run();
      expect(queue.all.single.state, QueuedState.refused);
      expect(queue.all.single.reason, 'trip_not_running');
    });
  });
}
