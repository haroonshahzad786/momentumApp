import 'package:flutter/material.dart';

import '../../services/asset_preloader.dart';
import '../../theme/momentum_tokens.dart';
import '../../widgets/momentum/starfield.dart';
import '../../widgets/momentum/web_shell.dart';

/// 5-page intro carousel shown to unauthenticated users before the login /
/// sign-up screens. Rebuilt from the client's "pagewise" reference designs:
///
///   1. Press-to-begin rocket splash
///   2. Welcome terminal + Earth
///   3. 5-Core rocket engine
///   4. Break gravity / Golden Habit
///   5. Flight-plan pyramid → Get Started
///
/// Navigation mirrors the previous intro (swipeable [PageView] + progress dots
/// + Skip) and adds the blue arrow buttons from the reference. [onFinish] hands
/// control back to the auth flow (sign-up), and Skip does the same.
class IntroCarousel extends StatefulWidget {
  const IntroCarousel({super.key, required this.onFinish});

  /// Called when the user finishes the last page, taps Skip, or presses the
  /// begin/get-started actions — i.e. "leave the intro and show login".
  final VoidCallback onFinish;

  @override
  State<IntroCarousel> createState() => _IntroCarouselState();
}

class _IntroCarouselState extends State<IntroCarousel> {
  final _ctrl = PageController();
  int _idx = 0;

  static const _count = 5;

  // Per-page accent used to tint the starfield + progress dots.
  static const _accents = <Color>[
    MM.blue,
    MM.blue,
    MM.teal,
    MM.violet,
    MM.yellow,
  ];

  // Screen-terminal copy for pages 2–4 (verbatim from the reference text).
  static const _welcomeText =
      'Welcome, Player One!\n'
      'Planet Earth is on the brink of self-destruction 🧨🌎. '
      'The only way to save it?\n'
      'Launch into the cosmos on an epic quest to discover:\n'
      'WHO you are\n'
      'WHAT you want\n'
      'HOW to get it\n'
      'Then return with the Universal, science-backed habit wisdom 🪐 '
      'needed to unite humankind and save the planet 🤝🌍😎.';

  static const _coresText =
      'Your Rocket Ship 🚀 is powered by the 5 Core Areas of Life tied to '
      'lasting happiness — each fueled by your habits. The more harmful habits '
      'you replace with healthy ones, the more momentum, upgrades, and rewards '
      'your rocket gains 🚀📈';

  static const _gravityText =
      'Break earth’s gravitational pull by uncovering a core challenge '
      'holding you back in one core area, and create your first personalized '
      'Golden Habit 🏆🔄 to defeat it 👊!';

  /// Copy shown on the persistent terminal frame. Pages 1 and 5 have no frame,
  /// but they keep the neighbouring page's text so it fades out with the frame
  /// instead of blanking mid-swipe.
  String get _screenText {
    switch (_idx) {
      case 2:
        return _coresText;
      case 3:
      case 4:
        return _gravityText;
      default:
        return _welcomeText;
    }
  }

  /// Live scroll position in pages (falls back to the settled index before the
  /// controller is attached).
  double get _page {
    if (_ctrl.hasClients && _ctrl.position.hasContentDimensions) {
      return _ctrl.page ?? _idx.toDouble();
    }
    return _idx.toDouble();
  }

