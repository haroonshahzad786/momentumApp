import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/momentum_tokens.dart';
import 'mm_buttons.dart';
import 'starfield.dart';

/// Below this viewport width the app keeps its full-bleed mobile screens;
/// at or above it the desktop [WebShell] (sidebar + topbar + content) renders.
const double kWebBreakpoint = 900;

/// The shell's content column is centered and capped at this width so it stays
/// readable on ultra-wide / maximized screens instead of stretching edge-to-edge.
const double kWebContentMaxWidth = 1680;

/// Marks a subtree as living inside [WebCenteredFlow]. Immersive screens use it
/// to drop their own opaque background + starfield: the flow already paints one
/// across the whole viewport, and a second one inside the narrow column reads as
/// a visible brighter stripe. [accent] lets the screen tint that shared
/// starfield (e.g. the intro carousel's per-page colour).
class WebFlowScope extends InheritedWidget {
  const WebFlowScope({super.key, required this.accent, required super.child});

  final ValueNotifier<Color?> accent;

  static WebFlowScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WebFlowScope>();

  /// Safe to call from build(): the write is deferred to after the frame.
  void setAccent(Color? color) {
    if (accent.value == color) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => accent.value = color);
  }

  @override
  bool updateShouldNotify(WebFlowScope old) => accent != old.accent;
}

/// Centers an intro / immersive screen (boot splash, auth, check-in flow) into
/// a phone-width column on desktop so it doesn't stretch across the viewport;
/// passes the child through unchanged below [kWebBreakpoint].
///
/// The starfield is painted once, full-bleed, behind the column — screens that
/// find a [WebFlowScope] must render transparently on top of it.
class WebCenteredFlow extends StatefulWidget {
  const WebCenteredFlow({super.key, required this.child, this.maxWidth = 480});
  final Widget child;
  final double maxWidth;

  @override
  State<WebCenteredFlow> createState() => _WebCenteredFlowState();
}

class _WebCenteredFlowState extends State<WebCenteredFlow> {
  final ValueNotifier<Color?> _accent = ValueNotifier<Color?>(null);

  @override
  void dispose() {
    _accent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= kWebBreakpoint;
    if (!isDesktop) return widget.child;
    return Scaffold(
      backgroundColor: MM.pageBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: ValueListenableBuilder<Color?>(
              valueListenable: _accent,
              builder: (_, accent, __) => AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                child: StarfieldBackground(
                  key: ValueKey(accent),
                  accent: accent,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: widget.maxWidth),
              child: WebFlowScope(accent: _accent, child: widget.child),
            ),
          ),
        ],
      ),
    );
  }
}

/// A primary destination in the desktop sidebar. [appKey] is the screen key
/// understood by MomentumHome's router ('dashboard' is labelled "Cockpit").
class WebNavItem {
  const WebNavItem(this.appKey, this.label, this.hint, this.icon, this.accent);
  final String appKey;
  final String label;
  final String hint;
  final IconData icon;
  final Color accent;
}

const List<WebNavItem> kWebNav = [
  WebNavItem('dashboard', 'Cockpit', 'Home', Icons.rocket_launch_outlined, MM.blue),
  WebNavItem('routines', 'Routines', 'Daily orbit', Icons.autorenew, MM.teal),
  WebNavItem('habits', 'Habits', 'Golden', Icons.spa_outlined, MM.magenta),
  WebNavItem('tasks', 'Tasks', 'Missions', Icons.checklist_rtl, MM.yellow),
  WebNavItem('lists', 'Lists', 'Manifest', Icons.view_list_outlined, MM.blue),
  WebNavItem('cantina', 'Cantina', 'Social', Icons.local_bar_outlined, MM.violet),
  WebNavItem('trophy', 'Trophy', 'Room', Icons.emoji_events_outlined, MM.yellow),
];

// Shown only when [WebShell.isAdmin] is true — see ADMIN_PANEL_BACKEND_PLAN.md
// §0. Kept out of [kWebNav] so non-admins never see it rendered at all.
const WebNavItem kAdminNavItem =
    WebNavItem('admin', 'Admin', 'Backend', Icons.admin_panel_settings_outlined, MM.red);

/// Desktop web shell: a fixed 264px sidebar (brand · nav · player card) beside
/// a content column with an optional topbar. Renders only at >= [kWebBreakpoint].
/// Mirrors web.jsx's WebSidebar/WebTopbar.
class WebShell extends StatelessWidget {
  const WebShell({
    super.key,
    required this.current,
    required this.onNav,
    required this.name,
    required this.streak,
    required this.planetName,
    required this.level,
    required this.onCheckIn,
    required this.onChat,
    required this.onSignOut,
    required this.content,
    this.showTopbar = true,
    this.title = 'Cockpit',
    this.subtitle = 'Mission Control',
    this.accent = MM.blue,
    this.isAdmin = false,
  });

