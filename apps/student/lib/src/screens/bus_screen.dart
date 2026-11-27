import 'dart:async';

import 'package:busin_core/busin_core.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../bus/bus_providers.dart';
import '../bus/eta.dart';
import '../bus/bus_updates.dart';
import '../bus/map_legend.dart';
import '../bus/map_scene.dart';
import '../bus/my_location.dart';
import '../bus/show_me.dart';
import '../bus/update_strip.dart';
import '../qr/qr_providers.dart';
import '../router.dart';
import '../subscription/subscription_providers.dart';

/// The fourth tab: where the bus is. The buses on a trip right now, the live position of the chosen one on a map,
/// and the stops with the student's own marked. The position arrives through a subscription filtered to that one bus.
class BusScreen extends ConsumerStatefulWidget {
  const BusScreen({super.key});

  @override
  ConsumerState<BusScreen> createState() => _BusScreenState();
}

class _BusScreenState extends ConsumerState<BusScreen> {
  final _recenter = ValueNotifier<int>(0);
  final _busInView = ValueNotifier<bool>(false);
  Timer? _timer;
  bool? _active;
  int _ticks = 0;

  /// The bus on screen, to notice when its trip ends.
  RunningBus? _shown;

  /// "The trip has ended", when the followed trip stopped running while the tab was open.
  BusUpdate? _ended;

  @override
  void initState() {
    super.initState();
    // "Updated 12 s ago" needs to keep counting between positions.
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      setState(() {});
      // Once a minute while a bus is followed: read the running trips again, to learn when this one ends.
      if (++_ticks % 12 == 0 && (_active ?? true) && _shown != null) ref.invalidate(runningBusesProvider);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Tabs that are not showing have animations switched off; use that to know when this one is on screen.
    final active = TickerMode.valuesOf(context).enabled;
    // Coming back to the tab: a trip may have started or ended meanwhile.
    // After this frame: a provider cannot be changed while the tree is building.
    if (active && _active == false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.invalidate(canFollowBusesProvider);
          ref.invalidate(runningBusesProvider);
        }
      });
    }
    _active = active;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recenter.dispose();
    _busInView.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final canFollow = ref.watch(canFollowBusesProvider);
    // Not subscribed: say so and lead to the subscription, instead of an empty map. (The database refuses the
    // positions anyway; this is the explanation.)
    if (canFollow.hasValue && !canFollow.requireValue) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          EmptyState(
            icon: HugeIcons.strokeRoundedBus01,
            title: l10n.busLockedTitle,
            body: l10n.busLockedBody,
            action: BusinButton(label: l10n.busLockedAction, onPressed: () => context.go(Routes.subscription)),
          ),
        ],
      );
    }
    if (canFollow.hasError) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          EmptyState(
            icon: HugeIcons.strokeRoundedWifiDisconnected01,
            title: canFollow.error is RepositoryException ? l10n.failure(canFollow.error! as RepositoryException) : l10n.errorGeneric,
            action: BusinButton(label: l10n.actionRetry, onPressed: () => ref.invalidate(canFollowBusesProvider)),
          ),
        ],
      );
    }
    if (!canFollow.hasValue) return const Center(child: CircularProgressIndicator());
    final running = ref.watch(runningBusesProvider);
    _shown = ref.watch(currentBusProvider).value ?? _shown;
    // The followed trip is no longer running: say so (on the next bus, or above "no bus is running").
    ref.listen(runningBusesProvider, (previous, next) {
      final shown = _shown;
      final buses = next.value;
      if (shown == null || buses == null || buses.any((b) => b.trip.id == shown.trip.id)) return;
      final now = ref.read(nowProvider)();
      ref.read(busUpdateLogProvider.notifier).forget(shown.trip.id);
      setState(() {
        _ended = BusUpdate(BusUpdateKind.tripEnded, at: now, seq: -now.millisecondsSinceEpoch, stopName: shown.label);
        _shown = null;
      });
    });
    final ended = _ended;

    return running.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ListView(
        children: [
          const SizedBox(height: 80),
          EmptyState(
            icon: HugeIcons.strokeRoundedWifiDisconnected01,
            title: error is RepositoryException ? l10n.failure(error) : l10n.errorGeneric,
            action: BusinButton(label: l10n.actionRetry, onPressed: () => ref.invalidate(runningBusesProvider)),
          ),
        ],
      ),
      data: (buses) {
        if (buses.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(runningBusesProvider),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (ended != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(BusinSpace.x4, BusinSpace.x4, BusinSpace.x4, 0),
                    child: Notice(tone: StatusTone.neutral, child: Text(l10n.busUpdateEnded(ended.stopName ?? ''))),
                  ),
                const SizedBox(height: 80),
                EmptyState(icon: HugeIcons.strokeRoundedBus01, title: l10n.busNoneTitle, body: l10n.busNoneBody),
              ],
            ),
          );
        }
        return _Tracking(buses: buses, recenter: _recenter, busInView: _busInView, active: _active ?? true, ended: ended);
      },
    );
  }
}

