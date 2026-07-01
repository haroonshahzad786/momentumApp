import 'package:flutter/material.dart';
import '../../services/cantina_service.dart';
import '../../theme/momentum_tokens.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key, this.onNav, this.activeKey});
  final void Function(String key)? onNav;
  final String? activeKey;

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  // Cached so the badge stream isn't re-subscribed on every rebuild.
  final _svc = CantinaService();
  late final Stream<int> _unread = _svc.watchUnreadTotal();

  static const _items = [
    _NavItem('habits', Icons.all_inclusive, 'Habits'),
    _NavItem('cantina', Icons.local_bar_outlined, 'Cantina'),
    _NavItem('trophy', Icons.emoji_events_outlined, 'Trophy'),
    _NavItem('profile', Icons.person_outline, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00060710), Color(0xD9060710), Color(0xF2060710)],
          stops: [0, 0.5, 1],
        ),
        border: Border(
          top: BorderSide(color: Color(0x0FF1F1F1), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _items.map((it) {
          final on = it.key == widget.activeKey;
          final color = on ? MM.blue : Colors.white.withOpacity(0.5);
          return InkWell(
            onTap: () => widget.onNav?.call(it.key),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _icon(it, color),
                  const SizedBox(height: 3),
                  Text(
                    it.label.toUpperCase(),
                    style: MM.display(
                      size: 9,
                      color: color,
                      weight: FontWeight.w600,
                      letterSpacing: 9 * 0.1,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _icon(_NavItem it, Color color) {
    final icon = Icon(it.icon, color: color, size: 22);
    if (it.key != 'cantina') return icon;
    // Cantina gets an unread badge fed by the user's inbox.
    return StreamBuilder<int>(
      stream: _unread,
      builder: (context, snap) {
        final n = snap.data ?? 0;
        if (n <= 0) return icon;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            icon,
            Positioned(
              right: -5,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                decoration: BoxDecoration(
                  color: MM.red,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: MM.pageBg, width: 1.5),
                ),
                child: Text(
                  n > 9 ? '9+' : '$n',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NavItem {
  const _NavItem(this.key, this.icon, this.label);
  final String key;
  final IconData icon;
  final String label;
}
