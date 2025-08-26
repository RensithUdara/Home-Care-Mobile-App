import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData darkMode = ThemeData(
  fontFamily: GoogleFonts.inter().fontFamily,
  colorScheme: ColorScheme.dark(
    surface: const Color(0xFF121212),
    primary: const Color(0xFF1E1E1E),
    secondary: const Color(0xFF2E2E2E),
    tertiary: const Color(0xFF1E1E1E),
    inversePrimary: const Color(0xFFE5E7EB),
    inverseSurface: const Color(0xFFD1D5DB),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.5),
    ),
  ),
);
