import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/momentum_tokens.dart';
import '../../widgets/momentum/journey_stage.dart';
import '../../widgets/momentum/starfield.dart';

/// Mobile Journey Map — the phone counterpart of the Cockpit's centre stage.
///
/// Everything the desktop Cockpit offers for reading planet state lives here:
/// the whole route with the rocket parked at the player's planet, the vertical
/// planet rail (visited · current · locked, tap to replay an arrival), the zoom
/// control (route ⇄ cockpit dashboard) and the arrival cinematic itself.
///
/// All chrome is vertical — a control rail on the left, the planet rail on the
/// right — so the route itself keeps the full height of the phone, and the
/// starfield keeps drifting behind everything (warping during a leg).
class JourneyPage extends StatefulWidget {
  const JourneyPage({
    super.key,
    required this.planet,
    required this.activeCores,
    required this.atRiskCores,
    required this.streak,
    required this.momentumScore,
    required this.onBack,
    required this.onNav,
    this.onCoreAlert,
  });

  final String planet;
  final List<String> activeCores;
  final Set<String> atRiskCores;
  final int streak;
  final int momentumScore;
  final VoidCallback onBack;
  final void Function(String key) onNav;
  final void Function(String coreId)? onCoreAlert;

  /// Momentum between planets — same ladder the Cockpit's "Next planet in …"
  /// readout uses.
  static const int kPtsPerPlanet = 12000;

  @override
  State<JourneyPage> createState() => _JourneyPageState();
}

class _JourneyPageState extends State<JourneyPage> {
  late final ValueNotifier<double> _warp =
      ValueNotifier<double>(journeyIdleWarp(_planetIdx));

  /// Opens on the whole route — on a phone "where am I" is the point of this
  /// screen; sliding to the top flies back into the cockpit dashboard.
  final ValueNotifier<double> _zoom = ValueNotifier<double>(0);

  /// The stop the stage is currently showing — the player's own planet unless a
  /// rail replay is in flight.
  late int _showing = _planetIdx;

  int get _planetIdx {
    final i = MM.planets.indexWhere((p) => p['id'] == widget.planet);
    return i < 0 ? 0 : i;
  }

  @override
  void initState() {
    super.initState();
    _zoom.addListener(_onZoom);
  }

  void _onZoom() => setState(() {});

