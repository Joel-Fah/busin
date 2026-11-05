import 'dart:math' as math;

import 'package:busin_core/busin_core.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'map_scene.dart';

/// Draws a [MapScene] with MapLibre: the base map from [styleUrl] (OpenFreeMap by default), a small dot for each
/// stop, a larger one for the student's own stop, and the bus. It does nothing the scene does not say, so all the
/// decisions live in the screen and its providers, which are tested; this file only draws.
class MapLibreSurface extends StatefulWidget {
  const MapLibreSurface({super.key, required this.scene, required this.styleUrl, required this.recenter});

  final MapScene scene;
  final String styleUrl;
  final ValueListenable<int> recenter;

  @override
  State<MapLibreSurface> createState() => _MapLibreSurfaceState();
}

class _MapLibreSurfaceState extends State<MapLibreSurface> {
  static const _stopColor = '#7A8C90';
  static const _myStopColor = '#F5951F';
  static const _busColor = '#002A33';

  MapLibreMapController? _controller;
  bool _styleReady = false;
  bool _fitted = false;
  List<Circle> _stopCircles = const [];
  Circle? _busCircle;
  MapScene? _drawn;

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

    // Stops change rarely; redraw them only when they or the highlighted one did.
    if (previous == null || previous.myStopId != scene.myStopId || previous.stops.length != scene.stops.length) {
      if (_stopCircles.isNotEmpty) await controller.removeCircles(_stopCircles);
      _stopCircles = await controller.addCircles([
        for (final stop in scene.stops)
          CircleOptions(
            geometry: _latLng(stop.location),
            circleRadius: stop.id == scene.myStopId ? 9 : 5,
            circleColor: stop.id == scene.myStopId ? _myStopColor : _stopColor,
            circleStrokeWidth: 2,
            circleStrokeColor: '#FFFFFF',
          ),
      ]);
    }

    final bus = scene.bus;
    if (bus == null) {
      if (_busCircle != null) {
        await controller.removeCircle(_busCircle!);
        _busCircle = null;
      }
      return;
    }
    if (_busCircle == null) {
      _busCircle = await controller.addCircle(
        CircleOptions(geometry: _latLng(bus), circleRadius: 12, circleColor: _busColor, circleStrokeWidth: 3, circleStrokeColor: '#FFFFFF'),
      );
    } else {
      await controller.updateCircle(_busCircle!, CircleOptions(geometry: _latLng(bus)));
    }
    // Show the bus the first time it appears; after that the student moves the map and "Show the bus" brings it back.
    if (!_fitted) await _fit();
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
      CameraUpdate.newLatLngBounds(LatLngBounds(southwest: LatLng(south, west), northeast: LatLng(north, east)), left: 64, top: 64, right: 64, bottom: 64),
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
    return Semantics(
      label: BusinL10n.of(context).busMapLabel,
      child: MapLibreMap(
        styleString: widget.styleUrl,
        initialCameraPosition: CameraPosition(target: _initialTarget, zoom: 13),
        onMapCreated: (controller) => _controller = controller,
        onStyleLoadedCallback: () {
          _styleReady = true;
          _draw();
        },
        compassEnabled: false,
        myLocationEnabled: false,
        rotateGesturesEnabled: false,
        tiltGesturesEnabled: false,
      ),
    );
  }
}
