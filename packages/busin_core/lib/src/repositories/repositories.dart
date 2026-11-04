import 'dart:typed_data';

import '../geo_point.dart';
import '../models/live_position.dart';
import '../models/profile.dart';
import '../models/scan.dart';
import '../models/scan_outcome.dart';
import '../models/school.dart';
import '../models/semester.dart';
import '../models/stop.dart';
import '../models/subscription.dart';
import '../models/trip.dart';
import 'page.dart';

/// The repositories the client apps use. Every method loads only what its screen
/// needs (named columns, paginated lists) and throws a `RepositoryException` on
/// failure. Implementations live in `busin_data`; tests use fakes.
///
/// Nothing here can do what only an administrator does: people, stops, semesters,
/// buses and trips are managed in the admin portal.

abstract interface class ProfileRepository {
  /// A person's own profile. The server decides what a caller may read.
  Future<Profile> getProfile(String userId);
}

abstract interface class SchoolRepository {
  Future<School> getSchool(String schoolId);
}

abstract interface class StopsRepository {
  /// The stops students can pick from, by name. A school has tens of stops, so
  /// this is one request; apps keep the result for the session.
  Future<List<Stop>> listActiveStops();

  Future<Stop> getStop(String stopId);
}

abstract interface class SemestersRepository {
  /// The semester that includes [today] (a calendar day in the school's time
  /// zone), or null between semesters.
  Future<Semester?> currentSemester(DateTime today);

  /// The semester that starts next after [today], or null.
  Future<Semester?> nextSemester(DateTime today);
}

abstract interface class SubscriptionsRepository {
  /// A student's subscriptions, newest first.
  Future<List<Subscription>> listForStudent(
    String studentId, {
    PageRequest page = const PageRequest(),
  });

  /// The pending or approved subscription of [studentId] in [semesterId], or null.
  Future<Subscription?> liveForSemester({
    required String studentId,
    required String semesterId,
  });

  /// Sends a request. The status is always pending; staff decide in the portal.
  Future<Subscription> request(NewSubscription subscription);
}

abstract interface class QrRepository {
  /// The student's boarding secret. Keep it in secure storage; the code is
  /// derived on the device with `QrCodeGenerator`.
  Future<Uint8List> fetchSecret();

  /// Replaces the secret, which makes codes made from the old one stop working.
  Future<Uint8List> rotateSecret();
}

abstract interface class TripsRepository {
  /// Trips a driver is assigned to that start within [from] and [to], soonest first.
  Future<List<Trip>> listForDriver(
    String driverId, {
    required DateTime from,
    required DateTime to,
  });

  Future<Trip> getTrip(String tripId);
}

abstract interface class ScansRepository {
  /// Submits a scanned code. A refusal that staff should see (bad code, no
  /// subscription) is a [ScanRefused] result; a problem with the caller or the
  /// trip is a `RepositoryException`.
  Future<ScanOutcome> recordScan({
    required String tripId,
    required String code,
    String? stopId,
    GeoPoint? location,
    double? accuracyMeters,
  });

  /// The boardings of one trip, newest first.
  Future<List<Scan>> listForTrip(
    String tripId, {
    PageRequest page = const PageRequest(),
  });
}

abstract interface class LivePositionsRepository {
  /// The last known position of a bus, or null if it has not reported.
  Future<LivePosition?> latestForBus(String busId);

  /// Positions of one bus as they arrive. The subscription is filtered to that
  /// bus, never to the whole table.
  Stream<LivePosition> watchBus(String busId);
}
