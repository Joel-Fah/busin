import 'dart:math' as math;

import 'package:busin_core/busin_core.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:maplibre_gl/maplibre_gl.dart';

import 'map_scene.dart';

/// Draws a [MapScene] with MapLibre: the base map (OpenFreeMap by default, light or dark with the theme), a small dot
/// for each stop, a 3D pin for the student's own stop, and a 3D bus for the bus. It does nothing the scene does not say, so all the
/// decisions live in the screen and its providers, which are tested; this file only draws.
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

class _MapLibreSurfaceState extends State<MapLibreSurface> {
  static const _stopColor = '#7A8C90';
  // The 3D art is 256 px on its long side; at 5 px per dp the bus is about 50 dp wide and the pin 51 dp tall.
  static const _artPixelRatio = 5.0;

  MapLibreMapController? _controller;
  bool _styleReady = false;
  bool _fitted = false;
  List<Circle> _stopCircles = const [];
  Symbol? _busSymbol;
  Symbol? _myStopSymbol;
  MapScene? _drawn;
  String? _style;

  @override
  void initState() {
    super.initState();
    widget.recenter.addListener(_fit);
  }

  @override
  void didUpdateWidget(MapLibreSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recenter != widget.recenter) {
      oldWidget.recenter.removeListener(_fit);
      widget.recenter.addListener(_fit);
    }
    if (oldWidget.scene != widget.scene) _draw();
  }

  /// A new base map (the phone switched between light and dark) drops everything drawn on the old one; the style's
  /// load callback then draws it again.
  void _styleChanged() {
    _styleReady = false;
    _stopCircles = const [];
    _busSymbol = null;
    _myStopSymbol = null;
    _drawn = null;
  }

  Future<void> _addArt(MapLibreMapController controller) async {
    for (final name in const ['bus', 'pin']) {
      final data = await rootBundle.load('assets/map/$name.webp');
      await controller.addImage(name, data.buffer.asUint8List(), false, _artPixelRatio);
    }
  }

  @override
  void dispose() {
    widget.recenter.removeListener(_fit);
    super.dispose();
  }

  LatLng _latLng(GeoPoint p) => LatLng(p.latitude, p.longitude);

  Future<void> _draw() async {
    final controller = _controller;
    if (controller == null || !_styleReady) return;
    final scene = widget.scene;
    final previous = _drawn;
    _drawn = scene;

    // Stops change rarely; redraw them only when they or the highlighted one did. The student's own stop is a pin.
    if (previous == null || previous.myStopId != scene.myStopId || previous.stops.length != scene.stops.length) {
      if (_stopCircles.isNotEmpty) await controller.removeCircles(_stopCircles);
      _stopCircles = await controller.addCircles([
        for (final stop in scene.stops)
          if (stop.id != scene.myStopId)
            CircleOptions(geometry: _latLng(stop.location), circleRadius: 5, circleColor: _stopColor, circleStrokeWidth: 2, circleStrokeColor: '#FFFFFF'),
      ]);
      if (_myStopSymbol != null) {
        await controller.removeSymbol(_myStopSymbol!);
        _myStopSymbol = null;
      }
      final mine = scene.stops.where((s) => s.id == scene.myStopId).firstOrNull;
      if (mine != null) {
        _myStopSymbol = await controller.addSymbol(SymbolOptions(geometry: _latLng(mine.location), iconImage: 'pin', iconAnchor: 'bottom'));
      }
    }

    final bus = scene.bus;
    if (bus == null) {
      if (_busSymbol != null) {
        await controller.removeSymbol(_busSymbol!);
        _busSymbol = null;
      }
      return;
    }
    if (_busSymbol == null) {
      _busSymbol = await controller.addSymbol(SymbolOptions(geometry: _latLng(bus), iconImage: 'bus', iconAnchor: 'center'));
    } else {
      await controller.updateSymbol(_busSymbol!, SymbolOptions(geometry: _latLng(bus)));
    }
    // Show the bus the first time it appears; after that the student moves the map and "Show the bus" brings it back.
    if (!_fitted) await _fit();
    await _checkBusInView();
  }

  Size _size = Size.zero;

  /// Whether the bus is in the part of the map the student can see: on the map, and above whatever floats over its
  /// bottom edge. Logical pixels, as the map reports them.
  Future<void> _checkBusInView() async {
    final controller = _controller;
    final bus = widget.scene.bus;
    if (controller == null || !_styleReady || bus == null || _size.isEmpty) {
      widget.busInView.value = false;
      return;
    }
    final point = await controller.toScreenLocation(_latLng(bus));
    if (!mounted) return;
    const margin = 24.0;
    final visibleBottom = _size.height - widget.scene.coveredBottom;
    widget.busInView.value = point.x >= margin && point.x <= _size.width - margin && point.y >= margin && point.y <= visibleBottom - margin;
  }

  Future<void> _fit() async {
    final controller = _controller;
    final scene = widget.scene;
    if (controller == null || !_styleReady || scene.bus == null) return;
    _fitted = true;

    final points = <GeoPoint>[scene.bus!];
    final mine = scene.stops.where((s) => s.id == scene.myStopId).firstOrNull;
    if (mine != null) points.add(mine.location);

    if (points.length == 1) {
      await controller.animateCamera(CameraUpdate.newLatLngZoom(_latLng(points.first), 15));
      return;
    }
    final south = points.map((p) => p.latitude).reduce(math.min);
    final north = points.map((p) => p.latitude).reduce(math.max);
    final west = points.map((p) => p.longitude).reduce(math.min);
    final east = points.map((p) => p.longitude).reduce(math.max);
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(LatLngBounds(southwest: LatLng(south, west), northeast: LatLng(north, east)), left: 64, top: 120, right: 64, bottom: 64 + scene.coveredBottom),
    );
  }

  /// Before the bus is known, look at the stops; failing that, a neutral view that the first fix replaces.
  LatLng get _initialTarget {
    final scene = widget.scene;
    if (scene.bus != null) return _latLng(scene.bus!);
    if (scene.stops.isNotEmpty) return _latLng(scene.stops.first.location);
    return const LatLng(3.848, 11.5021);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final style = dark ? widget.darkStyleUrl : widget.styleUrl;
    if (_style != null && _style != style) _styleChanged();
    _style = style;
    return LayoutBuilder(builder: (context, constraints) {
      _size = constraints.biggest;
      return Semantics(
      label: BusinL10n.of(context).busMapLabel,
      child: MapLibreMap(
        styleString: style,
        initialCameraPosition: CameraPosition(target: _initialTarget, zoom: 13),
        onMapCreated: (controller) => _controller = controller,
        onStyleLoadedCallback: () async {
          final controller = _controller;
          if (controller == null) return;
          await _addArt(controller);
          // Two stops or a bus can sit close together: never hide one for the other.
          await controller.setSymbolIconAllowOverlap(true);
          _styleReady = true;
          _draw();
        },
        onCameraIdle: _checkBusInView,
        compassEnabled: false,
        myLocationEnabled: false,
        rotateGesturesEnabled: false,
        tiltGesturesEnabled: false,
      ),
    );
    });
  }
}
