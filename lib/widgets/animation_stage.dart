import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Lower visual area. Plays the assistant's image(s) for the current turn.
/// When a turn returns SEVERAL images, they're shown one after another —
/// each dwells for [frameDuration], then slow-cross-fades to the next, holding
/// on the final frame. A single image just shows (and stays). Falls back to a
/// rocket placeholder when there's nothing to show.
///
/// TODO(future): support Lottie / Rive when a url ends with `.json` / `.riv`.
class AnimationStage extends StatefulWidget {
  const AnimationStage({
    super.key,
    this.imageUrls = const [],
    this.isThinking = false,
    this.frameDuration = const Duration(milliseconds: 3500),
    this.transitionDuration = const Duration(milliseconds: 800),
  });

  /// Ordered frames for the current turn. Empty → rocket placeholder.
  final List<String> imageUrls;
  final bool isThinking;

  /// How long each frame stays before advancing to the next.
  final Duration frameDuration;

  /// Cross-fade length between frames.
  final Duration transitionDuration;

  @override
  State<AnimationStage> createState() => _AnimationStageState();
}

class _AnimationStageState extends State<AnimationStage> {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  @override
  void didUpdateWidget(covariant AnimationStage old) {
    super.didUpdateWidget(old);
    // A new turn (different frame list) restarts the sequence from the top.
    if (!listEquals(old.imageUrls, widget.imageUrls)) {
      _index = 0;
      _restart();
    }
  }

  /// (Re)starts the advance timer. Each frame dwells for [frameDuration] before
  /// advancing; we stop on the last frame so it stays on screen.
  void _restart() {
    _timer?.cancel();
    _precacheAll();
    if (widget.imageUrls.length <= 1) return; // nothing to advance through
    _timer = Timer.periodic(widget.frameDuration, (t) {
      if (!mounted) return;
      if (_index >= widget.imageUrls.length - 1) {
        t.cancel(); // hold on the final frame
        return;
      }
      setState(() => _index++);
    });
  }

  /// Warm the image cache so cross-fades don't stutter on first show.
  void _precacheAll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final url in widget.imageUrls) {
        precacheImage(NetworkImage(url), context);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String? get _currentUrl =>
      (widget.imageUrls.isNotEmpty && _index < widget.imageUrls.length)
          ? widget.imageUrls[_index]
          : null;

  @override
  Widget build(BuildContext context) {
    final url = _currentUrl;
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: AnimatedSwitcher(
            duration: widget.transitionDuration,
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            child: url == null
                ? const _DefaultRocket(key: ValueKey('default-rocket'))
                : Padding(
                    key: ValueKey(url),
                    padding: const EdgeInsets.all(16),
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                      errorBuilder: (_, __, ___) => const _DefaultRocket(),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ),
        // Frame counter dots when a turn has multiple frames.
        if (widget.imageUrls.length > 1)
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: _FrameDots(count: widget.imageUrls.length, active: _index),
          ),
        if (isThinkingNow)
          const Positioned.fill(
            child: IgnorePointer(child: _ThinkingPulse()),
          ),
      ],
    );
  }

  bool get isThinkingNow => widget.isThinking;
}

/// Small progress dots showing which frame of a multi-image turn is playing.
class _FrameDots extends StatelessWidget {
  const _FrameDots({required this.count, required this.active});
  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final on = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: on ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: on ? 0.9 : 0.35),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

class _DefaultRocket extends StatelessWidget {
  const _DefaultRocket({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Image.asset('assets/images/rocket.png', fit: BoxFit.contain),
    );
  }
}

class _ThinkingPulse extends StatefulWidget {
  const _ThinkingPulse();

  @override
  State<_ThinkingPulse> createState() => _ThinkingPulseState();
}

class _ThinkingPulseState extends State<_ThinkingPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_ctrl.value);
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              radius: 0.6 + 0.1 * t,
              colors: [
                Colors.white.withValues(alpha: 0.05 + 0.10 * t),
                Colors.transparent,
              ],
            ),
          ),
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Thinking…',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
