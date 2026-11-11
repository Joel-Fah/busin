import 'dart:async';

import 'package:busin_app/busin_app.dart';
import 'package:busin_core/busin_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator_android/geolocator_android.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';

import '../access.dart';
import '../keys/roster.dart';
import '../providers.dart';
import '../queue/scan_queue.dart';
import '../queue/scan_sync.dart';

final qrRepositoryProvider = Provider<QrRepository>((ref) => ref.watch(repositoriesProvider).qr);
final scansRepositoryProvider = Provider<ScansRepository>((ref) => ref.watch(repositoriesProvider).scans);
final stopsRepositoryProvider = Provider<StopsRepository>((ref) => ref.watch(repositoriesProvider).stops);


/// The scan queue on this phone. One for the app's life; it outlives sign-outs on purpose (scans are never dropped).
final scanQueueProvider = Provider<ScanQueue>((ref) {
  final queue = DriftScanQueue();
  ref.onDispose(queue.close);
  return queue;
});

/// Today's riders with their day keys (ADR 0014). Loaded from the phone, and downloaded when there is none for today.
class RosterNotifier extends AsyncNotifier<Roster?> {
  @override
  Future<Roster?> build() async {
    final access = ref.watch(accessProvider);
    if (access is! OpsAllowed) return null;
    final saved = await ref.read(rosterStoreProvider).load(access.profile.id);
    if (saved != null && saved.isFor(await _today())) return saved;
    try {
      return await _download(access.profile.id);
    } on Offline {
      return saved != null && saved.isFor(await _today()) ? saved : null;
    }
  }

  Future<DateTime> _today() async {
    final school = await ref.read(schoolProvider.future);
    return ref.read(schoolClockProvider).today(school.timezone, now: ref.read(nowProvider)());
  }

  Future<Roster> _download(String userId) async {
    final riders = await ref.read(qrRepositoryProvider).staffDayKeys();
    final roster = Roster.fromDownload(riders, today: await _today(), now: ref.read(nowProvider)());
    await ref.read(rosterStoreProvider).save(userId, roster);
    return roster;
  }

  /// Downloads today's list again (pull to refresh, on reconnect, or the button).
  Future<void> refresh() async {
    final access = ref.read(accessProvider);
    if (access is! OpsAllowed) return;
    final roster = await _download(access.profile.id);
    state = AsyncData(roster);
  }
}

final rosterProvider = AsyncNotifierProvider<RosterNotifier, Roster?>(RosterNotifier.new);

/// The school's stops, read once for the session (to tag each scan with its stop).
final stopsProvider = FutureProvider<List<Stop>>((ref) async {
  if (ref.watch(accessProvider) is! OpsAllowed) return const [];
  return ref.watch(stopsRepositoryProvider).listActiveStops();
}, retry: noAutomaticRetry);

/// How many scans wait to be sent.
final pendingCountProvider = StreamProvider<int>((ref) => ref.watch(scanQueueProvider).watchPendingCount());

/// This phone's scans of one trip.
final tripScansProvider = FutureProvider.autoDispose.family<List<QueuedScan>, String>(
  (ref, tripId) => ref.watch(scanQueueProvider).forTrip(tripId),
);

final scanSyncerProvider = Provider<ScanSyncer>(
  (ref) => ScanSyncer(queue: ref.watch(scanQueueProvider), scans: ref.watch(scansRepositoryProvider)),
);

/// Sends what waits whenever it can: on start, every 30 seconds while the app runs, and when the connection comes back
/// (then today's list is refreshed too). Watched by the signed-in screens.
final syncLoopProvider = Provider<void>((ref) {
  if (ref.watch(accessProvider) is! OpsAllowed) return;
  final syncer = ref.watch(scanSyncerProvider);
  Future<void> send() async {
    await syncer.run();
  }

  unawaited(send());
  final timer = Timer.periodic(const Duration(seconds: 30), (_) => send());
  ref.onDispose(timer.cancel);
  ref.listen(connectivityProvider, (previous, next) {
    if (next.value == true && previous?.value != true) {
      unawaited(send());
      unawaited(ref.read(rosterProvider.notifier).refresh().catchError((Object _) {}));
    }
  });
});

/// One position reading. Speed (m/s) and heading (degrees) when the phone knows them.
typedef Fix = ({GeoPoint point, double accuracy, double? speed, double? heading});

Fix _fix(Position p) => (
      point: GeoPoint(p.latitude, p.longitude),
      accuracy: p.accuracy,
      speed: p.speed >= 0 ? p.speed : null,
      heading: p.heading >= 0 ? p.heading : null,
    );

/// The phone's position while the scanner is open, for the stop of each scan. Asked for only there, after an
/// explanation (busin-security: location in the ops app only while scanning or driving).
abstract interface class LocationFeed {
  Future<bool> hasPermission();
  Future<bool> requestPermission();
  Stream<Fix> watch();

  /// Positions while driving, also with the screen off: a foreground service with a visible notification
  /// ([title], [text]) keeps them coming. Stops when the subscription is cancelled.
  Stream<Fix> watchDriving({required String title, required String text});
}

class DeviceLocationFeed implements LocationFeed {
  GeolocatorPlatform get _geo => GeolocatorPlatform.instance;

  @override
  Future<bool> hasPermission() async {
    final p = await _geo.checkPermission();
    return p == LocationPermission.whileInUse || p == LocationPermission.always;
  }

  @override
  Future<bool> requestPermission() async {
    if (!await _geo.isLocationServiceEnabled()) return false;
    final p = await _geo.requestPermission();
    return p == LocationPermission.whileInUse || p == LocationPermission.always;
  }

  @override
  Stream<Fix> watch() =>
      _geo.getPositionStream(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10)).map(_fix);

  @override
  Stream<Fix> watchDriving({required String title, required String text}) => _geo
      .getPositionStream(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
          intervalDuration: const Duration(seconds: 5),
          foregroundNotificationConfig: ForegroundNotificationConfig(
            notificationTitle: title,
            notificationText: text,
            notificationChannelName: title,
            enableWakeLock: true,
            setOngoing: true,
          ),
        ),
      )
      .map(_fix);
}

final locationFeedProvider = Provider<LocationFeed>((ref) => DeviceLocationFeed());
