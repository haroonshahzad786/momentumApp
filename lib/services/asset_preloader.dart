import 'package:flutter/material.dart';

/// Art shown by the intro carousel, in the order the user meets it.
///
/// On the web these are separate HTTP requests (~2.7 MB in total, most of it
/// `rocket_glow.gif`), so without warming them up the first paint of each page
/// waits on its own download — the "images appear late when I press NEXT"
/// problem. Pulling them into the image cache during the boot splash means the
/// bytes are already decoded and resident by the time a page needs them.
const List<String> kIntroImages = <String>[
  'assets/momentum/intro/rocket.png',
  'assets/momentum/intro/press.gif',
  'assets/momentum/intro/screen.png',
  'assets/momentum/intro/earth.png',
  'assets/momentum/intro/rocket_cores.gif',
  'assets/momentum/intro/rocket_glow.gif',
  'assets/momentum/intro/pyramid.gif',
];

/// Art the Cockpit's rocket-journey stage flips through.
///
/// The hull reveal swaps a frame every 780 ms, so an armor plate still being
/// fetched when its turn comes paints *nothing* — the wings layer renders and
/// the body is a hole. Warming these when the Cockpit mounts (not at boot:
/// they are ~2 MB and only the desktop shell shows them) means every plate is
/// decoded before the first arrival plays.
const List<String> kJourneyImages = <String>[
  'assets/momentum/journey/rocket-journey.png',
  'assets/momentum/journey/armor-1.png',
  'assets/momentum/journey/armor-2.png',
  'assets/momentum/journey/armor-3.png',
  'assets/momentum/journey/hull-wings.png',
  'assets/momentum/journey/planet-earth.png',
  'assets/momentum/journey/planet-moon.png',
  'assets/momentum/journey/planet-mars.png',
  'assets/momentum/journey/planet-jupiter.png',
  'assets/momentum/journey/planet-saturn.png',
  'assets/momentum/journey/planet-pluto.png',
  'assets/momentum/journey/station3.png',
];

/// Loads [kIntroImages] into Flutter's image cache.
///
/// Never throws: a missing or unreadable asset just falls back to loading
/// on demand, exactly as before. Safe to call more than once — assets already
/// in the cache resolve immediately.
Future<void> precacheIntroImages(BuildContext context) =>
    _precacheAll(kIntroImages, context);

/// Loads [kJourneyImages] into Flutter's image cache. Same guarantees as
/// [precacheIntroImages].
Future<void> precacheJourneyImages(BuildContext context) =>
    _precacheAll(kJourneyImages, context);

Future<void> _precacheAll(List<String> assets, BuildContext context) {
  return Future.wait<void>([
    for (final asset in assets)
      // Guarded per image, not just around the group: Future.wait rejects on
      // the first error, and one 404 must not sink the whole warm-up.
      precacheImage(AssetImage(asset), context, onError: (_, __) {})
          .catchError((Object _) {}),
  ]);
}
