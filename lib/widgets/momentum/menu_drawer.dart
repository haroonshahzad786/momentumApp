import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/momentum_tokens.dart';

/// Slide-out menu drawer triggered by the dashboard hamburger.
/// Shows nav groups, AI co-pilot CTA, and Firebase account footer.
class MenuDrawer extends StatelessWidget {
  const MenuDrawer({
    super.key,
    required this.user,
    required this.onClose,
    required this.onNav,
    required this.onChat,
    required this.onSignOut,
  });

  final User? user;
  final VoidCallback onClose;
  final void Function(String key) onNav;
  final VoidCallback onChat;
  final VoidCallback onSignOut;

  static const _groups = [
    [
      'PHASE 1 · BUILD',
      [
        ['phase1', 'Foundation Hub', MM.yellow],
      ]
    ],
    [
      'COCKPIT',
      [
        ['dashboard', 'Dashboard', MM.blue],
        ['checkin', 'Daily Check-in', MM.yellow],
        ['summary', "Today's Recap", MM.violet],
      ]
    ],
    [
      'WORK',
      [
        ['lists', 'Lists', MM.blue],
        ['routines', 'Routines', MM.teal],
        ['habits', 'Habits', MM.magenta],
        ['tasks', 'Tasks', MM.yellow],
      ]
    ],
    [
      'CREW',
      [
        ['cantina', 'Cantina', MM.teal],
        ['trophy', 'Trophy Room', MM.yellow],
        ['profile', 'Profile', MM.yellow],
      ]
    ],
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Container(
              decoration: BoxDecoration(
                color: MM.pageBg.withOpacity(0.96),
                border: Border(
                  right: BorderSide(color: MM.blue.withOpacity(0.3)),
                ),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black54,
                      offset: Offset(8, 0),
                      blurRadius: 40),
                ],
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text('MOORE MOMENTUM',
                                  style: MM.displayX(
                                      size: 13, color: MM.yellow)),
                            ),
                            InkWell(
                              onTap: onClose,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.2)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.close,
                                    color: Colors.white, size: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Co-pilot CTA
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            onClose();
                            onChat();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  MM.violet.withOpacity(0.3),
                                  MM.blue.withOpacity(0.2),
                                ],
                              ),
                              border:
                                  Border.all(color: MM.violet.withOpacity(0.5)),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                    color: MM.violet.withOpacity(0.35),
                                    blurRadius: 18),
                              ],
                            ),
                            child: Row(children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [Color(0xFFB58AFF), MM.blue],
                                    stops: [0, 0.7],
                                  ),
                                ),
                                child: const Icon(Icons.star_border,
                                    color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Ask Co-pilot',
                                      style: MM.display(
                                          size: 13, color: Colors.white)),
                                  const SizedBox(height: 2),
                                  Text('AI mission assistant',
                                      style: MM.body(
                                          color: const Color(0xCCD8C0FF),
                                          size: 10)),
                                ],
                              ),
                            ]),
                          ),
                        ),
                      ),
                      // Nav groups
                      ..._groups.map((g) {
                        final label = g[0] as String;
                        final items = g[1] as List<List<dynamic>>;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 0, 20, 6),
                                child: Text(label,
                                    style: MM.displayX(
                                        size: 10,
                                        color: Colors.white.withOpacity(0.45))),
                              ),
                              ...items.map((it) {
                                final k = it[0] as String;
                                final name = it[1] as String;
                                final color = it[2] as Color;
                                return InkWell(
                                  onTap: () {
                                    onClose();
                                    onNav(k);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 10),
                                    child: Row(children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: color,
                                          boxShadow: [
                                            BoxShadow(
                                                color: color, blurRadius: 6),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(name,
                                          style: MM.body(
                                              color: Colors.white, size: 13)),
                                    ]),
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      }),
                      // Account footer
                      Container(
                        margin: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                        padding: const EdgeInsets.only(top: 14),
                        decoration: BoxDecoration(
                          border: Border(
                              top: BorderSide(
                                  color: Colors.white.withOpacity(0.08))),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ACCOUNT',
                                style: MM.displayX(
                                    size: 10,
                                    color: Colors.white.withOpacity(0.45))),
                            const SizedBox(height: 8),
                            if (user == null)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: Row(children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: MM.yellow,
                                      boxShadow: const [
                                        BoxShadow(
                                            color: MM.yellow, blurRadius: 6),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text('Sign in / Create account',
                                      style: MM.body(
                                          color: MM.yellow, size: 13)),
                                ]),
                              )
                            else ...[
                              Row(children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: user!.isAnonymous
                                        ? Colors.white.withOpacity(0.18)
                                        : null,
                                    gradient: user!.isAnonymous
                                        ? null
                                        : const RadialGradient(
                                            colors: [MM.yellow, MM.red]),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _initial(user!),
                                      style: TextStyle(
                                        color: user!.isAnonymous
                                            ? Colors.white
                                            : Colors.black,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _displayName(user!),
                                        overflow: TextOverflow.ellipsis,
                                        style: MM.body(
                                            color: Colors.white,
                                            weight: FontWeight.w600,
                                            size: 13),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        user!.isAnonymous
                                            ? 'GUEST · TEMPORARY'
                                            : (user!.email ?? 'SIGNED IN'),
                                        style: MM.display(
                                          size: 10,
                                          color: user!.isAnonymous
                                              ? MM.yellow
                                              : Colors.white.withOpacity(0.5),
                                          letterSpacing: 10 * 0.12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ]),
                              const SizedBox(height: 10),
                              InkWell(
                                onTap: () {
                                  onClose();
                                  onSignOut();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10),
                                  child: Row(children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: MM.red,
                                        boxShadow: const [
                                          BoxShadow(
                                              color: MM.red, blurRadius: 6),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text('Sign out',
                                        style: MM.body(
                                            color: MM.red, size: 13)),
                                  ]),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: onClose,
              child: Container(color: Colors.black.withOpacity(0.5)),
            ),
          ),
        ],
      ),
    );
  }

  String _displayName(User u) {
    if ((u.displayName ?? '').isNotEmpty) return u.displayName!;
    if ((u.email ?? '').isNotEmpty) return u.email!.split('@').first;
    return 'Cadet ${u.uid.substring(0, 4).toUpperCase()}';
  }

  String _initial(User u) {
    final n = _displayName(u);
    return n.isEmpty ? 'C' : n[0].toUpperCase();
  }
}
