import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../access.dart';
import '../providers.dart';
import '../scan/scan_providers.dart';
import 'position_publisher.dart';

final livePositionsRepositoryProvider = Provider((ref) => ref.watch(repositoriesProvider).livePositions);

typedef DriveState = ({ShareStatus status, DateTime? lastSentAt});

/// Sharing the bus position for one trip (driver mode). Kept while the app runs, whatever screen is open; the
/// foreground service keeps the readings coming with the screen off. Stops on sign-out, when the trip ends, or when
/// the server refuses.
class DriverMode extends Notifier<DriveState> {
  DriverMode(this.tripId);

  final String tripId;
  StreamSubscription<Fix>? _sub;
  PositionPublisher? _publisher;

  @override
  DriveState build() {
    ref.onDispose(_cancel);
    ref.listen(accessProvider, (_, next) {
      if (next is! OpsAllowed) stop();
    });
    return (status: ShareStatus.stopped, lastSentAt: null);
  }

  bool get isOn => state.status != ShareStatus.stopped;

  /// Starts sharing. Returns false when location is not allowed (nothing starts then).
  Future<bool> start({required String title, required String text}) async {
    if (isOn) return true;
    final feed = ref.read(locationFeedProvider);
    if (!await feed.hasPermission() && !await feed.requestPermission()) return false;
    final publisher = PositionPublisher(tripId: tripId, positions: ref.read(livePositionsRepositoryProvider), now: ref.read(nowProvider));
    publisher.onChange = () {
      state = (status: publisher.status, lastSentAt: publisher.lastSentAt);
      if (publisher.status == ShareStatus.stopped) _cancel();
    };
    _publisher = publisher;
    state = (status: ShareStatus.sharing, lastSentAt: null);
    _sub = feed.watchDriving(title: title, text: text).listen((fix) => publisher.offer(fix), onError: (Object _) {
      state = (status: ShareStatus.waiting, lastSentAt: state.lastSentAt);
    });
    return true;
  }

  void stop() {
    _cancel();
    state = (status: ShareStatus.stopped, lastSentAt: state.lastSentAt);
  }

  void _cancel() {
    _sub?.cancel();
    _sub = null;
    _publisher?.onChange = null;
    _publisher = null;
  }
}

final driverModeProvider = NotifierProvider.family<DriverMode, DriveState, String>(DriverMode.new);
