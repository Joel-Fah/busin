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

  @override
  Future<Profile> updateProfile(
    String userId, {
    String? fullName,
    String? phone,
    String? matricule,
    AcademicChoice? academic,
  }) =>
      guarded(() async {
        final changes = Profile.editableJson(fullName: fullName, phone: phone, matricule: matricule, academic: academic);
        final row = await _client.from('profiles').update(changes).eq('id', userId).select(Columns.profile).single();
        return Profile.fromJson(row);
      });
}

class SupabaseAcademicRepository implements AcademicRepository {
  SupabaseAcademicRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<AcademicUnits> load() => guarded(() async {
        final results = await Future.wait([
          _client.from('faculties').select(Columns.faculty).order('name'),
          _client.from('departments').select(Columns.department).order('name'),
          _client.from('programs').select(Columns.program).order('sort_order').order('name'),
        ]);
        return AcademicUnits(
          faculties: _rows(results[0]).map(Faculty.fromJson).toList(),
          departments: _rows(results[1]).map(Department.fromJson).toList(),
          programs: _rows(results[2]).map(Program.fromJson).toList(),
        );
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

class SupabaseNotificationPreferencesRepository implements NotificationPreferencesRepository {
  SupabaseNotificationPreferencesRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<NotificationPreferences> load() => guarded(() async {
        final rows = await _client.rpc<List<dynamic>>('my_notification_preferences');
        return rows.isEmpty ? const NotificationPreferences() : NotificationPreferences.fromJson(rows.first as Map<String, dynamic>);
      });

  @override
  Future<void> save(NotificationPreferences p) => guarded(() async {
        await _client.rpc<void>('set_notification_preferences', params: {
          'p_riding_days': NotificationPreferences.maskOf(p.ridingDays),
          'p_morning_on': p.morningOn,
          'p_morning_time': p.morningTime.text,
          'p_evening_on': p.eveningOn,
          'p_evening_time': p.eveningTime.text,
          'p_bus_near_on': p.busNearOn,
          'p_bus_near_minutes': p.busNearMinutes,
          'p_boarding_messages_on': p.boardingMessagesOn,
        });
      });
}

class SupabaseStreaksRepository implements StreaksRepository {
  SupabaseStreaksRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<void> setOptIn(bool on) => guarded(() async {
        await _client.rpc<void>('set_streak_opt_in', params: {'p_on': on});
      });

  @override
  Future<List<RideDay>> rideDays(String semesterId) => guarded(() async {
        final rows = await _client.rpc<List<dynamic>>('my_ride_days', params: {'p_semester_id': semesterId});
        return rows.cast<Map<String, dynamic>>().map(RideDay.fromJson).toList(growable: false);
      });

  @override
  Future<Streak?> streak(String semesterId) => guarded(() async {
        final rows = await _client.rpc<List<dynamic>>('my_streak', params: {'p_semester_id': semesterId});
        return rows.isEmpty ? null : Streak.fromJson(rows.first as Map<String, dynamic>);
      });
}

class SupabaseJoinRepository implements JoinRepository {
  SupabaseJoinRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<OpenSchool>> listOpenSchools() => guarded(() async {
        final rows = await _client.rpc<List<dynamic>>('list_open_schools');
        return rows.cast<Map<String, dynamic>>().map(OpenSchool.fromJson).toList();
      });

  @override
  Future<JoinRequest?> myRequest() => guarded(() async {
        final rows = await _client.rpc<List<dynamic>>('my_join_request');
        return rows.isEmpty ? null : JoinRequest.fromJson(rows.first as Map<String, dynamic>);
      });

  @override
  Future<void> requestSchool(String? schoolId) => guarded(() async {
        await _client.rpc<void>('request_school', params: {'p_school_id': schoolId});
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
  Future<List<SubscriptionEvent>> eventsFor(List<String> subscriptionIds) => guarded(() async {
        if (subscriptionIds.isEmpty) return const [];
        final data = await _client
            .from('subscription_events')
            .select(Columns.subscriptionEvent)
            .inFilter('subscription_id', subscriptionIds)
            .order('created_at')
            .order('id');
        return _rows(data).map(SubscriptionEvent.fromJson).toList(growable: false);
      });

  @override
  Stream<List<Subscription>> watchForStudent(String studentId) {
    // Filtered on the server to this one student; Row Level Security applies to Realtime as well.
    return _client
        .from('subscriptions')
        .stream(primaryKey: ['id'])
        .eq('student_id', studentId)
        .map((rows) => rows.map(Subscription.fromJson).toList(growable: false))
        .handleError((Object error) => throw mapError(error));
  }

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

  @override
  Future<List<Trip>> listActive() => guarded(() async {
        final data = await _client
            .from('trips')
            .select(Columns.trip)
            .eq('status', 'active')
            .order('started_at', ascending: false)
            .limit(PageRequest.defaultLimit);
        return _rows(data).map(Trip.fromJson).toList(growable: false);
      });

  @override
  Future<List<Trip>> listByIds(List<String> tripIds) => guarded(() async {
        if (tripIds.isEmpty) return const <Trip>[];
        if (tripIds.length > PageRequest.maxLimit) throw const Invalid('Too many trips asked for at once.');
        final data = await _client.from('trips').select(Columns.trip).inFilter('id', tripIds);
        return _rows(data).map(Trip.fromJson).toList(growable: false);
      });
}

class SupabaseDeviceTokensRepository implements DeviceTokensRepository {
  SupabaseDeviceTokensRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<void> register({required String token, required String platform, required String locale}) => guarded(() async {
        await _client.rpc<void>('register_device_token', params: {'p_token': token, 'p_platform': platform, 'p_locale': locale});
      });

  @override
  Future<void> unregister(String token) => guarded(() async {
        await _client.rpc<void>('unregister_device_token', params: {'p_token': token});
      });
}

class SupabaseBusesRepository implements BusesRepository {
  SupabaseBusesRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<Bus>> listByIds(List<String> busIds) => guarded(() async {
        if (busIds.isEmpty) return const <Bus>[];
        if (busIds.length > PageRequest.maxLimit) throw const Invalid('Too many buses asked for at once.');
        final data = await _client.from('buses').select(Columns.bus).inFilter('id', busIds);
        return _rows(data).map(Bus.fromJson).toList(growable: false);
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
  Stream<Scan?> watchLatestForStudent(String studentId) {
    // One row only: the newest boarding of this student, kept current by Realtime (RLS applies there too).
    return _client
        .from('scans')
        .stream(primaryKey: ['id'])
        .eq('student_id', studentId)
        .order('scanned_at')
        .limit(1)
        .map((rows) => rows.isEmpty ? null : Scan.fromJson(rows.first))
        .handleError((Object error) => throw mapError(error));
  }

  @override
  Future<int> countForStudentSince(String studentId, DateTime since) => guarded(() async {
        final result = await _client
            .from('scans')
            .select('id')
            .eq('student_id', studentId)
            .gte('scanned_at', since.toUtc().toIso8601String())
            .count(CountOption.exact);
        return result.count;
      });

  @override
  Future<List<Scan>> listForStudent(
    String studentId, {
    PageRequest page = const PageRequest(),
  }) =>
      guarded(() async {
        final data = await _client
            .from('scans')
            .select(Columns.scan)
            .eq('student_id', studentId)
            .order('scanned_at', ascending: false)
            .range(page.offset, page.lastIndex);
        return _rows(data).map(Scan.fromJson).toList(growable: false);
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
  Future<bool> canFollowBuses() => guarded(() async => (await _client.rpc<dynamic>('can_follow_buses')) == true);

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
