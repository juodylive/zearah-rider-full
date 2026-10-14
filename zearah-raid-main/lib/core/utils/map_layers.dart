import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/config.dart';
import 'theme/project_color.dart';

/// Single source of truth for every map in the app.
/// Fixes: blurry tiles on high-DPI screens (`{r}` was never resolved because
/// retinaMode was off), no dark map, no zoom limits, flicker while panning.
class AppTileLayer extends StatelessWidget {
  const AppTileLayer({super.key, this.dark});

  /// Force light/dark. When null it follows the in-app theme switch.
  final bool? dark;

  static String _url(bool isDark) =>
      'https://tiles.stadiamaps.com/tiles/'
      '${isDark ? 'alidade_smooth_dark' : 'osm_bright'}'
      '/{z}/{x}/{y}{r}.png?api_key=${Config.stadiaKey}';

  @override
  Widget build(BuildContext context) {
    final isDark = dark ?? notifires.getIsDark;
    return TileLayer(
      key: ValueKey('tiles_$isDark'),
      urlTemplate: _url(isDark),
      userAgentPackageName: 'com.zearah.rider',
      retinaMode: RetinaMode.isHighDensity(context),
      maxNativeZoom: 20,
      maxZoom: 21,
      keepBuffer: 4,
      panBuffer: 2,
      tileDisplay: const TileDisplay.fadeIn(
        duration: Duration(milliseconds: 150),
      ),
      evictErrorTileStrategy: EvictErrorTileStrategy.notVisibleRespectMargin,
    );
  }
}

/// Shared options. Rotation is disabled so the map cannot twist by accident.
MapOptions appMapOptions({
  required LatLng center,
  double zoom = 15,
  void Function(TapPosition, LatLng)? onTap,
  void Function(MapCamera, bool)? onPositionChanged,
  VoidCallback? onMapReady,
  Key? key,
}) {
  return MapOptions(
    initialCenter: center,
    initialZoom: zoom,
    minZoom: 3,
    maxZoom: 21,
    onTap: onTap,
    onMapReady: onMapReady,
    onPositionChanged: onPositionChanged == null
        ? null
        : (camera, hasGesture) => onPositionChanged(camera, hasGesture),
    interactionOptions: const InteractionOptions(
      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
    ),
  );
}

/// Route line(s) with a casing so they stay readable on any map colour.
class AppRoutePolylines extends StatelessWidget {
  const AppRoutePolylines({super.key, required this.routes});

  final Iterable<List<LatLng>> routes;

  @override
  Widget build(BuildContext context) {
    final valid = routes.where((r) => r.length >= 2).toList();
    if (valid.isEmpty) return const SizedBox.shrink();
    final isDark = notifires.getIsDark;
    return PolylineLayer(
      polylines: valid
          .map((points) => Polyline(
                points: points,
                strokeWidth: 6,
                color:
                    isDark ? const Color(0xFF4DA3FF) : const Color(0xFF1A73E8),
                borderStrokeWidth: 2,
                borderColor: isDark ? const Color(0xFF0B1B2E) : Colors.white,
                strokeCap: StrokeCap.round,
                strokeJoin: StrokeJoin.round,
              ))
          .toList(),
    );
  }
}
