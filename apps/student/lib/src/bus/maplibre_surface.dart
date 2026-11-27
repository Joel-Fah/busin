import 'dart:math' as math;

import 'package:busin_core/busin_core.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'map_layers.dart';
import 'map_motion.dart';
import 'map_scene.dart';

/// The colours of the map's markers, the same in light and dark (they sit on the map, not on the app's surfaces). The
/// legend on My bus uses them too.
abstract final class MapColors {
  static const stop = '#8A9A9E';
  static const myStop = '#F5951F';
  static const bus = '#2F6FED';
  static const me = '#0F9D58';
  static const campus = '#0C5D6D';
  static const route = '#0C5D6D';
  static const trail = '#2F6FED';

  static Color of(String hex) => Color(int.parse('FF${hex.substring(1)}', radix: 16));
}

/// Draws a [MapScene] with MapLibre: the base map (OpenFreeMap by default, light or dark with the theme), the planned
/// route and the trip's trail as lines, a circle for each stop with its name (orange for the student's own, pinging),
/// the campus, the bus as a blue dot pinging softly and gliding between positions, and the student in green while they
/// use Show me. It does nothing the scene does not say, so all the decisions live in the screen and its providers, which
/// are tested; this file only draws.
class MapLibreSurface extends StatefulWidget {
  const MapLibreSurface({super.key, required this.scene, required this.styleUrl, required this.darkStyleUrl, required this.recenter, required this.busInView});

  final MapScene scene;
  final String styleUrl;
  final String darkStyleUrl;
  final ValueListenable<int> recenter;

  /// Written by the surface: true while the bus is inside the visible part of the map.
  final ValueNotifier<bool> busInView;

  @override
  State<MapLibreSurface> createState() => _MapLibreSurfaceState();
}

class _MapLibreSurfaceState extends State<MapLibreSurface> with SingleTickerProviderStateMixin {
  static const _font = ['Noto Sans Regular'];

  /// How often the moving parts are redrawn: smooth to the eye, light on the bridge to the native map.
  static const _frame = Duration(milliseconds: 50);
  static const _busPing = Duration(milliseconds: 1800);
  static const _stopPing = Duration(milliseconds: 2600);

  MapLibreMapController? _controller;
  bool _styleReady = false;
  bool _fitted = false;
  MapScene? _drawn;
  String? _style;
  bool _dark = false;
  bool _reduced = false;

  late final Ticker _ticker = createTicker(_onTick);
  Duration _lastFrame = Duration.zero;
  bool _drawing = false;

  Glide? _bus;
  Glide? _me;
  DateTime? _lastBusReport;

  /// The camera moves with the bus until the student touches the map; "Show the bus" starts following again.
  bool _following = true;

  @override
  void initState() {
    super.initState();
    widget.recenter.addListener(_showBus);
  }

  void _showBus() {
    _following = true;
    _fit();
  }