  /// Frame is only part of pages 2–4; fade it across the two edge swipes.
  double _frameOpacity() {
    final p = _page;
    if (p <= 1) return p.clamp(0.0, 1.0);
    if (p >= 3) return (4 - p).clamp(0.0, 1.0);
    return 1;
  }

  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Normally already warm from the boot splash; this covers a direct entry
    // (hot restart, or the splash finishing before the art finished loading).
    if (!_precached) {
      _precached = true;
      precacheIntroImages(context);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _go(int i) {
    if (i < 0 || i >= _count) return;
    _ctrl.animateToPage(i,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic);
  }

  void _next() {
    if (_idx >= _count - 1) {
      widget.onFinish();
    } else {
      _go(_idx + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accents[_idx];
    // On desktop the surrounding [WebCenteredFlow] owns the (full-bleed)
    // starfield — tint it instead of painting a second one in this column.
    final flow = WebFlowScope.maybeOf(context);
    flow?.setAccent(accent);
    return Scaffold(
      backgroundColor: flow == null ? MM.pageBg : Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (flow == null)
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                child: StarfieldBackground(
                  key: ValueKey(_idx),
                  accent: accent,
                ),
              ),
            ),
          SafeArea(
            child: Column(
              children: [
                _TopBar(
                  count: _count,
                  index: _idx,
                  accent: accent,
                  onDotTap: _go,
                  onSkip: widget.onFinish,
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, c) {
                      // The terminal frame is identical on pages 2–4, so it is
                      // hoisted out of the PageView: one widget, laid out once,
                      // that never slides with the swipe and never re-decodes
                      // screen.png. Only the copy inside it and the hero below
                      // change per page.
                      final frameW = c.maxWidth - 36; // 18px page padding
                      final frameH = frameW * _kScreenAspectH;
                      final heroTop = 6 + frameH + 8;
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          PageView.builder(
                            controller: _ctrl,
                            itemCount: _count,
                            onPageChanged: (i) => setState(() => _idx = i),
                            itemBuilder: (_, i) {
                              switch (i) {
                                case 0:
                                  return _PressToBeginPage(onBegin: _next);
                                case 1:
                                  return _ScreenPage(
                                    topInset: heroTop,
                                    hero: const _EarthHero(),
                                  );
                                case 2:
                                  return _ScreenPage(
                                    topInset: heroTop,
                                    hero: const _AssetHero(
                                        'assets/momentum/intro/'
                                        'rocket_cores.gif'),
                                  );
                                case 3:
                                  return _ScreenPage(
                                    topInset: heroTop,
                                    hero: const _AssetHero(
                                        'assets/momentum/intro/'
                                        'rocket_glow.gif'),
                                  );
                                default:
                                  return const _PyramidPage();
                              }
                            },
                          ),
                          Positioned(
                            top: 6,
                            left: 18,
                            right: 18,
                            height: frameH,
                            child: IgnorePointer(
                              // Fades in/out at the page-0 and page-4 edges,
                              // stays fully opaque and still across 2–4.
                              child: AnimatedBuilder(
                                animation: _ctrl,
                                builder: (_, child) => Opacity(
                                  opacity: _frameOpacity(),
                                  child: child,
                                ),
                                child: _TerminalScreen(text: _screenText),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                _BottomNav(
                  last: _idx == _count - 1,
                  accent: accent,
                  onNext: _next,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Top bar: progress dots + Skip ───────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.count,
    required this.index,
    required this.accent,
    required this.onDotTap,
    required this.onSkip,
  });
  final int count;
  final int index;
  final Color accent;
  final ValueChanged<int> onDotTap;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: List.generate(count, (i) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onDotTap(i),
                    child: Container(
                      margin: EdgeInsets.only(right: i < count - 1 ? 6 : 0),
                      height: 3,
                      decoration: BoxDecoration(
                        color: i < index
                            ? accent
                            : (i == index
                                ? Colors.white
                                : Colors.white.withOpacity(0.18)),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: i == index
                            ? [BoxShadow(color: accent, blurRadius: 8)]
                            : null,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: onSkip,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('SKIP →',
                  style: MM.display(
                      size: 9,
                      color: Colors.white.withOpacity(0.7),
                      weight: FontWeight.w600,
                      letterSpacing: 9 * 0.18)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom nav: "SWIPE OR TAP" hint + NEXT pill on every page ──
class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.last,
    required this.accent,
    required this.onNext,
  });
  final bool last;
  final Color accent;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
      child: last
          ? Center(child: _GetStartedButton(onTap: onNext))
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('SWIPE OR TAP',
                    style: MM.display(
                        size: 10,
                        color: Colors.white.withOpacity(0.5),
                        letterSpacing: 10 * 0.18)),
                _NextButton(accent: accent, onTap: onNext),
              ],
            ),
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({required this.accent, required this.onTap});
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [accent, accent.withOpacity(0.8)],
          ),
          border: Border.all(color: accent),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(color: accent.withOpacity(0.4), blurRadius: 18),
          ],
        ),
        child: Text('NEXT →',
            style: MM.display(
                size: 12,
                color: Colors.white,
                weight: FontWeight.w700,
                letterSpacing: 12 * 0.14)),
      ),
    );
  }
}

class _GetStartedButton extends StatelessWidget {
  const _GetStartedButton({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [MM.yellow, Color(0xFFE0A800)],
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(color: MM.yellow.withOpacity(0.45), blurRadius: 18),
          ],
        ),
        child: Text('GET STARTED 🚀',
            style: MM.display(
                size: 13,
                color: const Color(0xFF1A1200),
                weight: FontWeight.w800,
                letterSpacing: 13 * 0.08)),
      ),
    );
  }
}