class _Tracking extends ConsumerStatefulWidget {
  const _Tracking({required this.buses, required this.recenter, required this.busInView, required this.active, this.ended});

  final List<RunningBus> buses;
  final ValueNotifier<int> recenter;
  final ValueNotifier<bool> busInView;

  /// False while another tab is showing: the live subscription is dropped then and taken up again on return.
  final bool active;

  /// The previously followed trip ended (its bus label in stopName).
  final BusUpdate? ended;

  @override
  ConsumerState<_Tracking> createState() => _TrackingState();
}

class _TrackingState extends ConsumerState<_Tracking> {
  /// The floating card's height on a phone, measured, so the map frames the bus above it.
  double _cardHeight = 150;

  @override
  Widget build(BuildContext context) {
    final buses = widget.buses;
    final recenter = widget.recenter;
    final busInView = widget.busInView;
    final active = widget.active;
    final ended = widget.ended;
    final current = ref.watch(currentBusProvider).value;
    if (current == null) return const Center(child: CircularProgressIndicator());

    final l10n = BusinL10n.of(context);
    final position = active ? ref.watch(busPositionProvider(current.busId)) : const AsyncLoading<LivePosition>();
    final stops = ref.watch(stopsProvider).value ?? const <Stop>[];
    final myStop = ref.watch(myStopProvider).value;
    final expanded = BusinLayout.of(context).isExpanded;
    // The feeder runs only while the tab shows (the live position stops with it); the updates themselves stay.
    if (active) ref.watch(busUpdateFeederProvider((busId: current.busId, tripId: current.trip.id)));
    final updates = ref.watch(busUpdatesProvider(current.trip.id));
    final live = updates.firstOrNull;
    // The student's own position: only while this tab shows and they chose Show me (ADR 0016).
    final showMe = ref.watch(showMeProvider);
    final me = active && showMe != null ? ref.watch(myPositionProvider).value : null;
    // The newest of the bus's own update and "the previous trip ended".
    final end = ended;
    final update = end != null && (live == null || end.at.isAfter(live.at)) ? end : live;
    // The planned route and campus (read once), and where this bus has been on its trip (while the tab shows).
    final route = ref.watch(schoolRouteProvider).value;
    final trail = active ? ref.watch(tripTrailProvider((busId: current.busId, tripId: current.trip.id))) : const <GeoPoint>[];

    final scene = MapScene(
      stops: stops,
      myStopId: myStop?.id,
      bus: position.value?.location,
      busHeading: position.value?.headingDeg,
      me: me,
      focusMe: ref.watch(focusMeProvider),
      // On a phone the details card floats over the lower part of the map.
      coveredBottom: expanded ? 0 : _cardHeight + BusinSpace.x3,
      route: route?.line ?? const [],
      trail: trail,
      campus: route?.campus,
      campusName: route?.campusName,
    );

    // What floats over the map, top down: a status line while waiting or failing, the latest update, and the way back
    // to the bus. One column, so they never overlap; below the bus pills when there are several buses on a phone.
    final now = ref.read(nowProvider)();
    final overlays = <Widget>[
      Positioned(
        top: buses.length > 1 && !expanded ? 56 : BusinSpace.x3,
        left: BusinSpace.x3,
        right: BusinSpace.x3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (position.isLoading) Notice(child: Text(l10n.busWaiting)),
            if (position.hasError)
              Notice(
                tone: StatusTone.bad,
                child: Row(
                  children: [
                    Expanded(child: Text(l10n.busLiveFailed)),
                    TextButton(onPressed: () => ref.invalidate(busPositionProvider(current.busId)), child: Text(l10n.actionRetry)),
                  ],
                ),
              ),
            // On a wide screen the updates sit in the panel beside the map instead.
            if (!expanded)
              BusUpdateStrip(
                update: update,
                busLabel: update?.kind == BusUpdateKind.tripEnded ? (update?.stopName ?? '') : current.label,
                direction: l10n.direction(current.trip.direction),
                now: now,
              ),
            Padding(
              padding: const EdgeInsets.only(top: BusinSpace.x2),
              // A wrap, so a narrow phone with large text moves a button to the next line instead of overflowing.
              child: Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: BusinSpace.x2,
                runSpacing: BusinSpace.x2,
                children: [
                  _LegendButton(onPressed: () => showMapLegend(context)),
                  if (me != null) ...[
                    BusinButton(
                      label: l10n.busMeFind,
                      variant: BusinButtonVariant.secondary,
                      icon: HugeIcons.strokeRoundedUserCircle,
                      onPressed: () => ref.read(focusMeProvider.notifier).request(),
                    ),
                  ],
                  BusinButton(
                    label: showMe == null ? l10n.busMeShow : l10n.busMeHide,
                    variant: BusinButtonVariant.secondary,
                    icon: HugeIcons.strokeRoundedGps01,
                    onPressed: () => showMe == null ? turnOnShowMe(context, ref) : ref.read(showMeProvider.notifier).turnOff(),
                  ),
                  if (scene.bus != null) ...[
                    // Only when the bus is out of frame; it fades in and out so the map is not jumpy.
                    ValueListenableBuilder<bool>(
                      valueListenable: busInView,
                      builder: (context, inView, button) => AnimatedSwitcher(
                        duration: BusinMotion.of(context, BusinMotion.fast),
                        transitionBuilder: (child, animation) =>
                            FadeTransition(opacity: animation, child: ScaleTransition(scale: Tween(begin: 0.9, end: 1.0).animate(animation), child: child)),
                        child: inView ? const SizedBox.shrink() : button,
                      ),
                      child: BusinButton(label: l10n.busRecenter, variant: BusinButtonVariant.secondary, icon: HugeIcons.strokeRoundedLocation01, onPressed: () => recenter.value++),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ];

    final map = DecoratedBox(
      decoration: const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(BusinRadius.xl)), boxShadow: BusinElevation.float),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(BusinRadius.xl),
        child: Stack(children: [Positioned.fill(child: ref.watch(mapSurfaceBuilderProvider)(context, scene, recenter, busInView)), ...overlays]),
      ),
    );
    final feedUpdates = [?end, ...updates]..sort((a, b) => b.at.compareTo(a.at));
    final feed = BusUpdateFeed(updates: feedUpdates, busLabel: current.label, direction: l10n.direction(current.trip.direction), now: now, showTitle: false);
    final card = _InfoCard(bus: current, position: position.value, myStop: myStop, me: me);

    if (expanded) {
      // A wide screen: the map takes the room, the buses and the details sit in a panel beside it.
      return Padding(
        padding: const EdgeInsets.all(BusinSpace.x4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: map),
            const SizedBox(width: BusinSpace.x4),
            SizedBox(
              width: 380,
              child: ListView(
                children: [
                  if (buses.length > 1) ...[
                    Text(l10n.busRunning, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: BusinSpace.x2),
                    _BusPills(buses: buses, selectedId: current.busId, wrap: true),
                    const SizedBox(height: BusinSpace.x4),
                  ],
                  card,
                  const SizedBox(height: BusinSpace.x4),
                  Text(l10n.busUpdatesTitle, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: BusinSpace.x2),
                  feed,
                ],
              ),
            ),
          ],
        ),
      );
    }

    // A phone or portrait tablet: the map floats as a rounded card, the bus pills ride on top of it and the details
    // card floats above the navigation bar.
    final inset = BusinScope.of(context).bottomInset;
    return Stack(
      children: [
        Positioned.fill(child: Padding(padding: EdgeInsets.fromLTRB(BusinSpace.x3, BusinSpace.x2, BusinSpace.x3, inset), child: map)),
        Positioned(
          left: BusinSpace.x5,
          right: BusinSpace.x5,
          bottom: inset + BusinSpace.x3,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: _SizeReporter(
                onSize: (size) {
                  if ((size.height - _cardHeight).abs() > 1) setState(() => _cardHeight = size.height);
                },
                child: _InfoCard(
                  bus: current,
                  position: position.value,
                  myStop: myStop,
                  me: me,
                  updates: feed,
                  updateCount: feedUpdates.length,
                  latest: feedUpdates.firstOrNull == null
                      ? null
                      : (
                          text: busUpdateText(
                            l10n,
                            feedUpdates.first,
                            busLabel: feedUpdates.first.kind == BusUpdateKind.tripEnded ? (feedUpdates.first.stopName ?? '') : current.label,
                            direction: l10n.direction(current.trip.direction),
                            now: now,
                          ),
                          icon: busUpdateLook(feedUpdates.first.kind).$2,
                        ),
                ),
              ),
            ),
          ),
        ),
        if (buses.length > 1)
          Positioned(top: BusinSpace.x2 + BusinSpace.x3, left: BusinSpace.x5, right: BusinSpace.x5, child: _BusPills(buses: buses, selectedId: current.busId)),
      ],
    );
  }
}

