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
import 'trip_providers.dart';

/// Today's trips at the school: the ones assigned to me first. Tapping one opens it to start, scan or end it.
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

    Future<void> refresh() async {
      ref.invalidate(todayTripsProvider);
      await ref.read(todayTripsProvider.future).catchError((Object _) => const <Trip>[]);
    }

    Widget section(String title, List<Trip> list) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: BusinSpace.x5, bottom: BusinSpace.x2),
              child: Text(title, style: text.titleSmall?.copyWith(color: p.muted)),
            ),
            for (final trip in list)
              Padding(
                padding: const EdgeInsets.only(bottom: BusinSpace.x3),
                child: TripCard(trip: trip, bus: buses[trip.busId], zone: zone, onTap: () => context.push(Routes.trip(trip.id))),
              ),
          ],
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.opsTodayTitle),
        actions: [
          IconButton(
            tooltip: l10n.actionSignOut,
            icon: HugeIcon(icon: HugeIcons.strokeRoundedLogout01, color: p.fg),
            onPressed: () async {
              // Scans still on the phone must reach the server first: they are never dropped.
              final pending = ref.read(pendingCountProvider).value ?? 0;
              if (pending > 0) {
                BusinToast.show(context, l10n.opsSignOutPending(pending), tone: ToastTone.warning);
                return;
              }
              await ref.read(signOutProvider)();
            },
          ),
        ],
      ),
      body: SafeArea(
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
                if (list.isEmpty || me == null) {
                  return ListView(children: [EmptyState(illustration: BusinIllustration.busStop, title: l10n.opsTodayEmpty)]);
                }
                final split = splitTrips(list, me.userId);
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: BusinSpace.x5, vertical: BusinSpace.x2),
                  children: [
                    if (split.mine.isNotEmpty) section(l10n.opsTodayMine, split.mine),
                    if (split.others.isNotEmpty) section(l10n.opsTodayOthers, split.others),
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
  const TripCard({super.key, required this.trip, required this.bus, required this.zone, required this.onTap});

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
    final time = MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(const SchoolClock().wallClock(zone, trip.scheduledStart)));
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
