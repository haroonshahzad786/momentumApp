import 'package:flutter/material.dart';

import 'auth_page.dart';

class No02EarthFromSpace extends StatelessWidget {
  const No02EarthFromSpace({super.key});

  static const _bodyText =
      '\n\nWelcome, Player One!\n'
      'Planet Earth is on the brink of self-destruction 🧨🌎. '
      'The only way to save it?\n'
      'Launch into the cosmos on an epic quest to discover:\n'
      'WHO you are\n'
      'WHAT you want\n'
      'HOW to get it\n'
      'Then return with the Universal, science-backed habit wisdom🪐 '
      'needed to unite humankind and save the planet 🤝🌍😎.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/backgrounds_green.jpg',
            fit: BoxFit.cover,
          ),
          Column(
            children: [
              const _ScreenWithText(text: _bodyText),
              Expanded(
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      _ArrowRow(
                        onBack: () => Navigator.of(context).maybePop(),
                        onForward: () => _goToAuth(context),
                      ),
                      Expanded(
                        child: IgnorePointer(
                          child: Transform.translate(
                            offset: const Offset(0, -70),
                            child: Center(
                              child: FractionallySizedBox(
                                widthFactor: 0.88,
                                heightFactor: 0.92,
                                child: Image.asset(
                                  'assets/images/rocket-animation-background3.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _goToAuth(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AuthPage()),
    );
  }
}

class _ScreenWithText extends StatelessWidget {
  const _ScreenWithText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Image.asset(
          'assets/images/only_screen.png',
          fit: BoxFit.contain,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(52, 24, 52, 56),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.3,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _ArrowRow extends StatelessWidget {
  const _ArrowRow({required this.onBack, required this.onForward});

  final VoidCallback onBack;
  final VoidCallback onForward;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ArrowButton(icon: Icons.arrow_back, onTap: onBack),
          _ArrowButton(icon: Icons.arrow_forward, onTap: onForward),
        ],
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF2F80ED),
      borderRadius: BorderRadius.circular(10),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: SizedBox(
            width: 28,
            height: 28,
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}