/// The running buses as pills the student can switch between: the chosen one is solid teal, the others are surface.
class _BusPills extends ConsumerWidget {
  const _BusPills({required this.buses, required this.selectedId, this.wrap = false});

  final List<RunningBus> buses;
  final String selectedId;
  final bool wrap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = BusinL10n.of(context);
    final p = BusinPalette.of(context);
    Widget pill(RunningBus bus) {
      final chosen = bus.busId == selectedId;
      return Semantics(
        button: true,
        selected: chosen,
        child: Material(
          color: chosen ? BusinRamps.seed : p.surface,
          elevation: chosen ? 0 : 2,
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.circular(BusinRadius.sm),
          child: InkWell(
            borderRadius: BorderRadius.circular(BusinRadius.sm),
            onTap: () {
              BusinHaptics.selection();
              ref.read(selectedBusIdProvider.notifier).select(bus.busId);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: BusinSpace.x4, vertical: BusinSpace.x3),
              child: Text(
                '${bus.label} · ${l10n.direction(bus.trip.direction)}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: chosen ? Colors.white : p.fg),
              ),
            ),
          ),
        ),
      );
    }

    if (wrap) return Wrap(spacing: BusinSpace.x2, runSpacing: BusinSpace.x2, children: [for (final b in buses) pill(b)]);
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: buses.length,
        separatorBuilder: (_, _) => const SizedBox(width: BusinSpace.x2),
        itemBuilder: (context, index) => pill(buses[index]),
      ),
    );
  }
}

