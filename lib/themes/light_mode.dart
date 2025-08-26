import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

ThemeData lightMode = ThemeData(
  fontFamily: GoogleFonts.inter().fontFamily,
  colorScheme: ColorScheme.light(
    surface: const Color(0xFFF8F9FA),
    primary: const Color(0xFFE3E7EC),
    secondary: const Color(0xFF9CA3AF),
    tertiary: const Color(0xFFFFFFFF),
    inversePrimary: const Color(0xFF1F2937),
    inverseSurface: const Color(0xFF374151),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.3),
    ),
  ),
);
