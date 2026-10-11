import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/momentum_list.dart';
import '../../services/momentum_lists_service.dart';
import '../../theme/momentum_tokens.dart';

/// The Command Center as a cockpit console — the look of the original app:
/// windshield on top, a metal dash with instrument clusters on both sides and
/// a centre screen of Momentum List buttons. It is drawn in code (no source
/// art survives), sized to the same box as the rocket so it can swap in place.
///
/// A list is unlocked once it has items (Command Center access "unlocks as
/// players provide information"); empty canonical lists show as locked slots.
class CommandCenterConsole extends StatefulWidget {
  const CommandCenterConsole({
    super.key,
    required this.width,
    required this.height,
    required this.onClose,
    this.onNav,
  });

  final double width;
  final double height;
  final VoidCallback onClose;

  /// `lists:<name>` opens one list; `lists` opens them all.
  final void Function(String key)? onNav;

  @override
  State<CommandCenterConsole> createState() => _CommandCenterConsoleState();
}

class _CommandCenterConsoleState extends State<CommandCenterConsole>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  List<_Slot>? _slots;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    List<MomentumList> lists = const [];
    var failed = false;
    if (uid != null && uid.isNotEmpty) {
      try {
        // Bounded: offline, the browser can sit on a dead request for minutes
        // and the screen would spin instead of showing the slots.
        lists =
            (await MomentumListsService()
                .getAllLists(uid)
                .timeout(const Duration(seconds: 8))).data;
      } catch (_) {
        failed = true;
      }
    }
    if (!mounted) return;
    setState(() {
      _failed = failed;
      _slots = _buildSlots(lists);
    });
  }

  /// Filled lists first (server order), then every canonical list that is
  /// still empty, locked.
  static List<_Slot> _buildSlots(List<MomentumList> lists) {
    final filled = [
      for (final l in lists)
        if (l.items.isNotEmpty && l.name.trim().isNotEmpty)
          _Slot(l.name, l.count),
    ];
    final have = {for (final s in filled) _norm(s.name)};
    return [
      ...filled,
      for (final n in kCanonicalMomentumLists)
        if (!have.contains(_norm(n))) _Slot(n, 0),
    ];
  }

  /// Server lists are often named "Obstacles List" — match "Obstacles".
  static String _norm(String name) => _Slot.label(name).trim().toLowerCase();

  @override
  Widget build(BuildContext context) {
    final w = widget.width;
    final h = widget.height;
    final u = _unit(w, h);
    final screen = _screenRect(w, h);
    final slots = _slots;
    final unlocked = slots?.where((s) => s.unlocked).length ?? 0;
    final items = slots?.fold<int>(0, (a, s) => a + s.count) ?? 0;
    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _blink,
                builder:
                    (_, __) => CustomPaint(
                      painter: _ConsolePainter(
                        t: _blink.value,
                        items: items,
                        fill:
                            slots == null || slots.isEmpty
                                ? 0
                                : unlocked / slots.length,
                      ),
                    ),
              ),
            ),
          ),
          // Purple-Lit Cockpit Frame overlay in the top windshield area (drawn second, behind all content)
          Positioned(
            left: -u * 0.05,
            right: 0,
            top: -u * 0.2,
            height: h * 0.03,
            child: IgnorePointer(
              child: Image.asset(
                'assets/momentum/cockpit_frame.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Back — closes the console and brings the rocket back.
          Positioned(
            left: u * 0.05,
            top: h * 0.025,
            width: u * 0.13,
            height: u * 0.13,
            child: Tooltip(
              message: 'Back to rocket',
              child: Semantics(
                button: true,
                label: 'Close Command Center',
                child: GestureDetector(
                  onTap: widget.onClose,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xCC0A1136),
                        border: Border.all(
                          color: const Color(0xFF5A6478),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_left_rounded,
                        color: MM.blue,
                        size: u * 0.1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: h * 0.035,
            child: IgnorePointer(
              child: Text(
                'COMMAND CENTER',
                textAlign: TextAlign.center,
                style: MM.displayX(
                  size: u * 0.042,
                  color: MM.white.withOpacity(0.85),
                ),
              ),
            ),
          ),
          // Centre screen.
          Positioned.fromRect(
            rect: screen,
            child: _buildScreen(u, screen.width, slots),
          ),
        ],
      ),
    );
  }

  /// [w] is the size unit; [screenW] the screen's real width — wide screens
  /// lay the buttons out in a grid so more lists fit at once.
  Widget _buildScreen(double w, double screenW, List<_Slot>? slots) {
    final pad = w * 0.025;
    if (slots == null) {
      return Center(
        child: SizedBox(
          width: w * 0.08,
          height: w * 0.08,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            color: MM.blue,
          ),
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.all(pad),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: math.max(
                1,
                ((screenW - pad * 2) / (w * 0.44)).floor(),
              ),
              mainAxisExtent: w * 0.11,
              mainAxisSpacing: w * 0.025,
              crossAxisSpacing: w * 0.025,
            ),
            itemCount: slots.length,
            itemBuilder:
                (_, i) => _ListButton(
                  slot: slots[i],
                  w: w,
                  onTap:
                      slots[i].unlocked
                          ? () => widget.onNav?.call('lists:${slots[i].name}')
                          : null,
                ),
          ),
        ),
        if (_failed)
          Padding(
            padding: EdgeInsets.only(bottom: w * 0.01),
            child: Text(
              'Offline — showing locked slots',
              style: MM.mono(size: w * 0.028, color: MM.yellow),
            ),
          ),
        GestureDetector(
          onTap: () => widget.onNav?.call('lists'),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Padding(
              padding: EdgeInsets.fromLTRB(pad, w * 0.012, pad, pad),
              child: Text(
                'OPEN ALL LISTS ›',
                style: MM.displayX(size: w * 0.03, color: MM.blue),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Slot {
  const _Slot(this.name, this.count);
  final String name;
  final int count;
  bool get unlocked => count > 0;

  /// Button text — the console already says these are lists.
  static String label(String name) =>
      name.trim().replaceFirst(RegExp(r'\s+list$', caseSensitive: false), '');
}

class _ListButton extends StatefulWidget {
  const _ListButton({required this.slot, required this.w, this.onTap});
  final _Slot slot;
  final double w;
  final VoidCallback? onTap;

  @override
  State<_ListButton> createState() => _ListButtonState();
}

class _ListButtonState extends State<_ListButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final w = widget.w;
    final on = widget.slot.unlocked;
    final textColor = on ? const Color(0xFF3A3F47) : const Color(0xFFCFC4C0);
    final button = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: w * 0.018, vertical: w * 0.01),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(w * 0.012),
        gradient:
            on
                ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors:
                      _hover
                          ? const [Color(0xFFF4F6F8), Color(0xFFCDD2D8)]
                          : const [Color(0xFFE2E5E9), Color(0xFFB9BEC5)],
                )
                : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF5E4C4A), Color(0xFF473938)],
                ),
        border: Border.all(
          color: on ? const Color(0xFFF7F8FA) : const Color(0xFF6E5B58),
          width: 0.8,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 3,
            offset: Offset(0, 1.5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _Slot.label(widget.slot.name),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: MM.display(
                size: w * 0.032,
                color: textColor,
                weight: FontWeight.w600,
                letterSpacing: 0.3,
                height: 1.15,
              ),
            ),
          ),
          Icon(
            on ? Icons.play_arrow_rounded : Icons.lock_rounded,
            size: w * 0.04,
            color: textColor.withOpacity(on ? 1 : 0.85),
          ),
        ],
      ),
    );
    return Tooltip(
      message:
          on
              ? '${widget.slot.count} item${widget.slot.count == 1 ? '' : 's'}'
              : 'Unlocks as you and Nova fill it in',
      child: Semantics(
        button: on,
        label:
            on
                ? '${_Slot.label(widget.slot.name)} list'
                : '${_Slot.label(widget.slot.name)} list, locked',
        child: MouseRegion(
          cursor: on ? SystemMouseCursors.click : SystemMouseCursors.basic,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(onTap: widget.onTap, child: button),
        ),
      ),
    );
  }
}

