import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/momentum_tokens.dart';
import '../../widgets/momentum/mm_buttons.dart';
import '../../widgets/momentum/starfield.dart';

/// Entry-point for unauthenticated users.
/// Flow: intro carousel → sign-up → sign-in (toggle), all wired to Firebase.
class AuthFlow extends StatefulWidget {
  const AuthFlow({super.key});

  @override
  State<AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<AuthFlow> {
  _Stage _stage = _Stage.intro;

  @override
  Widget build(BuildContext context) {
    switch (_stage) {
      case _Stage.intro:
        return IntroScreen(
          onFinish: () => setState(() => _stage = _Stage.signup),
        );
      case _Stage.signup:
        return SignUpScreen(
          onBack: () => setState(() => _stage = _Stage.intro),
          onSwitchToSignIn: () => setState(() => _stage = _Stage.signin),
        );
      case _Stage.signin:
        return SignInScreen(
          onBack: () => setState(() => _stage = _Stage.signup),
          onSwitchToSignUp: () => setState(() => _stage = _Stage.signup),
        );
    }
  }
}

enum _Stage { intro, signup, signin }

// ─── INTRO CAROUSEL ───────────────────────────────────────────
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key, required this.onFinish});
  final VoidCallback onFinish;

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _ctrl = PageController();
  int _idx = 0;

  static const _slides = <_IntroSlide>[
    _IntroSlide(
      eyebrow: 'WELCOME, CADET',
      title: 'A mission, not a checklist',
      body:
          'Moore Momentum turns becoming who you want to be into a space mission you actually want to fly. Real change, measured in light-years.',
      accent: MM.blue,
      hero: _HeroCores(),
    ),
    _IntroSlide(
      eyebrow: 'THE 5-CORE ENGINE',
      title: 'Powered by 5 Cores',
      body:
          'Your rocket runs on five life areas: Mindset, Career, Relationships, Physical & Emotional. Every habit you build fuels a Core — and the ship.',
      accent: MM.yellow,
      hero: _HeroJourney(),
    ),
    _IntroSlide(
      eyebrow: 'YOUR AI CO-PILOT',
      title: 'Nova has your six',
      body:
          'Ask Co-pilot to plan your day, decode a slump, or rework a stalled habit. Personal mission control — in your pocket, 24/7.',
      accent: MM.violet,
      hero: _HeroCopilot(),
    ),
    _IntroSlide(
      eyebrow: 'PLOT YOUR COURSE',
      title: 'Streaks. Planets. Trophies.',
      body:
          'Show up daily to push the rocket deeper into the system. Earn upgrades, unlock planets, fill your Trophy Room with identity you can keep.',
      accent: MM.red,
      hero: _HeroTrophies(),
    ),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_idx];
    final last = _idx == _slides.length - 1;
    return Scaffold(
      backgroundColor: MM.pageBg,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              child: StarfieldBackground(
                key: ValueKey(_idx),
                accent: slide.accent,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Progress dots + skip
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: List.generate(_slides.length, (i) {
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => _go(i),
                                child: Container(
                                  margin: EdgeInsets.only(
                                      right: i < _slides.length - 1 ? 6 : 0),
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: i < _idx
                                        ? slide.accent
                                        : (i == _idx
                                            ? Colors.white
                                            : Colors.white.withOpacity(0.18)),
                                    borderRadius: BorderRadius.circular(2),
                                    boxShadow: i == _idx
                                        ? [
                                            BoxShadow(
                                                color: slide.accent,
                                                blurRadius: 8),
                                          ]
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
                        onTap: widget.onFinish,
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.white.withOpacity(0.2)),
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
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _ctrl,
                    itemCount: _slides.length,
                    onPageChanged: (i) => setState(() => _idx = i),
                    itemBuilder: (_, i) {
                      final s = _slides[i];
                      return Column(
                        children: [
                          Expanded(
                            flex: 5,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: s.hero,
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.eyebrow,
                                      style: MM.displayX(
                                          size: 10, color: s.accent)),
                                  const SizedBox(height: 8),
                                  Text(s.title,
                                      style: MM.display(
                                          size: 24,
                                          color: Colors.white,
                                          height: 1.18)),
                                  const SizedBox(height: 10),
                                  Text(s.body,
                                      style: MM.body(
                                          color: Colors.white.withOpacity(0.75),
                                          size: 13,
                                          height: 1.55)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                  child: last
                      ? MMPrimaryButton(
                          label: 'Get Started 🚀',
                          pulse: true,
                          onPressed: widget.onFinish,
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('SWIPE OR TAP',
                                style: MM.display(
                                    size: 10,
                                    color: Colors.white.withOpacity(0.5),
                                    letterSpacing: 10 * 0.18)),
                            GestureDetector(
                              onTap: () => _go(_idx + 1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      slide.accent,
                                      slide.accent.withOpacity(0.8),
                                    ],
                                  ),
                                  border: Border.all(color: slide.accent),
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: [
                                    BoxShadow(
                                        color: slide.accent.withOpacity(0.4),
                                        blurRadius: 18),
                                  ],
                                ),
                                child: Text('NEXT →',
                                    style: MM.display(
                                        size: 12,
                                        color: Colors.white,
                                        weight: FontWeight.w700,
                                        letterSpacing: 12 * 0.14)),
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

  void _go(int i) {
    if (i < 0 || i >= _slides.length) return;
    _ctrl.animateToPage(i,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic);
  }
}

class _IntroSlide {
  const _IntroSlide({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.accent,
    required this.hero,
  });
  final String eyebrow;
  final String title;
  final String body;
  final Color accent;
  final Widget hero;
}

// ─── Hero visuals ──────────────────────────────────────────
class _HeroCores extends StatelessWidget {
  const _HeroCores();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [MM.blue.withOpacity(0.32), Colors.transparent],
            stops: const [0, 0.6],
          ),
        ),
        child: Image.asset('assets/momentum/intro-cores.png',
            fit: BoxFit.contain),
      ),
    );
  }
}

class _HeroJourney extends StatelessWidget {
  const _HeroJourney();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 280,
        child: AspectRatio(
          aspectRatio: 1.5,
          child: CustomPaint(
            painter: _JourneyHeroPainter(),
            child: Center(
              child: Transform.rotate(
                angle: 78 * 3.14159 / 180,
                child: Image.asset('assets/momentum/intro-cores.png',
                    width: 70, fit: BoxFit.contain),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _JourneyHeroPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Yellow ascent arc + planets
    final yellow = Paint()
      ..color = MM.yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final dashed = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xE52A7DE1), Color(0xB39B5CFF)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..moveTo(size.width * 0.08, size.height * 0.8)
      ..quadraticBezierTo(size.width * 0.27, size.height * 0.1,
          size.width * 0.5, size.height * 0.35);
    canvas.drawPath(path, yellow);
    final tail = Path()
      ..moveTo(size.width * 0.5, size.height * 0.35)
      ..quadraticBezierTo(size.width * 0.73, size.height * 0.55,
          size.width * 0.93, size.height * 0.65);
    canvas.drawPath(tail, dashed);

    // Planet dots
    void planet(double xPct, double yPct, Color c, {bool big = false}) {
      final p = Offset(size.width * xPct, size.height * yPct);
      canvas.drawCircle(
        p,
        big ? 11 : 7,
        Paint()
          ..color = c
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    planet(0.08, 0.82, const Color(0xFF3AA6FF), big: true);
    planet(0.24, 0.54, const Color(0xFFCFD2DC));
    planet(0.66, 0.44, const Color(0xFFD9A86B));
    planet(0.84, 0.64, const Color(0xFFE8C178));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _HeroTrophies extends StatelessWidget {
  const _HeroTrophies();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 96,
                  height: 128,
                  child: CustomPaint(
                    painter: _BigFlamePainter(),
                  ),
                ),
                Text('47',
                    style: MM.display(size: 32, color: Colors.white)),
                Text('DAY STREAK',
                    style: MM.displayX(size: 9, color: MM.yellow)),
              ],
            ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: const [
                _TrophyTile(Icons.rocket_launch, MM.blue),
                _TrophyTile(Icons.dark_mode, Color(0xFFCFD2DC)),
                _TrophyTile(Icons.local_fire_department, MM.red),
                _TrophyTile(Icons.bolt, MM.yellow),
                _TrophyTile(Icons.public, MM.violet, locked: true),
                _TrophyTile(Icons.star, MM.magenta, locked: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BigFlamePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final shader = const RadialGradient(
      center: Alignment(0, 0.6),
      radius: 0.6,
      colors: [
        Colors.white,
        MM.yellow,
        MM.red,
        Color(0x009B5CFF),
      ],
      stops: [0.0, 0.35, 0.75, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final p = Paint()..shader = shader;
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(w * 0.5, h * 0.10)
      ..cubicTo(w * 0.32, h * 0.32, w * 0.20, h * 0.45, w * 0.20, h * 0.62)
      ..cubicTo(w * 0.20, h * 0.80, w * 0.32, h * 0.92, w * 0.50, h * 0.92)
      ..cubicTo(w * 0.68, h * 0.92, w * 0.80, h * 0.80, w * 0.80, h * 0.62)
      ..cubicTo(w * 0.80, h * 0.50, w * 0.65, h * 0.40, w * 0.60, h * 0.26)
      ..cubicTo(w * 0.58, h * 0.40, w * 0.50, h * 0.45, w * 0.46, h * 0.40)
      ..cubicTo(w * 0.46, h * 0.26, w * 0.50, h * 0.18, w * 0.50, h * 0.10)
      ..close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _TrophyTile extends StatelessWidget {
  const _TrophyTile(this.icon, this.color, {this.locked = false});
  final IconData icon;
  final Color color;
  final bool locked;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: locked
            ? null
            : RadialGradient(
                colors: [color.withOpacity(0.33), Colors.transparent],
                stops: const [0, 0.7],
              ),
        color: locked ? Colors.white.withOpacity(0.05) : null,
        border: Border.all(
            color: locked
                ? Colors.white.withOpacity(0.12)
                : color.withOpacity(0.47)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: locked
            ? null
            : [BoxShadow(color: color.withOpacity(0.33), blurRadius: 12)],
      ),
      child: Icon(icon,
          color: locked ? Colors.white.withOpacity(0.3) : color, size: 22),
    );
  }
}

class _HeroCopilot extends StatelessWidget {
  const _HeroCopilot();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFFB58AFF), Color(0xFF6B3DF5), MM.blue],
                    stops: [0, 0.55, 1],
                  ),
                  boxShadow: const [
                    BoxShadow(color: Color(0xB39B5CFF), blurRadius: 30),
                  ],
                ),
                child: const Icon(Icons.star_border,
                    color: Colors.white, size: 66),
              ),
              const SizedBox(height: 8),
              Text('CO-PILOT',
                  style: MM.displayX(
                      size: 9, color: const Color(0xFFD8C0FF))),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF00FF88),
                      boxShadow: [
                        BoxShadow(color: Color(0xFF00FF88), blurRadius: 6),
                      ],
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text('ONLINE',
                      style: MM.display(
                          size: 9,
                          color: const Color(0xFF00FF88),
                          letterSpacing: 9 * 0.14)),
                ],
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: MM.navy.withOpacity(0.55),
                border: Border.all(color: MM.violet.withOpacity(0.35)),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: MM.violet.withOpacity(0.2), blurRadius: 18),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ChatBubble(
                      text: 'Pattern: Mindset dipped 3 days. Want a tweak?',
                      mine: false),
                  const SizedBox(height: 6),
                  _ChatBubble(text: 'Yes please', mine: true),
                  const SizedBox(height: 6),
                  _ChatBubble(
                      text:
                          'Move meditation to right after coffee. Lower friction.',
                      mine: false),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.text, required this.mine});
  final String text;
  final bool mine;
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 200),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          gradient: mine
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF3A8DFF), Color(0xFF1F5FB8)],
                )
              : null,
          color: mine ? null : MM.violet.withOpacity(0.18),
          border: Border.all(
              color: mine
                  ? const Color(0xFF4D9BFF).withOpacity(0.5)
                  : MM.violet.withOpacity(0.35)),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(10),
            topRight: const Radius.circular(10),
            bottomLeft: Radius.circular(mine ? 10 : 3),
            bottomRight: Radius.circular(mine ? 3 : 10),
          ),
        ),
        child: Text(text,
            style: MM.body(color: Colors.white, size: 10, height: 1.4)),
      ),
    );
  }
}