/// The bus's details: a 3D bus, its name (or plate) and direction, the estimated arrival at the student's stop when it can be
/// worked out, how fresh the position is, and the student's stop.
class _InfoCard extends ConsumerWidget {
  const _InfoCard({required this.bus, required this.position, required this.myStop, this.me, this.updates, this.updateCount = 0, this.latest});

  final RunningBus bus;
  final LivePosition? position;
  final Stop? myStop;

  /// Where the student is, while they use Show me.
  final GeoPoint? me;

  /// On a phone: the live updates, folded under the details (on a wide screen they sit in the side panel instead).
  final Widget? updates;
  final int updateCount;

  /// The newest update, shown on the closed fold so it rarely needs opening.
  final ({String text, List<List<dynamic>> icon})? latest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = BusinL10n.of(context);
    final palette = BusinPalette.of(context);
    final walk = me == null || myStop == null ? null : walkTo(me!, myStop!.location);
    final text = Theme.of(context).textTheme;

    String? updated;
    var stale = false;
    int? staleMinutes;
    final p = position;
    if (p != null) {
      final age = positionAge(p, ref.read(nowProvider)());
      stale = isStale(age);
      staleMinutes = age.inMinutes;
      updated = age.inSeconds < 90 ? l10n.busUpdatedSeconds('${age.inSeconds}') : l10n.busUpdatedMinutes('${age.inMinutes}');
    }
    final kmh = p == null ? null : speedKmh(p.speedMps);
    // An estimate only from a fresh position: a stale one would promise something the bus may not be doing.
    final eta = stale || myStop == null ? null : estimateEta(bus: p?.location, stop: myStop!.location, speedMps: p?.speedMps);

