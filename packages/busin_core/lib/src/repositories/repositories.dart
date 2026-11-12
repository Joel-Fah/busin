import '../enums.dart';
import '../models/academic.dart';
import 'dart:typed_data';

import '../geo_point.dart';
import '../models/bus.dart';
import '../models/field_trip.dart';
import '../models/joining.dart';
import '../models/position_holder.dart';
import '../models/live_position.dart';
import '../models/notification_preferences.dart';
import '../models/profile.dart';
import '../models/rider_key.dart';
import '../models/manifest_entry.dart';
import '../models/scan.dart';
import '../models/scan_outcome.dart';
import '../models/school.dart';
import '../models/semester.dart';
import '../models/stop.dart';
import '../models/streak.dart';
import '../models/student_area.dart';
import '../models/subscription.dart';
import '../models/subscription_event.dart';
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

/// Streaks (opt-in). Turning them on also puts the student on their school's leaderboard.
abstract interface class StreaksRepository {
  Future<void> setOptIn(bool on);

  /// The student's days of a semester, from the day they opted in; empty when they have not.
  Future<List<RideDay>> rideDays(String semesterId);

  /// Null when the student has not opted in.
  Future<Streak?> streak(String semesterId);

  /// The school's board for a semester, best streaks first, with the caller's own row always included.
  Future<List<LeaderboardEntry>> leaderboard(String semesterId, {int limit = 50});
}

/// The student's own area (ADR 0013). Nobody else reads it; the school only sees counts per zone.
abstract interface class AreaRepository {
  /// Null when the student has not given one.
  Future<StudentArea?> myArea();

  /// Stores the area; the server snaps the point to about 500 m. [Invalid] when it is too far from the school's buses.
  Future<void> setArea({required double lat, required double lng, required String label, required AreaSource source});

  Future<void> clearArea();

  /// Places of the school's area matching [query] (from OpenStreetMap, searched on the server). [NotAllowed] when the
  /// student searched too much in a short time.
  Future<List<PlaceResult>> searchPlaces(String query);
}

/// The student's notification preferences. Reads give the defaults until something is saved.
abstract interface class NotificationPreferencesRepository {
  Future<NotificationPreferences> load();
  Future<void> save(NotificationPreferences preferences);
}

/// Joining a school without a school email (ADR 0012). Only a pending account uses it.
abstract interface class JoinRepository {
  /// The schools that accept the signed-in account's email, by name.
  Future<List<OpenSchool>> listOpenSchools();

  /// The account's own request, or null when the account is not waiting for a school.
  Future<JoinRequest?> myRequest();

  /// Asks to join [schoolId], or withdraws the request when it is null.
  Future<void> requestSchool(String? schoolId);
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

  /// Everything that happened to these subscriptions (the student's own), oldest first.
  Future<List<SubscriptionEvent>> eventsFor(List<String> subscriptionIds);
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

  /// Staff only: today's riders with their day keys, to check codes offline (ADR 0014). Each call is audited.
  Future<List<RiderKey>> staffDayKeys();
}

abstract interface class TripsRepository {
  /// Trips a staff member is on the crew of (as the driver or the assistant) that start within [from] and [to],
  /// soonest first.
  Future<List<Trip>> listForCrew(
    String staffId, {
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

  /// The school's trips scheduled within [from] and [to] (a school day), soonest first, at most 100.
  Future<List<Trip>> listBetween({required DateTime from, required DateTime to});

  /// Starts a scheduled trip of today (ops app). [NotAllowed] when it is assigned to someone else; [Conflict] when
  /// it is not scheduled, not today, or its bus is already on another trip.
  Future<void> start(String tripId);

  /// What the app needs to start a trip nobody scheduled: whether the school allows it, the free buses and the
  /// colleagues to choose from (staff only).
  Future<FieldTripOptions> fieldTripOptions();

  /// Starts a trip nobody scheduled (ADR 0020) and returns its id. [role] is what the caller is on it; [otherId] is
  /// the other crew member, if any. [NotAllowed] when the school has it off or the daily limit is reached (see
  /// [RepositoryException.reason]: `field_trips_off`, `too_many_field_trips`); [Conflict] when the bus is out of
  /// service or busy, or a scheduled trip exists today for it (`bus_out_of_service`, `bus_busy`,
  /// `use_scheduled_trip`); [Invalid] for a crew member who cannot be picked (`invalid_crew`).
  Future<String> startFieldTrip({
    required String busId,
    required TripDirection direction,
    required CrewRole role,
    String? otherId,
  });

  /// Ends a running trip (ops app).
  Future<void> end(String tripId);

  /// Who has boarded the trip, newest first (staff).
  Future<List<ManifestEntry>> manifest(String tripId);
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
  /// trip is a `RepositoryException`. A scan made offline and sent later carries [scannedAt] (when it was made, checked against
  /// the code) and [clientId] (the phone's own id for it, so sending it twice records it once).
  Future<ScanOutcome> recordScan({
    required String tripId,
    required String code,
    String? stopId,
    GeoPoint? location,
    double? accuracyMeters,
    DateTime? scannedAt,
    String? clientId,
  });

  /// A student's own boardings, newest first. The server returns only the caller's own.
  Future<List<Scan>> listForStudent(
    String studentId, {
    PageRequest page = const PageRequest(),
  });

  /// The student's newest boarding, then each new one as it is recorded (Realtime, one row, own rows only). Null when
  /// there is none yet.
  Stream<Scan?> watchLatestForStudent(String studentId);

  /// How many times the student boarded since [since] (for "your 10th ride this semester").
  Future<int> countForStudentSince(String studentId, DateTime since);

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

  /// Sends the bus position from the phone on board (ops driver mode). Returns false when the server dropped it (too
  /// soon after the last one, or too imprecise). [NotAllowed] for anyone but the person sharing this trip's bus.
  Future<bool> publish({
    required String tripId,
    required GeoPoint position,
    double? speedMps,
    double? headingDeg,
    double? accuracyM,
  });

  /// Whose phone leads the position of this trip right now, or null when nobody does (staff only). Used by the crew's
  /// app to say whether to keep sharing or stand by.
  Future<PositionHolder?> positionHolder(String tripId);
}
