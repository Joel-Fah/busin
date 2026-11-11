import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:busin_core/busin_core.dart';
import 'package:busin_data/busin_data.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

/// Builds repositories on a client whose network is a recording fake.
class Harness {
  Harness(this._reply) {
    final fake = MockClient((request) async {
      requests.add(request);
      final reply = await _reply(request);
      // The client reads the request back from the response, as a real one carries it.
      return http.Response(reply.body, reply.statusCode, headers: reply.headers, request: request);
    });
    repos = SupabaseRepositories(SupabaseClient('http://localhost:54321', 'public-key', httpClient: fake));
  }

  final Future<http.Response> Function(http.Request request) _reply;
  final List<http.Request> requests = [];
  late final SupabaseRepositories repos;

  http.Request get last => requests.last;
}

http.Response json(Object body, {int status = 200}) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

const _id = 'a1000000-0000-4000-8000-000000000001';
const _other = 'a1000000-0000-4000-8000-000000000002';
const _school = '00000000-0000-4000-8000-000000000001';

Map<String, dynamic> stopRow(String name, {bool active = true}) => {
      'id': _id,
      'school_id': _school,
      'name': name,
      'location': 'SRID=4326;POINT(11.5021 3.8480)',
      'photo_path': null,
      'active': active,
    };

Map<String, dynamic> tripRow({String status = 'scheduled'}) => {
      'id': _id,
      'school_id': _school,
      'bus_id': _other,
      'driver_id': _id,
      'direction': 'inbound',
      'status': status,
      'scheduled_start': '2026-11-05T06:30:00Z',
      'started_at': null,
      'ended_at': null,
    };

Map<String, dynamic> subscriptionRow({String status = 'pending'}) => {
      'id': _id,
      'school_id': _school,
      'student_id': _other,
      'semester_id': _id,
      'stop_id': _id,
      'status': status,
      'proof_path': null,
      'review_note': null,
      'reviewed_by': null,
      'reviewed_at': null,
      'created_at': '2026-11-04T08:00:00Z',
      'updated_at': '2026-11-04T08:00:00Z',
    };

Map<String, dynamic> semesterRow() => {
      'id': _id,
      'school_id': _school,
      'name': 'fall',
      'year': 2026,
      'start_date': '2026-09-07',
      'end_date': '2027-01-29',
    };