    // One status line: the direction, how fresh the position is and the speed; or the warning if it has gone quiet.
    final status = stale ? l10n.busStale('$staleMinutes') : [l10n.direction(bus.trip.direction), ?updated, if (kmh != null) l10n.busSpeed('$kmh')].join(' · ');

    return BusinCard(
      // Room inside the thread, so the text never touches it.
      padding: const EdgeInsets.fromLTRB(BusinSpace.x5, BusinSpace.x4, BusinSpace.x5, BusinSpace.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Illustration(BusinIllustration.bus, width: 44, height: 44),
              const SizedBox(width: BusinSpace.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(bus.label, style: text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(status, style: text.bodySmall?.copyWith(color: stale ? palette.warn : palette.muted), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (eta != null) ...[
                const SizedBox(width: BusinSpace.x3),
                Semantics(
                  label: '${l10n.busEtaLabel}: ${eta.arriving ? l10n.busEtaArriving : l10n.busEtaMinutes('${eta.minutes}')}. ${l10n.busEtaCaption(_km(eta.kilometres, l10n.localeName), myStop!.name)}',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(eta.arriving ? l10n.busEtaArriving : l10n.busEtaMinutes('${eta.minutes}'), style: text.headlineSmall?.copyWith(color: palette.accent, fontWeight: FontWeight.w800)),
                      Text(l10n.busDistanceKm(_km(eta.kilometres, l10n.localeName)), style: text.bodySmall?.copyWith(color: palette.muted)),
                    ],
                  ),
                ),
              ],
            ],
          ),
          // With Show me on: how far the student is from their stop, on foot.
          if (walk != null) ...[
            const SizedBox(height: BusinSpace.x2),
            Row(
              children: [
                HugeIcon(icon: HugeIcons.strokeRoundedWalking, size: 18, color: palette.info),
                const SizedBox(width: BusinSpace.x2),
                Expanded(child: Text(walkText(l10n, walk), style: text.bodySmall?.copyWith(fontWeight: FontWeight.w600))),
              ],
            ),
          ],
          // Without an estimate the student's stop still gets its line.
          if (myStop != null && eta == null) ...[
            const SizedBox(height: BusinSpace.x2),
            Row(
              children: [
                HugeIcon(icon: HugeIcons.strokeRoundedFlag02, size: 18, color: palette.accent),
                const SizedBox(width: BusinSpace.x2),
                Expanded(child: Text('${l10n.busYourStop}: ${myStop!.name}', style: text.bodySmall?.copyWith(fontWeight: FontWeight.w600))),
              ],
            ),
          ],
          if (updates != null) ...[
            const SizedBox(height: BusinSpace.x2),
            _UpdatesFold(count: updateCount, latest: latest, child: updates!),
          ],
        ],
      ),
    );
  }
}

