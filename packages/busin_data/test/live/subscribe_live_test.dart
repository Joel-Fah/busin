@Tags(['live'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:busin_core/busin_core.dart';
import 'package:busin_data/busin_data.dart';
import 'package:http/http.dart' as http;
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

/// Runs the student's subscribe flow against the LOCAL Supabase stack, with a real student session, so
/// Row Level Security and the private storage policies are the real ones. Opt-in:
///
///   npm run backend:start
///   cd packages/busin_data && fvm dart test -t live --run-skipped
///
/// It creates a throwaway student and removes everything it made. Local development only.

const _school = '00000000-0000-4000-8000-000000000001';
const _semester = '00000000-0000-4000-8000-000000000011';
const _stop = '00000000-0000-4000-8000-000000000021';
const _domain = 'ictuniversity.edu.cm';

String _env(String output, String name) {
  final match = RegExp('^$name="?([^"\\r\\n]+)"?', multiLine: true).firstMatch(output);
  if (match == null) throw StateError('Could not read $name from "supabase status". Is the local stack running?');
  return match.group(1)!;
}

String _hex(Random r, int bytes) => List.generate(bytes, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();

String _uuid(Random r) {
  final h = _hex(r, 16);
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-4${h.substring(13, 16)}-8${h.substring(17, 20)}-${h.substring(20)}';
}

Future<void> _sql(String statement) async {
  final result = await Process.run('docker', ['exec', '-i', 'supabase_db_busin', 'psql', '-U', 'postgres', '-v', 'ON_ERROR_STOP=1', '-q', '-c', statement]);
  if (result.exitCode != 0) throw StateError('psql failed: ${result.stderr}');
}

Future<String> _query(String statement) async {
  final result = await Process.run('docker', ['exec', '-i', 'supabase_db_busin', 'psql', '-U', 'postgres', '-v', 'ON_ERROR_STOP=1', '-tA', '-c', statement]);
  if (result.exitCode != 0) throw StateError('psql failed: ${result.stderr}');
  return (result.stdout as String).trim();
}

/// A real 1x1 PNG.
final _png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');

void main() {
  late String url;
  late String publishableKey;
  late String serviceKey;
  late String studentId;
  late String otherId;
  String? historyTripId;
  final feedBuses = <String>[];
  late SupabaseClient client;
  late SupabaseRepositories repos;
  final uploaded = <String>[];

  setUpAll(() async {
    final repoRoot = Directory.current.parent.parent.path;
    final status = await Process.run('npx', ['supabase', 'status', '-o', 'env'], workingDirectory: repoRoot);
    final out = status.stdout as String;
    url = _env(out, 'API_URL');
    publishableKey = _env(out, 'PUBLISHABLE_KEY');
    serviceKey = _env(out, 'SERVICE_ROLE_KEY');

    final random = Random.secure();
    studentId = _uuid(random);
    otherId = _uuid(random);
    final password = _hex(random, 16);
    final email = 'live-${_hex(random, 4)}@$_domain';

    for (final (id, mail) in [(studentId, email), (otherId, 'live-other-${_hex(random, 4)}@$_domain')]) {
      await _sql('''
        insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
          raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
          confirmation_token, recovery_token, email_change_token_new, email_change)
        values ('00000000-0000-0000-0000-000000000000', '$id', 'authenticated', 'authenticated', '$mail',
          extensions.crypt('$password', extensions.gen_salt('bf')), now(),
          '{"provider":"google","providers":["google"]}', '{"full_name":"Live test"}', now(), now(), '', '', '', '');
        insert into auth.identities (id, user_id, provider_id, provider, identity_data, last_sign_in_at, created_at, updated_at)
        values (gen_random_uuid(), '$id', '$id', 'google', '{"sub":"$id","email":"$mail"}', now(), now(), now());
        update public.profiles set status = 'verified' where id = '$id';
      ''');
    }

    client = SupabaseClient(url, publishableKey);
    await client.auth.signInWithPassword(email: email, password: password);
    repos = SupabaseRepositories(client);
  });

  tearDownAll(() async {
    final admin = SupabaseClient(url, serviceKey);
    if (uploaded.isNotEmpty) await admin.storage.from('proofs').remove(uploaded);
    // Rotating a secret writes an audit entry that points at the student; remove it with the throwaway user.
    if (feedBuses.isNotEmpty) await _sql("delete from public.live_positions where bus_id in (${feedBuses.map((b) => "'$b'").join(',')});");
    await _sql("delete from public.scans where student_id in ('$studentId', '$otherId');");
    if (historyTripId != null) await _sql("delete from public.trips where id = '$historyTripId';");
    await _sql("delete from public.audit_log where actor_id in ('$studentId', '$otherId');");
    await _sql("delete from public.subscriptions where student_id in ('$studentId', '$otherId');");
    await _sql("delete from auth.users where id in ('$studentId', '$otherId');");
    await client.auth.signOut();
  });

  test('the student reads their own profile and sees the school data they need', () async {
    final profile = await repos.profiles.getProfile(studentId);
    expect(profile.role, UserRole.student);
    expect(profile.status, AccountStatus.verified);
    expect(profile.schoolId, _school);

    expect((await repos.schools.getSchool(_school)).timezone, isNotEmpty);
    expect(await repos.stops.listActiveStops(), isNotEmpty);
  });

  test('upload a proof, read it back through a signed address, then send the request', () async {
    final path = await repos.proofs.upload(schoolId: _school, studentId: studentId, bytes: Uint8List.fromList(_png), contentType: 'image/png');
    uploaded.add(path);
    expect(path, startsWith('$_school/$studentId/'));

    final signed = await repos.proofs.signedUrl(path);
    final response = await http.get(Uri.parse(signed.startsWith('http') ? signed : '$url/storage/v1$signed'));
    expect(response.statusCode, 200);
    expect(response.bodyBytes, _png);

    final created = await repos.subscriptions.request(
      NewSubscription(schoolId: _school, studentId: studentId, semesterId: _semester, stopId: _stop, proofPath: path),
    );
    expect(created.status, SubscriptionStatus.pending);
    expect(created.proofPath, path);

    final live = await repos.subscriptions.liveForSemester(studentId: studentId, semesterId: _semester);
    expect(live?.id, created.id);
  });

  test('no boarding secret before the subscription is approved', () async {
    await expectLater(repos.qr.fetchSecret(), throwsA(isA<NotAllowed>()));
  });

  test('once approved, the secret is released and the database accepts exactly the codes the app derives', () async {
    await _sql("update public.subscriptions set status = 'approved' where student_id = '$studentId';");

    final secret = await repos.qr.fetchSecret();
    expect(secret, hasLength(32));
    expect(await repos.qr.fetchSecret(), secret, reason: 'fetching again returns the same secret');

    final window = QrCodeGenerator.windowFor(DateTime.now().toUtc());
    final appMac = QrCodeGenerator.mac(secret: secret, studentId: studentId, window: window);
    final dbMac = await _query("select private.qr_mac((select secret from private.qr_secrets where student_id = '$studentId'), '$studentId', $window)");
    expect(appMac, dbMac, reason: 'the Dart generator and the database function agree on this student secret');

    final code = QrCodeGenerator.generate(secret: secret, studentId: studentId, now: DateTime.now().toUtc());
    expect(code, startsWith('busin1.$studentId.'));
    expect(code, endsWith(appMac));
  });

  test('rotating the secret makes the old codes stop matching', () async {
    final before = await repos.qr.fetchSecret();
    final after = await repos.qr.rotateSecret();
    expect(after, isNot(before));

    final window = QrCodeGenerator.windowFor(DateTime.now().toUtc());
    final dbMac = await _query("select private.qr_mac((select secret from private.qr_secrets where student_id = '$studentId'), '$studentId', $window)");
    expect(QrCodeGenerator.mac(secret: after, studentId: studentId, window: window), dbMac);
    expect(QrCodeGenerator.mac(secret: before, studentId: studentId, window: window), isNot(dbMac));
  });

  test('a second live request for the semester is a Conflict', () async {
    await expectLater(
      repos.subscriptions.request(NewSubscription(schoolId: _school, studentId: studentId, semesterId: _semester, stopId: _stop)),
      throwsA(isA<Conflict>()),
    );
  });

  test('a student reads only their own boardings, and the trips they were on', () async {
    final random = Random.secure();
    final tripId = _uuid(random);
    historyTripId = tripId;
    final bus = await _query('select id from public.buses order by created_at limit 1');
    final subscription = await _query("select id from public.subscriptions where student_id = '$studentId' limit 1");
    await _sql("""
      insert into public.subscriptions (school_id, student_id, semester_id, stop_id, status)
        values ('$_school', '$otherId', '$_semester', '$_stop', 'approved');
      insert into public.trips (id, school_id, bus_id, direction, status, scheduled_start, started_at, ended_at)
        values ('$tripId', '$_school', '$bus', 'inbound', 'completed', now() - interval '2 hours', now() - interval '2 hours', now() - interval '1 hour');
      insert into public.scans (school_id, trip_id, student_id, subscription_id, stop_id, scanned_by, scanned_at)
        values ('$_school', '$tripId', '$studentId', '$subscription', '$_stop', '$studentId', now() - interval '90 minutes'),
               ('$_school', '$tripId', '$otherId', (select id from public.subscriptions where student_id = '$otherId'), '$_stop', '$studentId', now() - interval '80 minutes');
    """);

    final mine = await repos.scans.listForStudent(studentId, page: const PageRequest(limit: 20));
    expect(mine, hasLength(1));
    expect(mine.single.studentId, studentId);
    expect(mine.single.stopId, _stop);

    // Asking for another student's history returns nothing: Row Level Security, not the app, hides it.
    expect(await repos.scans.listForStudent(otherId), isEmpty);

    final trips = await repos.trips.listByIds([tripId]);
    expect(trips.single.direction, TripDirection.inbound);
  });

  test('the live feed of one bus carries that bus only, as it moves', () async {
    final ids = (await _query("select id from public.buses where school_id = '$_school' order by created_at limit 2")).split('\n');
    expect(ids, hasLength(2), reason: 'the local data needs two buses (npm run seed:demo)');
    final (mine, other) = (ids[0], ids[1]);
    feedBuses.addAll([mine, other]);

    final received = <LivePosition>[];
    final subscription = repos.livePositions.watchBus(mine).listen(received.add);
    addTearDown(subscription.cancel);
    await Future<void>.delayed(const Duration(seconds: 3)); // let the channel join

    String upsert(String bus, double lat, double lng) => """
      insert into public.live_positions (bus_id, school_id, location, source, recorded_at)
      values ('$bus', '$_school', extensions.st_point($lng, $lat)::extensions.geography, 'phone', now())
      on conflict (bus_id) do update set location = excluded.location, recorded_at = excluded.recorded_at;""";

    await _sql(upsert(other, 3.90, 11.60)); // another bus moves: must not arrive
    await _sql(upsert(mine, 3.851, 11.501));
    await _sql(upsert(other, 3.91, 11.61));
    await _sql(upsert(mine, 3.852, 11.502));

    for (var i = 0; i < 40 && !received.any((p) => (p.location.latitude - 3.852).abs() < 1e-6); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    expect(received, isNotEmpty, reason: 'the student receives the bus they follow');
    expect(received.map((p) => p.busId).toSet(), {mine}, reason: 'and nothing from other buses');
    expect(received.last.location.latitude, closeTo(3.852, 1e-6));
    expect(received.any((p) => p.location.latitude > 3.89), isFalse);

    final latest = await repos.livePositions.latestForBus(mine);
    expect(latest?.location.longitude, closeTo(11.502, 1e-6));
  });

  test('a student cannot upload into someone else\'s folder', () async {
    await expectLater(
      repos.proofs.upload(schoolId: _school, studentId: otherId, bytes: Uint8List.fromList(_png), contentType: 'image/png'),
      throwsA(isA<NotAllowed>()),
    );
  });

  test('a student cannot send a request in someone else\'s name', () async {
    await expectLater(
      repos.subscriptions.request(NewSubscription(schoolId: _school, studentId: otherId, semesterId: _semester, stopId: _stop)),
      throwsA(isA<NotAllowed>()),
    );
  });

  test('the bucket itself refuses a file type it does not allow, even if a client skips the checks', () async {
    final path = '$_school/$studentId/${_hex(Random.secure(), 8)}.pdf';
    await expectLater(
      client.storage.from('proofs').uploadBinary(path, Uint8List.fromList(utf8.encode('%PDF-1.4')), fileOptions: const FileOptions(contentType: 'application/pdf')),
      throwsA(isA<StorageException>()),
    );
  });

  test('a proof cannot be replaced or deleted by the student', () async {
    final path = uploaded.first;
    await expectLater(
      client.storage.from('proofs').uploadBinary(path, Uint8List.fromList(_png), fileOptions: const FileOptions(contentType: 'image/png', upsert: true)),
      throwsA(isA<StorageException>()),
    );
    final removed = await client.storage.from('proofs').remove([path]);
    expect(removed, isEmpty, reason: 'the delete policy removes nothing');
  });
}
