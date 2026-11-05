/// Supabase implementations of the `busin_core` repository interfaces.
///
/// The only package that talks to the backend. Every query names its columns and
/// paginates its lists; failures reach apps as `RepositoryException`s.
library;

import 'package:busin_core/busin_core.dart';
import 'package:supabase/supabase.dart';

import 'src/repositories.dart';

export 'src/error_mapping.dart' show mapError;
export 'src/repositories.dart';

/// All the repositories on one signed-in client. Apps expose each as a provider,
/// so tests replace it with a fake.
class SupabaseRepositories {
  SupabaseRepositories(SupabaseClient client)
      : profiles = SupabaseProfileRepository(client),
        schools = SupabaseSchoolRepository(client),
        stops = SupabaseStopsRepository(client),
        semesters = SupabaseSemestersRepository(client),
        subscriptions = SupabaseSubscriptionsRepository(client),
        proofs = SupabaseProofsRepository(client),
        qr = SupabaseQrRepository(client),
        trips = SupabaseTripsRepository(client),
        buses = SupabaseBusesRepository(client),
        deviceTokens = SupabaseDeviceTokensRepository(client),
        scans = SupabaseScansRepository(client),
        livePositions = SupabaseLivePositionsRepository(client);

  final ProfileRepository profiles;
  final SchoolRepository schools;
  final StopsRepository stops;
  final SemestersRepository semesters;
  final SubscriptionsRepository subscriptions;
  final ProofsRepository proofs;
  final QrRepository qr;
  final TripsRepository trips;
  final BusesRepository buses;
  final DeviceTokensRepository deviceTokens;
  final ScansRepository scans;
  final LivePositionsRepository livePositions;
}
