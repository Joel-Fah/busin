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
