import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/boot_splash.dart';
import 'screens/momentum/auth_flow.dart';
import 'screens/momentum/momentum_home.dart';
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
        return const MomentumHome();
      },
    );
  }
}