// ─── Page 1: Press to begin ──────────────────────────────────
class _PressToBeginPage extends StatelessWidget {
  const _PressToBeginPage({required this.onBegin});
  final VoidCallback onBegin;

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    return LayoutBuilder(
      builder: (context, c) {
        // Target ~60% of the screen height for the rocket, but never so tall
        // that the press-to-begin block below would overflow this page area.
        final rocketH =
            (screenH * 0.60).clamp(0.0, c.maxHeight - 130).toDouble();
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/momentum/intro/rocket.png',
                height: rocketH,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: onBegin,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/momentum/intro/press.gif',
                      width: 150,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 4),
                    Text('TAP TO BEGIN',
                        style: MM.display(
                            size: 12,
                            color: Colors.white.withOpacity(0.85),
                            letterSpacing: 12 * 0.2)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Height of the terminal frame as a fraction of its width (screen.png is
/// 1000×715). The carousel needs this to reserve the frame's slot on each page.
const double _kScreenAspectH = 715 / 1000;

// ─── Pages 2–4: hero under the (hoisted) terminal screen ─────
/// The frame itself is painted once by [IntroCarousel]; each page only reserves
/// its height with [topInset] and supplies the hero art below it.
class _ScreenPage extends StatelessWidget {
  const _ScreenPage({required this.topInset, required this.hero});
  final double topInset;
  final Widget hero;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(18, topInset, 18, 0),
      child: Center(child: hero),
    );
  }
}

/// The rounded "cockpit terminal" frame (screen.png) with copy laid over its
/// glass. Text auto-scales down to always fit inside the glass area, and
/// cross-fades between pages — the frame image itself never moves or reloads.
class _TerminalScreen extends StatelessWidget {
  const _TerminalScreen({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/momentum/intro/screen.png', fit: BoxFit.fill),
        LayoutBuilder(
          builder: (context, c) {
            return Padding(
              // Keep text inside the curved glass region of the frame.
              padding: EdgeInsets.fromLTRB(
                c.maxWidth * 0.15,
                c.maxHeight * 0.15,
                c.maxWidth * 0.15,
                c.maxHeight * 0.14,
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  child: FittedBox(
                    key: ValueKey(text),
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: c.maxWidth * 0.70,
                      child: Text(
                        text,
                        textAlign: TextAlign.center,
                        style: MM.body(
                          color: Colors.white,
                          size: 12.5,
                          height: 1.42,
                        ).copyWith(fontStyle: FontStyle.italic),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _EarthHero extends StatelessWidget {
  const _EarthHero();
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: MM.blue.withOpacity(0.35), blurRadius: 40),
        ],
      ),
      child: Image.asset('assets/momentum/intro/earth.png',
          fit: BoxFit.contain),
    );
  }
}

class _AssetHero extends StatelessWidget {
  const _AssetHero(this.asset);
  final String asset;
  @override
  Widget build(BuildContext context) {
    return Image.asset(asset, fit: BoxFit.contain);
  }
}

// ─── Page 5: flight-plan pyramid ─────────────────────────────
class _PyramidPage extends StatelessWidget {
  const _PyramidPage();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
      child: Column(
        children: [
          Text('YOUR FLIGHT PLAN',
              style: MM.displayX(size: 11, color: MM.yellow)),
          const SizedBox(height: 4),
          Text('Climb one habit at a time',
              style: MM.body(
                  color: Colors.white.withOpacity(0.7), size: 12.5)),
          const SizedBox(height: 10),
          Expanded(
            child: Center(
              child: Image.asset(
                'assets/momentum/intro/pyramid.gif',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
