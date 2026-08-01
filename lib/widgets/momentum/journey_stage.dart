import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../services/asset_preloader.dart';
import '../../services/offline.dart';
import '../../theme/momentum_tokens.dart';
import 'rocket_widget.dart';

// ═══════════════════════════════════════════════════════════════
// The world — laid out ONCE in fixed logical px; only the camera moves.
// Geometry is verbatim from design/ref/design_handoff_rocket_journey.
// ═══════════════════════════════════════════════════════════════
const double kWorldW = 2000;
const double kWorldH = 5800;
const double kLaneX = 1000;
const double kContentTop = 700;
const double kContentBottom = 5700;
const double kRocketW = 86;
const double kRocketH = kRocketW * 980 / 516;

/// How far a leg's bezier control point is pushed off the straight line between
/// its two seats. Alternating the sign leg by leg is what makes the route an
/// S-sweep instead of a row of identical bulges.
const double kBow = 330;

/// One stop on the route. [y] is the body's centre in world px and [dx] its
/// offset from the lane centre — planets sit staggered left and right so the
/// legs between them read as arcs; Earth and the Station stay centred. [w] is
/// its drawn width, [ar] the source PNG's aspect (w/h), and [seatF] the
/// fraction of its height above centre where the rocket rests — Saturn and the
/// Station use a smaller seat because their rings/structure overhang the body.
class JourneyStop {
  const JourneyStop(this.id, this.name, this.asset, this.y, this.dx, this.w,
      this.ar, this.seatF);

  final String id;
  final String name;
  final String asset;
  final double y;
  final double dx;
  final double w;
  final double ar;
  final double seatF;

  double get h => w / ar;
  double get halfH => h / 2;

  /// Body centre in world px.
  double get x => kLaneX + dx;

  /// Landing point — the rocket sits on top of the body.
  double get seatY => y - h * seatF + 6;
  Offset get seat => Offset(x, seatY);
}

/// Earth → Pluto are the six planets the game progresses through
/// ([MM.planets]); the Station is the route's destination — drawn, never docked.
const List<JourneyStop> kJourneyStops = <JourneyStop>[
  JourneyStop(
      'earth', 'Earth', 'planet-earth.png', 5400, 0, 360, 595 / 594, 0.50),
  JourneyStop(
      'moon', 'Moon', 'planet-moon.png', 4720, 360, 190, 256 / 256, 0.50),
  JourneyStop(
      'mars', 'Mars', 'planet-mars.png', 4030, -340, 270, 588 / 594, 0.50),
  JourneyStop('jupiter', 'Jupiter', 'planet-jupiter.png', 3200, 380, 450,
      608 / 595, 0.50),
  JourneyStop('saturn', 'Saturn', 'planet-saturn.png', 2300, -300, 780,
      1096 / 595, 0.45),
  JourneyStop(
      'pluto', 'Pluto', 'planet-pluto.png', 1560, 360, 180, 594 / 594, 0.50),
  JourneyStop(
      'station', 'Station', 'station3.png', 950, 0, 330, 712 / 581, 0.42),
];

/// One leg of the route: a quadratic bezier from [a]'s seat to [b]'s seat whose
/// control point bows [kBow] to one side, alternating by leg index.
class JourneyLeg {
  JourneyLeg(this.a, this.b, this.index);

  final JourneyStop a;
  final JourneyStop b;
  final int index;

  Offset get p0 => a.seat;
  Offset get p2 => b.seat;

  /// Control point — bows right on even legs, left on odd ones.
  Offset get p1 => Offset(
        (p0.dx + p2.dx) / 2 + (index.isOdd ? -kBow : kBow),
        (p0.dy + p2.dy) / 2,
      );

  Offset pos(double t) {
    final u = 1 - t;
    final a0 = p0, a1 = p1, a2 = p2;
    return Offset(
      u * u * a0.dx + 2 * u * t * a1.dx + t * t * a2.dx,
      u * u * a0.dy + 2 * u * t * a1.dy + t * t * a2.dy,
    );
  }

  /// Nose angle in degrees from the curve's tangent — 0° is upright (the art
  /// points up), so the rocket leans into the arc and straightens as it lands.
  double angleDeg(double t) {
    final u = 1 - t;
    final a0 = p0, a1 = p1, a2 = p2;
    final dx = 2 * u * (a1.dx - a0.dx) + 2 * t * (a2.dx - a1.dx);
    final dy = 2 * u * (a1.dy - a0.dy) + 2 * t * (a2.dy - a1.dy);
    return math.atan2(dy, dx) * 180 / math.pi + 90;
  }

  /// The exact curve the rocket flies. The drawn trajectory must be built from
  /// this — shifting the endpoints to trim it (and leaving [p1] alone) bends
  /// the curve away from the flown path.
  Path get path => Path()
    ..moveTo(p0.dx, p0.dy)
    ..quadraticBezierTo(p1.dx, p1.dy, p2.dx, p2.dy);

  /// Horizontal span the arc actually sweeps. The bow carries the rocket well
  /// off the line between the two bodies, so framing a leg on planet widths
  /// alone flies it off the side of a narrow panel.
  ({double left, double right}) get xSpan {
    final a0 = p0, a1 = p1, a2 = p2;
    double lo = math.min(a0.dx, a2.dx), hi = math.max(a0.dx, a2.dx);
    // Extremum of the quadratic in x, when it falls inside the segment.
    final denom = a0.dx - 2 * a1.dx + a2.dx;
    if (denom.abs() > 1e-6) {
      final t = (a0.dx - a1.dx) / denom;
      if (t > 0 && t < 1) {
        final x = pos(t).dx;
        lo = math.min(lo, x);
        hi = math.max(hi, x);
      }
    }
    return (left: lo, right: hi);
  }
}

