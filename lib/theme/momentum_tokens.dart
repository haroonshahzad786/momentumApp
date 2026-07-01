import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MM {
  MM._();

  // ─── Primary ─────────────────────────────────────────────
  static const Color blue = Color(0xFF2A7DE1);     // Momentum Blue — primary, Mindset
  static const Color red = Color(0xFFEA0029);      // Ignition Red — alerts, streak fire

  // ─── Secondary ───────────────────────────────────────────
  static const Color teal = Color(0xFF00A98F);     // Cosmic Teal — Physical, success
  static const Color yellow = Color(0xFFFFC629);   // Solar Yellow — achievements, Career
  static const Color magenta = Color(0xFFFF3D8B);  // Relationships glow
  static const Color violet = Color(0xFF9B5CFF);   // Emotional glow

  // ─── Neutrals ────────────────────────────────────────────
  static const Color navy = Color(0xFF111C4E);
  static const Color navy2 = Color(0xFF0A1136);
  static const Color black = Color(0xFF0A0D12);
  static const Color pageBg = Color(0xFF06070D);
  static const Color panel = Color(0xFF131A3D);
  static const Color gray = Color(0xFF20372E);
  static const Color gray2 = Color(0xFF2B3955);
  static const Color white = Color(0xFFF1F1F1);
  static Color white60 = Colors.white.withOpacity(0.60);
  static Color white36 = Colors.white.withOpacity(0.36);
  static Color white18 = Colors.white.withOpacity(0.18);

  // ─── Core hex per id ─────────────────────────────────────
  static const Map<String, Color> coreColor = {
    'mindset': blue,
    'career': yellow,
    'relationships': magenta,
    'physical': teal,
    'emotional': violet,
  };

  // ─── Planets ─────────────────────────────────────────────
  static const List<Map<String, dynamic>> planets = [
    {'id': 'earth',   'name': 'Earth',   'color': Color(0xFF3AA6FF)},
    {'id': 'moon',    'name': 'Moon',    'color': Color(0xFFCFD2DC)},
    {'id': 'mars',    'name': 'Mars',    'color': Color(0xFFD76B3A)},
    {'id': 'jupiter', 'name': 'Jupiter', 'color': Color(0xFFD9A86B)},
    {'id': 'saturn',  'name': 'Saturn',  'color': Color(0xFFE8C178)},
    {'id': 'pluto',   'name': 'Pluto',   'color': Color(0xFF9AA3C7)},
  ];

  // ─── Radii ───────────────────────────────────────────────
  static const double r1 = 4;
  static const double r2 = 8;
  static const double r3 = 12;

  // ─── Typography ──────────────────────────────────────────
  static TextStyle display({
    double size = 16,
    Color color = white,
    FontWeight weight = FontWeight.w700,
    double letterSpacing = 0.04 * 16,
    double? height,
  }) {
    return GoogleFonts.orbitron(
      fontSize: size,
      color: color,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  /// Wide-letter uppercase display (t-display-x in CSS).
  static TextStyle displayX({
    double size = 11,
    Color color = white,
    FontWeight weight = FontWeight.w800,
  }) {
    return GoogleFonts.orbitron(
      fontSize: size,
      color: color,
      fontWeight: weight,
      letterSpacing: 0.06 * size,
    );
  }

  static TextStyle body({
    double size = 13,
    Color? color,
    FontWeight weight = FontWeight.w400,
    double height = 1.45,
  }) {
    return GoogleFonts.redHatDisplay(
      fontSize: size,
      color: color ?? white,
      fontWeight: weight,
      height: height,
    );
  }

  static TextStyle mono({
    double size = 11,
    Color? color,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: size,
      color: color ?? white,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}