  @override
  void didUpdateWidget(MapLibreSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recenter != widget.recenter) {
      oldWidget.recenter.removeListener(_showBus);
      widget.recenter.addListener(_showBus);
    }
    final busMoved = widget.scene.bus != oldWidget.scene.bus;
    _follow(widget.scene, oldWidget.scene);
    if (busMoved && _fitted) _keepBusInView();
    if (oldWidget.scene != widget.scene) _draw();
    // "Find me": move to the student, above whatever floats over the bottom of the map.
    final me = widget.scene.me;
    if (widget.scene.focusMe != oldWidget.scene.focusMe && me != null) {
      // Looking at themselves: the camera stops following the bus ("Show the bus" follows it again).
      _following = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.busInView.value = false;
      });
      _controller?.animateCamera(CameraUpdate.newLatLngZoom(_latLng(me), 16));
    }
  }

  /// Starts a glide when the bus or the student moved.
  void _follow(MapScene scene, MapScene? old) {
    final now = DateTime.now();
    final bus = scene.bus;
    if (bus == null) {
      _bus = null;
      _lastBusReport = null;
    } else if (_bus == null) {
      _bus = Glide.at(bus, now);
      _lastBusReport = now;
    } else if (bus != old?.bus) {
      final since = _lastBusReport == null ? Duration.zero : now.difference(_lastBusReport!);
      _bus = _bus!.towards(bus, now: now, sinceLastReport: since, reduced: _reduced);
      _lastBusReport = now;
    }
    final me = scene.me;
    if (me == null) {
      _me = null;
    } else if (_me == null) {
      _me = Glide.at(me, now);
    } else if (me != old?.me) {
      _me = _me!.towards(me, now: now, sinceLastReport: const Duration(seconds: 1), reduced: _reduced);
    }
  }

  /// While following: pans the camera along with the bus's glide, so the bus stays in the middle of the part of the map
  /// the student can see (above the card). The zoom is the student's.
  Future<void> _keepBusInView() async {
    final c = _controller;
    final glide = _bus;
    if (!_following || c == null || !_styleReady || glide == null || _size.isEmpty) return;
    try {
      final bus = await c.toScreenLocation(_latLng(glide.to));
      if (!mounted || !_following) return;
      final visibleMiddle = Offset(_size.width / 2, (_size.height - widget.scene.coveredBottom) / 2 + _topCovered / 2);
      final screenMiddle = Offset(_size.width / 2, _size.height / 2);
      final target = await c.toLatLng(math.Point(screenMiddle.dx + bus.x - visibleMiddle.dx, screenMiddle.dy + bus.y - visibleMiddle.dy));
      if (!mounted || !_following) return;
      final duration = glide.duration > Duration.zero ? glide.duration : const Duration(milliseconds: 600);
      await c.animateCamera(CameraUpdate.newLatLng(target), duration: duration);
    } on Object {
      // The map is being replaced (style change); the next report pans again.
    }
  }

  /// What floats over the top of the map (the latest update and the buttons), so the bus is not centred under them.
  static const _topCovered = 120.0;

  @override
  void dispose() {
    widget.recenter.removeListener(_showBus);
    _ticker.dispose();
    super.dispose();
  }

  LatLng _latLng(GeoPoint p) => LatLng(p.latitude, p.longitude);

  GeoPoint? get _myStop => widget.scene.stops.where((s) => s.id == widget.scene.myStopId).firstOrNull?.location;

  /// A new base map (the phone switched between light and dark) drops everything drawn on the old one; the style's
  /// load callback then draws it again.
  void _styleChanged() {
    _styleReady = false;
    _drawn = null;
  }

  /// The sources and layers, bottom to top: the route, the trail, the rings, the stops, the campus, the student, the
  /// bus, then the names. Added once per base map; afterwards only their data changes.
  Future<void> _addLayers(MapLibreMapController c) async {
    final empty = collection(const []);
    for (final id in const ['route', 'trail', 'pulse', 'stops', 'campus', 'me', 'bus']) {
      await c.addGeoJsonSource(id, empty);
    }
    final halo = _dark ? '#0B1F24' : '#FFFFFF';
    final ink = _dark ? '#E6EEF0' : '#1F2A2E';
    await c.addLineLayer(
      'route',
      'route-line',
      LineLayerProperties(lineColor: MapColors.route, lineOpacity: _dark ? 0.75 : 0.5, lineWidth: 4, lineJoin: 'round', lineCap: 'round'),
      enableInteraction: false,
    );
    await c.addLineLayer(
      'trail',
      'trail-line',
      const LineLayerProperties(lineColor: MapColors.trail, lineOpacity: 0.4, lineWidth: 3, lineJoin: 'round', lineCap: 'round', lineDasharray: [1, 1.6]),
      enableInteraction: false,
    );
    await c.addCircleLayer('pulse', 'pulse-ring', _pulseLook(0, 0), enableInteraction: false);
    await c.addCircleLayer(
      'stops',
      'stops-dot',
      const CircleLayerProperties(
        circleColor: [
          'case',
          ['get', 'mine'],
          MapColors.myStop,
          MapColors.stop,
        ],
        circleRadius: [
          'case',
          ['get', 'mine'],
          8,
          5.5,
        ],
        circleStrokeColor: '#FFFFFF',
        circleStrokeWidth: 2,
      ),
      enableInteraction: false,
    );
    await c.addCircleLayer(
      'campus',
      'campus-dot',
      const CircleLayerProperties(circleColor: MapColors.campus, circleRadius: 9, circleStrokeColor: '#FFFFFF', circleStrokeWidth: 3),
      enableInteraction: false,
    );
    await c.addCircleLayer(
      'me',
      'me-dot',
      const CircleLayerProperties(circleColor: MapColors.me, circleRadius: 7.5, circleStrokeColor: '#FFFFFF', circleStrokeWidth: 3),
      enableInteraction: false,
    );
    await c.addCircleLayer(
      'bus',
      'bus-dot',
      const CircleLayerProperties(circleColor: MapColors.bus, circleRadius: 9, circleStrokeColor: '#FFFFFF', circleStrokeWidth: 3),
      enableInteraction: false,
    );
    // Names under the dots. The student's own stop wins a crowded spot; other names give way rather than overlap.
    await c.addSymbolLayer(
      'stops',
      'stops-name',
      SymbolLayerProperties(
        textField: ['get', 'name'],
        textFont: _font,
        textSize: [
          'case',
          ['get', 'mine'],
          13,
          11.5,
        ],
        textColor: [
          'case',
          ['get', 'mine'],
          _dark ? '#FFB55C' : '#B8650A',
          ink,
        ],
        textHaloColor: halo,
        textHaloWidth: 1.4,
        textAnchor: 'top',
        textOffset: [0, 0.9],
        textMaxWidth: 9,
        symbolSortKey: [
          'case',
          ['get', 'mine'],
          0,
          1,
        ],
      ),
      enableInteraction: false,
    );
    await c.addSymbolLayer(
      'campus',
      'campus-name',
      SymbolLayerProperties(
        textField: ['get', 'name'],
        textFont: _font,
        textSize: 12.5,
        textColor: _dark ? '#7FD3E0' : MapColors.campus,
        textHaloColor: halo,
        textHaloWidth: 1.4,
        textAnchor: 'top',
        textOffset: [0, 1.1],
        textMaxWidth: 9,
      ),
      enableInteraction: false,
    );
  }

  /// The rings at [busPhase] and [stopPhase] (0 to 1 through a ping). The whole look is given every time: the map resets
  /// what is left out.
  CircleLayerProperties _pulseLook(double busPhase, double stopPhase) {
    final bus = pulseAt(busPhase, radius: 9, spread: 14, opacity: 0.35);
    final stop = pulseAt(stopPhase, radius: 8, spread: 12, opacity: 0.4);
    return CircleLayerProperties(
      circleColor: [
        'match',
        ['get', 'kind'],
        'bus',
        MapColors.bus,
        MapColors.myStop,
      ],
      circleRadius: [
        'match',
        ['get', 'kind'],
        'bus',
        bus.radius,
        stop.radius,
      ],
      circleOpacity: _reduced
          ? 0
          : [
              'match',
              ['get', 'kind'],
              'bus',
              bus.opacity,
              stop.opacity,
            ],
      circleStrokeWidth: 0,
    );
  }

  /// Every frame (about 20 a second): the rings grow, and the bus and the student glide. Skipped while the previous
  /// frame is still being drawn, and stopped by Flutter while the tab is hidden.
  Future<void> _onTick(Duration elapsed) async {
    if (_drawing || !_styleReady || elapsed - _lastFrame < _frame) return;
    final c = _controller;
    if (c == null) return;
    _lastFrame = elapsed;
    _drawing = true;
    try {
      final now = DateTime.now();
      final bus = _bus?.at(now);
      if (_bus?.movingAt(now) ?? false) await c.setGeoJsonSource('bus', pointData(bus));
      if (_me?.movingAt(now) ?? false) await c.setGeoJsonSource('me', pointData(_me!.at(now)));
      if (bus != null || _myStop != null) {
        await c.setGeoJsonSource('pulse', pulseData(bus: bus, myStop: _myStop));
        if (!_reduced) {
          final ms = elapsed.inMilliseconds;
          await c.setLayerProperties('pulse-ring', _pulseLook(ms / _busPing.inMilliseconds, ms / _stopPing.inMilliseconds));
        }
      }
    } on Object {
      // The map went away mid-frame (style change, tab closed); the next style load draws everything again.
    } finally {
      _drawing = false;
    }
  }

  Future<void> _draw() async {
    final c = _controller;
    if (c == null || !_styleReady) return;
    final scene = widget.scene;
    final previous = _drawn;
    _drawn = scene;
    final now = DateTime.now();

    if (previous == null || previous.myStopId != scene.myStopId || previous.stops.length != scene.stops.length) {
      await c.setGeoJsonSource('stops', stopsData(scene.stops, scene.myStopId));
    }
    if (previous == null || !identical(previous.route, scene.route)) await c.setGeoJsonSource('route', lineData(scene.route));
    if (previous == null || previous.trail.length != scene.trail.length || (scene.trail.isNotEmpty && previous.trail.last != scene.trail.last)) {
      await c.setGeoJsonSource('trail', lineData(scene.trail));
    }
    if (previous == null || previous.campus != scene.campus || previous.campusName != scene.campusName) {
      await c.setGeoJsonSource('campus', pointData(scene.campus, {'name': scene.campusName ?? ''}));
    }
    // Not moving (or just appeared): draw it where it is. A glide is drawn by the ticker.
    if (!(_me?.movingAt(now) ?? false)) await c.setGeoJsonSource('me', pointData(_me?.at(now)));
    if (!(_bus?.movingAt(now) ?? false)) await c.setGeoJsonSource('bus', pointData(_bus?.at(now)));
    if (_reduced || (_bus == null && _myStop == null)) await c.setGeoJsonSource('pulse', pulseData(bus: _bus?.at(now), myStop: _myStop));

    // Seeing themselves the first time frames the student too; the bus is framed the first time it appears. After that
    // the student moves the map and "Show the bus" brings it back.
    if (scene.me != null && previous?.me == null && previous != null) await _fit();
    if (scene.bus != null && !_fitted) await _fit();
    await _checkBusInView();
  }

  Size _size = Size.zero;

  /// Whether the bus is in the part of the map the student can see: on the map, and above whatever floats over its
  /// bottom edge. Logical pixels, as the map reports them.
  Future<void> _checkBusInView() async {
    final c = _controller;
    final bus = widget.scene.bus;
    if (c == null || !_styleReady || bus == null || _size.isEmpty) {
      widget.busInView.value = false;
      return;
    }
    final point = await c.toScreenLocation(_latLng(bus));
    if (!mounted) return;
    const margin = 24.0;
    final visibleBottom = _size.height - widget.scene.coveredBottom;
    final inView = point.x >= margin && point.x <= _size.width - margin && point.y >= margin && point.y <= visibleBottom - margin;
    // Not following (the student moved the map): "Show the bus" is offered at once, to follow it again.
    widget.busInView.value = inView && _following;
  }

  Future<void> _fit() async {
    final c = _controller;
    final scene = widget.scene;
    if (c == null || !_styleReady || (scene.bus == null && scene.me == null)) return;
    if (scene.bus != null) _fitted = true;

    final points = <GeoPoint>[?scene.bus, ?scene.me, ?_myStop];
    if (points.length == 1) {
      await c.animateCamera(CameraUpdate.newLatLngZoom(_latLng(points.first), 15));
      return;
    }
    final south = points.map((p) => p.latitude).reduce(math.min);
    final north = points.map((p) => p.latitude).reduce(math.max);
    final west = points.map((p) => p.longitude).reduce(math.min);
    final east = points.map((p) => p.longitude).reduce(math.max);
    await c.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: LatLng(south, west), northeast: LatLng(north, east)),
        left: 64,
        top: 120,
        right: 64,
        bottom: 64 + scene.coveredBottom,
      ),
    );
  }

  /// Before the bus is known, look at the student's stop, then any stop; failing that, a neutral view that the first
  /// fix replaces.
  LatLng get _initialTarget {
    final scene = widget.scene;
    if (scene.bus != null) return _latLng(scene.bus!);
    final mine = _myStop;
    if (mine != null) return _latLng(mine);
    if (scene.stops.isNotEmpty) return _latLng(scene.stops.first.location);
    return const LatLng(3.848, 11.5021);
  }

  @override
  Widget build(BuildContext context) {
    _dark = Theme.of(context).brightness == Brightness.dark;
    _reduced = BusinMotion.reduced(context);
    final style = _dark ? widget.darkStyleUrl : widget.styleUrl;
    if (_style != null && _style != style) _styleChanged();
    _style = style;
    if (_bus == null && widget.scene.bus != null || _me == null && widget.scene.me != null) _follow(widget.scene, null);
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = constraints.biggest;
        return Semantics(
          label: BusinL10n.of(context).busMapLabel,
          // A finger on the map means the student is looking around: stop following the bus until they ask again.
          child: Listener(
            onPointerDown: (_) {
              if (!_following) return;
              _following = false;
              _checkBusInView();
            },
            child: MapLibreMap(
              styleString: style,
              initialCameraPosition: CameraPosition(target: _initialTarget, zoom: 13),
              onMapCreated: (controller) => _controller = controller,
              onStyleLoadedCallback: () async {
                final c = _controller;
                if (c == null) return;
                await _addLayers(c);
                _styleReady = true;
                await _draw();
                if (!_ticker.isActive) _ticker.start();
              },
              onCameraIdle: _checkBusInView,
              compassEnabled: false,
              myLocationEnabled: false,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
            ),
          ),
        );
      },
    );
  }
}
