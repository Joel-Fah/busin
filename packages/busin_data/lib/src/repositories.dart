import 'dart:math';
import 'dart:typed_data';

import 'package:busin_core/busin_core.dart';
import 'package:supabase/supabase.dart';

import 'columns.dart';
import 'error_mapping.dart';

/// The calendar day as the database compares it (`YYYY-MM-DD`).
String _day(DateTime day) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${day.year.toString().padLeft(4, '0')}-${two(day.month)}-${two(day.day)}';
}

List<Map<String, dynamic>> _rows(Object? data) =>
    (data as List<dynamic>).cast<Map<String, dynamic>>();

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<Profile> getProfile(String userId) => guarded(() async {
        final row = await _client.from('profiles').select(Columns.profile).eq('id', userId).single();
        return Profile.fromJson(row);
      });
}

class SupabaseSchoolRepository implements SchoolRepository {
  SupabaseSchoolRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<School> getSchool(String schoolId) => guarded(() async {
        final row = await _client.from('schools').select(Columns.school).eq('id', schoolId).single();
        return School.fromJson(row);
      });
}

class SupabaseStopsRepository implements StopsRepository {
  SupabaseStopsRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<Stop>> listActiveStops() => guarded(() async {
        final data = await _client
            .from('stops')
            .select(Columns.stop)
            .eq('active', true)
            .order('name', ascending: true)
            .limit(500);
        return _rows(data).map(Stop.fromJson).toList(growable: false);
      });

  @override
  Future<Stop> getStop(String stopId) => guarded(() async {
        final row = await _client.from('stops').select(Columns.stop).eq('id', stopId).single();
        return Stop.fromJson(row);
      });
}

class SupabaseSemestersRepository implements SemestersRepository {
  SupabaseSemestersRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<Semester?> currentSemester(DateTime today) => guarded(() async {
        final row = await _client
            .from('semesters')
            .select(Columns.semester)
            .lte('start_date', _day(today))
            .gte('end_date', _day(today))
            .order('start_date', ascending: false)
            .limit(1)
            .maybeSingle();
        return row == null ? null : Semester.fromJson(row);
      });

  @override
  Future<Semester?> nextSemester(DateTime today) => guarded(() async {
        final row = await _client
            .from('semesters')
            .select(Columns.semester)
            .gt('start_date', _day(today))
            .order('start_date', ascending: true)
            .limit(1)
            .maybeSingle();
        return row == null ? null : Semester.fromJson(row);
      });
}

class SupabaseSubscriptionsRepository implements SubscriptionsRepository {
  SupabaseSubscriptionsRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<Subscription>> listForStudent(
    String studentId, {
    PageRequest page = const PageRequest(),
  }) =>
      guarded(() async {
        final data = await _client
            .from('subscriptions')
            .select(Columns.subscription)
            .eq('student_id', studentId)
            .order('created_at', ascending: false)
            .range(page.offset, page.lastIndex);
        return _rows(data).map(Subscription.fromJson).toList(growable: false);
      });

  @override
  Future<Subscription?> liveForSemester({
    required String studentId,
    required String semesterId,
  }) =>
      guarded(() async {
        final row = await _client
            .from('subscriptions')
            .select(Columns.subscription)
            .eq('student_id', studentId)
            .eq('semester_id', semesterId)
            .inFilter('status', ['pending', 'approved'])
            .maybeSingle();
        return row == null ? null : Subscription.fromJson(row);
      });

  @override
  Future<Subscription> request(NewSubscription subscription) => guarded(() async {
        final row = await _client
            .from('subscriptions')
            .insert(subscription.toJson())
            .select(Columns.subscription)
            .single();
        return Subscription.fromJson(row);
      });
}

class SupabaseProofsRepository implements ProofsRepository {
  SupabaseProofsRepository(this._client, {Random? random}) : _random = random ?? Random.secure();
  final SupabaseClient _client;
  final Random _random;

  static const _bucket = 'proofs';
  static const _extensions = {'image/jpeg': 'jpg', 'image/png': 'png', 'image/webp': 'webp'};

