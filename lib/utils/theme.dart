import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class JaexoTheme {
  static const String matrix = 'matrix';
  static const String redline = 'redline';
  static const String deepspace = 'deepspace';
  static const String amber = 'amber';
  static const String ghost = 'ghost';

  static ThemeData getTheme(String theme) {
    final colorScheme = _getColorScheme(theme);

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      colorScheme: colorScheme,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.orbitron(
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: GoogleFonts.orbitron(
          color: colorScheme.primary,
        ),
        bodyLarge: GoogleFonts.jetBrainsMono(
          color: colorScheme.primary,
        ),
        bodyMedium: GoogleFonts.jetBrainsMono(
          color: colorScheme.primary,
        ),
      ),
    );
  }

  static ColorScheme _getColorScheme(String theme) {
    switch (theme) {
      case matrix:
        return const ColorScheme.dark(
          primary: Color(0xFF00FF41),
          secondary: Color(0xFF008F11),
          error: Color(0xFFFF3333),
          surface: Color(0xFF0A0A0A),
        );
      case redline:
        return const ColorScheme.dark(
          primary: Color(0xFFFF0000),
          secondary: Color(0xFF880000),
          error: Color(0xFFFFAA00),
          surface: Color(0xFF0A0A0A),
        );
      case deepspace:
        return const ColorScheme.dark(
          primary: Color(0xFF00DDFF),
          secondary: Color(0xFF0066AA),
          error: Color(0xFFFF00FF),
          surface: Color(0xFF0A0A0A),
        );
      case amber:
        return const ColorScheme.dark(
          primary: Color(0xFFFFBB00),
          secondary: Color(0xFF886600),
          error: Color(0xFFFF4400),
          surface: Color(0xFF0A0A0A),
        );
      case ghost:
      default:
        return const ColorScheme.dark(
          primary: Color(0xFFE0E0E0),
          secondary: Color(0xFF555555),
          error: Color(0xFFFF66BB),
          surface: Color(0xFF0A0A0A),
        );
    }
  }

  static Color getPrimaryColor(String theme) {
    return _getColorScheme(theme).primary;
  }

  static Color getSecondaryColor(String theme) {
    return _getColorScheme(theme).secondary;
  }
}
