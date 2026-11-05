import 'dart:async';

import 'package:busin_core/busin_core.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../bus/bus_providers.dart';
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

    final scene = MapScene(
      stops: stops,
      myStopId: myStop?.id,
      bus: position.value?.location,
      busHeading: position.value?.headingDeg,
    );

    return Column(
      children: [
        if (buses.length > 1) _BusChips(buses: buses, selectedId: current.busId),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(child: ref.watch(mapSurfaceBuilderProvider)(context, scene, recenter)),
              if (position.isLoading)
                Positioned(top: BusinSpace.x3, left: BusinSpace.x3, right: BusinSpace.x3, child: _Banner(text: l10n.busWaiting)),
              if (position.hasError)
                Positioned(
                  top: BusinSpace.x3,
                  left: BusinSpace.x3,
                  right: BusinSpace.x3,
                  child: _Banner(text: l10n.busLiveFailed, action: l10n.actionRetry, onAction: () => ref.invalidate(busPositionProvider(current.busId)), bad: true),
                ),
              if (scene.bus != null)
                Positioned(
                  right: BusinSpace.x3,
                  bottom: BusinSpace.x3,
                  child: BusinButton(label: l10n.busRecenter, variant: BusinButtonVariant.secondary, icon: HugeIcons.strokeRoundedLocation01, onPressed: () => recenter.value++),
                ),
            ],
          ),
        ),
        Padding(padding: EdgeInsets.only(bottom: BusinScope.of(context).bottomInset), child: _InfoCard(bus: current, position: position.value, myStopName: myStop?.name)),
      ],
    );
  }
}

class _BusChips extends ConsumerWidget {
  const _BusChips({required this.buses, required this.selectedId});

  final List<RunningBus> buses;
  final String selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = BusinL10n.of(context);
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: BusinSpace.x4, vertical: BusinSpace.x2),
        itemCount: buses.length,
        separatorBuilder: (_, _) => const SizedBox(width: BusinSpace.x2),
        itemBuilder: (context, index) {
          final bus = buses[index];
          return ChoiceChip(
            label: Text('${bus.plate} · ${l10n.direction(bus.trip.direction)}'),
            selected: bus.busId == selectedId,
            onSelected: (_) => ref.read(selectedBusIdProvider.notifier).select(bus.busId),
          );
        },
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, this.action, this.onAction, this.bad = false});

  final String text;
  final String? action;
  final VoidCallback? onAction;
  final bool bad;

  @override
  Widget build(BuildContext context) {
    final palette = BusinPalette.of(context);
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(color: bad ? palette.badBg : palette.surface, borderRadius: BorderRadius.circular(BusinRadius.sm), boxShadow: const [BoxShadow(blurRadius: 8, color: Color(0x22000000))]),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: BusinSpace.x4, vertical: BusinSpace.x3),
          child: Row(
            children: [
              Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: bad ? palette.bad : palette.fg))),
              if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends ConsumerWidget {
  const _InfoCard({required this.bus, required this.position, required this.myStopName});

  final RunningBus bus;
  final LivePosition? position;
  final String? myStopName;

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

    return Material(
      color: palette.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(BusinSpace.x4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: Text(bus.plate, style: text.titleLarge)),
                  StatusChip(label: l10n.direction(bus.trip.direction), tone: StatusTone.info),
                ],
              ),
              const SizedBox(height: BusinSpace.x1),
              if (stale)
                Text(l10n.busStale('$staleMinutes'), style: text.bodyMedium?.copyWith(color: palette.warn))
              else if (updated != null)
                Text([updated, if (kmh != null) l10n.busSpeed('$kmh')].join(' · '), style: text.bodyMedium?.copyWith(color: palette.muted)),
              if (myStopName != null) ...[
                const SizedBox(height: BusinSpace.x2),
                Row(
                  children: [
                    HugeIcon(icon: HugeIcons.strokeRoundedFlag02, size: 16, color: palette.accent),
                    const SizedBox(width: BusinSpace.x2),
                    Text('${l10n.busYourStop}: $myStopName', style: text.bodyMedium),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
