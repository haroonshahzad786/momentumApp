import 'package:flutter/material.dart';
import '../../theme/momentum_tokens.dart';
import 'starfield.dart';
import 'bottom_nav.dart';

/// Shared chrome: starfield bg, back button, subtitle/title, optional chat
/// button, scrollable body, optional bottom nav.
class ScreenShell extends StatelessWidget {
  const ScreenShell({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.accent,
    this.onBack,
    this.onChat,
    this.onNav,
    this.hideNav = false,
  });

  final String title;
  final String? subtitle;
  final Color? accent;
  final VoidCallback? onBack;
  final VoidCallback? onChat;
  final void Function(String key)? onNav;
  final bool hideNav;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final acc = accent ?? MM.blue;
    return Scaffold(
      backgroundColor: MM.pageBg,
      body: Stack(
        children: [
          const Positioned.fill(child: StarfieldBackground()),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                  child: Row(
                    children: [
                      _IconButton(
                        onTap: onBack ?? () => Navigator.of(context).maybePop(),
                        child: const Icon(Icons.chevron_left,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (subtitle ?? 'COCKPIT').toUpperCase(),
                              style: MM.displayX(size: 11, color: acc),
                            ),
                            const SizedBox(height: 2),
                            Text(title,
                                style: MM.display(size: 22, color: Colors.white)),
                          ],
                        ),
                      ),
                      if (onChat != null)
                        _ChatIconButton(onTap: onChat!),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: SingleChildScrollView(child: child),
                  ),
                ),
                if (!hideNav) BottomNav(onNav: onNav),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: MM.navy.withOpacity(0.55),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _ChatIconButton extends StatelessWidget {
  const _ChatIconButton({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4D9BFF), Color(0xFF2A7DE1)],
          ),
          border: Border.all(color: MM.violet.withOpacity(0.55)),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(color: Color(0x73B58AFF), blurRadius: 14)
          ],
        ),
        child: const Icon(Icons.star_border, color: Colors.white, size: 26),
      ),
    );
  }
}
