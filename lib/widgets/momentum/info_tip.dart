import 'package:flutter/material.dart';

import '../../theme/momentum_tokens.dart';

Tooltip _tip(String text, Widget child) => Tooltip(
      richMessage: WidgetSpan(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Text(text,
              style: MM.body(size: 12.5, color: Colors.white, height: 1.4)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.all(12),
      waitDuration: const Duration(milliseconds: 150),
      showDuration: const Duration(seconds: 8),
      triggerMode: TooltipTriggerMode.tap,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1330),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: child,
    );

/// A small ⓘ that explains a dashboard block: hover on desktop, tap anywhere.
/// For players who skipped the Flight Deck tour.
class InfoTip extends StatelessWidget {
  const InfoTip(this.text, {super.key, this.size = 15});
  final String text;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
        label: text,
        child: _tip(
          text,
          Padding(
            padding: const EdgeInsets.all(3),
            child: Icon(Icons.info_outline,
                size: size, color: Colors.white.withOpacity(0.55)),
          ),
        ),
      );
}

/// Pins an [InfoTip] to a corner of [child] (a block that has no header row).
class WithInfo extends StatelessWidget {
  const WithInfo(
      {super.key,
      required this.text,
      required this.child,
      this.top = 6,
      this.right = 6});
  final String text;
  final Widget child;
  final double top;
  final double right;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          child,
          Positioned(top: top, right: right, child: InfoTip(text)),
        ],
      );
}

/// Hover / tap explanation on a button, without adding an icon next to it.
class HoverHint extends StatelessWidget {
  const HoverHint({super.key, required this.text, required this.child});
  final String text;
  final Widget child;

  @override
  Widget build(BuildContext context) => Tooltip(
        richMessage: WidgetSpan(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Text(text,
                style: MM.body(size: 12.5, color: Colors.white, height: 1.4)),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        waitDuration: const Duration(milliseconds: 300),
        showDuration: const Duration(seconds: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1330),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: child,
      );
}
