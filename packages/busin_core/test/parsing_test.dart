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
        'name': 'Mendong',
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
}
