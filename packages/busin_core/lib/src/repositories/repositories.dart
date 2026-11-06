import '../models/academic.dart';
import 'dart:typed_data';

import '../geo_point.dart';
import '../models/bus.dart';
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

  /// Saves the fields a person may change about themselves and returns the profile as the server now has it. Role,
  /// status and school cannot be sent from here (see `Profile.editableJson`), and the server refuses them anyway.
  Future<Profile> updateProfile(
    String userId, {
    String? fullName,
    String? phone,
    String? matricule,
    AcademicChoice? academic,
  });
}

abstract interface class AcademicRepository {
  /// The faculties, departments and degree levels of the caller's school. Small lists: one read, kept for the session.
  Future<AcademicUnits> load();
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

  /// This student's subscriptions: what there is now, then again whenever one changes (approved, rejected, ended).
  /// Filtered to the student's own rows on the server, and delivered only while someone listens.
  Stream<List<Subscription>> watchForStudent(String studentId);
}

/// What a proof of payment may be. The `proofs` bucket enforces the same limits on the server.
abstract final class ProofRules {
  static const maxBytes = 5 * 1024 * 1024;
  static const contentTypes = ['image/jpeg', 'image/png', 'image/webp'];
}

abstract interface class ProofsRepository {
  /// Stores a payment proof in the student's own folder of the private `proofs` bucket and returns its
  /// path, to be sent with the subscription request. Throws [Invalid] for a type or size the bucket
  /// refuses. A file is never replaced: a new request uploads a new file.
  Future<String> upload({
    required String schoolId,
    required String studentId,
    required Uint8List bytes,
    required String contentType,
  });

  /// A short-lived address for showing a stored proof. The bucket is private, so there is no public URL.
  Future<String> signedUrl(String path, {Duration expiresIn = const Duration(minutes: 10)});
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

  /// The trips running right now at the caller's school, most recently started first. A school runs a
  /// handful at a time; the list is capped at [PageRequest.defaultLimit].
  Future<List<Trip>> listActive();

  /// The trips with these ids, in no particular order. At most [PageRequest.maxLimit] ids at a time;
  /// ids a caller may not read are left out.
  Future<List<Trip>> listByIds(List<String> tripIds);
}

abstract interface class DeviceTokensRepository {
  /// Registers this phone's push token for the signed-in user, or refreshes it. A token another user held moves
  /// to the caller (a token follows the phone). [platform] is `android` or `ios`, [locale] is `en` or `fr`.
  /// Throws [NotAllowed] for an account that is not verified.
  Future<void> register({required String token, required String platform, required String locale});

  /// Forgets this phone's token for the signed-in user (on sign-out). Not an error if it is already gone.
  Future<void> unregister(String token);
}

abstract interface class BusesRepository {
  /// The buses with these ids (for plates on a map or a list). At most [PageRequest.maxLimit] at a time.
  Future<List<Bus>> listByIds(List<String> busIds);
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

  /// A student's own boardings, newest first. The server returns only the caller's own.
  Future<List<Scan>> listForStudent(
    String studentId, {
    PageRequest page = const PageRequest(),
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

  /// Whether this person may follow buses live: an approved subscription covering today, or staff. The database
  /// decides (and enforces it on the positions themselves); this is how an app learns the answer.
  Future<bool> canFollowBuses();
}
