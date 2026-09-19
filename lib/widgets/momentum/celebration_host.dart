import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/celebration_service.dart';
import '../../theme/momentum_tokens.dart';
import 'confetti_overlay.dart';

/// Guards against two celebrations for the same award.
///
/// A ledger-triggered celebration and the HHS chat's own section-reward card
/// are raised by different signals (a points-ledger write vs the polled
/// onboarding sync) that describe the same moment. Whichever wins
/// the race claims the window; the other stays quiet.
class CelebrationBus {
  CelebrationBus._();

  static DateTime? _last;

  /// True if a celebration may play now. Marks the window when it grants.
  static bool claim({Duration window = const Duration(seconds: 6)}) {
    final now = DateTime.now();
    final last = _last;
    if (last != null && now.difference(last) < window) return false;
    _last = now;
    return true;
  }
}

/// Drops a confetti burst (plus an optional "+N MP" badge) over everything on
/// screen, including pushed routes — it goes into the ROOT overlay, so the
/// Co-Pilot console and the inline cockpit screens are both covered.
///
/// Purely decorative and non-interactive; removes itself when the burst ends.
void showCelebrationBurst(
  BuildContext context, {
  String? amountLabel,
  String? title,
  int count = 90,
  Duration duration = const Duration(milliseconds: 3000),
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  late final OverlayEntry entry;
  entry = OverlayEntry(
    // Positioned.fill, not a bare child: an overlay entry is laid out by the
    // Overlay's theatre with LOOSE constraints, so an unpositioned Stack of
    // positioned children collapses to zero and paints nothing.
    builder: (_) => Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            ConfettiOverlay(count: count, duration: duration),
            if (amountLabel != null || title != null)
              Align(
                alignment: const Alignment(0, -0.35),
                child: _BurstLabel(amountLabel: amountLabel, title: title),
              ),
          ],
        ),
      ),
    ),
  );

  overlay.insert(entry);
  Timer(duration + const Duration(milliseconds: 400), entry.remove);
}

class _BurstLabel extends StatelessWidget {
  const _BurstLabel({this.amountLabel, this.title});
  final String? amountLabel;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (amountLabel != null) PointsPopBadge(label: amountLabel!),
        if (title != null) ...[
          const SizedBox(height: 6),
          _FadeIn(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: MM.navy.withOpacity(0.85),
                border: Border.all(color: MM.yellow.withOpacity(0.45)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(title!.toUpperCase(),
                  style: MM.displayX(size: 10, color: MM.yellow)),
            ),
          ),
        ],
      ],
    );
  }
}

class _FadeIn extends StatefulWidget {
  const _FadeIn({required this.child});
  final Widget child;
  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _ctrl, child: widget.child);
}

/// Listens for points celebrations for the signed-in player and bursts
/// confetti wherever they happen to be.
///
/// Mount once, high in the tree. The award amount/label come from the
/// points-ledger entry that triggered it — when it can't be read the burst
/// still plays, without a number (nothing fabricated).
class CelebrationHost extends StatefulWidget {
  const CelebrationHost({
    super.key,
    required this.userId,
    required this.child,
  });

  final String userId;
  final Widget child;

  @override
  State<CelebrationHost> createState() => _CelebrationHostState();
}

class _CelebrationHostState extends State<CelebrationHost> {
  final _service = CelebrationService();
  StreamSubscription<CelebrationEvent>? _sub;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(covariant CelebrationHost old) {
    super.didUpdateWidget(old);
    if (old.userId != widget.userId) {
      _sub?.cancel();
      _subscribe();
    }
  }

  void _subscribe() {
    if (widget.userId.isEmpty) return;
    _sub = _service.watch(widget.userId).listen((e) {
      if (!mounted || !e.isCelebration) return;
      if (!CelebrationBus.claim()) return;
      final award = e.award;
      showCelebrationBurst(
        context,
        amountLabel: award == null ? null : '+${award.points} MP',
        title: (award?.type.isNotEmpty ?? false)
            ? award!.type
            : 'Progress saved',
      );
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
