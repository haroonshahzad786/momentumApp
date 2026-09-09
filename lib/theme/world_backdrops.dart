import 'package:flutter/material.dart';
import 'momentum_tokens.dart';

/// Which way the player is looking at a world.
enum WorldView {
  /// From orbit: the planet's limb curving across the lower third, open space
  /// above. Used for travel, dashboards and anything between arrivals.
  orbit,

  /// From the ground: standing on the surface with the landing pad in the
  /// foreground and the sky overhead. Used for arrival and departure.
  surface,
}

/// Per-world background art.
///
/// Each stop on the journey has its own environment: a distinct palette and a
/// colour temperature. Mars, Jupiter and Saturn are graded warm; Earth, Moon,
/// Pluto and the Station are graded cool. Pluto is the coldest, Jupiter the
/// warmest — so the player can tell where they are with the labels off.
///
/// Two views ([WorldView]) x two cuts, all WebP (28 files, ~2.8 MB; the same
/// set as PNG was over 100 MB, which is why none of these are PNG):
///
///  * [bg]    1284x2778 — a phone-screen backdrop. Drop-in replacement for the
///            painted `StarfieldBackground` on a planet-aware screen.
///  * [scene] 1440x4100 — the tall scrolling cut, same canvas shape as the old
///            `*.mp4` backdrops it replaces. The horizon sits low, so the
///            rocket has open sky to fly through above it.
///
/// The landing pad in the [WorldView.surface] art is one rendered asset
/// composited onto every world, so it is pixel-identical everywhere — same
/// octagon, same hazard chevrons, same running lights. Only the ground, sky and
/// the light falling on the pad change. [padSprite] is that asset on its own,
/// with alpha, if a screen needs to place or animate it directly.
class WorldBackdrops {
  WorldBackdrops._();

  /// Every world with art, in journey order. [MM.planets] plus the Station,
  /// which is the route's destination and never appears in that list.
  static const List<String> ids = [
    'earth', 'moon', 'mars', 'jupiter', 'saturn', 'pluto', 'station',
  ];

  static const String _dir = 'assets/momentum/worlds';

  /// Falls back to Earth rather than throwing — a missing backdrop should never
  /// be what takes a screen down.
  static String _safe(String id) => ids.contains(id) ? id : 'earth';

  static String _prefix(WorldView v) => v == WorldView.surface ? 'land-' : '';

  /// Phone-screen backdrop for [planetId] (1284x2778).
  static String bg(String planetId, {WorldView view = WorldView.orbit}) =>
      '$_dir/${_prefix(view)}bg-${_safe(planetId)}.webp';

  /// Tall scrolling cut for [planetId] (1440x4100).
  static String scene(String planetId, {WorldView view = WorldView.orbit}) =>
      '$_dir/${_prefix(view)}scene-${_safe(planetId)}.webp';

  /// The landing pad on its own, transparent, 1600x820. Already composited into
  /// every [WorldView.surface] plate — use this only to place or animate it
  /// yourself.
  static const String padSprite = '$_dir/pad.png';

  /// Warm worlds read amber/rust, cool worlds blue/teal. Handy when a screen
  /// wants to tint its own chrome to match the world it is sitting on.
  static bool isWarm(String planetId) =>
      const {'mars', 'jupiter', 'saturn'}.contains(_safe(planetId));

  /// Every asset path, for warming the image cache ahead of an arrival.
  static List<String> get allPaths => [
        for (final v in WorldView.values) ...[
          for (final id in ids) bg(id, view: v),
          for (final id in ids) scene(id, view: v),
        ],
        padSprite,
      ];

  /// Just the two plates a single world needs — cheaper to preload than
  /// [allPaths] when you know where the player is heading.
  static List<String> pathsFor(String planetId, {WorldView view = WorldView.orbit}) =>
      [bg(planetId, view: view), scene(planetId, view: view)];
}

/// Drop-in replacement for `StarfieldBackground` on a screen that knows which
/// world the player is on.
///
///     Positioned.fill(child: WorldBackdrop(planet: planet['id'] as String)),
///
/// Pass `view: WorldView.surface` for the ground-level plate with the landing
/// pad — that is the arrival shot; the default orbit view is everything else.
///
/// Fills the screen with [BoxFit.cover] — the art is built taller than a phone
/// so the crop always takes sky off the top, never the ground off the bottom.
class WorldBackdrop extends StatelessWidget {
  const WorldBackdrop({
    super.key,
    required this.planet,
    this.view = WorldView.orbit,
    this.scrim = 0,
    this.alignment = Alignment.bottomCenter,
  });

  /// A planet id from [MM.planets], or `'station'`.
  final String planet;

  /// Orbit (default) or the ground-level landing-pad plate.
  final WorldView view;

  /// Extra darkening under dense UI, 0–1. The art is already dark enough for
  /// white body text; reach for this only where a screen stacks a lot of copy.
  final double scrim;

  /// Which edge to hold when the crop bites. Bottom keeps the pad in frame.
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: const BoxDecoration(color: MM.pageBg),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              WorldBackdrops.bg(planet, view: view),
              fit: BoxFit.cover,
              alignment: alignment,
              filterQuality: FilterQuality.medium,
              // A backdrop that has not decoded yet should be the page colour,
              // not a white flash.
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
            if (scrim > 0)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: MM.pageBg.withOpacity(scrim.clamp(0, 1)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
