import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'data_store.dart';

/// A single geocoding result.
class GeoPlace {
  final String name;
  final double lat;
  final double lon;
  const GeoPlace(this.name, this.lat, this.lon);
}

/// Thrown when the provider asks us to slow down (HTTP 429 / 503).
class GeocodingRateLimited implements Exception {
  final Duration retryAfter;
  const GeocodingRateLimited(this.retryAfter);
}

/// Swap point: to move to Google Places / Stadia later, implement this
/// interface and change `GeocodingService.instance.provider`. No screen changes.
abstract class GeocodingProvider {
  Future<List<GeoPlace>> search(
    String query, {
    double? biasLat,
    double? biasLon,
    String? lang,
    int limit = 5,
  });
}

/// Temporary provider (public OSM server, ~1 request/second policy).
class NominatimProvider implements GeocodingProvider {
  static const _headers = {
    'User-Agent': 'ZearahRiderApp/1.0 (contact@zearah.dpdns.org)'
  };

  @override
  Future<List<GeoPlace>> search(
    String query, {
    double? biasLat,
    double? biasLon,
    String? lang,
    int limit = 5,
  }) async {
    final params = <String, String>{
      'format': 'json',
      'addressdetails': '0',
      'limit': '$limit',
      'q': query,
      if (lang != null && lang.isNotEmpty) 'accept-language': lang,
      // Soft bias (bounded=0): prefer results near the rider, never exclude.
      if (biasLat != null && biasLon != null) ...{
        'viewbox': '${biasLon - 0.5},${biasLat + 0.5},'
            '${biasLon + 0.5},${biasLat - 0.5}',
        'bounded': '0',
      },
    };
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', params);
    final res =
        await http.get(uri, headers: _headers).timeout(const Duration(seconds: 8));

    if (res.statusCode == 429 || res.statusCode == 503) {
      final secs = int.tryParse(res.headers['retry-after'] ?? '') ?? 30;
      throw GeocodingRateLimited(Duration(seconds: secs.clamp(5, 120)));
    }
    if (res.statusCode != 200) return const [];

    final List data = json.decode(utf8.decode(res.bodyBytes));
    final out = <GeoPlace>[];
    for (final p in data) {
      final lat = double.tryParse('${p['lat']}');
      final lon = double.tryParse('${p['lon']}');
      final name = '${p['display_name'] ?? ''}';
      if (lat != null && lon != null && name.isNotEmpty) {
        out.add(GeoPlace(name, lat, lon));
      }
    }
    return out;
  }
}

class _CacheEntry {
  final List<GeoPlace> places;
  final DateTime at;
  _CacheEntry(this.places) : at = DateTime.now();
}

/// Adds caching, in-flight de-duplication, rate limiting/back-off, location
/// bias and language to any [GeocodingProvider].
class GeocodingService {
  GeocodingService._();
  static final GeocodingService instance = GeocodingService._();

  GeocodingProvider provider = NominatimProvider();

  static const int minChars = 3;
  static const Duration _ttl = Duration(minutes: 10);
  static const Duration _minGap = Duration(milliseconds: 1100);
  static const int _maxCache = 60;

  final LinkedHashMap<String, _CacheEntry> _cache = LinkedHashMap();
  final Map<String, Future<List<GeoPlace>>> _inFlight = {};
  // Every suggestion we have shown, so choosing one needs no second request.
  final Map<String, GeoPlace> _byName = {};

  DateTime? _cooldownUntil;
  DateTime _lastRequest = DateTime.fromMillisecondsSinceEpoch(0);
  Position? _bias;
  DateTime _biasAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// App language so addresses are not returned in mixed languages.
  String get language {
    final c = lanBox.get('lCode');
    final s = c == null ? 'en' : c.toString();
    return s.isEmpty ? 'en' : s;
  }

  bool get isCoolingDown =>
      _cooldownUntil != null && DateTime.now().isBefore(_cooldownUntil!);

  Future<Position?> _biasPosition() async {
    if (_bias != null &&
        DateTime.now().difference(_biasAt) < const Duration(minutes: 5)) {
      return _bias;
    }
    try {
      _bias = await Geolocator.getLastKnownPosition();
      _biasAt = DateTime.now();
    } catch (_) {}
    return _bias;
  }

  void _remember(List<GeoPlace> places) {
    for (final p in places) {
      _byName[p.name] = p;
    }
    if (_byName.length > 300) {
      _byName.remove(_byName.keys.first);
    }
  }

  /// Autocomplete search. Throws [GeocodingRateLimited] while cooling down.
  Future<List<GeoPlace>> search(String query) async {
    final q = query.trim();
    if (q.length < minChars) return const [];

    final key = '$language|${q.toLowerCase()}';

    final hit = _cache[key];
    if (hit != null && DateTime.now().difference(hit.at) < _ttl) {
      _cache.remove(key); // refresh LRU position
      _cache[key] = hit;
      return hit.places;
    }

    if (isCoolingDown) {
      throw GeocodingRateLimited(_cooldownUntil!.difference(DateTime.now()));
    }

    // Same query already on the wire? Share it.
    final pending = _inFlight[key];
    if (pending != null) return pending;

    final future = _fetch(q, key, limit: 5);
    _inFlight[key] = future;
    try {
      return await future;
    } finally {
      _inFlight.remove(key);
    }
  }

  /// Coordinates for an address string. Uses the suggestion cache first, so
  /// picking a suggestion normally costs zero extra network requests.
  Future<GeoPlace?> resolve(String address) async {
    final a = address.trim();
    if (a.isEmpty) return null;
    final known = _byName[a];
    if (known != null) return known;

    final key = '$language|resolve|${a.toLowerCase()}';
    final hit = _cache[key];
    if (hit != null && DateTime.now().difference(hit.at) < _ttl) {
      return hit.places.isEmpty ? null : hit.places.first;
    }
    if (isCoolingDown) {
      throw GeocodingRateLimited(_cooldownUntil!.difference(DateTime.now()));
    }
    final list = await _fetch(a, key, limit: 1);
    return list.isEmpty ? null : list.first;
  }

  Future<List<GeoPlace>> _fetch(String q, String key, {required int limit}) async {
    // Respect the ~1 request/second public-server policy.
    final gap = DateTime.now().difference(_lastRequest);
    if (gap < _minGap) await Future.delayed(_minGap - gap);
    _lastRequest = DateTime.now();

    final pos = await _biasPosition();
    try {
      final places = await provider.search(
        q,
        biasLat: pos?.latitude,
        biasLon: pos?.longitude,
        lang: language,
        limit: limit,
      );
      _remember(places);
      _cache[key] = _CacheEntry(places);
      while (_cache.length > _maxCache) {
        _cache.remove(_cache.keys.first);
      }
      return places;
    } on GeocodingRateLimited catch (e) {
      _cooldownUntil = DateTime.now().add(e.retryAfter);
      rethrow;
    }
  }

  void clear() {
    _cache.clear();
    _byName.clear();
    _inFlight.clear();
  }
}