// ─── SIGN-UP ────────────────────────────────────────────────
class SignUpScreen extends StatefulWidget {
  const SignUpScreen(
      {super.key, required this.onBack, required this.onSwitchToSignIn});
  final VoidCallback onBack;
  final VoidCallback onSwitchToSignIn;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _auth = AuthService();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  bool get _valid =>
      _emailCtrl.text.contains('@') && _pwCtrl.text.length >= 6;

  Future<void> _doSignUp() async {
    if (!_valid || _busy) return;
    setState(() => _busy = true);
    try {
      await _auth.signUpWithEmail(_emailCtrl.text, _pwCtrl.text);
      final u = _auth.currentUser;
      final name = _nameCtrl.text.trim();
      if (u != null) {
        if (name.isNotEmpty) {
          await u.updateDisplayName(name);
        }
        // Persist the name into the `users/{uid}` document so it lives in the
        // users collection alongside the rest of the profile (Cantina,
        // leaderboard, etc. can resolve a name by uid). Best-effort — a
        // failure here must never block sign-up.
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(u.uid)
              .set({
            if (name.isNotEmpty) 'name': name,
            'email': u.email,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('Saving user name to Firestore failed: $e');
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AuthService.describeError(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _doGuest() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _auth.signInAnonymously();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AuthService.describeError(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MM.pageBg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const Positioned.fill(child: StarfieldBackground()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BackButton(onTap: widget.onBack),
                  const SizedBox(height: 14),
                  Text('NEW CADET',
                      style: MM.displayX(size: 11, color: MM.yellow)),
                  const SizedBox(height: 4),
                  Text('Launch your account',
                      style: MM.display(size: 24, color: Colors.white)),
                  const SizedBox(height: 6),
                  Text(
                      'Save your streaks, sync across devices, join a squad.',
                      style: MM.body(
                          color: Colors.white.withOpacity(0.6), size: 12)),
                  const SizedBox(height: 22),
                  _AuthField(
                    label: 'CALL SIGN',
                    controller: _nameCtrl,
                    hint: 'Alex Moore',
                  ),
                  _AuthField(
                    label: 'EMAIL',
                    controller: _emailCtrl,
                    hint: 'cadet@momentum.app',
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => setState(() {}),
                  ),
                  _AuthField(
                    label: 'PASSWORD',
                    controller: _pwCtrl,
                    hint: '••••••••',
                    obscure: true,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  MMPrimaryButton(
                    label: 'Create Account',
                    pulse: _valid,
                    busy: _busy,
                    onPressed: _valid ? _doSignUp : null,
                  ),
                  const SizedBox(height: 18),
                  Row(children: [
                    Expanded(
                        child: Container(
                            height: 1,
                            color: Colors.white.withOpacity(0.18))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text('OR',
                          style: MM.display(
                              size: 10,
                              color: Colors.white.withOpacity(0.4),
                              letterSpacing: 10 * 0.18)),
                    ),
                    Expanded(
                        child: Container(
                            height: 1,
                            color: Colors.white.withOpacity(0.18))),
                  ]),
                  const SizedBox(height: 18),
                  MMGhostButton(
                    label: 'Skip — Continue as Guest',
                    expand: true,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    onPressed: _busy ? null : _doGuest,
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                        'Creates a temporary account · upgrade anytime',
                        style: MM.body(
                            color: Colors.white.withOpacity(0.45),
                            size: 10)),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: GestureDetector(
                      onTap: widget.onSwitchToSignIn,
                      child: RichText(
                        text: TextSpan(
                          style: MM.body(
                              color: Colors.white.withOpacity(0.6), size: 12),
                          children: [
                            const TextSpan(text: 'Already flying? '),
                            TextSpan(
                              text: 'Sign in',
                              style: TextStyle(
                                  color: MM.blue,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SIGN-IN ────────────────────────────────────────────────
class SignInScreen extends StatefulWidget {
  const SignInScreen(
      {super.key, required this.onBack, required this.onSwitchToSignUp});
  final VoidCallback onBack;
  final VoidCallback onSwitchToSignUp;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _auth = AuthService();
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  bool get _valid =>
      _emailCtrl.text.contains('@') && _pwCtrl.text.length >= 6;

  Future<void> _doSignIn() async {
    if (!_valid || _busy) return;
    setState(() => _busy = true);
    try {
      await _auth.signInWithEmail(_emailCtrl.text, _pwCtrl.text);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AuthService.describeError(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MM.pageBg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const Positioned.fill(child: StarfieldBackground()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BackButton(onTap: widget.onBack),
                  const SizedBox(height: 14),
                  Text('RETURNING PILOT',
                      style: MM.displayX(size: 11, color: MM.blue)),
                  const SizedBox(height: 4),
                  Text('Welcome back',
                      style: MM.display(size: 24, color: Colors.white)),
                  const SizedBox(height: 6),
                  Text('Your streaks are waiting.',
                      style: MM.body(
                          color: Colors.white.withOpacity(0.6), size: 12)),
                  const SizedBox(height: 22),
                  _AuthField(
                    label: 'EMAIL',
                    controller: _emailCtrl,
                    hint: 'cadet@momentum.app',
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => setState(() {}),
                  ),
                  _AuthField(
                    label: 'PASSWORD',
                    controller: _pwCtrl,
                    hint: '••••••••',
                    obscure: true,
                    onChanged: (_) => setState(() {}),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Password reset coming soon')),
                        );
                      },
                      child: Text('Forgot?',
                          style: MM.body(color: MM.blue, size: 11)),
                    ),
                  ),
                  MMPrimaryButton(
                    label: 'Sign In',
                    pulse: _valid,
                    busy: _busy,
                    onPressed: _valid ? _doSignIn : null,
                  ),
                  const SizedBox(height: 22),
                  Center(
                    child: GestureDetector(
                      onTap: widget.onSwitchToSignUp,
                      child: RichText(
                        text: TextSpan(
                          style: MM.body(
                              color: Colors.white.withOpacity(0.6), size: 12),
                          children: [
                            const TextSpan(text: 'New here? '),
                            TextSpan(
                              text: 'Create an account',
                              style: TextStyle(
                                  color: MM.yellow,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared field + back button ──────────────────────────────
class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.label,
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.keyboardType,
    this.onChanged,
  });
  final String label;
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: MM.displayX(
                  size: 9, color: Colors.white.withOpacity(0.55))),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: MM.body(color: Colors.white, size: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  MM.body(color: Colors.white.withOpacity(0.4), size: 14),
              filled: true,
              fillColor: MM.navy.withOpacity(0.55),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: MM.blue.withOpacity(0.35)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: MM.blue.withOpacity(0.35)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: MM.blue),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
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
          color: MM.navy.withOpacity(0.55),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.chevron_left, color: Colors.white, size: 22),
      ),
    );
  }
}