/// The live updates folded into the bus card on a phone: a row with their number that opens and closes smoothly. Open,
/// they scroll inside a bounded height so the map stays visible.
class _UpdatesFold extends StatefulWidget {
  const _UpdatesFold({required this.count, required this.child, this.latest});

  final int count;
  final Widget child;
  final ({String text, List<List<dynamic>> icon})? latest;

  @override
  State<_UpdatesFold> createState() => _UpdatesFoldState();
}

class _UpdatesFoldState extends State<_UpdatesFold> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final duration = BusinMotion.of(context, BusinMotion.normal);
    final screen = MediaQuery.sizeOf(context).height;
    final latest = widget.latest;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          expanded: _open,
          excludeSemantics: true,
          label: l10n.busUpdatesToggle(widget.count),
          child: InkWell(
            borderRadius: BorderRadius.circular(BusinRadius.sm),
            onTap: () {
              BusinHaptics.selection();
              setState(() => _open = !_open);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: BusinSpace.x2),
              child: Row(
                children: [
                  HugeIcon(icon: !_open && latest != null ? latest.icon : HugeIcons.strokeRoundedNotification03, size: 18, color: p.muted),
                  const SizedBox(width: BusinSpace.x2),
                  // Closed: the newest update itself, trimmed to one line. Open: the list's title.
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: BusinMotion.of(context, BusinMotion.fast),
                      // Start-aligned, as the rest of the card (the switcher centres by default).
                      layoutBuilder: (current, previous) => Stack(alignment: AlignmentDirectional.centerStart, children: [...previous, ?current]),
                      child: Text(
                        !_open && latest != null ? latest.text : l10n.busUpdatesTitle,
                        key: ValueKey(!_open && latest != null ? latest.text : ''),
                        style: text.labelLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (widget.count > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: BusinSpace.x2, vertical: 2),
                      decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(BusinRadius.sm)),
                      child: Text('${widget.count}', style: text.labelSmall),
                    ),
                  const SizedBox(width: BusinSpace.x2),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: duration,
                    curve: BusinMotion.soft,
                    child: HugeIcon(icon: HugeIcons.strokeRoundedArrowUp01, size: 18, color: p.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: duration,
          curve: BusinMotion.soft,
          alignment: Alignment.topCenter,
          child: _open
              ? ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: screen * 0.32),
                  child: SingleChildScrollView(padding: const EdgeInsets.only(top: BusinSpace.x2), child: widget.child),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// The map's info button: a round button that opens the legend.
class _LegendButton extends StatelessWidget {
  const _LegendButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final p = BusinPalette.of(context);
    final label = BusinL10n.of(context).busLegendOpen;
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: p.surface2,
          shape: const CircleBorder(),
          elevation: 2,
          shadowColor: Colors.black26,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(width: 48, height: 48, child: Center(child: HugeIcon(icon: HugeIcons.strokeRoundedInformationCircle, size: 22, color: p.fg))),
          ),
        ),
      ),
    );
  }
}

/// Tells [onSize] the size of its child after each layout where it changed.
class _SizeReporter extends SingleChildRenderObjectWidget {
  const _SizeReporter({required this.onSize, super.child});

  final ValueChanged<Size> onSize;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderSizeReporter(onSize);

  @override
  void updateRenderObject(BuildContext context, _RenderSizeReporter renderObject) => renderObject.onSize = onSize;
}

class _RenderSizeReporter extends RenderProxyBox {
  _RenderSizeReporter(this.onSize);

  ValueChanged<Size> onSize;
  Size? _reported;

  @override
  void performLayout() {
    super.performLayout();
    if (size == _reported) return;
    _reported = size;
    final now = size;
    WidgetsBinding.instance.addPostFrameCallback((_) => onSize(now));
  }
}

/// One decimal, with the language's decimal mark.
String _km(double km, String languageCode) {
  final text = km.toStringAsFixed(1);
  return languageCode.startsWith('fr') ? text.replaceFirst('.', ',') : text;
}
