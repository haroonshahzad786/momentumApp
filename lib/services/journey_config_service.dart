import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// One stop in the current galaxy's catalogue (`config/journey.planets`).
@immutable
class JourneyPlanet {
  const JourneyPlanet({
    required this.id,
    required this.name,
    required this.color,
    this.enabled = true,
    this.start = false,
    this.mpRequired,
  });

  final String id;
  final String name;
  final Color color;
  final bool enabled;

  /// Earth — the fixed launch point, always on the route.
  final bool start;

  /// MP needed to reach this stop; null until the planet economy is designed.
  final int? mpRequired;

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'color': color};
}

/// The planet route players fly, read from `config/journey` (Will, 2026-09-25:
/// admin-controlled, default 5 destinations, up to 8; later galaxies are new
/// catalogues under a new `galaxyId`).
///
/// Mirrors `parseJourney` in vf-bridge/functions-flutter/economyConfig.js —
/// keep the two in step. Every screen reads [route]; until the doc loads (or if
/// it can't be read) the default 5-planet route is used, which is exactly the
/// route the app shipped with.
class JourneyConfigService {
  JourneyConfigService._();

  static const int minDestinations = 5;
  static const int maxDestinations = 8;

  static const List<JourneyPlanet> catalogue = [
    JourneyPlanet(id: 'earth', name: 'Earth', color: Color(0xFF3AA6FF), start: true),
    JourneyPlanet(id: 'spacestation', name: 'Space Station', color: Color(0xFF8FA3C7), enabled: false),
    JourneyPlanet(id: 'moon', name: 'Moon', color: Color(0xFFCFD2DC)),
    JourneyPlanet(id: 'mars', name: 'Mars', color: Color(0xFFD76B3A)),
    JourneyPlanet(id: 'jupiter', name: 'Jupiter', color: Color(0xFFD9A86B)),
    JourneyPlanet(id: 'saturn', name: 'Saturn', color: Color(0xFFE8C178)),
    JourneyPlanet(id: 'uranus', name: 'Uranus', color: Color(0xFF7FC8E8), enabled: false),
    JourneyPlanet(id: 'neptune', name: 'Neptune', color: Color(0xFF3FB8C9), enabled: false),
    JourneyPlanet(id: 'pluto', name: 'Pluto', color: Color(0xFF9AA3C7)),
  ];

  static final ValueNotifier<List<JourneyPlanet>> _route =
      ValueNotifier(_enabledOf(catalogue));

  /// Enabled stops in journey order, Earth first.
  static List<JourneyPlanet> get route => _route.value;

  /// Rebuild hook for widgets that draw the route.
  static ValueListenable<List<JourneyPlanet>> get listenable => _route;

  static String galaxyId = 'milky_way';

  static bool _started = false;

  /// Starts listening to `config/journey` once (signed-in read per the rules).
  /// Safe to call from anywhere; later calls are no-ops.
  static void ensureLoaded({FirebaseFirestore? db}) {
    if (_started) return;
    _started = true;
    (db ?? FirebaseFirestore.instance)
        .collection('config')
        .doc('journey')
        .snapshots()
        .listen((snap) {
      final parsed = parse(snap.data());
      galaxyId = parsed.$1;
      final next = _enabledOf(parsed.$2);
      if (!listEquals(next.map((p) => p.id).toList(), route.map((p) => p.id).toList()) ||
          !listEquals(next.map((p) => p.name).toList(), route.map((p) => p.name).toList())) {
        _route.value = next;
      }
    }, onError: (_) {/* keep the current route */});
  }

  static List<JourneyPlanet> _enabledOf(List<JourneyPlanet> all) =>
      List.unmodifiable(all.where((p) => p.enabled));

  /// (galaxyId, full catalogue with enabled flags). Pure — used by the admin
  /// card too, so what it shows is exactly what players get.
  static (String, List<JourneyPlanet>) parse(Map<String, dynamic>? doc) {
    final byId = <String, Map>{};
    final raw = doc?['planets'];
    if (raw is List) {
      for (final p in raw) {
        if (p is Map && p['id'] != null) byId['${p['id']}'] = p;
      }
    }
    var out = [
      for (final d in catalogue)
        () {
          final o = byId[d.id] ?? const {};
          final name = o['name'] is String && (o['name'] as String).trim().isNotEmpty
              ? (o['name'] as String).trim()
              : d.name;
          final hex = o['color'] is String ? o['color'] as String : '';
          final color = RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(hex)
              ? Color(int.parse('FF${hex.substring(1)}', radix: 16))
              : d.color;
          final mp = o['mpRequired'];
          return JourneyPlanet(
            id: d.id,
            name: name,
            color: color,
            start: d.start,
            enabled: d.start ? true : (o['enabled'] is bool ? o['enabled'] as bool : d.enabled),
            mpRequired: mp is num && mp >= 0 ? mp.toInt() : null,
          );
        }(),
    ];
    final n = out.where((p) => !p.start && p.enabled).length;
    if (n < minDestinations || n > maxDestinations) {
      out = [
        for (final p in out)
          JourneyPlanet(
            id: p.id,
            name: p.name,
            color: p.color,
            start: p.start,
            mpRequired: p.mpRequired,
            enabled: p.start || catalogue.firstWhere((d) => d.id == p.id).enabled,
          ),
      ];
    }
    final g = doc?['galaxyId'];
    return (g is String && g.isNotEmpty ? g : 'milky_way', out);
  }
}
