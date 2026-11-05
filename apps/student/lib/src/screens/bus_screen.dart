import 'dart:async';

import 'package:busin_core/busin_core.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../bus/bus_providers.dart';
import '../bus/eta.dart';
import '../bus/map_scene.dart';
import '../qr/qr_providers.dart';
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
  Timer? _timer;
  bool? _active;

  @override
  void initState() {
    super.initState();
    // "Updated 12 s ago" needs to keep counting between positions.
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() {});
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
        if (mounted) ref.invalidate(runningBusesProvider);
      });
    }
    _active = active;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recenter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final running = ref.watch(runningBusesProvider);

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
                const SizedBox(height: 80),
                EmptyState(icon: HugeIcons.strokeRoundedBus01, title: l10n.busNoneTitle, body: l10n.busNoneBody),
              ],
            ),
          );
        }
        return _Tracking(buses: buses, recenter: _recenter, active: _active ?? true);
      },
    );
  }
}

class _Tracking extends ConsumerWidget {
  const _Tracking({required this.buses, required this.recenter, required this.active});

  final List<RunningBus> buses;
  final ValueNotifier<int> recenter;

  /// False while another tab is showing: the live subscription is dropped then and taken up again on return.
  final bool active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentBusProvider).value;
    if (current == null) return const Center(child: CircularProgressIndicator());

    final l10n = BusinL10n.of(context);
    final position = active ? ref.watch(busPositionProvider(current.busId)) : const AsyncLoading<LivePosition>();
    final stops = ref.watch(stopsProvider).value ?? const <Stop>[];
    final myStop = ref.watch(myStopProvider).value;
    final expanded = BusinLayout.of(context).isExpanded;

    final scene = MapScene(
      stops: stops,
      myStopId: myStop?.id,
      bus: position.value?.location,
      busHeading: position.value?.headingDeg,
      // On a phone the details card floats over the lower part of the map.
      coveredBottom: expanded ? 0 : 150,
    );

    // What floats over the map: a status line while waiting or failing, and the way back to the bus.
    final overlays = <Widget>[
      if (position.isLoading)
        Positioned(top: BusinSpace.x3, left: BusinSpace.x3, right: BusinSpace.x3, child: Notice(child: Text(l10n.busWaiting))),
      if (position.hasError)
        Positioned(
          top: BusinSpace.x3,
          left: BusinSpace.x3,
          right: BusinSpace.x3,
          child: Notice(
            tone: StatusTone.bad,
            child: Row(
              children: [
                Expanded(child: Text(l10n.busLiveFailed)),
                TextButton(onPressed: () => ref.invalidate(busPositionProvider(current.busId)), child: Text(l10n.actionRetry)),
              ],
            ),
          ),
        ),
      if (scene.bus != null)
        Positioned(
          right: BusinSpace.x3,
          top: position.isLoading || position.hasError ? 76 : BusinSpace.x3,
          child: BusinButton(label: l10n.busRecenter, variant: BusinButtonVariant.secondary, icon: HugeIcons.strokeRoundedLocation01, onPressed: () => recenter.value++),
        ),
    ];

    final map = DecoratedBox(
      decoration: const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(BusinRadius.xl)), boxShadow: BusinElevation.float),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(BusinRadius.xl),
        child: Stack(children: [Positioned.fill(child: ref.watch(mapSurfaceBuilderProvider)(context, scene, recenter)), ...overlays]),
      ),
    );
    final card = _InfoCard(bus: current, position: position.value, myStop: myStop);

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
        Positioned(left: BusinSpace.x5, right: BusinSpace.x5, bottom: inset + BusinSpace.x3, child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: card))),
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
                '${bus.plate} · ${l10n.direction(bus.trip.direction)}',
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

/// The bus's details: a 3D bus, the plate and direction, the estimated arrival at the student's stop when it can be
/// worked out, how fresh the position is, and the student's stop.
class _InfoCard extends ConsumerWidget {
  const _InfoCard({required this.bus, required this.position, required this.myStop});

  final RunningBus bus;
  final LivePosition? position;
  final Stop? myStop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = BusinL10n.of(context);
    final palette = BusinPalette.of(context);
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
      padding: const EdgeInsets.fromLTRB(BusinSpace.x4, BusinSpace.x3, BusinSpace.x4, BusinSpace.x3),
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
                    Text(bus.plate, style: text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
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
          // Without an estimate the student's stop still gets its line.
          if (myStop != null && eta == null) ...[
            const SizedBox(height: BusinSpace.x2),
            Row(
              children: [
                const Illustration(BusinIllustration.busStop, width: 22, height: 22),
                const SizedBox(width: BusinSpace.x2),
                Expanded(child: Text('${l10n.busYourStop}: ${myStop!.name}', style: text.bodySmall?.copyWith(fontWeight: FontWeight.w600))),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// One decimal, with the language's decimal mark.
String _km(double km, String languageCode) {
  final text = km.toStringAsFixed(1);
  return languageCode.startsWith('fr') ? text.replaceFirst('.', ',') : text;
}