String _art(String file) => 'assets/momentum/journey/$file';

// ── Hull reveal frames ─────────────────────────────────────────
/// A reveal frame registered on the rocket BODY: [box] is the art's measured
/// alpha bounding box as *fractions* of its native size, so every frame can be
/// drawn at the same body height and the silhouette never jumps between them.
class _HullFrame {
  const _HullFrame(this.asset, this.aspect, this.box, {this.wings = false});
  final String asset;
  final double aspect; // native w / h
  final Rect box;
  final bool wings;
}

// Native boxes from the handoff:
//   rocket-journey.png 320×608  box 15,14,308,575
//   armor-1/2/3.png    430×775  box 51,24,376,695
//   hull-wings.png     332×558  box 74,246,259,350
const Rect _kArmorBox =
    Rect.fromLTRB(51 / 430, 24 / 775, 376 / 430, 695 / 775);
const List<_HullFrame> _kHullFrames = <_HullFrame>[
  _HullFrame('rocket-journey.png', 320 / 608,
      Rect.fromLTRB(15 / 320, 14 / 608, 308 / 320, 575 / 608)),
  _HullFrame('armor-1.png', 430 / 775, _kArmorBox, wings: true),
  _HullFrame('armor-2.png', 430 / 775, _kArmorBox, wings: true),
  _HullFrame('armor-3.png', 430 / 775, _kArmorBox, wings: true),
];
const _HullFrame _kWings = _HullFrame('hull-wings.png', 332 / 558,
    Rect.fromLTRB(74 / 332, 246 / 558, 259 / 332, 350 / 558));

/// Body-height fraction of the cockpit art (assets/momentum/rocket.png) so
/// [RocketWidget] lands at exactly the body height the armor frames left off
/// at. Measured box 16…593 of 627 native px.
const double _kCockpitBodyFrac = (593 - 16) / 627;
const double _kCockpitAspect = 516 / 980;

const Duration _kHullStep = Duration(milliseconds: 780);

// ── Camera ─────────────────────────────────────────────────────
class _Cam {
  const _Cam(this.fx, this.fy, this.s);

  /// Focus point in world px. [fx] moves now that planets are staggered — with
  /// a single lane it was always the lane centre.
  final double fx;
  final double fy;
  final double s;
}

double _lerp(double a, double b, double t) => a + (b - a) * t;
double _easeInOut(double t) =>
    t < 0.5 ? 4 * t * t * t : 1 - math.pow(-2 * t + 2, 3).toDouble() / 2;
double _easeOut(double t) => 1 - math.pow(1 - t, 3).toDouble();

/// Geometric scale blend — linear interpolation makes the pull-back stall.
double _blendScale(double a, double b, double e) =>
    a * math.pow(b / a, e).toDouble();

enum _Mode { dashboard, flying, reveal }

/// The Cockpit's centre stage.
///
/// Normally this is the cockpit dashboard ([RocketWidget]). When the player
/// reaches a new planet it plays the journey cinematic in place — pull back to
/// the whole route, cruise the leg, land, then peel the hull open back onto the
/// dashboard. The vertical planet rail on the right shows where they are and
/// replays any arrival on tap.
class JourneyStage extends StatefulWidget {
  const JourneyStage({
    super.key,
    required this.planetIdx,
    required this.activeCores,
    required this.atRiskCores,
    required this.streak,
    this.rocketWidth = 260,
    this.height = 470,
    this.warpSpeed,
    this.onNav,
    this.onCoreAlert,
    this.compact = false,
    this.initialZoom = 1,
    this.onDockedChanged,
    this.zoomController,
    this.controlsOnLeft = false,
  });

  /// Star-drift speed this stage publishes for a [MovingStarfield] behind the
  /// whole panel: idle drift when parked, full warp during a leg.
  final ValueNotifier<double>? warpSpeed;

  /// Index into [MM.planets] — the planet the player is currently on.
  final int planetIdx;
  final List<String> activeCores;
  final Set<String> atRiskCores;
  final int streak;
  final double rocketWidth;
  final double height;
  final void Function(String key)? onNav;
  final void Function(String coreId)? onCoreAlert;

  /// Phone-sized surface: shrinks the rail + zoom bar so the stage itself keeps
  /// a usable width, and lets the world be pinched.
  final bool compact;

  /// 1 = the cockpit dashboard, 0 = the whole route. Mobile opens the Journey
  /// screen at 0 — seeing where you are IS the point of that screen.
  final double initialZoom;

  /// Fires with the stop the rocket is parked at / flying to, so a host screen
  /// can label it. Called on replays too.
  final void Function(int stopIdx)? onDockedChanged;

  /// Puts the planet rail + zoom bar down the LEFT edge instead of the right —
  /// the mobile cockpit keeps its right edge for the Co-Pilot.
  final bool controlsOnLeft;

  /// Hoists zoom out of the stage: pass one and the built-in zoom bar is hidden
  /// so the host can put a [JourneyZoomBar] wherever it likes (mobile keeps its
  /// controls in a left rail). The stage still drives it on pinch.
  final ValueNotifier<double>? zoomController;

  @override
  State<JourneyStage> createState() => _JourneyStageState();
}

