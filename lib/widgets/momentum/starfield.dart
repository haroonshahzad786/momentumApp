import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../theme/momentum_tokens.dart';

/// Animated starfield + radial nebula background.
/// Drop this at the bottom of a Stack — paints itself, ignores hits.
class StarfieldBackground extends StatefulWidget {
  const StarfieldBackground({
    super.key,
    this.showScanlines = true,
    this.showStars = true,
    this.showSpaceObjects = true,
    this.accent,
  });

  final bool showScanlines;

  /// Set false to keep only the nebula/gradient base — used where an animated
  /// starfield is layered on top and two sets of stars would fight.
  final bool showStars;

  /// Distant galaxies, tumbling asteroids and the occasional meteor. Rides on
  /// [showStars] — a screen that supplies its own star layer supplies its own
  /// scene. Set false on its own to quiet a busy screen down to plain stars.
  final bool showSpaceObjects;
  final Color? accent;

  @override
  State<StarfieldBackground> createState() => _StarfieldBackgroundState();
}

class _StarfieldBackgroundState extends State<StarfieldBackground>
    with SingleTickerProviderStateMixin {
  /// Monotonic seconds since the field appeared. Drives the drift, each star's
  /// twinkle phase and the meteor schedule; handed to the painters as a repaint
  /// listenable so only the canvas re-paints, not the whole subtree.
  final ValueNotifier<double> _time = ValueNotifier<double>(0);

  // Started in initState, NOT via a `late final` initialiser: nothing in build
  // reads the ticker, so a lazy field would not be created until dispose()
  // touched it — the clock would never run and the field would sit frozen.
  Ticker? _ticker;

  /// Obstacle sprites, once they have decoded. Null until then — the debris
  /// layer simply doesn't paint on the first frame or two.
  List<ui.Image>? _sprites;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      _time.value = elapsed.inMicroseconds / 1e6;
    })
      ..start();

    if (_SpaceArt.images != null) {
      _sprites = _SpaceArt.images;
    } else {
      _SpaceArt.load().then(
        (images) {
          if (mounted) setState(() => _sprites = images);
        },
        // A missing sprite must not take the whole background down — the stars
        // and galaxies are procedural and still fine on their own.
        onError: (Object e, StackTrace s) =>
            debugPrint('Starfield: obstacle sprites unavailable — $e'),
      );
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent ?? MM.blue;
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // base radial nebula
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -1.2),
                radius: 1.3,
                colors: [
                  accent.withOpacity(0.18),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, 1.2),
                radius: 1.5,
                colors: [Color(0x269B5CFF), Colors.transparent],
              ),
            ),
          ),
          DecoratedBox(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [Color(0xFF111C4E), Color(0xFF060B22), Color(0xFF02030A)],
                stops: [0.0, 0.6, 1.0],
              ),
            ),
          ),
          // Deep space sits behind the stars; debris tumbles in front of them.
          if (widget.showStars && widget.showSpaceObjects)
            RepaintBoundary(
              child: CustomPaint(painter: _GalaxyPainter(_time, accent)),
            ),
          // stars
          if (widget.showStars)
            RepaintBoundary(
              child: CustomPaint(painter: _StarsPainter(_time)),
            ),
          if (widget.showStars &&
              widget.showSpaceObjects &&
              _sprites != null)
            RepaintBoundary(
              child: CustomPaint(painter: _DebrisPainter(_time, _sprites!)),
            ),
          if (widget.showScanlines)
            CustomPaint(painter: _ScanlinesPainter()),
        ],
      ),
    );
  }
}

class _StarsPainter extends CustomPainter {
  _StarsPainter(this.time) : super(repaint: time);

  /// Seconds since the field started — see [_StarfieldBackgroundState._time].
  final ValueListenable<double> time;

  // Fixed seed so stars don't jitter between frames.
  static final List<_Star> _stars = _generate();