  final String current;
  final void Function(String key) onNav;
  final String name;
  final int streak;
  final String planetName;
  final String level;
  final VoidCallback onCheckIn;
  final VoidCallback onChat;
  final VoidCallback onSignOut;
  final Widget content;
  final bool showTopbar;
  final String title;
  final String subtitle;
  final Color accent;
  // Shows the "Admin" sidebar entry when true. This is a visibility
  // convenience only — AdminGate (not this flag) is what actually enforces
  // access on the destination screen. See ADMIN_PANEL_BACKEND_PLAN.md §0.
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MM.pageBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: StarfieldBackground()),
          Positioned.fill(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _WebSidebar(
                  current: current,
                  onNav: onNav,
                  name: name,
                  streak: streak,
                  planetName: planetName,
                  level: level,
                  onSignOut: onSignOut,
                  isAdmin: isAdmin,
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, c) {
                      // Cap the content column on ultra-wide / maximized
                      // screens so it stays readable and centered instead of
                      // sprawling edge-to-edge.
                      final w = c.maxWidth > kWebContentMaxWidth
                          ? kWebContentMaxWidth
                          : c.maxWidth;
                      return Align(
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: w,
                          height: c.maxHeight,
                          child: Column(
                            children: [
                              if (showTopbar)
                                _WebTopbar(
                                  title: title,
                                  subtitle: subtitle,
                                  accent: accent,
                                  onCheckIn: onCheckIn,
                                  onChat: onChat,
                                ),
                              Expanded(child: content),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SIDEBAR
// ═══════════════════════════════════════════════════════════════
class _WebSidebar extends StatelessWidget {
  const _WebSidebar({
    required this.current,
    required this.onNav,
    required this.name,
    required this.streak,
    required this.planetName,
    required this.level,
    required this.onSignOut,
    this.isAdmin = false,
  });

  final String current;
  final void Function(String key) onNav;
  final String name;
  final int streak;
  final String planetName;
  final String level;
  final VoidCallback onSignOut;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 264,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF111C4E).withOpacity(0.72),
            const Color(0xFF0A1136).withOpacity(0.55),
          ],
        ),
        border: Border(
          right: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── brand ──
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
            child: Row(
              children: [
                Image.asset('assets/brand/moore_mark.png',
                    width: 40, height: 40),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.orbitron(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3),
                        children: const [
                          TextSpan(
                              text: 'MOORE',
                              style: TextStyle(color: MM.red)),
                          TextSpan(
                              text: 'MOMENTUM',
                              style: TextStyle(color: MM.blue)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('MOMENTUM OS',
                        style: GoogleFonts.orbitron(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.4,
                            color: Colors.white.withOpacity(0.45))),
                  ],
                ),
              ],
            ),
          ),
          // ── nav ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                  child: Text('NAVIGATION',
                      style: GoogleFonts.orbitron(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.8,
                          color: Colors.white.withOpacity(0.35))),
                ),
                for (final it in kWebNav)
                  _NavButton(item: it, on: current == it.appKey, onNav: onNav),
                if (isAdmin)
                  _NavButton(
                    item: kAdminNavItem,
                    on: current == kAdminNavItem.appKey,
                    onNav: onNav,
                  ),
              ],
            ),
          ),
          // ── player card (opens Profile) + log out ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: _PlayerCard(
              name: name,
              streak: streak,
              planetName: planetName,
              level: level,
              active: current == 'profile',
              onTap: () => onNav('profile'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
            child: Row(
              children: [
                Expanded(
                  child: _SidebarAction(
                    icon: Icons.person_outline,
                    label: 'Profile',
                    accent: MM.violet,
                    active: current == 'profile',
                    onTap: () => onNav('profile'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SidebarAction(
                    icon: Icons.logout,
                    label: 'Log out',
                    accent: MM.red,
                    active: false,
                    onTap: onSignOut,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarAction extends StatelessWidget {
  const _SidebarAction({
    required this.icon,
    required this.label,
    required this.accent,
    required this.active,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color accent;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            color: active ? accent.withOpacity(0.14) : Colors.white.withOpacity(0.03),
            border: Border.all(
                color: active
                    ? accent.withOpacity(0.5)
                    : accent.withOpacity(0.28)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: accent),
              const SizedBox(width: 7),
              Flexible(
                child: Text(label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.orbitron(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: Colors.white.withOpacity(0.85))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton(
      {required this.item, required this.on, required this.onNav});
  final WebNavItem item;
  final bool on;
  final void Function(String key) onNav;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onNav(item.appKey),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: on
                  ? LinearGradient(
                      colors: [item.accent.withOpacity(0.15), Colors.transparent],
                    )
                  : null,
              border: Border.all(
                  color: on
                      ? item.accent.withOpacity(0.33)
                      : Colors.transparent),
            ),
            child: Row(
              children: [
                Icon(item.icon,
                    size: 20,
                    color:
                        on ? item.accent : Colors.white.withOpacity(0.55)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(item.label,
                      style: GoogleFonts.orbitron(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                          color: on
                              ? Colors.white
                              : Colors.white.withOpacity(0.66))),
                ),
                Text(item.hint.toUpperCase(),
                    style: GoogleFonts.orbitron(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: on
                            ? item.accent
                            : Colors.white.withOpacity(0.3))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.name,
    required this.streak,
    required this.planetName,
    required this.level,
    required this.active,
    required this.onTap,
  });
  final String name;
  final int streak;
  final String planetName;
  final String level;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initial = (name.isEmpty ? 'C' : name)[0].toUpperCase();
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: MM.navy.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: active
                    ? MM.violet.withOpacity(0.47)
                    : Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  gradient: const RadialGradient(
                    center: Alignment(-0.4, -0.4),
                    colors: [Color(0xFFB58AFF), Color(0xFF6B3DF5), MM.blue],
                    stops: [0.0, 0.65, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: MM.violet.withOpacity(0.5),
                        blurRadius: 14,
                        spreadRadius: -2),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(initial,
                    style: GoogleFonts.orbitron(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(name.isEmpty ? 'Commander' : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MM.body(
                            size: 13,
                            color: Colors.white,
                            weight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text('${level.toUpperCase()} · ${planetName.toUpperCase()}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.orbitron(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                            color: MM.yellow)),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text('🔥$streak',
                  style: GoogleFonts.orbitron(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: MM.red)),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TOPBAR
// ═══════════════════════════════════════════════════════════════
class _WebTopbar extends StatelessWidget {
  const _WebTopbar({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onCheckIn,
    required this.onChat,
  });
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onCheckIn;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xD906070D), Color(0x0006070D)],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          // The trailing items (search + two actions) are fixed-width, so on a
          // narrow window they starve the title column and the heading wraps
          // one letter per line. Drop them progressively instead.
          final w = c.maxWidth;
          final hPad = w < 760 ? 20.0 : 40.0;
          final showSearch = w >= 900;
          final compactCta = w < 780;
          return Padding(
            padding: EdgeInsets.fromLTRB(hPad, 26, hPad, 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(subtitle.toUpperCase(),
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.orbitron(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.4,
                              color: accent)),
                      const SizedBox(height: 4),
                      Text(title,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: MM.display(
                              size: compactCta ? 24 : 30,
                              color: Colors.white,
                              weight: FontWeight.w700)),
                    ],
                  ),
                ),
                // decorative search
                if (showSearch) ...[
                  const SizedBox(width: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 260),
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: MM.navy.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.12)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search,
                              size: 16, color: Colors.white.withOpacity(0.5)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text('Search missions, habits, crew…',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: MM.body(
                                    size: 13,
                                    color: Colors.white.withOpacity(0.4))),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 12),
                // AI co-pilot
                _CopilotButton(onTap: onChat),
                const SizedBox(width: 12),
                MMPrimaryButton(
                  label: compactCta ? 'Check-in →' : 'Daily Check-in →',
                  onPressed: onCheckIn,
                  expand: false,
                  padding: EdgeInsets.symmetric(
                      horizontal: compactCta ? 16 : 22, vertical: 13),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CopilotButton extends StatelessWidget {
  const _CopilotButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const RadialGradient(
              center: Alignment(-0.4, -0.4),
              colors: [Color(0xFFB58AFF), Color(0xFF6B3DF5), MM.blue],
              stops: [0.0, 0.65, 1.0],
            ),
            border: Border.all(color: const Color(0xFFD8C0FF).withOpacity(0.55)),
            boxShadow: [
              BoxShadow(
                  color: MM.violet.withOpacity(0.5),
                  blurRadius: 18,
                  spreadRadius: -2),
            ],
          ),
          child: const Icon(Icons.star_border, size: 26, color: Colors.white),
        ),
      ),
    );
  }
}
