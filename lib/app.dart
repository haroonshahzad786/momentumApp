import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/boot_splash.dart';
import 'screens/force_password_reset_page.dart';
import 'screens/momentum/auth_flow.dart';
import 'screens/momentum/momentum_home.dart';
import 'services/access_service.dart';
import 'services/notification_service.dart';
import 'theme/momentum_tokens.dart';
import 'widgets/momentum/web_shell.dart';

class MomentumApp extends StatelessWidget {
  const MomentumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moore Momentum',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: NotificationService.instance.messengerKey,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: MM.pageBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: MM.blue,
          brightness: Brightness.dark,
          surface: MM.navy,
        ),
        textTheme: GoogleFonts.redHatDisplayTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
        useMaterial3: true,
      ),
      // Bump every text widget ~18% larger app-wide so labels, hints and
      // metadata stay readable on dense screens.
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final scaled = media.textScaler.clamp(minScaleFactor: 1.18);
        return MediaQuery(
          data: media.copyWith(textScaler: scaled),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const _RootGate(),
    );
  }
}

/// Shows the branded boot splash once on launch, then hands off to the auth
/// gate. The splash plays while Firebase finishes warming up.
class _RootGate extends StatefulWidget {
  const _RootGate();

  @override
  State<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<_RootGate> {
  bool _booting = true;

  @override
  Widget build(BuildContext context) {
    if (_booting) {
      return WebCenteredFlow(
        child: BootSplash(onDone: () => setState(() => _booting = false)),
      );
    }
    return const _AuthGate();
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: MM.pageBg,
            body: Center(
              child: CircularProgressIndicator(color: MM.blue),
            ),
          );
        }
        if (snap.data == null) {
          return const WebCenteredFlow(child: AuthFlow());
        }
        return _PostAuthGate(uid: snap.data!.uid);
      },
    );
  }
}

/// Checks the admin-set "force reset on next sign-in" flag
/// (ADMIN_PANEL_BACKEND_PLAN.md §3 / #A3.2) once per sign-in before handing
/// off to the app proper — a blocked player never reaches MomentumHome.
class _PostAuthGate extends StatefulWidget {
  const _PostAuthGate({required this.uid});

  final String uid;

  @override
  State<_PostAuthGate> createState() => _PostAuthGateState();
}

class _PostAuthGateState extends State<_PostAuthGate> {
  final _access = AccessService();
  bool? _forceReset;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    // Fail-open on a read error (e.g. offline) — this is a UX nudge, not the
    // security boundary, and a network hiccup must never permanently strand
    // a player outside the app.
    bool required = false;
    try {
      required = await _access.forcePasswordResetRequired(widget.uid);
    } catch (_) {}
    if (mounted) setState(() => _forceReset = required);
  }

  @override
  Widget build(BuildContext context) {
    if (_forceReset == null) {
      return const Scaffold(
        backgroundColor: MM.pageBg,
        body: Center(child: CircularProgressIndicator(color: MM.blue)),
      );
    }
    if (_forceReset == true) {
      return ForcePasswordResetPage(
        onDone: () => setState(() => _forceReset = false),
      );
    }
    return const MomentumHome();
  }
}
