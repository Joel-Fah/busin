import 'dart:async';

import 'package:busin_app/busin_app.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../trips/my_trips_providers.dart';
import '../trips/trip_providers.dart';

/// The staff member's tabs, in the order of the shell's destinations.
abstract final class OpsTabs {
  static const trips = 0;
  static const history = 1;
  static const stats = 2;
  static const profile = 3;
}

/// The tabs with news waiting (see [TabBadges]). Starts empty again for each person who signs in.
class OpsTabBadges extends TabBadges {
  @override
  Set<int> build() {
    ref.watch(authUserIdProvider);
    return super.build();
  }
}

final tabBadgesProvider = NotifierProvider<OpsTabBadges, Set<int>>(OpsTabBadges.new);

/// While someone is signed in, listens for trips put on their crew (an administrator assigning or moving one, a colleague
/// starting one in the field with them): the trip lists are read again and the Trips tab gets a dot when it is not on
/// screen. Push says the same when the app is closed; this is the cheap path while it is open (changes only, filtered to
/// this person's trips).
class CrewNewsBinder extends ConsumerStatefulWidget {
  const CrewNewsBinder({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<CrewNewsBinder> createState() => _CrewNewsBinderState();
}

class _CrewNewsBinderState extends ConsumerState<CrewNewsBinder> {
  StreamSubscription<String>? _feed;

  @override
  void initState() {
    super.initState();
    final userId = ref.read(authUserIdProvider).value;
    if (userId == null) return;
    _feed = ref.read(tripsRepositoryProvider).watchCrewNews(userId).listen((_) {
      if (!mounted) return;
      ref.invalidate(todayTripsProvider);
      ref.invalidate(upcomingTripsProvider);
      ref.read(tabBadgesProvider.notifier).mark(const [OpsTabs.trips]);
    }, onError: (Object _) {
      // A convenience: if it drops, the lists still refresh when they are opened or pulled.
    });
  }

  @override
  void dispose() {
    _feed?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