  static List<_Star> _generate() {
    final rng = math.Random(42);
    return List.generate(90, (_) {
      final r = rng.nextDouble();
      // Bigger star = nearer = drifts faster, so the field has parallax
      // instead of sliding as one flat sheet.
      final radius = 0.6 + rng.nextDouble() * 1.4;
      return _Star(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        radius: radius,
        speed: 20 + ((radius - 0.6) / 1.4) * 44,
        twinkleRate: 0.18 + rng.nextDouble() * 0.32,
        phase: rng.nextDouble(),
        color: r < 0.85
            ? Colors.white
            : (r < 0.92
                ? const Color(0xFFFFC88C)
                : const Color(0xFF8CC8FF)),
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final t = time.value;
    for (final s in _stars) {
      // Drift downward and wrap — modulo on the normalised position keeps the
      // loop seamless at any viewport height.
      final y = ((s.y + s.speed * t / size.height) % 1.0) * size.height;
      final twinkle = 0.72 +
          0.28 * math.sin((s.phase + s.twinkleRate * t) * 2 * math.pi);
      canvas.drawCircle(
        Offset(s.x * size.width, y),
        s.radius,
        Paint()..color = s.color.withOpacity(twinkle.clamp(0.0, 1.0)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarsPainter old) => false;
}

class _Star {
  const _Star({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.twinkleRate,
    required this.phase,
    required this.color,
  });
  final double x;
  final double y;
  final double radius;

  /// Downward drift in logical px per second.
  final double speed;

  /// Twinkle cycles per second, and where in that cycle this star starts —
  /// staggered so the field shimmers instead of pulsing in unison.
  final double twinkleRate;
  final double phase;
  final Color color;
}

// ═══════════════════════════════════════════════════════════════
// DEEP SPACE — distant galaxies drifting behind the starfield
// ═══════════════════════════════════════════════════════════════
class _GalaxyPainter extends CustomPainter {
  _GalaxyPainter(this.time, this.accent) : super(repaint: time);
  final ValueListenable<double> time;
  final Color accent;

  static final List<_Galaxy> _galaxies = _generate();

  static List<_Galaxy> _generate() {
    final rng = math.Random(1977);
    const specs = [
      // cx, cy (fraction of the viewport), radius (fraction of the short side),
      // tilt, spin rad/s
      (0.15, 0.20, 0.20, -0.55, 0.011),
      (0.84, 0.71, 0.14, 0.95, -0.008),
      (0.62, 0.09, 0.09, 0.30, 0.016),
    ];
    return [
      for (final s in specs)
        _Galaxy(
          cx: s.$1,
          cy: s.$2,
          radius: s.$3,
          tilt: s.$4,
          spin: s.$5,
          // A dusting of suns inside the disc, in unit-disc coordinates, so a
          // galaxy reads as stars rather than a plain smudge.
          motes: List.generate(16, (_) {
            final a = rng.nextDouble() * 2 * math.pi;
            // sqrt keeps them spread evenly instead of clumping at the core
            final d = math.sqrt(rng.nextDouble());
            return (math.cos(a) * d, math.sin(a) * d,
                0.5 + rng.nextDouble() * 0.9);
          }),
        ),
    ];
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final t = time.value;
    final base = math.min(size.width, size.height);

    for (final g in _galaxies) {
      final r = g.radius * base;
      if (r < 8) continue;
      canvas.save();
      canvas.translate(g.cx * size.width, g.cy * size.height);
      canvas.rotate(g.tilt + t * g.spin);
      // Flatten the disc so we're looking at it edge-on-ish, not face-on.
      canvas.scale(1.0, 0.38);

      // outer halo
      canvas.drawCircle(
        Offset.zero,
        r,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset.zero,
            r,
            [
              accent.withOpacity(0.16),
              accent.withOpacity(0.05),
              const Color(0x00000000),
            ],
            [0.0, 0.5, 1.0],
          ),
      );

      // two opposing arms, offset from the core
      for (var a = 0; a < 2; a++) {
        canvas.save();
        canvas.rotate(a * math.pi);
        canvas.translate(r * 0.36, 0);
        canvas.drawCircle(
          Offset.zero,
          r * 0.55,
          Paint()
            ..shader = ui.Gradient.radial(
              Offset.zero,
              r * 0.55,
              [Colors.white.withOpacity(0.09), const Color(0x00FFFFFF)],
            ),
        );
        canvas.restore();
      }

      // core
      canvas.drawCircle(
        Offset.zero,
        r * 0.26,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset.zero,
            r * 0.26,
            [
              Colors.white.withOpacity(0.42),
              accent.withOpacity(0.16),
              const Color(0x00000000),
            ],
            [0.0, 0.45, 1.0],
          ),
      );

      // individual suns
      for (final m in g.motes) {
        canvas.drawCircle(
          Offset(m.$1 * r * 0.92, m.$2 * r * 0.92),
          m.$3,
          Paint()..color = Colors.white.withOpacity(0.30),
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _GalaxyPainter old) => old.accent != accent;
}

class _Galaxy {
  const _Galaxy({
    required this.cx,
    required this.cy,
    required this.radius,
    required this.tilt,
    required this.spin,
    required this.motes,
  });
  final double cx;
  final double cy;
  final double radius;
  final double tilt;

  /// Radians per second — slow enough that it reads as depth, not spin.
  final double spin;

  /// (x, y) in unit-disc coordinates plus a pixel radius.
  final List<(double, double, double)> motes;
}

// ═══════════════════════════════════════════════════════════════
// OBSTACLE ART — the journey sprites, decoded once per app run
// ═══════════════════════════════════════════════════════════════
class _SpaceArt {
  /// The six rocks were cut out of the original `asteroids.png` field sheet;
  /// the crate and saucer are the trimmed originals.
  static const List<String> assets = [
    'assets/momentum/space/asteroid_1.png',
    'assets/momentum/space/asteroid_2.png',
    'assets/momentum/space/asteroid_3.png',
    'assets/momentum/space/asteroid_4.png',
    'assets/momentum/space/asteroid_5.png',
    'assets/momentum/space/asteroid_6.png',
    'assets/momentum/space/crate.png',
    'assets/momentum/space/ufo.png',
  ];
  static const int rockCount = 6;
  static const int crate = 6;
  static const int ufo = 7;

  static List<ui.Image>? images;
  static Future<List<ui.Image>>? _pending;

  /// Shared across every starfield on every screen — decoding these per screen
  /// would be pure waste, since the background is mounted app-wide.
  static Future<List<ui.Image>> load() {
    final ready = images;
    if (ready != null) return Future<List<ui.Image>>.value(ready);
    return _pending ??= Future.wait(assets.map(_decode)).then((list) {
      images = list;
      return list;
    }, onError: (Object e, StackTrace s) {
      // Let the next starfield retry rather than caching the failure.
      _pending = null;
      throw e;
    });
  }

  static Future<ui.Image> _decode(String path) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    return (await codec.getNextFrame()).image;
  }
}

// ═══════════════════════════════════════════════════════════════
// DEBRIS — falling obstacles and the occasional meteor
// ═══════════════════════════════════════════════════════════════
class _DebrisPainter extends CustomPainter {
  _DebrisPainter(this.time, this.sprites) : super(repaint: time);
  final ValueListenable<double> time;
  final List<ui.Image> sprites;

  /// Rolled once per app run — unseeded on purpose, so the field is arranged
  /// differently each launch but holds still while you use the app.
  static final List<_Obstacle> _obstacles = _generateObstacles();

  static List<_Obstacle> _generateObstacles() {
    final rng = math.Random();
    _Obstacle rock() {
      // 20–70px wide. Bigger reads as nearer, so it falls faster and sits at a
      // higher opacity; the small ones hang back in the haze.
      final width = 20 + rng.nextDouble() * 50;
      final near = (width - 20) / 50;
      return _Obstacle(
        sprite: rng.nextInt(_SpaceArt.rockCount),
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        width: width,
        // Randomised around the depth baseline so no two fall in step.
        speed: (12 + near * 30) * (0.7 + rng.nextDouble() * 0.7),
        spin: (rng.nextDouble() - 0.5) * 0.5,
        phase: rng.nextDouble() * 2 * math.pi,
        sway: 6 + rng.nextDouble() * 18,
        drift: 0,
        opacity: 0.4 + near * 0.4,
      );
    }

    return [
      for (var i = 0; i < 7; i++) rock(),
      // A supply crate, bigger and tumbling lazily.
      _Obstacle(
        sprite: _SpaceArt.crate,
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        width: 34 + rng.nextDouble() * 16,
        speed: 16 + rng.nextDouble() * 14,
        spin: (rng.nextDouble() - 0.5) * 0.3,
        phase: rng.nextDouble() * 2 * math.pi,
        sway: 10,
        drift: 0,
        opacity: 0.7,
      ),
      // The saucer flies rather than falls: mostly lateral, sinking gently, and
      // it banks instead of tumbling — a spinning UFO would read as debris.
      _Obstacle(
        sprite: _SpaceArt.ufo,
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        width: 46 + rng.nextDouble() * 22,
        speed: 5 + rng.nextDouble() * 5,
        spin: 0,
        phase: rng.nextDouble() * 2 * math.pi,
        sway: 14,
        drift: (rng.nextBool() ? 1 : -1) * (26 + rng.nextDouble() * 20),
        opacity: 0.8,
      ),
    ];
  }

  /// Meteors are scheduled off the clock rather than spawned at random, so the
  /// painter stays stateless: each slot is visible for [_Meteor.duty] of its
  /// own period and dark the rest of the time. Co-prime-ish periods keep them
  /// from ever falling into lockstep.
  static const List<_Meteor> _meteors = [
    _Meteor(
        period: 9.0,
        offset: 0.10,
        x0: -0.08,
        y0: 0.02,
        angle: 0.62,
        duty: 0.10,
        tail: 0.16,
        width: 2.4,
        color: Colors.white,
        rocky: false),
    _Meteor(
        period: 14.0,
        offset: 0.55,
        x0: 1.06,
        y0: 0.05,
        angle: 2.45,
        duty: 0.12,
        tail: 0.13,
        width: 2.0,
        color: Color(0xFFBFDBFF),
        rocky: false),
    // The big one: a genuine falling asteroid with a burning trail.
    _Meteor(
        period: 23.0,
        offset: 0.34,
        x0: -0.06,
        y0: 0.26,
        angle: 0.44,
        duty: 0.18,
        tail: 0.20,
        width: 3.6,
        color: Color(0xFFFFB067),
        rocky: true),
  ];

  /// Draws sprite [index] centred on the current origin, [width] px across.
  void _drawSprite(Canvas canvas, int index, double width, double alpha) {
    final img = sprites[index];
    if (img.width == 0) return;
    final scale = width / img.width;
    canvas.save();
    canvas.scale(scale);
    canvas.drawImage(
      img,
      Offset(-img.width / 2, -img.height / 2),
      Paint()
        ..filterQuality = FilterQuality.medium
        ..color = Color.fromRGBO(255, 255, 255, alpha.clamp(0.0, 1.0)),
    );
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || sprites.isEmpty) return;
    final t = time.value;

    // ── falling obstacles ──
    // Positions wrap over a 1.3 range rather than 1.0, so a sprite slides in
    // from off-screen and out the far side instead of popping into existence
    // at the edge.
    for (final o in _obstacles) {
      final v = (o.y + o.speed * t / size.height) % 1.3;
      final y = (v - 0.15) * size.height;
      final u = (o.x + o.drift * t / size.width) % 1.3;
      final x = (u - 0.15) * size.width +
          math.sin(t * 0.13 + o.phase) * o.sway;

      canvas.save();
      canvas.translate(x, y);
      if (o.spin != 0) {
        canvas.rotate(o.phase + o.spin * t);
      } else {
        // Banks side to side instead of tumbling.
        canvas.rotate(math.sin(t * 0.35 + o.phase) * 0.09);
      }
      _drawSprite(canvas, o.sprite, o.width, o.opacity);
      canvas.restore();
    }

    // ── meteors ──
    final travel = math.sqrt(size.width * size.width +
            size.height * size.height) *
        1.15;
    for (final m in _meteors) {
      final phase = ((t / m.period) + m.offset) % 1.0;
      if (phase > m.duty) continue;
      final p = phase / m.duty; // 0 → 1 across the flight
      // Fade in off one edge and out again, so nothing pops into existence.
      final alpha = math.sin(p * math.pi).clamp(0.0, 1.0);
      final dx = math.cos(m.angle);
      final dy = math.sin(m.angle);
      final head = Offset(
        m.x0 * size.width + dx * travel * p,
        m.y0 * size.height + dy * travel * p,
      );
      final tailLen = m.tail * size.width;
      final tail = head - Offset(dx * tailLen, dy * tailLen);

      canvas.drawLine(
        tail,
        head,
        Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = m.width
          ..shader = ui.Gradient.linear(
            tail,
            head,
            [m.color.withOpacity(0), m.color.withOpacity(0.9 * alpha)],
          ),
      );

      if (m.rocky) {
        // Warm glow, then the rock itself tumbling as it burns in.
        canvas.drawCircle(
          head,
          m.width * 3.2,
          Paint()
            ..shader = ui.Gradient.radial(
              head,
              m.width * 3.2,
              [m.color.withOpacity(0.5 * alpha), m.color.withOpacity(0)],
            ),
        );
        canvas.save();
        canvas.translate(head.dx, head.dy);
        canvas.rotate(t * 1.6);
        _drawSprite(canvas, 0, m.width * 7, alpha);
        canvas.restore();
      } else {
        canvas.drawCircle(
          head,
          m.width * 0.85,
          Paint()..color = Colors.white.withOpacity(alpha),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DebrisPainter old) => old.sprites != sprites;
}

class _Obstacle {
  const _Obstacle({
    required this.sprite,
    required this.x,
    required this.y,
    required this.width,
    required this.speed,
    required this.spin,
    required this.phase,
    required this.sway,
    required this.drift,
    required this.opacity,
  });

  /// Index into [_SpaceArt.assets].
  final int sprite;

  /// Starting position as a fraction of the viewport.
  final double x;
  final double y;

  /// On-screen width in logical px; the sprite keeps its own aspect.
  final double width;

  /// Fall rate in px/s, tumble in rad/s (0 = banks instead), and how far it
  /// wanders sideways as it goes.
  final double speed;
  final double spin;
  final double phase;
  final double sway;

  /// Sustained horizontal travel in px/s — the saucer's cruise.
  final double drift;
  final double opacity;
}

class _Meteor {
  const _Meteor({
    required this.period,
    required this.offset,
    required this.x0,
    required this.y0,
    required this.angle,
    required this.duty,
    required this.tail,
    required this.width,
    required this.color,
    required this.rocky,
  });

  /// Seconds between appearances, and where in that cycle this slot starts.
  final double period;
  final double offset;

  /// Launch point as a fraction of the viewport — off-screen by design.
  final double x0;
  final double y0;

  /// Heading in radians (0 = due right, y grows downward).
  final double angle;

  /// Fraction of [period] the meteor is actually in flight.
  final double duty;

  /// Trail length as a fraction of viewport width.
  final double tail;
  final double width;
  final Color color;

  /// Draws a tumbling rock at the head instead of a bright point.
  final bool rocky;
}

class _ScanlinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.025)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScanlinesPainter old) => false;
}