void main() {
  group('reading lists', () {
    test('active stops: named columns, only active, by name', () async {
      final h = Harness((_) async => json([stopRow('Mvan'), stopRow('Mendong')]));
      final stops = await h.repos.stops.listActiveStops();

      expect(stops.map((s) => s.name), ['Mvan', 'Mendong']);
      expect(stops.first.location.latitude, closeTo(3.848, 1e-9));
      final query = h.last.url.queryParameters;
      expect(h.last.url.path, '/rest/v1/stops');
      expect(query['select'], isNot(contains('*')));
      expect(query['select'], contains('photo_path'));
      expect(query['active'], 'eq.true');
      expect(query['order'], startsWith('name.asc'));
      expect(query['limit'], '500');
    });

    test('a student\'s subscriptions are paginated and newest first', () async {
      final h = Harness((_) async => json([subscriptionRow()]));
      final list = await h.repos.subscriptions.listForStudent(_other, page: const PageRequest(limit: 10, offset: 20));

      expect(list.single.status, SubscriptionStatus.pending);
      final query = h.last.url.queryParameters;
      expect(query['student_id'], 'eq.$_other');
      expect(query['order'], startsWith('created_at.desc'));
      expect(query['limit'], '10');
      expect(query['offset'], '20');
    });

    test('a driver\'s trips are limited to a window and to that driver', () async {
      final h = Harness((_) async => json([
            {
              'id': _id,
              'school_id': _school,
              'bus_id': _other,
              'driver_id': _id,
              'direction': 'inbound',
              'status': 'scheduled',
              'scheduled_start': '2026-11-05T06:30:00Z',
              'started_at': null,
              'ended_at': null,
            },
          ]));
      final trips = await h.repos.trips.listForDriver(
        _id,
        from: DateTime.utc(2026, 11, 5),
        to: DateTime.utc(2026, 11, 6),
      );

      expect(trips.single.direction, TripDirection.inbound);
      final query = h.last.url.queryParameters;
      expect(query['driver_id'], 'eq.$_id');
      expect(query['scheduled_start'], contains('2026-11-06'));
      expect(query['limit'], '100');
    });

    test('scans of a trip are paginated', () async {
      final h = Harness((_) async => json(<Object>[]));
      expect(await h.repos.scans.listForTrip(_id), isEmpty);
      expect(h.last.url.queryParameters['trip_id'], 'eq.$_id');
      expect(h.last.url.queryParameters['limit'], '20');
    });
  });

  group('academic units', () {
    test('reads the three lists with named columns and builds the choices', () async {
      final h = Harness((request) async {
        return switch (request.url.path) {
          '/rest/v1/faculties' => json([{'id': 'f1', 'name': 'Faculty One', 'code': 'F1'}]),
          '/rest/v1/departments' => json([{'id': 'd1', 'faculty_id': 'f1', 'name': 'Department One', 'code': null}]),
          _ => json([{'id': 'p1', 'name': 'Bachelor'}]),
        };
      });
      final units = await h.repos.academic.load();
      expect(units.departmentsOf('f1').single.name, 'Department One');
      expect(units.facultyOfDepartment('d1')?.name, 'Faculty One');
      expect(units.program('p1')?.name, 'Bachelor');
      for (final r in h.requests) {
        expect(r.url.queryParameters['select'], isNot('*'));
      }
    });
  });

  group('subscription history', () {
    test('asks for the events of these subscriptions only, with named columns, oldest first', () async {
      final h = Harness((_) async => json([
            {'id': 1, 'subscription_id': _id, 'action': 'requested', 'note': null, 'created_at': '2026-11-03T09:00:00Z'},
            {'id': 2, 'subscription_id': _id, 'action': 'revoked', 'note': 'Payment reversed', 'created_at': '2026-11-04T09:00:00Z'},
          ]));
      final events = await h.repos.subscriptions.eventsFor([_id, _other]);
      expect(events.map((e) => e.action.name), ['requested', 'revoked']);
      expect(h.last.url.path, '/rest/v1/subscription_events');
      expect(h.last.url.queryParameters['select'], isNot('*'));
      expect(h.last.url.queryParameters['subscription_id'], contains(_id));
      expect(h.last.url.queryParameters['order'], contains('created_at'));
    });

    test('with nothing to ask about it asks nothing', () async {
      final h = Harness((_) async => json([]));
      expect(await h.repos.subscriptions.eventsFor(const []), isEmpty);
      expect(h.requests, isEmpty);
    });
  });

  group('following buses', () {
    test('asks the database, which decides', () async {
      final yes = Harness((_) async => json(true));
      expect(await yes.repos.livePositions.canFollowBuses(), isTrue);
      expect(yes.last.url.path, '/rest/v1/rpc/can_follow_buses');
      expect(await Harness((_) async => json(false)).repos.livePositions.canFollowBuses(), isFalse);
    });
  });

  group('student history', () {
    Map<String, dynamic> scanRow(String id, String at) => {
          'id': id,
          'school_id': _school,
          'trip_id': _id,
          'student_id': _other,
          'subscription_id': _id,
          'stop_id': _id,
          'scanned_by': _id,
          'scanned_at': at,
          'location': null,
          'accuracy_m': null,
        };

    test('a student\'s own boardings come newest first, a page at a time', () async {
      final h = Harness((_) async => json([scanRow(_id, '2026-11-05T07:00:00Z'), scanRow(_other, '2026-11-04T07:00:00Z')]));
      final scans = await h.repos.scans.listForStudent(_other, page: const PageRequest(limit: 2, offset: 4));

      expect(scans, hasLength(2));
      final query = h.last.url.queryParameters;
      expect(query['student_id'], 'eq.$_other');
      expect(query['order'], startsWith('scanned_at.desc'));
      expect(query['limit'], '2');
      expect(query['offset'], '4');
      expect(query['select'], isNot(contains('*')));
    });

    test('trips are fetched by id in one request, and not at all for none', () async {
      final h = Harness((_) async => json([tripRow()]));
      expect(await h.repos.trips.listByIds(const []), isEmpty);
      expect(h.requests, isEmpty);

      final trips = await h.repos.trips.listByIds([_id, _other]);
      expect(trips, hasLength(1));
      expect(h.requests, hasLength(1));
      expect(h.last.url.queryParameters['id'], 'in.("$_id","$_other")');
    });

    test('asking for too many trips at once is refused before any request', () async {
      final h = Harness((_) async => json(<Object>[]));
      await expectLater(h.repos.trips.listByIds(List.filled(PageRequest.maxLimit + 1, _id)), throwsA(isA<Invalid>()));
      expect(h.requests, isEmpty);
    });
  });

  group('device tokens', () {
    test('registering sends the token, platform and language to the function and nothing else', () async {
      final h = Harness((_) async => http.Response('', 204));
      await h.repos.deviceTokens.register(token: 'token-of-this-phone-aaaaaaaaaaaa', platform: 'android', locale: 'fr');

      expect(h.last.url.path, '/rest/v1/rpc/register_device_token');
      expect(jsonDecode(h.last.body), {'p_token': 'token-of-this-phone-aaaaaaaaaaaa', 'p_platform': 'android', 'p_locale': 'fr'});
    });

    test('unregistering names only the token', () async {
      final h = Harness((_) async => http.Response('', 204));
      await h.repos.deviceTokens.unregister('token-of-this-phone-aaaaaaaaaaaa');
      expect(h.last.url.path, '/rest/v1/rpc/unregister_device_token');
      expect(jsonDecode(h.last.body), {'p_token': 'token-of-this-phone-aaaaaaaaaaaa'});
    });

    test('an account that may not register is NotAllowed, a bad value is Invalid, no network is Offline', () async {
      Future<Object> failure(Harness h) async {
        try {
          await h.repos.deviceTokens.register(token: 'token-of-this-phone-aaaaaaaaaaaa', platform: 'android', locale: 'en');
        } catch (e) {
          return e;
        }
        return 'no error';
      }

      expect(await failure(Harness((_) async => json({'code': '42501', 'message': 'no', 'details': null, 'hint': null}, status: 403))), isA<NotAllowed>());
      expect(await failure(Harness((_) async => json({'code': '22023', 'message': 'bad', 'details': null, 'hint': null}, status: 400))), isA<Invalid>());
      expect(await failure(Harness((_) async => throw const SocketException('down'))), isA<Offline>());
    });
  });

  group('live bus lookups', () {
    test('active trips are asked for by status, newest started first, and capped', () async {
      final h = Harness((_) async => json([tripRow(status: 'active')]));
      final trips = await h.repos.trips.listActive();

      expect(trips.single.status, TripStatus.active);
      final query = h.last.url.queryParameters;
      expect(query['status'], 'eq.active');
      expect(query['order'], startsWith('started_at.desc'));
      expect(query['limit'], '20');
      expect(query['select'], isNot(contains('*')));
    });

    test('buses are fetched by id in one request with named columns, and not at all for none', () async {
      final h = Harness((_) async => json([
            {'id': _id, 'school_id': _school, 'plate': 'DEMO-101', 'capacity': 50, 'in_service': true},
          ]));
      expect(await h.repos.buses.listByIds(const []), isEmpty);
      expect(h.requests, isEmpty);

      final buses = await h.repos.buses.listByIds([_id]);
      expect(buses.single.plate, 'DEMO-101');
      expect(h.last.url.queryParameters['id'], 'in.("$_id")');
      expect(h.last.url.queryParameters['select'], 'id,school_id,plate,name,capacity,in_service');
    });

    test('too many buses at once is refused before any request', () async {
      final h = Harness((_) async => json(<Object>[]));
      await expectLater(h.repos.buses.listByIds(List.filled(PageRequest.maxLimit + 1, _id)), throwsA(isA<Invalid>()));
      expect(h.requests, isEmpty);
    });
  });

  group('semesters', () {
    test('the current one contains the day', () async {
      final h = Harness((_) async => json(semesterRow()));
      final semester = await h.repos.semesters.currentSemester(DateTime.utc(2026, 11, 4));

      expect(semester?.year, 2026);
      final query = h.last.url.queryParameters;
      expect(query['start_date'], 'lte.2026-11-04');
      expect(query['end_date'], 'gte.2026-11-04');
      expect(query['limit'], '1');
    });

    test('between semesters there is none', () async {
      final h = Harness((_) async => json(<Object>[]));
      expect(await h.repos.semesters.currentSemester(DateTime.utc(2026, 7, 4)), isNull);
    });

    test('the next one starts after the day', () async {
      final h = Harness((_) async => json(semesterRow()));
      await h.repos.semesters.nextSemester(DateTime.utc(2026, 7, 4));
      expect(h.last.url.queryParameters['start_date'], 'gt.2026-07-04');
      expect(h.last.url.queryParameters['order'], startsWith('start_date.asc'));
    });
  });

  group('writing', () {
    test('a subscription request sends only what the database accepts, and reads the row back', () async {
      final h = Harness((_) async => json(subscriptionRow(), status: 201));
      final created = await h.repos.subscriptions.request(const NewSubscription(
        schoolId: _school,
        studentId: _other,
        semesterId: _id,
        stopId: _id,
      ));

      expect(created.isLive, isTrue);
      expect(h.last.method, 'POST');
      final body = jsonDecode(h.last.body) as Map<String, dynamic>;
      expect(body.keys.toSet(), {'school_id', 'student_id', 'semester_id', 'stop_id'});
      expect(body.containsKey('status'), isFalse);
      expect(h.last.url.queryParameters['select'], isNot(contains('*')));
    });

    test('a live subscription is looked up among pending and approved only', () async {
      final h = Harness((_) async => json(<Object>[]));
      expect(await h.repos.subscriptions.liveForSemester(studentId: _other, semesterId: _id), isNull);
      expect(h.last.url.queryParameters['status'], matches(r'^in\.\("?pending"?,"?approved"?\)$'));
    });
  });

  group('trip control', () {
    test('starts and ends a trip through the server functions', () async {
      final h = Harness((_) async => json(const <String, dynamic>{}));
      await h.repos.trips.start(_id);
      expect(h.last.url.path, '/rest/v1/rpc/start_trip');
      expect((jsonDecode(h.last.body) as Map<String, dynamic>)['p_trip_id'], _id);
      await h.repos.trips.end(_id);
      expect(h.last.url.path, '/rest/v1/rpc/end_trip');
    });

    test('a bus already on a trip is a Conflict', () async {
      final h = Harness((_) async => json({'code': '55000', 'message': 'bus_busy'}, status: 400));
      await expectLater(h.repos.trips.start(_id), throwsA(isA<Conflict>()));
    });

    test('reads the manifest', () async {
      final h = Harness((_) async => json([
            {'scan_id': _id, 'student_id': _other, 'full_name': 'Ada', 'avatar_url': null, 'matricule': 'M1', 'stop_id': null, 'scanned_at': '2026-11-12T07:15:00+00:00'},
          ]));
      final rows = await h.repos.trips.manifest(_id);
      expect(rows.single.fullName, 'Ada');
      expect(h.last.url.path, '/rest/v1/rpc/trip_manifest');
    });

    test('publishes a position and says whether the server kept it', () async {
      final h = Harness((_) async => json(false));
      final kept = await h.repos.livePositions.publish(tripId: _id, position: GeoPoint(3.85, 11.5), speedMps: 6, headingDeg: 90, accuracyM: 8);
      expect(kept, isFalse);
      final body = jsonDecode(h.last.body) as Map<String, dynamic>;
      expect(h.last.url.path, '/rest/v1/rpc/publish_position');
      expect(body['p_lat'], 3.85);
      expect(body['p_speed_mps'], 6);
    });
  });

  group('boarding scans', () {
    test('sends the code with the position and reads an accepted result', () async {
      final h = Harness((_) async => json({
            'valid': true,
            'duplicate': false,
            'scan_id': _id,
            'student': {'full_name': 'Ada Lovelace', 'avatar_url': null, 'matricule': 'ICTU20260001'},
          }));
      final outcome = await h.repos.scans.recordScan(
        tripId: _id,
        code: 'busin2.x.1.y',
        stopId: _other,
        location: GeoPoint(3.848, 11.502),
        accuracyMeters: 8,
      );

      expect(outcome, isA<ScanAccepted>());
      expect((outcome as ScanAccepted).student.fullName, 'Ada Lovelace');
      expect(h.last.url.path, '/rest/v1/rpc/record_qr_scan');
      final body = jsonDecode(h.last.body) as Map<String, dynamic>;
      expect(body['p_trip_id'], _id);
      expect(body['p_lat'], 3.848);
      expect(body['p_lng'], 11.502);
      expect(body['p_accuracy'], 8);
      expect(body['p_scanned_at'], isNull, reason: 'a live scan is timed by the server');
    });

    test('a queued scan sends when it was made and the phone\'s id for it', () async {
      final h = Harness((_) async => json({'valid': true, 'duplicate': true, 'scan_id': null, 'student': {'full_name': 'Ada'}}));
      await h.repos.scans.recordScan(tripId: _id, code: 'busin2.x.1.y', scannedAt: DateTime.utc(2026, 11, 12, 7, 15), clientId: _other);
      final body = jsonDecode(h.last.body) as Map<String, dynamic>;
      expect(body['p_scanned_at'], '2026-11-12T07:15:00.000Z');
      expect(body['p_client_id'], _other);
    });

    test('a refusal staff should see is a result, not an error', () async {
      final h = Harness((_) async => json({'valid': false, 'reason': 'no_active_subscription'}));
      final outcome = await h.repos.scans.recordScan(tripId: _id, code: 'busin2.x.1.y');
      expect(outcome, const ScanRefused(ScanFailure.noActiveSubscription));
      final body = jsonDecode(h.last.body) as Map<String, dynamic>;
      expect(body['p_lat'], isNull);
    });
  });

  group('day keys for staff', () {
    test('are read with the rider details and decoded', () async {
      final key = Uint8List.fromList(List<int>.generate(32, (i) => 31 - i));
      final h = Harness((_) async => json([
            {'student_id': _id, 'day_key': base64.encode(key), 'full_name': 'Ada', 'avatar_url': null, 'matricule': 'M1', 'stop_id': _other, 'day': '2026-11-12'},
          ]));
      final riders = await h.repos.qr.staffDayKeys();
      expect(h.last.url.path, '/rest/v1/rpc/staff_day_keys');
      expect(riders.single.dayKey, key);
      expect(riders.single.day, DateTime.utc(2026, 11, 12));
      expect(riders.single.stopId, _other);
    });
  });

  group('the boarding secret', () {
    test('is decoded from base64 and must be 32 bytes', () async {
      final secret = Uint8List.fromList(List<int>.generate(32, (i) => i));
      final h = Harness((_) async => json(base64.encode(secret)));
      expect(await h.repos.qr.fetchSecret(), secret);
      expect(h.last.url.path, '/rest/v1/rpc/get_my_qr_secret');

      final short = Harness((_) async => json(base64.encode([1, 2, 3])));
      expect(short.repos.qr.fetchSecret(), throwsA(isA<Unexpected>()));
    });

    test('can be replaced', () async {
      final secret = Uint8List(32);
      final h = Harness((_) async => json(base64.encode(secret)));
      await h.repos.qr.rotateSecret();
      expect(h.last.url.path, '/rest/v1/rpc/rotate_my_qr_secret');
    });
  });

  group('failures', () {
    Future<Object?> failure(Harness h) async {
      try {
        await h.repos.profiles.getProfile(_id);
      } on Object catch (error) {
        return error;
      }
      return null;
    }

    http.Response refusal(String code, {int status = 400}) =>
        json({'code': code, 'message': 'x', 'details': null, 'hint': null}, status: status);

    test('a row that is not there is NotFound', () async {
      expect(await failure(Harness((_) async => refusal('PGRST116', status: 406))), isA<NotFound>());
    });

    test('a refused role or school is NotAllowed', () async {
      expect(await failure(Harness((_) async => json({'code': '42501', 'message': 'no', 'details': null, 'hint': null}, status: 403))), isA<NotAllowed>());
    });

    test('a second live subscription is a Conflict', () async {
      final h = Harness((_) async => refusal('23505', status: 409));
      expect(
        h.repos.subscriptions.request(const NewSubscription(schoolId: _school, studentId: _other, semesterId: _id, stopId: _id)),
        throwsA(isA<Conflict>()),
      );
    });

    test('a bad value is Invalid', () async {
      expect(await failure(Harness((_) async => refusal('23514'))), isA<Invalid>());
    });

    test('no network is Offline', () async {
      expect(await failure(Harness((_) async => throw const SocketException('down'))), isA<Offline>());
    });

    test('an unknown code is Unexpected and carries the code, not the row', () async {
      final error = await failure(Harness((_) async => refusal('XX000', status: 500)));
      expect(error, isA<Unexpected>());
      expect((error as Unexpected).message, 'database XX000');
    });

    test('a session that could not be refreshed offline is Offline, a real auth refusal is NotAllowed', () {
      expect(mapError(AuthRetryableFetchException(message: 'no network')), isA<Offline>());
      expect(mapError(const AuthException('invalid token', statusCode: '401')), isA<NotAllowed>());
    });

    test('mapError leaves an already mapped error alone', () {
      const original = NotFound('x');
      expect(identical(mapError(original), original), isTrue);
    });
  });

  group('proofs', () {
    final jpeg = Uint8List.fromList(List.filled(2048, 7));

    test('uploads into the student folder with an unguessable name and the right type', () async {
      final h = Harness((r) async => json({'Key': 'proofs/x', 'Id': 'abc'}));
      final path = await h.repos.proofs.upload(schoolId: _school, studentId: _other, bytes: jpeg, contentType: 'image/jpeg');

      expect(path, matches(RegExp('^$_school/$_other/[0-9a-f]{32}\\.jpg\$')));
      expect(h.last.method, 'POST');
      expect(h.last.url.path, '/storage/v1/object/proofs/$path');
      expect(h.last.headers['content-type'], startsWith('multipart/form-data'));
      expect(h.last.body, contains('image/jpeg'));
      expect(h.last.headers['x-upsert'], 'false', reason: 'evidence is never overwritten');
    });

    test('two uploads never share a name', () async {
      final h = Harness((r) async => json({'Key': 'proofs/x'}));
      final a = await h.repos.proofs.upload(schoolId: _school, studentId: _other, bytes: jpeg, contentType: 'image/png');
      final b = await h.repos.proofs.upload(schoolId: _school, studentId: _other, bytes: jpeg, contentType: 'image/png');
      expect(a, isNot(b));
      expect(a, endsWith('.png'));
    });

    test('refuses a type, an empty file and a file over 5 MB before any request', () async {
      final h = Harness((r) async => json({}));
      await expectLater(h.repos.proofs.upload(schoolId: _school, studentId: _other, bytes: jpeg, contentType: 'application/pdf'), throwsA(isA<Invalid>()));
      await expectLater(h.repos.proofs.upload(schoolId: _school, studentId: _other, bytes: Uint8List(0), contentType: 'image/jpeg'), throwsA(isA<Invalid>()));
      await expectLater(
        h.repos.proofs.upload(schoolId: _school, studentId: _other, bytes: Uint8List(ProofRules.maxBytes + 1), contentType: 'image/jpeg'),
        throwsA(isA<Invalid>()),
      );
      expect(h.requests, isEmpty);
    });

    test('maps what the bucket says into repository exceptions', () async {
      for (final (status, matcher) in [(403, isA<NotAllowed>()), (413, isA<Invalid>()), (409, isA<Conflict>()), (404, isA<NotFound>())]) {
        final h = Harness((r) async => json({'statusCode': '$status', 'error': 'x', 'message': 'x'}, status: status));
        await expectLater(
          h.repos.proofs.upload(schoolId: _school, studentId: _other, bytes: jpeg, contentType: 'image/jpeg'),
          throwsA(matcher),
          reason: 'status $status',
        );
      }
    });

    test('asks for a short-lived signed address', () async {
      final h = Harness((r) async => json({'signedURL': '/object/sign/proofs/a/b/c.jpg?token=t'}));
      final url = await h.repos.proofs.signedUrl('a/b/c.jpg', expiresIn: const Duration(minutes: 5));

      expect(url, contains('token=t'));
      expect(h.last.url.path, '/storage/v1/object/sign/proofs/a/b/c.jpg');
      expect(jsonDecode(h.last.body), {'expiresIn': 300});
    });
  });
}