  @override
  void dispose() {
    _zoom.removeListener(_onZoom);
    _zoom.dispose();
    _warp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final idx = _planetIdx;
    final planet = MM.planets[idx];
    final planetColor = planet['color'] as Color;

    return Scaffold(
      backgroundColor: MM.pageBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Nebula + static starfield (as on the cockpit), with the drifting
          // field layered over it so the stars streak while a leg is flying.
          Positioned.fill(child: StarfieldBackground(accent: planetColor)),
          Positioned.fill(child: MovingStarfield(speed: _warp)),
          SafeArea(
            child: Column(
              children: [
                _header(planet['name'] as String),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ControlRail(
                        planetColor: planetColor,
                        currentName: planet['name'] as String,
                        nextName: idx + 1 < kJourneyStops.length
                            ? kJourneyStops[idx + 1].name
                            : null,
                        toNext: _ptsToNext(),
                        showing: kJourneyStops[
                            _showing.clamp(0, kJourneyStops.length - 1)],
                        showingState: _showingState(idx),
                        zoom: _zoom.value,
                        onZoom: (v) => _zoom.value = v,
                        onBack: widget.onBack,
                      ),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, c) {
                            return JourneyStage(
                              planetIdx: idx,
                              activeCores: widget.activeCores,
                              atRiskCores: widget.atRiskCores,
                              streak: widget.streak,
                              height: c.maxHeight,
                              rocketWidth:
                                  math.min(c.maxWidth * 0.66, 230).toDouble(),
                              warpSpeed: _warp,
                              compact: true,
                              zoomController: _zoom,
                              onNav: widget.onNav,
                              onCoreAlert: widget.onCoreAlert,
                              onDockedChanged: (stop) {
                                if (mounted && stop != _showing) {
                                  setState(() => _showing = stop);
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _ptsToNext() {
    const step = JourneyPage.kPtsPerPlanet;
    final target = ((widget.momentumScore ~/ step) + 1) * step;
    return (target - widget.momentumScore).clamp(0, step);
  }

  (String, Color) _showingState(int planetIdx) {
    if (_showing < planetIdx) return ('VISITED', MM.teal);
    if (_showing == planetIdx) return ('HERE', Colors.white);
    return ('LOCKED', Colors.white.withOpacity(0.45));
  }

  Widget _header(String planetName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('JOURNEY MAP',
                    style: MM.display(size: 15, color: Colors.white)),
                const SizedBox(height: 2),
                Text('EARTH → STATION · ${planetName.toUpperCase()} ORBIT',
                    style: MM.displayX(
                        size: 8, color: Colors.white.withOpacity(0.5))),
              ],
            ),
          ),
          Text('TAP A PLANET TO REPLAY',
              textAlign: TextAlign.right,
              style: MM.displayX(
                  size: 7, color: Colors.white.withOpacity(0.35))),
        ],
      ),
    );
  }
}

/// The left-hand vertical bar: back, mission readouts, zoom, and the state of
/// whichever stop the stage is showing.
class _ControlRail extends StatelessWidget {
  const _ControlRail({
    required this.planetColor,
    required this.currentName,
    required this.nextName,
    required this.toNext,
    required this.showing,
    required this.showingState,
    required this.zoom,
    required this.onZoom,
    required this.onBack,
  });

  final Color planetColor;
  final String currentName;
  final String? nextName;
  final int toNext;
  final JourneyStop showing;
  final (String, Color) showingState;
  final double zoom;
  final ValueChanged<double> onZoom;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      // Landscape / small phones: drop the readouts before the zoom control —
      // flying the route is the function, the numbers are the commentary.
      final h = c.maxHeight;
      final showReadouts = h >= 430;
      final showState = h >= 340;
      final track =
          (h - (showReadouts ? 250 : 120) - (showState ? 48 : 0)).clamp(56, 130).toDouble();
      return _shell(showReadouts: showReadouts, showState: showState, track: track);
    });
  }

  Widget _shell({
    required bool showReadouts,
    required bool showState,
    required double track,
  }) {
    return Container(
      width: 64,
      margin: const EdgeInsets.fromLTRB(10, 2, 6, 10),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0D1E).withOpacity(0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MM.navy.withOpacity(0.6),
                border: Border.all(color: Colors.white.withOpacity(0.14)),
              ),
              child:
                  const Icon(Icons.arrow_back, color: Colors.white, size: 18),
            ),
          ),
          if (showReadouts) ...[
            const SizedBox(height: 12),
            _readout('NOW', currentName.toUpperCase(), planetColor),
            const SizedBox(height: 10),
            _readout('NEXT', nextName?.toUpperCase() ?? '—', Colors.white),
            const SizedBox(height: 10),
            _readout(
              'TO NEXT',
              nextName == null ? 'FINAL' : _fmt(toNext),
              MM.yellow,
            ),
          ],
          const Spacer(),
          JourneyZoomBar(
            value: zoom,
            enabled: true,
            width: 26,
            trackHeight: track,
            onChanged: onZoom,
          ),
          const Spacer(),
          if (showState) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: showingState.$2,
                boxShadow: [BoxShadow(color: showingState.$2, blurRadius: 8)],
              ),
            ),
            const SizedBox(height: 5),
            _tiny(showing.name.toUpperCase(), Colors.white),
            const SizedBox(height: 2),
            _tiny(showingState.$1, showingState.$2),
          ],
        ],
      ),
    );
  }

  Widget _readout(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: MM.displayX(
                size: 6.5, color: Colors.white.withOpacity(0.5))),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value,
              maxLines: 1,
              softWrap: false,
              style: MM.display(size: 11, color: color, height: 1)),
        ),
      ],
    );
  }

  Widget _tiny(String text, Color color) => FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(text,
            maxLines: 1,
            softWrap: false,
            style: MM.displayX(size: 7, color: color)),
      );

  static String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
