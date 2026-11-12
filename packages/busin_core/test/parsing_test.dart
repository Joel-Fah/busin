import 'package:busin_core/busin_core.dart';
import 'package:test/test.dart';

void main() {
  group('enums', () {
    test('parse known values', () {
      expect(UserRole.parse('admin'), UserRole.admin);
      expect(AccountStatus.parse('suspended'), AccountStatus.suspended);
      expect(SubscriptionStatus.parse('approved'), SubscriptionStatus.approved);
      expect(TripStatus.parse('active'), TripStatus.active);
      expect(ScanFailure.parse('expired_code'), ScanFailure.expiredCode);
    });

    test('fail loudly on unknown or missing values', () {
      expect(() => UserRole.parse('owner'), throwsFormatException);
      expect(() => UserRole.parse(null), throwsFormatException);
      expect(() => AccountStatus.parse(''), throwsFormatException);
      expect(() => ScanFailure.parse('other'), throwsFormatException);
    });
  });

  group('Bus', () {
    Map<String, dynamic> row({Object? name}) => {
          'id': 'b1',
          'school_id': 's1',
          'plate': 'LT 100 AA',
          'name': name,
          'capacity': 60,
          'in_service': true,
        };

    test('is called by its name when it has one, otherwise by its plate', () {
      expect(Bus.fromJson(row(name: 'Blue Line')).label, 'Blue Line');
      expect(Bus.fromJson(row()).label, 'LT 100 AA');
      expect(Bus.fromJson(row(name: '  ')).label, 'LT 100 AA');
    });
  });

  group('School', () {
    test('reads its profile and builds the public logo address', () {
      final school = School.fromJson({
        'id': 's1',
        'name': 'Hill University',
        'short_name': 'HU',
        'timezone': 'Africa/Douala',
        'status': 'active',
        'logo_path': 's1/logo-1.webp',
        'city': 'Yaounde',
        'about': 'A school on a hill.',
      });
      expect(school.logoUrl('http://127.0.0.1:54321/'), 'http://127.0.0.1:54321/storage/v1/object/public/school-logos/s1/logo-1.webp');
      expect(school.city, 'Yaounde');
      expect(School.fromJson(school.toJson()), school);
      expect(School.fromJson({'id': 's2', 'name': 'B', 'timezone': 'UTC', 'status': 'active'}).logoUrl('http://x'), isNull);
    });
  });

  group('GeoPoint', () {
    test('reads GeoJSON with longitude first', () {
      final p = GeoPoint.fromApi({
        'type': 'Point',
        'coordinates': [11.5021, 3.848],
      });
      expect(p.latitude, 3.848);
      expect(p.longitude, 11.5021);
    });

    test('reads WKT with and without SRID', () {
      expect(GeoPoint.fromApi('POINT(11.5 3.85)'), GeoPoint(3.85, 11.5));
      expect(GeoPoint.fromApi('SRID=4326;POINT(11.5 3.85)'), GeoPoint(3.85, 11.5));
    });

    test('writes GeoJSON with longitude first', () {
      expect(GeoPoint(3.85, 11.5).toGeoJson(), {
        'type': 'Point',
        'coordinates': [11.5, 3.85],
      });
    });

    test('rejects impossible coordinates and unknown shapes', () {
      expect(() => GeoPoint(91, 0), throwsRangeError);
      expect(() => GeoPoint(0, 181), throwsRangeError);
      expect(() => GeoPoint.fromApi('not a point'), throwsFormatException);
      expect(() => GeoPoint.fromApi({'type': 'Line'}), throwsFormatException);
      expect(() => GeoPoint.fromApi(null), throwsFormatException);
    });
  });

  group('models', () {
    final profileJson = <String, dynamic>{
      'id': 'a1',
      'school_id': 's1',
      'email': 'ada@a.edu',
      'full_name': 'Ada Lovelace',
      'avatar_url': null,
      'phone': null,
      'role': 'student',
      'status': 'verified',
      'matricule': 'M-001',
      'department': null,
      'program': null,
      'created_at': '2026-10-30T10:00:00+00:00',
      'updated_at': '2026-10-30T10:00:00.123456+00:00',
    };

    test('Profile parses and derives initials', () {
      final p = Profile.fromJson(profileJson);
      expect(p.role, UserRole.student);
      expect(p.isVerified, isTrue);
      expect(p.initials, 'AL');
      expect(p.createdAt.isUtc, isTrue);
    });

    test('Profile rejects an unknown role instead of defaulting', () {
      expect(
        () => Profile.fromJson({...profileJson, 'role': 'superuser'}),
        throwsFormatException,
      );
    });

    test('Profile editable fields never include role, status or school', () {
      final json = Profile.editableJson(fullName: 'New Name', phone: '650000000');
      expect(json.keys, unorderedEquals(['full_name', 'phone']));
      expect(json.containsKey('role'), isFalse);
      expect(json.containsKey('status'), isFalse);
      expect(json.containsKey('school_id'), isFalse);
    });

    test('the academic choice is written together, and null clears', () {
      expect(Profile.editableJson(academic: const AcademicChoice(departmentId: 'd1')), {'department_id': 'd1', 'program_id': null});
      expect(Profile.editableJson(fullName: 'A B').containsKey('department_id'), isFalse);
    });

    test('departments narrow to their faculty and find their faculty back', () {
      const units = AcademicUnits(
        faculties: [Faculty(id: 'f1', name: 'One'), Faculty(id: 'f2', name: 'Two')],
        departments: [Department(id: 'd1', facultyId: 'f1', name: 'A'), Department(id: 'd2', facultyId: 'f2', name: 'B')],
        programs: [Program(id: 'p1', name: 'Bachelor')],
      );
      expect(units.departmentsOf('f2').map((d) => d.name), ['B']);
      expect(units.departmentsOf(null), isEmpty);
      expect(units.facultyOfDepartment('d1')?.id, 'f1');
      expect(units.facultyOfDepartment('missing'), isNull);
      expect(units.isEmpty, isFalse);
      expect(const AcademicUnits().isEmpty, isTrue);
    });

    test('SubscriptionEvent parses, and refuses an action it does not know', () {
      final e = SubscriptionEvent.fromJson({'id': 7, 'subscription_id': 's1', 'action': 'reinstated', 'note': 'Paid in cash', 'created_at': '2026-11-04T09:00:00+00:00'});
      expect(e.action, SubscriptionEventAction.reinstated);
      expect(e.note, 'Paid in cash');
      expect(e.createdAt.isUtc, isTrue);
      expect(() => SubscriptionEvent.fromJson({'id': 7, 'subscription_id': 's1', 'action': 'deleted', 'created_at': '2026-11-04T09:00:00+00:00'}), throwsFormatException);
    });

    test('Semester parses dates and checks inclusion on both ends', () {
      final s = Semester.fromJson({
        'id': 'm1',
        'school_id': 's1',
        'name': 'fall',
        'year': 2026,
        'start_date': '2026-09-07',
        'end_date': '2027-01-29',
      });
      expect(s.includes(DateTime(2026, 9, 7)), isTrue);
      expect(s.includes(DateTime(2027, 1, 29, 23, 59)), isTrue);
      expect(s.includes(DateTime(2026, 9, 6)), isFalse);
      expect(s.includes(DateTime(2027, 1, 30)), isFalse);
    });

    test('Semester rejects a malformed date', () {
      expect(
        () => Semester.fromJson({
          'id': 'm1',
          'school_id': 's1',
          'name': 'fall',
          'year': 2026,
          'start_date': '07/09/2026',
          'end_date': '2027-01-29',
        }),
        throwsFormatException,
      );
    });

    test('Stop reads its location', () {
      final stop = Stop.fromJson({
        'id': 'p1',
        'school_id': 's1',
        'name': 'Poste Centrale',
        'location': {'type': 'Point', 'coordinates': [11.4833, 3.8333]},
        'photo_path': null,
        'active': true,
      });
      expect(stop.location, GeoPoint(3.8333, 11.4833));
    });

    test('Trip only accepts scans when active', () {
      Trip trip(String status) => Trip.fromJson({
            'id': 't1',
            'school_id': 's1',
            'bus_id': 'b1',
            'driver_id': null,
            'direction': 'inbound',
            'status': status,
            'scheduled_start': '2026-10-30T06:30:00+00:00',
            'started_at': null,
            'ended_at': null,
          });
      expect(trip('active').acceptsScans, isTrue);
      expect(trip('scheduled').acceptsScans, isFalse);
      expect(trip('completed').acceptsScans, isFalse);
    });

    test('Subscription knows whether it is live', () {
      Subscription sub(String status) => Subscription.fromJson({
            'id': 'u1',
            'school_id': 's1',
            'student_id': 'a1',
            'semester_id': 'm1',
            'stop_id': 'p1',
            'status': status,
            'proof_path': null,
            'review_note': null,
            'reviewed_by': null,
            'reviewed_at': null,
            'created_at': '2026-10-30T10:00:00+00:00',
            'updated_at': '2026-10-30T10:00:00+00:00',
          });
      expect(sub('pending').isLive, isTrue);
      expect(sub('approved').isLive, isTrue);
      expect(sub('rejected').isLive, isFalse);
      expect(sub('expired').isLive, isFalse);
    });

    test('NewSubscription sends no status and builds the required proof path', () {
      final path = NewSubscription.proofPathFor(
        schoolId: 's1', studentId: 'a1', fileName: 'receipt.jpg');
      expect(path, 's1/a1/receipt.jpg');
      final json = NewSubscription(
        schoolId: 's1', studentId: 'a1', semesterId: 'm1', stopId: 'p1', proofPath: path,
      ).toJson();
      expect(json.containsKey('status'), isFalse);
      expect(json['proof_path'], 's1/a1/receipt.jpg');
    });

    test('LivePosition goes stale after the allowed age', () {
      final pos = LivePosition.fromJson({
        'bus_id': 'b1',
        'school_id': 's1',
        'trip_id': null,
        'location': 'POINT(11.5 3.85)',
        'speed_mps': 8,
        'heading_deg': 90.5,
        'accuracy_m': null,
        'source': 'phone',
        'recorded_at': '2026-10-30T10:00:00+00:00',
      });
      final at = pos.recordedAt;
      expect(pos.isStale(at.add(const Duration(minutes: 1))), isFalse);
      expect(pos.isStale(at.add(const Duration(minutes: 3))), isTrue);
    });

    test('Scan parses with and without a location', () {
      final base = <String, dynamic>{
        'id': 'x1',
        'school_id': 's1',
        'trip_id': 't1',
        'student_id': 'a1',
        'subscription_id': 'u1',
        'stop_id': null,
        'scanned_by': 'f1',
        'scanned_at': '2026-10-30T07:12:00+00:00',
        'location': null,
        'accuracy_m': null,
      };
      expect(Scan.fromJson(base).location, isNull);
      expect(
        Scan.fromJson({...base, 'location': 'POINT(11.5 3.85)', 'accuracy_m': 12})
            .accuracyM,
        12.0,
      );
    });

    test('models compare by value', () {
      expect(GeoPoint(1, 2), GeoPoint(1, 2));
      expect(GeoPoint(1, 2).hashCode, GeoPoint(1, 2).hashCode);
      expect(GeoPoint(1, 2), isNot(GeoPoint(2, 1)));
    });
  });

  group('ScanOutcome', () {
    test('parses an accepted scan', () {
      final outcome = ScanOutcome.fromJson({
        'valid': true,
        'duplicate': false,
        'scan_id': 'x1',
        'student': {'full_name': 'Ada', 'avatar_url': null, 'matricule': 'M-1'},
      });
      expect(outcome, isA<ScanAccepted>());
      final accepted = outcome as ScanAccepted;
      expect(accepted.duplicate, isFalse);
      expect(accepted.student.fullName, 'Ada');
    });

    test('parses a duplicate scan', () {
      final outcome = ScanOutcome.fromJson({
        'valid': true,
        'duplicate': true,
        'scan_id': null,
        'student': {'full_name': 'Ada', 'avatar_url': null, 'matricule': null},
      }) as ScanAccepted;
      expect(outcome.duplicate, isTrue);
      expect(outcome.scanId, isNull);
    });

    test('parses every refusal reason the server can return', () {
      for (final reason in [
        'invalid_code',
        'expired_code',
        'student_not_found',
        'account_not_verified',
        'no_active_subscription',
      ]) {
        final outcome = ScanOutcome.fromJson({'valid': false, 'reason': reason});
        expect(outcome, isA<ScanRefused>(), reason: reason);
        expect((outcome as ScanRefused).reason.wire, reason);
      }
    });

    test('rejects malformed payloads', () {
      expect(() => ScanOutcome.fromJson({'valid': 'yes'}), throwsFormatException);
      expect(() => ScanOutcome.fromJson({'valid': false}), throwsFormatException);
      expect(() => ScanOutcome.fromJson({'valid': true}), throwsFormatException);
    });
  });

  group('leaderboard', () {
    test('reads a row, with or without a picture', () {
      final row = LeaderboardEntry.fromJson({
        'rank': 2,
        'display_name': 'Kofi M.',
        'avatar_url': null,
        'current_streak': 4,
        'rides': 9,
        'is_me': true,
      });
      expect(row, const LeaderboardEntry(rank: 2, displayName: 'Kofi M.', currentStreak: 4, rides: 9, isMe: true));
      expect(() => LeaderboardEntry.fromJson({'rank': 1}), throwsFormatException);
    });
  });

  group('student area', () {
    test('reads the stored area and a search result', () {
      final area = StudentArea.fromJson({'label': 'Bastos', 'lat': 3.86, 'lng': 11.52, 'source': 'device', 'updated_at': '2026-11-11T08:00:00+00:00'});
      expect(area.source, AreaSource.device);
      expect(area.lat, 3.86);
      expect(PlaceResult.fromJson({'label': 'Etoudi', 'kind': 'area', 'lat': 3.9, 'lng': 11.5}).kind, PlaceKind.area);
      expect(() => PlaceResult.fromJson({'label': 'x', 'kind': 'river', 'lat': 1, 'lng': 1}), throwsFormatException);
      expect(() => AreaSource.parse('gps'), throwsFormatException);
      expect(() => PlaceResult.fromJson({'label': 'x'}), throwsFormatException);
    });
  });

  group('who runs a trip', () {
    Trip trip({String? driver, String? assistant, String? startedBy, TripStatus status = TripStatus.scheduled}) => Trip(
          id: 't',
          schoolId: 's',
          busId: 'b',
          direction: TripDirection.inbound,
          status: status,
          scheduledStart: DateTime.utc(2026, 11, 12, 7),
          driverId: driver,
          assistantId: assistant,
          startedBy: startedBy,
        );

    test('the assignee starts and ends, anyone on staff when nobody is assigned, admins always', () {
      expect(trip(driver: 'd').canRun('d', isAdmin: false), isTrue);
      expect(trip(driver: 'd').canRun('x', isAdmin: false), isFalse);
      expect(trip().canRun('x', isAdmin: false), isTrue);
      expect(trip(driver: 'd').canRun('x', isAdmin: true), isTrue);
      expect(trip(driver: 'd', startedBy: 'x', status: TripStatus.active).canRun('x', isAdmin: false), isTrue,
          reason: 'whoever started it may end it');
    });

    test('the position comes from the assignee, else whoever started the trip', () {
      expect(trip(driver: 'd').sharesPosition('d', isAdmin: false), isTrue);
      expect(trip(driver: 'd', startedBy: 'x').sharesPosition('x', isAdmin: false), isFalse);
      expect(trip(startedBy: 'x').sharesPosition('x', isAdmin: false), isTrue);
      expect(trip(startedBy: 'x').sharesPosition('y', isAdmin: false), isFalse);
    });

    test('the assistant runs the trip and shares the position like the driver (ADR 0019)', () {
      expect(trip(driver: 'd', assistant: 'a').canRun('a', isAdmin: false), isTrue);
      expect(trip(driver: 'd', assistant: 'a').canRun('d', isAdmin: false), isTrue);
      expect(trip(driver: 'd', assistant: 'a').canRun('x', isAdmin: false), isFalse);
      expect(trip(assistant: 'a').canRun('x', isAdmin: false), isFalse, reason: 'an assistant alone is still a crew');
      expect(trip(assistant: 'a').canRun('a', isAdmin: false), isTrue);
      expect(trip(driver: 'd', assistant: 'a').sharesPosition('a', isAdmin: false), isTrue);
      expect(trip(driver: 'd', assistant: 'a', startedBy: 'x').sharesPosition('x', isAdmin: false), isFalse);
      expect(trip(assistant: 'a', startedBy: 'x').sharesPosition('x', isAdmin: false), isFalse);
      expect(trip(driver: 'd', assistant: 'a').isCrew('a'), isTrue);
      expect(trip(driver: 'd', assistant: 'a').isCrew('x'), isFalse);
      expect(trip().hasNoCrew, isTrue);
      expect(trip(assistant: 'a').hasNoCrew, isFalse);
    });

    test('reads the assistant and the position holder', () {
      final parsed = Trip.fromJson({
        'id': 't', 'school_id': 's', 'bus_id': 'b', 'driver_id': 'd', 'assistant_id': 'a', 'direction': 'inbound', 'status': 'scheduled',
        'scheduled_start': '2026-11-12T07:00:00+00:00', 'started_at': null, 'ended_at': null,
      });
      expect(parsed.assistantId, 'a');
      final holder = PositionHolder.fromJson({'holder_id': 'a', 'holder_name': 'Alex', 'is_me': false, 'seconds_ago': 7});
      expect(holder, const PositionHolder(holderId: 'a', name: 'Alex', isMe: false, secondsAgo: 7));
    });

    test('reads a trip started in the field, and the choices for starting one (ADR 0020)', () {
      final field = Trip.fromJson({
        'id': 't', 'school_id': 's', 'bus_id': 'b', 'driver_id': 'd', 'assistant_id': null, 'direction': 'outbound', 'status': 'active',
        'scheduled_start': '2026-11-12T07:00:00+00:00', 'started_at': '2026-11-12T07:00:00+00:00', 'ended_at': null,
        'origin': 'field', 'created_by': 'd',
      });
      expect(field.startedInField, isTrue);
      expect(field.createdBy, 'd');
      expect(trip().startedInField, isFalse, reason: 'a trip without an origin was scheduled');

      final options = FieldTripOptions.fromJson({
        'allowed': true,
        'buses': [
          {'id': 'b1', 'plate': 'A-1', 'name': null},
          {'id': 'b2', 'plate': 'A-2', 'name': 'Express'},
        ],
        'staff': [
          {'id': 'u2', 'name': 'Dina'},
        ],
      });
      expect(options.allowed, isTrue);
      expect(options.buses.map((b) => b.label), ['A-1', 'Express']);
      expect(options.staff.single.name, 'Dina');
      expect(FieldTripOptions.fromJson({'allowed': false, 'buses': <Object>[], 'staff': <Object>[]}).allowed, isFalse);
      expect(CrewRole.assistant.wire, 'assistant');
    });

    test('reads who started it', () {
      final parsed = Trip.fromJson({
        'id': 't', 'school_id': 's', 'bus_id': 'b', 'driver_id': null, 'direction': 'inbound', 'status': 'active',
        'scheduled_start': '2026-11-12T07:00:00+00:00', 'started_at': '2026-11-12T07:02:00+00:00', 'ended_at': null,
        'started_by': 'u1',
      });
      expect(parsed.startedBy, 'u1');
    });
  });
}