// Centre screen bounds, as fractions of the console box.

const double _screenT = 0.285;
const double _screenB = 0.9;
const double _dashTop = 0.25;

/// Size unit for gadgets and text: the console's width at its natural
/// phone-dash proportion. A wider box (the full Cockpit stage) keeps gadgets
/// at that scale and gives the extra room to the centre screen.
double _unit(double w, double h) => math.min(w, h * 0.62);

/// The centre screen sits between the two instrument columns.
Rect _screenRect(double w, double h) {
  final u = _unit(w, h);
  return Rect.fromLTRB(u * 0.235, h * _screenT, w - u * 0.235, h * _screenB);
}

/// Windshield, struts, dash body and the decorative instrument clusters.
class _ConsolePainter extends CustomPainter {
  _ConsolePainter({required this.t, required this.items, required this.fill});

  /// 0..1 loop for blinking LEDs and the radar sweep.
  final double t;

  /// Total list items — shown on the right-hand odometer.
  final int items;

  /// Share of lists unlocked — drives the gauge needle.
  final double fill;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final u = _unit(w, h);
    final r = Radius.circular(u * 0.06);
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(Offset.zero & size, r));

    // Old windshield graphics replaced by Purple-Lit Cockpit Frame image overlay
    // _windshield(canvas, w, h, u);
    _dash(canvas, w, h, u);
    _leftCluster(canvas, w, h, u);
    _rightCluster(canvas, w, h, u);
    _screen(canvas, w, h, u);

    canvas.restore();
  }

  /// Bottom of the window glass, where the sill starts.
  double _sillY(double h) => h * (_dashTop - 0.03);

  /// Inner edge of a canopy pillar (the front window's side), for [s] = ±1.
  Path _pillarInner(double w, double h, double s) {
    double x(double d) => w * 0.5 + s * d;
    return Path()
      ..moveTo(x(w * 0.31), h * 0.02)
      ..quadraticBezierTo(x(w * 0.36), h * 0.13, x(w * 0.29), _sillY(h) + h * 0.01);
  }

  /// Outer edge of a canopy pillar (the side window's inner edge).
  Path _pillarOuter(double w, double h, double s) {
    double x(double d) => w * 0.5 + s * d;
    return Path()
      ..moveTo(x(w * 0.355), h * 0.02)
      ..quadraticBezierTo(x(w * 0.43), h * 0.13, x(w * 0.365), _sillY(h) + h * 0.01);
  }

  /// The canopy glass: one wide front window between two curved pillars,
  /// and a rounded side window in each corner.
  Path _glass(double w, double h, double u) {
    final cx = w * 0.5;
    final yS = _sillY(h) + h * 0.01;
    final path = Path();
    // Front window — its top edge sags slightly under the overhead console.
    path
      ..moveTo(cx - w * 0.31, h * 0.02)
      ..quadraticBezierTo(cx, h * 0.05, cx + w * 0.31, h * 0.02)
      ..quadraticBezierTo(cx + w * 0.36, h * 0.13, cx + w * 0.29, yS)
      ..lineTo(cx - w * 0.29, yS)
      ..quadraticBezierTo(cx - w * 0.36, h * 0.13, cx - w * 0.31, h * 0.02)
      ..close();
    for (final s in [-1.0, 1.0]) {
      double x(double d) => cx + s * d;
      final r = u * 0.06;
      path
        ..moveTo(x(w * 0.355), h * 0.02)
        ..lineTo(x(w * 0.485 - r), h * 0.02)
        ..quadraticBezierTo(x(w * 0.485), h * 0.02, x(w * 0.485), h * 0.02 + r)
        ..lineTo(x(w * 0.485), yS)
        ..lineTo(x(w * 0.365), yS)
        ..quadraticBezierTo(x(w * 0.43), h * 0.13, x(w * 0.355), h * 0.02)
        ..close();
    }
    return path;
  }

  void _windshield(Canvas c, double w, double h, double u) {
    final cx = w * 0.5;
    // Canopy frame — deep navy structure around the glass.
    final frame = Rect.fromLTWH(0, 0, w, h * (_dashTop + 0.02));
    c.drawRect(
      frame,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0C1030), Color(0xFF1A1F4E)],
        ).createShader(frame),
    );

    final glass = _glass(w, h, u);
    c.save();
    c.clipPath(glass);
    final sky = Rect.fromLTWH(0, 0, w, h * _dashTop);
    c.drawRect(
      sky,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, 0.4),
          radius: 0.9,
          colors: [Color(0xFF1A2A6C), Color(0xFF0B1238), Color(0xFF050818)],
          stops: [0, 0.55, 1],
        ).createShader(sky),
    );
    // Stars — fixed seed so they never jump between frames.
    // Enhanced with more stars and varied twinkling speeds for depth.
    final rnd = math.Random(7);
    final star = Paint();
    for (var i = 0; i < 150; i++) {
      final x = rnd.nextDouble() * w;
      final y = rnd.nextDouble() * h * _dashTop;
      // Varied twinkle rates for different stars
      final twinkleRate = 0.18 + rnd.nextDouble() * 0.32;
      final phase = rnd.nextDouble();
      final tw = 0.5 + 0.5 * math.sin((t * twinkleRate + phase) * math.pi * 2);

      // Color variation: mostly white, some warm/cool tints
      final tint = rnd.nextDouble();
      final starColor = tint > 0.92
          ? const Color(0xFFBED7FF)  // cool
          : (tint > 0.84 ? const Color(0xFFFFD6BE) : Colors.white);  // warm

      star.color = starColor.withOpacity(0.25 + 0.6 * tw);
      final radius = 0.5 + rnd.nextDouble() * 1.2;
      c.drawCircle(Offset(x, y), u * (0.002 + radius * 0.003), star);
    }
    // A couple of distant planets.
    c.drawCircle(
      Offset(cx + w * 0.11, h * 0.07),
      u * 0.011,
      Paint()..color = const Color(0xFF7FD6FF),
    );
    c.drawCircle(
      Offset(cx - w * 0.2, h * 0.11),
      u * 0.006,
      Paint()..color = const Color(0xFF9FB4FF).withOpacity(0.7),
    );
    // Radar rings around a tiny rocket, dead ahead.
    final ahead = Offset(cx, h * 0.16);
    final ring =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8;
    for (var i = 1; i <= 5; i++) {
      final phase = (t + i / 5) % 1;
      ring.color = MM.blue.withOpacity(0.35 * (1 - phase));
      c.drawArc(
        Rect.fromCircle(center: ahead, radius: u * (0.04 + 0.22 * phase)),
        math.pi * 1.05,
        math.pi * 0.9,
        false,
        ring,
      );
    }
    final ship =
        Path()
          ..moveTo(ahead.dx, ahead.dy - u * 0.035)
          ..quadraticBezierTo(
            ahead.dx + u * 0.014,
            ahead.dy - u * 0.01,
            ahead.dx + u * 0.012,
            ahead.dy + u * 0.015,
          )
          ..lineTo(ahead.dx - u * 0.012, ahead.dy + u * 0.015)
          ..quadraticBezierTo(
            ahead.dx - u * 0.014,
            ahead.dy - u * 0.01,
            ahead.dx,
            ahead.dy - u * 0.035,
          )
          ..close();
    c.drawPath(ship, Paint()..color = const Color(0xFF9FD8FF));
    c.drawCircle(
      Offset(ahead.dx, ahead.dy + u * 0.022),
      u * 0.007,
      Paint()..color = MM.yellow.withOpacity(0.6 + 0.4 * t),
    );
    c.restore();

    // Thin dark gasket round every pane.
    c.drawPath(
      glass,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = u * 0.006
        ..color = const Color(0xFF070A1C),
    );
    // Pillars: a soft violet glow, then a bright rim on each edge.
    final glow =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = u * 0.03
          ..color = const Color(0xFF8B5CF6).withOpacity(0.35)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, u * 0.012);
    final rim =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = u * 0.007
          ..color = const Color(0xFFB08CFF);
    final rimDim =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = u * 0.004
          ..color = const Color(0xFF6B4BC8);
    final yP = _sillY(h) + h * 0.01;
    for (final s in [-1.0, 1.0]) {
      double x(double d) => cx + s * d;
      final body =
          Path()
            ..moveTo(x(w * 0.31), h * 0.02)
            ..quadraticBezierTo(x(w * 0.36), h * 0.13, x(w * 0.29), yP)
            ..lineTo(x(w * 0.365), yP)
            ..quadraticBezierTo(x(w * 0.43), h * 0.13, x(w * 0.355), h * 0.02)
            ..close();
      c.drawPath(
        body,
        Paint()
          ..shader = LinearGradient(
            begin: s < 0 ? Alignment.centerRight : Alignment.centerLeft,
            end: s < 0 ? Alignment.centerLeft : Alignment.centerRight,
            colors: const [Color(0xFF4A3A9E), Color(0xFF231E5A), Color(0xFF15183F)],
            stops: const [0, 0.45, 1],
          ).createShader(body.getBounds()),
      );
      c.drawPath(_pillarInner(w, h, s), glow);
      c.drawPath(_pillarInner(w, h, s), rim);
      c.drawPath(_pillarOuter(w, h, s), rimDim);
    }

    // Overhead console with its strip of lights.
    final head = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, h * 0.022),
        width: w * 0.3,
        height: h * 0.03,
      ),
      Radius.circular(h * 0.015),
    );
    c.drawRRect(head, Paint()..color = const Color(0xFF161B45));
    c.drawRRect(
      head,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = u * 0.003
        ..color = const Color(0xFF3B4590),
    );
    final pod = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, h * 0.024),
        width: u * 0.11,
        height: h * 0.018,
      ),
      Radius.circular(h * 0.009),
    );
    c.drawRRect(pod, Paint()..color = const Color(0xFF0A0D24));
    for (var i = 0; i < 5; i++) {
      final lx = cx + (i - 2) * u * 0.016;
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(lx, h * 0.024),
            width: u * 0.009,
            height: h * 0.009,
          ),
          Radius.circular(u * 0.003),
        ),
        Paint()
          ..color = i == 2
              ? MM.yellow.withOpacity(0.6 + 0.4 * t)
              : const Color(0xFF6FD3FF).withOpacity(_on(i * 0.2, 0.7) ? 1 : 0.5),
      );
    }
    for (final s in [-1.0, 1.0]) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx + s * w * 0.1, h * 0.022),
            width: u * 0.04,
            height: h * 0.006,
          ),
          Radius.circular(u * 0.003),
        ),
        Paint()..color = const Color(0xFF4FB8FF).withOpacity(0.85),
      );
    }

    // Window sill — a navy ledge with a violet top edge and two vents.
    final yS = _sillY(h);
    final sillTop =
        Path()
          ..moveTo(0, yS - h * 0.012)
          ..quadraticBezierTo(cx, yS + h * 0.012, w, yS - h * 0.012);
    final sill =
        Path.from(sillTop)
          ..lineTo(w, h * (_dashTop + 0.02))
          ..lineTo(0, h * (_dashTop + 0.02))
          ..close();
    c.drawPath(
      sill,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2B3170), Color(0xFF151A42)],
        ).createShader(Rect.fromLTWH(0, yS - h * 0.012, w, h * 0.06)),
    );
    c.drawPath(sillTop, glow);
    c.drawPath(
      sillTop,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = u * 0.006
        ..color = const Color(0xFF9B7BFF),
    );
    final vent = Paint()..color = const Color(0xFF3A4288);
    for (final s in [-1.0, 1.0]) {
      final vx = cx + s * w * 0.26;
      final vy = yS + h * 0.012;
      c.drawPath(
        Path()
          ..moveTo(vx - u * 0.05, vy)
          ..lineTo(vx + u * 0.05, vy)
          ..lineTo(vx + u * 0.035, vy + h * 0.012)
          ..lineTo(vx - u * 0.035, vy + h * 0.012)
          ..close(),
        vent,
      );
    }
  }

  void _dash(Canvas c, double w, double h, double u) {
    final y = h * _dashTop;
    final body = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.02, y, w * 0.96, h - y),
      topLeft: Radius.circular(u * 0.08),
      topRight: Radius.circular(u * 0.08),
    );
    c.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4A4D52), Color(0xFF2E3034), Color(0xFF232427)],
          stops: [0, 0.45, 1],
        ).createShader(body.outerRect),
    );
    // Brushed-metal streaks.
    final streak =
        Paint()
          ..color = Colors.white.withOpacity(0.025)
          ..strokeWidth = 1;
    for (var x = w * 0.04; x < w * 0.96; x += u * 0.018) {
      c.drawLine(Offset(x, y + u * 0.02), Offset(x, h), streak);
    }
    // Top bevel highlight.
    c.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = u * 0.006
        ..color = const Color(0xFF7A7E86),
    );
    // Rivets.
    final rivet = Paint()..color = const Color(0xFF6C7078);
    for (final p in [
      Offset(u * 0.07, y + u * 0.05),
      Offset(w - u * 0.07, y + u * 0.05),
      Offset(u * 0.07, h - u * 0.06),
      Offset(w - u * 0.07, h - u * 0.06),
    ]) {
      c.drawCircle(p, u * 0.008, rivet);
    }
    // Floor strip.
    final floor = Rect.fromLTWH(0, h * 0.94, w, h * 0.06);
    c.drawRect(
      floor,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3B4466), Color(0xFF1B2036)],
        ).createShader(floor),
    );
  }

  void _screen(Canvas c, double w, double h, double u) {
    final rect = _screenRect(w, h);
    final bezel = RRect.fromRectAndRadius(
      rect.inflate(u * 0.018),
      Radius.circular(u * 0.04),
    );
    c.drawRRect(bezel, Paint()..color = const Color(0xFF1A1B1E));
    c.drawRRect(
      bezel,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = u * 0.006
        ..color = const Color(0xFF8A8E96),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(u * 0.03)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2A2C31), Color(0xFF1C1D21)],
        ).createShader(rect),
    );
  }

  bool _on(double offset, [double duty = 0.5]) => (t + offset) % 1 < duty;

  void _leftCluster(Canvas c, double w, double h, double u) {
    final cx = u * 0.14;
    var y = h * 0.32;

    // Round cyan scope.
    final scopeR = u * 0.06;
    c.drawCircle(
      Offset(cx, y),
      scopeR + u * 0.01,
      Paint()..color = const Color(0xFF1C1D20),
    );
    c.drawCircle(
      Offset(cx, y),
      scopeR,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF8FF3FF), Color(0xFF1FA8D6)],
        ).createShader(Rect.fromCircle(center: Offset(cx, y), radius: scopeR)),
    );
    final sweep = t * math.pi * 2;
    c.drawLine(
      Offset(cx, y),
      Offset(
        cx + math.cos(sweep) * scopeR * 0.85,
        y + math.sin(sweep) * scopeR * 0.85,
      ),
      Paint()
        ..color = Colors.white.withOpacity(0.7)
        ..strokeWidth = 1,
    );

    // LED bar readout.
    y += u * 0.13;
    _plate(
      c,
      Rect.fromCenter(
        center: Offset(cx, y),
        width: u * 0.12,
        height: u * 0.075,
      ),
    );
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 4; col++) {
        final lit = _on((row * 4 + col) / 12, 0.6);
        c.drawRect(
          Rect.fromLTWH(
            cx - u * 0.045 + col * u * 0.024,
            y - u * 0.026 + row * u * 0.02,
            u * 0.016,
            u * 0.008,
          ),
          Paint()
            ..color =
                lit
                    ? const Color(0xFF5EC8FF)
                    : const Color(0xFF5EC8FF).withOpacity(0.2),
        );
      }
    }

    // Slot.
    y += u * 0.11;
    _plate(
      c,
      Rect.fromCenter(center: Offset(cx, y), width: u * 0.12, height: u * 0.04),
    );
    c.drawRect(
      Rect.fromCenter(
        center: Offset(cx, y),
        width: u * 0.08,
        height: u * 0.008,
      ),
      Paint()..color = const Color(0xFF0A0B0D),
    );

    // Red/blue button grid.
    y += u * 0.1;
    _plate(
      c,
      Rect.fromCenter(center: Offset(cx, y), width: u * 0.12, height: u * 0.08),
    );
    for (var row = 0; row < 2; row++) {
      for (var col = 0; col < 3; col++) {
        final red = (row + col).isEven;
        final color = red ? const Color(0xFFE5484D) : const Color(0xFF3D7BFF);
        final lit = _on((row * 3 + col) / 6 + 0.2, 0.7);
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              cx - u * 0.045 + col * u * 0.032,
              y - u * 0.03 + row * u * 0.032,
              u * 0.022,
              u * 0.022,
            ),
            Radius.circular(u * 0.004),
          ),
          Paint()..color = lit ? color : color.withOpacity(0.45),
        );
      }
    }

    // Keypad with a little LCD.
    y += u * 0.13;
    final pad = Rect.fromCenter(
      center: Offset(cx, y),
      width: u * 0.13,
      height: u * 0.1,
    );
    _plate(c, pad);
    c.drawRect(
      Rect.fromLTWH(
        pad.left + u * 0.012,
        pad.top + u * 0.012,
        u * 0.045,
        u * 0.03,
      ),
      Paint()..color = const Color(0xFF9EEB8A).withOpacity(0.85),
    );
    for (var i = 0; i < 6; i++) {
      c.drawRect(
        Rect.fromLTWH(
          pad.left + u * 0.065 + (i % 3) * u * 0.018,
          pad.top + u * 0.014 + (i ~/ 3) * u * 0.018,
          u * 0.012,
          u * 0.012,
        ),
        Paint()..color = const Color(0xFFD9DCE0),
      );
    }
    for (var i = 0; i < 4; i++) {
      c.drawCircle(
        Offset(pad.left + u * 0.02 + i * u * 0.028, pad.bottom - u * 0.022),
        u * 0.007,
        Paint()..color = i == 0 && _on(0.4) ? MM.red : const Color(0xFF6A6E75),
      );
    }

    // Slider bar.
    y += u * 0.12;
    _plate(
      c,
      Rect.fromCenter(
        center: Offset(cx, y),
        width: u * 0.12,
        height: u * 0.025,
      ),
    );

    // Red/white flag switch.
    y += u * 0.09;
    final flag = Rect.fromCenter(
      center: Offset(cx, y),
      width: u * 0.1,
      height: u * 0.065,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(flag, Radius.circular(u * 0.006)),
      Paint()..color = const Color(0xFFF2F2F2),
    );
    final tri =
        Path()
          ..moveTo(flag.left, flag.top)
          ..lineTo(flag.right, flag.top)
          ..lineTo(flag.right, flag.top + flag.height * 0.35)
          ..lineTo(flag.left, flag.bottom)
          ..close();
    c.drawPath(tri, Paint()..color = const Color(0xFFD6333A));
  }

  void _rightCluster(Canvas c, double w, double h, double u) {
    final cx = w - u * 0.125;
    var y = h * 0.315;

    // Throttle lever on a slot.
    _plate(
      c,
      Rect.fromCenter(
        center: Offset(cx - u * 0.02, y + u * 0.04),
        width: u * 0.03,
        height: u * 0.13,
      ),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, y - u * 0.04),
          width: u * 0.1,
          height: u * 0.02,
        ),
        Radius.circular(u * 0.006),
      ),
      Paint()..color = const Color(0xFFBFC3C9),
    );
    c.drawLine(
      Offset(cx - u * 0.02, y - u * 0.04),
      Offset(cx - u * 0.02, y + u * 0.02),
      Paint()
        ..color = const Color(0xFF9EA2A8)
        ..strokeWidth = u * 0.01,
    );
    // Status LEDs.
    for (var i = 0; i < 3; i++) {
      final color = i == 1 ? MM.red : MM.blue;
      c.drawCircle(
        Offset(cx + u * 0.05, y + i * u * 0.025),
        u * 0.008,
        Paint()..color = _on(i / 3) ? color : color.withOpacity(0.3),
      );
    }

    // Round knob.
    y += u * 0.21;
    final knobC = Offset(cx, y);
    c.drawCircle(knobC, u * 0.055, Paint()..color = const Color(0xFF1C1D20));
    c.drawCircle(
      knobC,
      u * 0.047,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [Color(0xFFF2F3F5), Color(0xFF9DA1A8)],
        ).createShader(Rect.fromCircle(center: knobC, radius: u * 0.047)),
    );
    c.drawLine(
      knobC,
      knobC + Offset(0, -u * 0.035),
      Paint()
        ..color = const Color(0xFF4A4D52)
        ..strokeWidth = 1.5,
    );

    // Odometer — total items across lists.
    y += u * 0.13;
    final odo = Rect.fromCenter(
      center: Offset(cx, y),
      width: u * 0.14,
      height: u * 0.055,
    );
    _plate(c, odo);
    final digits = items.clamp(0, 9999).toString().padLeft(4, '0');
    for (var i = 0; i < 4; i++) {
      final cell = Rect.fromLTWH(
        odo.left + u * 0.01 + i * u * 0.033,
        odo.top + u * 0.009,
        u * 0.028,
        u * 0.037,
      );
      c.drawRect(cell, Paint()..color = const Color(0xFFEDEDED));
      final tp = TextPainter(
        text: TextSpan(
          text: digits[i],
          style: TextStyle(
            fontSize: u * 0.03,
            color: const Color(0xFF1C1D20),
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(c, cell.center - Offset(tp.width / 2, tp.height / 2));
    }

    // Gauge — needle sweeps with the share of lists unlocked.
    y += u * 0.17;
    final g = Offset(cx, y);
    final gr = u * 0.064;
    // Indicator LEDs above and below the gauge.
    for (var i = 0; i < 2; i++) {
      c.drawCircle(
        Offset(cx - u * 0.04 + i * u * 0.08, y - gr - u * 0.03),
        u * 0.008,
        Paint()..color = i == 0 ? MM.red : MM.teal,
      );
      c.drawCircle(
        Offset(cx - u * 0.04 + i * u * 0.08, y + gr + u * 0.03),
        u * 0.008,
        Paint()..color = _on(0.5 * i) ? MM.teal : MM.teal.withOpacity(0.3),
      );
    }
    c.drawCircle(g, gr + u * 0.012, Paint()..color = const Color(0xFF8A8E96));
    c.drawCircle(g, gr, Paint()..color = const Color(0xFFF5F5F2));
    final tick =
        Paint()
          ..color = const Color(0xFF3A3D42)
          ..strokeWidth = 1;
    for (var i = 0; i <= 10; i++) {
      final a = math.pi * 0.75 + i * math.pi * 1.5 / 10;
      c.drawLine(
        g + Offset(math.cos(a), math.sin(a)) * gr * 0.8,
        g + Offset(math.cos(a), math.sin(a)) * gr * 0.95,
        tick,
      );
    }
    final a = math.pi * 0.75 + fill.clamp(0.0, 1.0) * math.pi * 1.5;
    c.drawLine(
      g,
      g + Offset(math.cos(a), math.sin(a)) * gr * 0.78,
      Paint()
        ..color = MM.red
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    c.drawCircle(g, u * 0.008, Paint()..color = const Color(0xFF3A3D42));
  }

  void _plate(Canvas c, Rect r) {
    final rr = RRect.fromRectAndRadius(
      r,
      Radius.circular(r.shortestSide * 0.15),
    );
    c.drawRRect(rr, Paint()..color = const Color(0xFF1E1F22));
    c.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFF5A5D63),
    );
  }

  @override
  bool shouldRepaint(_ConsolePainter old) =>
      old.t != t || old.items != items || old.fill != fill;
}
