import 'package:busin_app/busin_app.dart';
import 'package:busin_core/busin_core.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../providers.dart';
import '../router.dart';
import '../scan/scan_providers.dart';
import '../access.dart';
import 'field_trip_sheet.dart';
import 'my_trips_providers.dart';
import 'trip_providers.dart';

/// My trips: today's (an administrator also sees the school's other trips of today), then the ones coming up in the next
/// weeks, grouped by week. Tapping one opens it to start, scan or end it.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = BusinL10n.of(context);
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final me = staffOf(ref.watch(accessProvider));
    // While signed in, scans waiting on the phone are sent whenever possible.
    ref.watch(syncLoopProvider);
    ref.watch(pendingCountProvider);
    final trips = ref.watch(todayTripsProvider);
    final buses = ref.watch(todayBusesProvider).value ?? const <String, Bus>{};
    final zone = ref.watch(schoolProvider).value?.timezone ?? 'UTC';
    final access = ref.watch(accessProvider);
    final profile = access is OpsAllowed ? access.profile : null;
    final upcoming = ref.watch(upcomingTripsProvider).value ?? const <Trip>[];
    final upcomingBuses = ref.watch(upcomingBusesProvider).value ?? const <String, Bus>{};
    final thisMonday = ref.watch(thisMondayProvider);
    final bottom = BusinScope.of(context).bottomInset;

    // A trip nobody scheduled can be started from here, when the school allows it (ADR 0020).
    final fieldAllowed = ref.watch(fieldTripOptionsProvider).value?.allowed ?? false;

    Future<void> startField() async {
      // Fresh choices each time: buses come and go as trips start and end.
      ref.invalidate(fieldTripOptionsProvider);
      final tripId = await showBusinSheet<String>(context, builder: (context) => const FieldTripSheet());
      if (tripId == null || !context.mounted) return;
      ref.invalidate(todayTripsProvider);
      ref.read(shareOfferProvider.notifier).offer(tripId);
      BusinToast.show(context, l10n.opsFieldStarted, tone: ToastTone.success);
      context.push(Routes.trip(tripId));
    }

    Future<void> refresh() async {
      ref.invalidate(fieldTripOptionsProvider);
      ref.invalidate(todayTripsProvider);
      ref.invalidate(upcomingTripsProvider);
      await ref.read(todayTripsProvider.future).catchError((Object _) => const <Trip>[]);
    }

    Widget section(String title, List<Trip> list, {Map<String, Bus>? busesOf, bool withDay = false}) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: BusinSpace.x5, bottom: BusinSpace.x2),
              child: Text(title, style: text.titleSmall?.copyWith(color: p.muted)),
            ),
            for (final trip in list)
              Padding(
                padding: const EdgeInsets.only(bottom: BusinSpace.x3),
                child: TripCard(trip: trip, bus: (busesOf ?? buses)[trip.busId], zone: zone, withDay: withDay, onTap: () => context.push(Routes.trip(trip.id))),
              ),
          ],
        );

    // The trips ahead, one section per week.
    List<Widget> comingUp() => [
          Padding(
            padding: const EdgeInsets.only(top: BusinSpace.x6),
            child: Text(l10n.opsUpcomingTitle, style: text.titleMedium),
          ),
          if (upcoming.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: BusinSpace.x2),
              child: Text(l10n.opsUpcomingEmpty, style: text.bodyMedium?.copyWith(color: p.muted)),
            ),
          for (final week in groupByWeek(upcoming, (Trip t) => t.scheduledStart, zone: zone))
            section(weekLabel(context, week.monday, thisMonday: thisMonday), week.items, busesOf: upcomingBuses, withDay: true),
        ];

    return Scaffold(
      floatingActionButton: fieldAllowed
          ? Padding(
              // Above the floating tab bar.
              padding: EdgeInsets.only(bottom: bottom),
              child: FloatingActionButton.extended(
                onPressed: startField,
                icon: HugeIcon(icon: HugeIcons.strokeRoundedBus01, color: p.fg),
                label: Text(l10n.opsFieldStart),
              ),
            )
          : null,
      appBar: AppBar(
        title: Text(l10n.opsTodayTitle),
        actions: [
          // The profile holds the settings, the legal texts and signing out; the button is the person's own picture.
          IconButton(
            tooltip: l10n.opsProfileOpen,
            icon: profile == null
                ? HugeIcon(icon: HugeIcons.strokeRoundedUserCircle, color: p.fg)
                : UserAvatar(name: profile.fullName, email: profile.email, imageUrl: profile.avatarUrl, size: 32),
            onPressed: () => context.go(Routes.profile),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: ContentColumn(
          child: RefreshIndicator(
            onRefresh: refresh,
            child: trips.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => ListView(
                children: [
                  EmptyState(
                    illustration: BusinIllustration.waiting,
                    title: l10n.errorGeneric,
                    action: BusinButton(label: l10n.actionRetry, onPressed: refresh),
                  ),
                ],
              ),
              data: (list) {
                if (me == null) return const SizedBox.shrink();
                final split = splitTrips(list, me.userId);
                // Staff only receive their own trips from the server; the others of today are an administrator's view.
                final others = me.isAdmin ? split.others : const <Trip>[];
                final since = ref.watch(offlineSinceProvider);
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  // Room under the last card for the floating tab bar and the button that starts a trip nobody scheduled.
                  padding: EdgeInsets.fromLTRB(BusinSpace.x5, BusinSpace.x2, BusinSpace.x5, 96 + bottom),
                  children: [
                    // Without a connection the list is the copy saved on the phone; scanning still works.
                    if (since != null)
                      Padding(
                        padding: const EdgeInsets.only(top: BusinSpace.x3),
                        child: Notice(
                          tone: StatusTone.warn,
                          icon: HugeIcons.strokeRoundedWifiDisconnected01,
                          title: l10n.offlineTitle,
                          child: Text(l10n.opsOfflineBody(savedWhen(context, since))),
                        ),
                      ),
                    if (split.mine.isNotEmpty) section(l10n.opsTodayMine, split.mine),
                    if (split.mine.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: BusinSpace.x5),
                        child: Text(me.isAdmin && others.isEmpty ? l10n.opsTodayEmpty : l10n.opsTodayEmptyMine, style: text.bodyMedium?.copyWith(color: p.muted)),
                      ),
                    if (others.isNotEmpty) section(l10n.opsTodayOthers, others),
                    ...comingUp(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// One trip in the list: when it leaves, which way, which bus, and where it stands.
class TripCard extends StatelessWidget {
  const TripCard({super.key, required this.trip, required this.bus, required this.zone, required this.onTap, this.withDay = false});

  /// Say the day too (a trip that is not today's).
  final bool withDay;

  final Trip trip;
  final Bus? bus;

  /// The school's time zone: departure times are shown as they are at the school.
  final String zone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final material = MaterialLocalizations.of(context);
    final wall = const SchoolClock().wallClock(zone, trip.scheduledStart);
    final clock = material.formatTimeOfDay(TimeOfDay.fromDateTime(wall));
    // A trip of another day says which: "Tue, Nov 17, 7:30".
    final time = withDay ? '${material.formatMediumDate(wall)}, $clock' : clock;
    return BusinCard(
      onTap: onTap,
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(BusinRadius.sm)),
            child: Padding(padding: const EdgeInsets.all(BusinSpace.x3), child: HugeIcon(icon: HugeIcons.strokeRoundedBus01, size: 22, color: p.fg)),
          ),
          const SizedBox(width: BusinSpace.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bus?.label ?? '', style: text.titleMedium),
                Text('${l10n.direction(trip.direction)} · ${l10n.opsDeparts(time)}', style: text.bodySmall?.copyWith(color: p.muted)),
              ],
            ),
          ),
          StatusChip(label: l10n.tripStatus(trip.status), tone: tripTone(trip.status)),
        ],
      ),
    );
  }
}

/// "12 Nov 2026, 06:05": when the saved copy was made, in the phone's own clock and language.
String savedWhen(BuildContext context, DateTime savedAt) {
  final material = MaterialLocalizations.of(context);
  final local = savedAt.toLocal();
  return '${material.formatMediumDate(local)}, ${material.formatTimeOfDay(TimeOfDay.fromDateTime(local), alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context))}';
}
