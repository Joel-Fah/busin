import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/access.dart';
import '../bus/bus_providers.dart';
import '../providers.dart';
import '../subscription/subscription_providers.dart';
import 'tab_badges.dart';

/// A dot on My bus while a trip runs that the student has not looked at yet. Checked when the app opens and each time
/// it comes back to the front (one small read of the running trips); a "trip started" notification marks it too. Seeing
/// the trips on My bus clears it. Kept in memory: a new session shows the dot again for a trip still running.
class BusTabNews extends Notifier<int> {
  final _seen = <String>{};

  @override
  int build() {
    ref.watch(authUserIdProvider);
    _seen.clear();
    final listener = AppLifecycleListener(onResume: check);
    ref.onDispose(listener.dispose);
    Future.microtask(check);
    return 0;
  }

  Future<void> check() async {
    if (ref.read(accessProvider) is! Allowed) return;
    try {
      // Only for a student who may follow buses; the tab would otherwise open on "subscribe first".
      if (!await ref.read(livePositionsRepositoryProvider).canFollowBuses()) return;
      final running = await ref.read(tripsRepositoryProvider).listActive();
      if (!ref.mounted) return;
      if (running.any((t) => !_seen.contains(t.id))) ref.read(tabBadgesProvider.notifier).mark({StudentTabs.bus});
    } on Object {
      // Offline or refused: no dot, and nothing to say about it.
    }
  }

  /// The student is looking at these trips on My bus.
  void seen(Iterable<String> tripIds) => _seen.addAll(tripIds);
}

final busTabNewsProvider = NotifierProvider<BusTabNews, int>(BusTabNews.new);