class _JourneyStageState extends State<JourneyStage>
    with TickerProviderStateMixin {
  static const String _seenKey = 'mm.journey.seen_planet';

  late final AnimationController _flight =
      AnimationController(vsync: this, duration: const Duration(seconds: 5))
        ..addStatusListener(_onFlightStatus);

  _Mode _mode = _Mode.dashboard;
  int _docked = 0; // stop the rocket is parked at
  int _from = 0;
  int _to = 0;

  /// The arc currently being flown — null whenever the stage is parked.
  JourneyLeg? _leg;

  /// 1 = fully zoomed in (the cockpit dashboard), 0 = the whole route with the
  /// rocket at its current stop. Driven by the zoom bar (built-in or hosted)
  /// and by pinch on touch.
  late double _localZoom = widget.initialZoom.clamp(0.0, 1.0);

  double get _zoom => widget.zoomController?.value ?? _localZoom;

  void _setZoom(double v) {
    final z = v.clamp(0.0, 1.0);
    final c = widget.zoomController;
    if (c != null) {
      c.value = z; // the listener rebuilds
    } else {
      setState(() => _localZoom = z);
    }
  }

  // ── Compact (phone) metrics ──────────────────────────────────
  double get _railW => widget.compact ? 54 : 76;
  double get _zoomW => widget.compact ? 26 : 30;
  double get _zoomBarH => widget.compact ? 132 : 190;

  /// Right-hand strip the rail (+ built-in zoom bar) own, kept clear of the
  /// stage.
  double get _gutter =>
      _railW +
      (widget.zoomController == null ? _zoomW : 0) +
      (widget.compact ? 8 : 12);

  /// Where the player actually is, from their data. Rail taps replay a leg for
  /// demo purposes but must never move this — once the replay ends the rocket
  /// returns here.
  int get _real =>
      widget.planetIdx.clamp(0, kJourneyStops.length - 1);

  /// Publishes the star speed for the panel-wide [MovingStarfield]: the plume
  /// cross-fades it in on liftoff and out on touchdown.
  void _publishWarp(double plume) {
    final n = widget.warpSpeed;
    if (n == null) return;
    final idle = journeyIdleWarp(_from);
    final fly = 300 * math.pow(1.42, _from).toDouble();
    n.value = _lerp(idle, fly, plume.clamp(0.0, 1.0));
  }

  List<int> _revealOrder = const [];
  int _revealStep = 0;

  @override
  void initState() {
    super.initState();
    _docked = widget.planetIdx;
    _from = _docked;
    _to = _docked;
    widget.zoomController?.addListener(_onZoomChanged);
    _restoreAndMaybeFly();
  }

  void _onZoomChanged() {
    if (mounted) setState(() {});
  }

  bool _warmed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Warm the hull plates and planets before an arrival needs them — a frame
    // that is still loading when its 780 ms slot comes up paints an empty body.
    if (_warmed) return;
    _warmed = true;
    precacheJourneyImages(context);
  }

  @override
  void didUpdateWidget(covariant JourneyStage old) {
    super.didUpdateWidget(old);
    if (old.zoomController != widget.zoomController) {
      old.zoomController?.removeListener(_onZoomChanged);
      widget.zoomController?.addListener(_onZoomChanged);
    }
    // The player levelled up while the Cockpit was open.
    if (widget.planetIdx != old.planetIdx && _mode == _Mode.dashboard) {
      _restoreAndMaybeFly();
    }
  }

  @override
  void dispose() {
    widget.zoomController?.removeListener(_onZoomChanged);
    _flight.dispose();
    super.dispose();
  }

  /// Plays each arrival exactly once: the furthest planet the player has been
  /// shown is persisted, so a refresh never replays the cinematic.
  Future<void> _restoreAndMaybeFly() async {
    final seen = await LocalCache.getJson(_seenKey);
    if (!mounted) return;
    final int? last = seen is num ? seen.toInt() : null;
    final target = widget.planetIdx;

    if (last == null || target <= last) {
      await LocalCache.putJson(_seenKey, math.max(last ?? target, target));
      if (mounted) setState(() => _docked = target);
      return;
    }
    await LocalCache.putJson(_seenKey, target);
    if (!mounted) return;
    // Reduced motion: land on the dashboard without the cinematic.
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      setState(() => _docked = target);
      return;
    }
    _flyTo(target, from: last);
  }

  int? _notifiedStop;

  /// Tells the host which stop is showing — after the frame, so a host that
  /// rebuilds on it never sets state during this build.
  void _notifyDocked() {
    final cb = widget.onDockedChanged;
    if (cb == null) return;
    final stop = _mode == _Mode.dashboard ? _real : _docked;
    if (stop == _notifiedStop) return;
    _notifiedStop = stop;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) cb(stop);
    });
  }

  // ── Flight ───────────────────────────────────────────────────
  /// Flies to [to]. Without [from] this replays the *arrival* at [to] — i.e.
  /// the leg that ends there — which is what the rail taps want.
  void _flyTo(int to, {int? from}) {
    if (_mode != _Mode.dashboard) return;
    final start =
        (from ?? (to > 0 ? to - 1 : 0)).clamp(0, kJourneyStops.length - 1);
    if (to == start) {
      setState(() => _docked = to);
      _startReveal(to);
      return;
    }
    final pace = math.pow(0.88, start).toDouble(); // later legs are quicker
    final ms = (1000 + 2600 * pace + 1500).round();
    setState(() {
      _from = start;
      _to = to;
      _docked = start;
      _mode = _Mode.flying;
      // A replay can run backwards (rail taps); bow by the *route* leg index so
      // a leg always curves the same way it does on the drawn trajectory.
      _leg = JourneyLeg(kJourneyStops[start], kJourneyStops[to],
          math.min(start, to));
      _flight.duration = Duration(milliseconds: ms);
    });
    _flight.forward(from: 0);
  }

  void _onFlightStatus(AnimationStatus s) {
    if (s != AnimationStatus.completed || !mounted) return;
    setState(() => _docked = _to);
    _startReveal(_to);
  }

  void _startReveal(int planet) {
    // Depth is how many armor plates this arrival peels; the sequence always
    // terminates on the cockpit dashboard.
    final depth = (planet + 1).clamp(1, _kHullFrames.length);
    setState(() {
      _mode = _Mode.reveal;
      _revealOrder = [for (var i = 0; i < depth; i++) i, _kHullFrames.length];
      _revealStep = 0;
    });
    _advanceReveal();
  }

  void _advanceReveal() {
    Future<void>.delayed(_kHullStep, () {
      if (!mounted || _mode != _Mode.reveal) return;
      if (_revealStep >= _revealOrder.length - 1) {
        // Back to the player's real stop — a rail replay is a preview, not a
        // change of position.
        setState(() {
          _mode = _Mode.dashboard;
          _docked = _real;
        });
        return;
      }
      setState(() => _revealStep++);
      _advanceReveal();
    });
  }

  // ── Camera framing ───────────────────────────────────────────
  double _visH(Size vp) => math.max(120, vp.height);

  _Cam _landedCam(JourneyStop p, Size vp) {
    final top = p.y - p.h * p.seatF - kRocketH - 40;
    final bot = p.y + p.halfH + 100;
    final s = math.min(
      1.0,
      math.min(_visH(vp) * 0.92 / (bot - top), vp.width * 0.9 / (p.w * 1.1)),
    );
    return _Cam(p.x, (top + bot) / 2, s);
  }

  /// Frames the whole route — the zoom bar's "out" end.
  _Cam _fitCam(Size vp) {
    final s = math.min(
            vp.width / kWorldW, _visH(vp) / (kContentBottom - kContentTop)) *
        0.94;
    return _Cam(kLaneX, (kContentTop + kContentBottom) / 2, s);
  }

  /// The pull-back frame. The prototype frames the *entire* route here, but
  /// this stage is a ~470px column inside the Cockpit: at that scale the whole
  /// route puts the rocket at 8px and the beat reads as nothing happening. So
  /// the pull-back frames the leg instead — departure planet, destination and
  /// the rocket between them. The rail carries the full-route context.
  ///
  /// The horizontal fit spans the *arc*, not just the two bodies: the bow
  /// carries the rocket outside both planets, and framing on widths alone
  /// swings it off the side of a narrow panel mid-cruise.
  _Cam _legCam(JourneyLeg leg, Size vp) {
    final a = leg.a, b = leg.b;
    final top = b.y - b.h * b.seatF - kRocketH - 40;
    final bot = a.y + a.halfH + 100;
    final span = leg.xSpan;
    final left = math.min(
        span.left - kRocketW / 2, math.min(a.x - a.w / 2, b.x - b.w / 2));
    final right = math.max(
        span.right + kRocketW / 2, math.max(a.x + a.w / 2, b.x + b.w / 2));
    final s = math.min(
      1.0,
      math.min(_visH(vp) * 0.92 / (bot - top),
          vp.width * 0.9 / ((right - left) * 1.05)),
    );
    return _Cam((left + right) / 2, (top + bot) / 2, s);
  }

  double _screenY(double worldY, _Cam c, Size vp) =>
      _visH(vp) / 2 + (worldY - c.fy) * c.s;

  double _screenX(double worldX, _Cam c, Size vp) =>
      vp.width / 2 + (worldX - c.fx) * c.s;

  /// Solves the focus so the subject's *screen* y is a lerp between its start
  /// and end screen positions — without this the rocket swings off-frame
  /// mid-zoom. Focus x just lerps between the two frames' centres.
  _Cam _camPin(double worldY, double y0, double y1, double s, double e,
          double fx0, double fx1, Size vp) =>
      _Cam(_lerp(fx0, fx1, e),
          worldY - (_lerp(y0, y1, e) - _visH(vp) / 2) / s, s);

  /// Camera, rocket position + nose angle, plume and touchdown dust for the
  /// current point on the timeline.
  ({_Cam cam, Offset rocket, double angle, double plume, double puff}) _frame(
      Size vp) {
    if (_mode != _Mode.flying) {
      // Parked: the zoom bar blends between the landed frame (1) and the whole
      // route (0), pinning the rocket so it never swings across the panel.
      // Parked position always reflects the player's real stop.
      final p = kJourneyStops[_real];
      final landed = _landedCam(p, vp);
      final full = _fitCam(vp);
      final e = (1 - _zoom).clamp(0.0, 1.0);
      final s = _blendScale(landed.s, full.s, e);
      final cam = _camPin(p.seatY, _screenY(p.seatY, landed, vp),
          _screenY(p.seatY, full, vp), s, e, landed.fx, full.fx, vp);
      return (cam: cam, rocket: p.seat, angle: 0, plume: 0, puff: 0);
    }

    final leg = _leg!;
    final a = leg.a;
    final b = leg.b;
    final landedA = _landedCam(a, vp);
    final landedB = _landedCam(b, vp);
    final fit = _legCam(leg, vp);

    final total = _flight.duration!.inMilliseconds.toDouble();
    final el = _flight.value * total;
    final pace = math.pow(0.88, _from).toDouble();
    const d1 = 1000.0;
    final d2 = 2600.0 * pace;
    const d3 = 1500.0;

    if (el < d1) {
      // Beat 1 — pull back until the leg is on screen. The rocket is still
      // upright on the pad; it only picks up the arc's tangent once moving.
      final e = _easeInOut(el / d1);
      final s = _blendScale(landedA.s, fit.s, e);
      final cam = _camPin(a.seatY, _screenY(a.seatY, landedA, vp),
          _screenY(a.seatY, fit, vp), s, e, landedA.fx, fit.fx, vp);
      final lift = 30 * math.max(0, e - 0.6) / 0.4;
      return (
        cam: cam,
        rocket: Offset(a.seat.dx, a.seatY - lift),
        angle: 0,
        plume: math.min(1, e * 2),
        puff: 0
      );
    }
    if (el < d1 + d2) {
      // Beat 2 — cruise the arc. The camera HOLDS the pulled-back frame;
      // drifting it slides content out from under the viewport.
      final e = _easeInOut((el - d1) / d2);
      final t = e * 0.86;
      return (
        cam: fit,
        rocket: leg.pos(t),
        angle: leg.angleDeg(t),
        plume: 1,
        puff: 0
      );
    }
    // Beat 3 — approach and land. The nose straightens back to upright as the
    // rocket settles onto the seat.
    final e = _easeOut(((el - d1 - d2) / d3).clamp(0.0, 1.0));
    final t = 0.86 + 0.14 * e;
    final s = _blendScale(fit.s, landedB.s, e);
    final cam = _camPin(b.seatY, _screenY(b.seatY, fit, vp),
        _screenY(b.seatY, landedB, vp), s, e, fit.fx, landedB.fx, vp);
    return (
      cam: cam,
      rocket: leg.pos(t),
      angle: _lerp(leg.angleDeg(t), 0, e),
      plume: 1 - e,
      // Dust kicks up over the last sliver of the descent.
      puff: ((e - 0.88) / 0.12).clamp(0.0, 1.0),
    );
  }

  // ── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_mode != _Mode.flying) {
      // Parked (dashboard or hull reveal): stars keep drifting, never frozen.
      widget.warpSpeed?.value = journeyIdleWarp(_real);
    }
    _notifyDocked();
    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          // The rail floats over one edge so the stage keeps its width.
          Positioned.fill(
            child: Padding(
              padding: widget.controlsOnLeft
                  ? EdgeInsets.only(left: _gutter)
                  : EdgeInsets.only(right: _gutter),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: switch (_mode) {
                  // Zoomed all the way in, the stage IS the cockpit dashboard.
                  _Mode.dashboard when _zoom >= 1 => Center(
                      key: const ValueKey('dash'),
                      child: RocketWidget(
                        maxWidth: widget.rocketWidth,
                        viewportFraction: 1,
                        activeCores: widget.activeCores,
                        atRiskCores: widget.atRiskCores,
                        streak: widget.streak,
                        onNav: widget.onNav,
                        onCoreAlert: widget.onCoreAlert,
                      ),
                    ),
                  _Mode.reveal => _buildReveal(),
                  _ => _buildWorld(),
                },
              ),
            ),
          ),
          if (widget.zoomController == null)
            Positioned(
              right: widget.controlsOnLeft ? null : _railW + 2,
              left: widget.controlsOnLeft ? _railW + 2 : null,
              top: 0,
              bottom: 0,
              child: Center(
                child: JourneyZoomBar(
                  value: _zoom,
                  enabled: _mode == _Mode.dashboard,
                  width: _zoomW,
                  trackHeight: _zoomBarH,
                  onChanged: _setZoom,
                ),
              ),
            ),
          Positioned(
            right: widget.controlsOnLeft ? null : 0,
            left: widget.controlsOnLeft ? 0 : null,
            top: 0,
            bottom: 0,
            child: Center(
              child: _PlanetRail(
                width: _railW,
                compact: widget.compact,
                // Parked, the highlight is the player's real stop; only while a
                // replay is running does it follow the rocket.
                docked: _mode == _Mode.dashboard ? _real : _docked,
                reached: _real,
                busy: _mode != _Mode.dashboard,
                onTap: _flyTo,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Pinch on the route (touch only — the zoom bar is the pointer affordance).
  /// Scaling up flies the camera back in toward the cockpit dashboard.
  Widget _pinchable(Widget child) {
    if (!widget.compact) return child;
    double start = _zoom;
    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onScaleStart: (_) => start = _zoom,
      onScaleUpdate: (d) {
        if (_mode != _Mode.dashboard || d.pointerCount < 2) return;
        _setZoom(start * d.scale);
      },
      child: child,
    );
  }

  Widget _buildWorld() {
    return LayoutBuilder(
      key: const ValueKey('world'),
      builder: (context, c) {
        final vp = Size(c.maxWidth, c.maxHeight);
        return _pinchable(ClipRect(
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _flight,
                  // The world is built once; only the transform changes.
                  child: _WorldLayer(reached: widget.planetIdx),
                  builder: (context, world) {
                    final f = _frame(vp);
                    _publishWarp(f.plume);
                    final cam = f.cam;
                    // Zoomed right out the rocket would be ~8px — keep it
                    // readable so "you are here" still lands.
                    final rs = math.max(cam.s, 26 / kRocketH);
                    final rw = kRocketW * rs;
                    final rh = kRocketH * rs;
                    final rocketX = _screenX(f.rocket.dx, cam, vp);
                    final rocketY = _screenY(f.rocket.dy, cam, vp);
                    final seat = kJourneyStops[_to].seat;
                    final seatScreenX = _screenX(seat.dx, cam, vp);
                    final seatScreenY = _screenY(seat.dy, cam, vp);
                    return Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        Positioned.fill(
                          child: Transform(
                            transform: Matrix4.identity()
                              ..translate(vp.width / 2, _visH(vp) / 2)
                              ..scale(cam.s)
                              ..translate(-cam.fx, -cam.fy),
                            child: OverflowBox(
                              alignment: Alignment.topLeft,
                              minWidth: 0,
                              maxWidth: double.infinity,
                              minHeight: 0,
                              maxHeight: double.infinity,
                              child: world,
                            ),
                          ),
                        ),
                        if (f.puff > 0)
                          Positioned(
                            left: seatScreenX - 110 * cam.s,
                            top: seatScreenY - 35 * cam.s,
                            width: 220 * cam.s,
                            height: 70 * cam.s,
                            child: _DustPuff(t: f.puff),
                          ),
                        // The rocket rides in screen space, so the pin math is
                        // exactly what positions it. Rotation pivots near the
                        // engine (50% / 88% of the sprite) so the nose swings
                        // into the arc rather than the whole body sliding.
                        Positioned(
                          left: rocketX - rw / 2,
                          top: rocketY - rh,
                          width: rw,
                          height: rh,
                          child: Transform.rotate(
                            angle: f.angle * math.pi / 180,
                            alignment: const Alignment(0, 0.76),
                            child: _FlightRocket(plume: f.plume),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ));
      },
    );
  }

  Widget _buildReveal() {
    final idx = _revealOrder.isEmpty
        ? 0
        : _revealOrder[_revealStep.clamp(0, _revealOrder.length - 1)];
    final body = widget.height * 0.72; // body height the sequence registers on
    // Final frame: the real cockpit dashboard, sized so its body matches.
    final imageH = body / _kCockpitBodyFrac;
    final onDash = idx >= _kHullFrames.length;

    // Every frame stays MOUNTED for the whole sequence and is toggled by
    // opacity — swapping one widget for the next re-resolves its image, and a
    // plate that has not finished loading paints an empty body (the wings
    // layer renders, the hull does not). Per the handoff: "frames are mounted
    // once and toggled via opacity + visibility (never unmounted)".
    return Center(
      key: const ValueKey('reveal'),
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < _kHullFrames.length; i++)
            Opacity(
              opacity: idx == i ? 1 : 0,
              child: _HullFrameView(frame: _kHullFrames[i], bodyHeight: body),
            ),
          // Hidden dashboard keeps its state but must not eat taps meant for
          // the plates underneath it.
          IgnorePointer(
            ignoring: !onDash,
            child: Opacity(
              opacity: onDash ? 1 : 0,
              child: RocketWidget(
                width: imageH * _kCockpitAspect,
                maxWidth: imageH * _kCockpitAspect,
                activeCores: widget.activeCores,
                atRiskCores: widget.atRiskCores,
                streak: widget.streak,
                onNav: widget.onNav,
                onCoreAlert: widget.onCoreAlert,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Static world contents (planets, labels, trajectories) ──────
class _WorldLayer extends StatelessWidget {
  const _WorldLayer({required this.reached});

  /// Legs up to this stop are drawn as completed (teal).
  final int reached;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: kWorldW,
        height: kWorldH,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _TrajectoryPainter(reached: reached)),
            ),
            for (final p in kJourneyStops) ...[
              Positioned(
                left: p.x - p.w / 2,
                top: p.y - p.halfH,
                width: p.w,
                height: p.h,
                child: Image.asset(_art(p.asset), fit: BoxFit.contain),
              ),
              // Centred on the body, not the world — the planets are staggered
              // off the lane now, so a full-width centred label would drift.
              Positioned(
                left: p.x - 400,
                width: 800,
                top: p.y + p.halfH + 30,
                child: Text(
                  p.name.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: MM.display(
                    size: 34,
                    color: const Color(0xFFF1F1F1).withOpacity(0.75),
                    letterSpacing: 34 * 0.3,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrajectoryPainter extends CustomPainter {
  _TrajectoryPainter({required this.reached});
  final int reached;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < kJourneyStops.length - 1; i++) {
      final leg = JourneyLeg(kJourneyStops[i], kJourneyStops[i + 1], i);
      paint.color = i < reached
          ? const Color(0xFF00A98F).withOpacity(0.7)
          : const Color(0xFFF1F1F1).withOpacity(0.22);
      // Exactly the curve the rocket flies, trimmed back along its OWN arc
      // length at each end — clear of the parked rocket on the launch side and
      // short of the body on the landing side.
      _dashed(canvas, leg.path, paint, headTrim: kRocketH, tailTrim: 40);
    }
  }

  /// Walks the curve with `PathMetrics` — a quadratic can't be dashed by
  /// stepping a straight direction vector, and trimming it by moving the
  /// endpoints would change its shape.
  void _dashed(Canvas canvas, Path path, Paint p,
      {double headTrim = 0, double tailTrim = 0}) {
    const dash = 4.0, gap = 18.0;
    for (final metric in path.computeMetrics()) {
      final total = metric.length;
      final start = math.min(headTrim, total);
      final end = math.max(start, total - tailTrim);
      for (double d = start; d < end; d += dash + gap) {
        canvas.drawPath(metric.extractPath(d, math.min(d + dash, end)), p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TrajectoryPainter old) =>
      old.reached != reached;
}

// ── The map rocket + engine plume ──────────────────────────────
class _FlightRocket extends StatefulWidget {
  const _FlightRocket({required this.plume});
  final double plume;

  @override
  State<_FlightRocket> createState() => _FlightRocketState();
}

class _FlightRocketState extends State<_FlightRocket>
    with SingleTickerProviderStateMixin {
  // Created eagerly, NOT `late`: the plume only builds while it is burning, so
  // a rocket disposed without ever showing one would have `dispose()` be the
  // first touch — constructing a ticker against a deactivated element throws
  // "Looking up a deactivated widget's ancestor is unsafe".
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth, h = c.maxHeight;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (widget.plume > 0.01)
              Positioned(
                left: w * 0.37,
                width: w * 0.26,
                top: h * 0.9,
                height: h * 0.34,
                child: Opacity(
                  opacity: widget.plume.clamp(0.0, 1.0),
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, child) => Transform.scale(
                      scaleY:
                          1 + 0.18 * Curves.easeInOut.transform(_pulse.value),
                      alignment: Alignment.topCenter,
                      child: child,
                    ),
                    child: const _Plume(),
                  ),
                ),
              ),
            Positioned.fill(
              child:
                  Image.asset(_art('rocket-journey.png'), fit: BoxFit.contain),
            ),
          ],
        );
      },
    );
  }
}

class _Plume extends StatelessWidget {
  const _Plume();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.7),
          colors: [
            Color(0xFFFFF5B3),
            Color(0xFFFFCE3A),
            Color(0xFFFF6A1A),
            Colors.transparent,
          ],
          stops: [0.0, 0.30, 0.65, 0.90],
        ),
      ),
    );
  }
}

/// Touchdown dust — scales 0.2 → 2.6 as it fades out.
class _DustPuff extends StatelessWidget {
  const _DustPuff({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: (0.9 * (1 - t)).clamp(0.0, 1.0),
        child: Transform.scale(
          scale: _lerp(0.2, 2.6, _easeOut(t)),
          child: const DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color(0x8CF1F1F1),
                  Color(0x26F1F1F1),
                  Colors.transparent,
                ],
                stops: [0.0, 0.55, 0.75],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Hull reveal frame ──────────────────────────────────────────
class _HullFrameView extends StatelessWidget {
  const _HullFrameView({required this.frame, required this.bodyHeight});
  final _HullFrame frame;
  final double bodyHeight;

  @override
  Widget build(BuildContext context) {
    // Scale so the measured body box is exactly [bodyHeight] tall, then offset
    // so that body — not the image box — is what stays centred.
    final h = bodyHeight / (frame.box.bottom - frame.box.top);
    final w = h * frame.aspect;
    final dx = (0.5 - (frame.box.left + frame.box.right) / 2) * w;
    final dy = (0.5 - (frame.box.top + frame.box.bottom) / 2) * h;

    // Wings ship separately from the armor plates: scale them to the hull's
    // body width and seat their bottoms at the hull base.
    final bodyW = (frame.box.right - frame.box.left) * w;
    final wingsW =
        bodyW * 1.04 / (_kWings.box.right - _kWings.box.left);
    final wingsH = wingsW / _kWings.aspect;

    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (frame.wings)
            Positioned(
              left: (w - wingsW) / 2 + dx,
              top: dy + h / 2 + bodyHeight / 2 - bodyHeight * 0.045 -
                  _kWings.box.bottom * wingsH,
              width: wingsW,
              height: wingsH,
              child: Image.asset(_art(_kWings.asset), fit: BoxFit.contain),
            ),
          Transform.translate(
            offset: Offset(dx, dy),
            child: Image.asset(_art(frame.asset),
                width: w, height: h, fit: BoxFit.contain),
          ),
        ],
      ),
    );
  }
}

// ── Vertical zoom bar ──────────────────────────────────────────
/// Sits parallel to the planet rail (desktop) or in the mobile control rail.
/// Top = zoomed in (the cockpit dashboard, rocket only); bottom = zoomed out
/// (the whole route with the rocket at its current stop).
class JourneyZoomBar extends StatelessWidget {
  const JourneyZoomBar({
    super.key,
    required this.value,
    required this.enabled,
    required this.onChanged,
    this.width = 30,
    this.trackHeight = 190,
  });

  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;
  final double width;
  final double trackHeight;

  double get _h => trackHeight;

  void _setFromLocal(double dy) {
    // Top of the track is 1 (in), bottom is 0 (out).
    onChanged((1 - (dy / _h)).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0D1E).withOpacity(0.7),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ZoomStep(
              icon: Icons.add,
              enabled: enabled && value < 1,
              onTap: () => onChanged((value + 0.25).clamp(0.0, 1.0)),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown:
                  enabled ? (d) => _setFromLocal(d.localPosition.dy) : null,
              onVerticalDragUpdate:
                  enabled ? (d) => _setFromLocal(d.localPosition.dy) : null,
              child: SizedBox(
                width: width - 8,
                height: _h,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    // track
                    Container(
                      width: 3,
                      height: _h,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    // filled portion (from the thumb up to "in")
                    Positioned(
                      top: 0,
                      height: _h * (1 - value),
                      child: Container(
                        width: 3,
                        decoration: BoxDecoration(
                          color: MM.blue,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Positioned(
                      top: (_h * (1 - value) - 7).clamp(0.0, _h - 14),
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: const [
                            BoxShadow(color: MM.blue, blurRadius: 10),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            _ZoomStep(
              icon: Icons.remove,
              enabled: enabled && value > 0,
              onTap: () => onChanged((value - 0.25).clamp(0.0, 1.0)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoomStep extends StatelessWidget {
  const _ZoomStep({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: 22,
        height: 20,
        child: Icon(icon,
            size: 13,
            color: Colors.white.withOpacity(enabled ? 0.75 : 0.3)),
      ),
    );
  }
}

// ── Vertical planet rail ───────────────────────────────────────
/// The whole route at a glance with the player's position highlighted.
/// Tapping a stop replays that arrival — the "show me the path" demo.
class _PlanetRail extends StatelessWidget {
  const _PlanetRail({
    required this.docked,
    required this.reached,
    required this.busy,
    required this.onTap,
    this.width = 76,
    this.compact = false,
  });

  final int docked;
  final int reached;
  final bool busy;
  final ValueChanged<int> onTap;
  final double width;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    // Top of the rail is the far end of the route, matching the world.
    final stops =
        List<int>.generate(kJourneyStops.length, (i) => i).reversed.toList();
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0D1E).withOpacity(0.7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final i in stops)
            _RailStop(
              stop: kJourneyStops[i],
              current: i == docked,
              visited: i < reached,
              enabled: !busy,
              compact: compact,
              onTap: () => onTap(i),
            ),
        ],
      ),
    );
  }
}

class _RailStop extends StatelessWidget {
  const _RailStop({
    required this.stop,
    required this.current,
    required this.visited,
    required this.enabled,
    required this.onTap,
    this.compact = false,
  });

  final JourneyStop stop;
  final bool current;
  final bool visited;
  final bool enabled;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = current
        ? Colors.white
        : (visited ? MM.teal : const Color(0xFFF1F1F1).withOpacity(0.45));
    final dot = compact ? (current ? 10.0 : 6.0) : (current ? 11.0 : 7.0);
    final label = compact ? 6.5 : 7.0;
    return Tooltip(
      message: enabled ? 'Replay arrival · ${stop.name}' : stop.name,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: dot,
                height: dot,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: current
                      ? const [BoxShadow(color: MM.blue, blurRadius: 10)]
                      : null,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                stop.name.toUpperCase(),
                style: MM.display(
                  size: label,
                  color: color,
                  letterSpacing: label * 0.12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Warp starfield ─────────────────────────────────────────────
class _Star {
  _Star({
    required this.x,
    required this.y,
    required this.depth,
    required this.radius,
    required this.alpha,
    required this.color,
  });
  double x;
  double y;
  double trail = 0;
  final double depth;
  final double radius;
  final double alpha;
  final Color color;
}

/// Idle drift speed for a player docked at stop [i] — the stars are never
/// completely still.
double journeyIdleWarp(int i) => 8 + i * 5.0;

/// The speed cue: stars stream downward continuously, and past ~2.5px of
/// per-frame travel they stretch into streaks. [speed] is in px/s at depth 1 —
/// [JourneyStage] drives it up during a leg (each one 42% faster than the last)
/// and back down to the idle drift when parked.
class MovingStarfield extends StatefulWidget {
  const MovingStarfield({super.key, required this.speed});

  final ValueListenable<double> speed;

  @override
  State<MovingStarfield> createState() => _MovingStarfieldState();
}

class _MovingStarfieldState extends State<MovingStarfield>
    with SingleTickerProviderStateMixin {
  final List<_Star> _stars = <_Star>[];
  final math.Random _rnd = math.Random(7);
  Ticker? _ticker;
  Size _size = Size.zero;
  Duration _last = Duration.zero;
  double _warp = 8;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  void _seed(Size size) {
    if (size == _size || size.isEmpty) return;
    _size = size;
    _stars.clear();
    final count = (size.width * size.height / 7000).round().clamp(20, 400);
    for (var i = 0; i < count; i++) {
      final r = _rnd.nextDouble();
      final tint = _rnd.nextDouble();
      _stars.add(_Star(
        x: _rnd.nextDouble() * size.width,
        y: _rnd.nextDouble() * size.height,
        depth: 0.3 + r * r * 1.5,
        radius: 0.4 + _rnd.nextDouble() * 1.5,
        alpha: 0.25 + _rnd.nextDouble() * 0.65,
        color: tint > 0.92
            ? const Color(0xFFBED7FF)
            : (tint > 0.84 ? const Color(0xFFFFD6BE) : Colors.white),
      ));
    }
  }

  void _tick(Duration elapsed) {
    if (_size.isEmpty) return;
    final dt = _last == Duration.zero
        ? 0.016
        : ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;

    final target = widget.speed.value;
    _warp += (target - _warp) * math.min(1, dt * 3.2);

    for (final s in _stars) {
      s.y += _warp * s.depth * dt;
      s.trail = _warp * 0.055 * s.depth;
      if (s.y - s.trail > _size.height) {
        s.y = -s.trail;
        s.x = _rnd.nextDouble() * _size.width;
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        _seed(Size(c.maxWidth, c.maxHeight));
        return RepaintBoundary(
          child: CustomPaint(
            painter: _WarpPainter(_stars),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}

class _WarpPainter extends CustomPainter {
  _WarpPainter(this.stars);
  final List<_Star> stars;

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in stars) {
      if (s.trail > 2.5) {
        final paint = Paint()
          ..strokeWidth = s.radius * 1.1
          ..strokeCap = StrokeCap.round
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [s.color.withOpacity(0), s.color.withOpacity(s.alpha)],
          ).createShader(Rect.fromLTWH(s.x - 1, s.y - s.trail, 2, s.trail));
        canvas.drawLine(Offset(s.x, s.y - s.trail), Offset(s.x, s.y), paint);
      } else {
        canvas.drawCircle(Offset(s.x, s.y), s.radius,
            Paint()..color = s.color.withOpacity(s.alpha));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WarpPainter old) => true;
}
