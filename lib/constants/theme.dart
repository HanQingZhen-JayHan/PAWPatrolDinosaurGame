import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PawTheme {
  PawTheme._();

  static const Color primaryBlue = Color(0xFF1E88E5);
  static const Color primaryRed = Color(0xFFE53935);
  static const Color backgroundDark = Color(0xFF1A237E);
  static const Color backgroundLight = Color(0xFF42A5F5);
  static const Color goldStar = Color(0xFFFFD600);
  static const Color white = Colors.white;
  static const Color heartRed = Color(0xFFFF1744);

  static ThemeData get themeData {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.fredokaTextTheme(),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      useMaterial3: true,
    );
  }
}