  @override
  Future<String> upload({
    required String schoolId,
    required String studentId,
    required Uint8List bytes,
    required String contentType,
  }) =>
      guarded(() async {
        final extension = _extensions[contentType];
        if (extension == null) throw const Invalid('Proofs must be JPEG, PNG or WebP images.');
        if (bytes.isEmpty || bytes.length > ProofRules.maxBytes) throw const Invalid('A proof must be between 1 byte and 5 MB.');

        // Unguessable name in the student's own folder; the database policy checks both folders.
        final name = List.generate(16, (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
        final path = NewSubscription.proofPathFor(schoolId: schoolId, studentId: studentId, fileName: '$name.$extension');
        await _client.storage.from(_bucket).uploadBinary(path, bytes, fileOptions: FileOptions(contentType: contentType, upsert: false));
        return path;
      });

  @override
  Future<String> signedUrl(String path, {Duration expiresIn = const Duration(minutes: 10)}) =>
      guarded(() => _client.storage.from(_bucket).createSignedUrl(path, expiresIn.inSeconds));
}

class SupabaseQrRepository implements QrRepository {
  SupabaseQrRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<Uint8List> fetchSecret() => guarded(() async {
        final secret = await _client.rpc<String>('get_my_qr_secret');
        return QrCodeGenerator.decodeSecret(secret);
      });

  @override
  Future<Uint8List> rotateSecret() => guarded(() async {
        final secret = await _client.rpc<String>('rotate_my_qr_secret');
        return QrCodeGenerator.decodeSecret(secret);
      });
}

class SupabaseTripsRepository implements TripsRepository {
  SupabaseTripsRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<Trip>> listForDriver(
    String driverId, {
    required DateTime from,
    required DateTime to,
  }) =>
      guarded(() async {
        final data = await _client
            .from('trips')
            .select(Columns.trip)
            .eq('driver_id', driverId)
            .gte('scheduled_start', from.toUtc().toIso8601String())
            .lt('scheduled_start', to.toUtc().toIso8601String())
            .order('scheduled_start', ascending: true)
            .limit(100);
        return _rows(data).map(Trip.fromJson).toList(growable: false);
      });

  @override
  Future<Trip> getTrip(String tripId) => guarded(() async {
        final row = await _client.from('trips').select(Columns.trip).eq('id', tripId).single();
        return Trip.fromJson(row);
      });
}

class SupabaseScansRepository implements ScansRepository {
  SupabaseScansRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<ScanOutcome> recordScan({
    required String tripId,
    required String code,
    String? stopId,
    GeoPoint? location,
    double? accuracyMeters,
  }) =>
      guarded(() async {
        final result = await _client.rpc<Map<String, dynamic>>('record_qr_scan', params: {
          'p_trip_id': tripId,
          'p_code': code,
          'p_stop_id': stopId,
          'p_lat': location?.latitude,
          'p_lng': location?.longitude,
          'p_accuracy': accuracyMeters,
        });
        return ScanOutcome.fromJson(result);
      });

  @override
  Future<List<Scan>> listForTrip(
    String tripId, {
    PageRequest page = const PageRequest(),
  }) =>
      guarded(() async {
        final data = await _client
            .from('scans')
            .select(Columns.scan)
            .eq('trip_id', tripId)
            .order('scanned_at', ascending: false)
            .range(page.offset, page.lastIndex);
        return _rows(data).map(Scan.fromJson).toList(growable: false);
      });
}

class SupabaseLivePositionsRepository implements LivePositionsRepository {
  SupabaseLivePositionsRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<LivePosition?> latestForBus(String busId) => guarded(() async {
        final row = await _client
            .from('live_positions')
            .select(Columns.livePosition)
            .eq('bus_id', busId)
            .maybeSingle();
        return row == null ? null : LivePosition.fromJson(row);
      });

  @override
  Stream<LivePosition> watchBus(String busId) {
    // Filtered to one bus on the server, so a phone never receives other buses' positions.
    return _client
        .from('live_positions')
        .stream(primaryKey: ['bus_id'])
        .eq('bus_id', busId)
        .expand((rows) => rows)
        .map(LivePosition.fromJson)
        .handleError((Object error) => throw mapError(error));
  }
}
