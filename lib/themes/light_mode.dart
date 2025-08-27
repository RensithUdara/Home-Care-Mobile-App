import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData lightMode = ThemeData(
  fontFamily: GoogleFonts.inter().fontFamily,
  colorScheme: const ColorScheme.light(
    surface: Color(0xFFF8F9FA), // Light background
    primary: Color(0xFFE3E7EC), // Light container
    secondary: Color(0xFF9CA3AF), // Medium gray
    tertiary: Color(0xFFFFFFFF), // Pure white for containers
    inversePrimary: Color(0xFF1F2937), // Dark text (for readability)
    inverseSurface: Color(0xFF374151), // Darker gray for contrast
    // Added custom colors for better visibility
    onSurface: Color(0xFF1F2937), // Dark text on light surface
    onPrimary: Color(0xFF1F2937), // Dark text on light primary
    onSecondary: Color(0xFFFFFFFF), // White text on secondary
    onTertiary: Color(0xFF1F2937), // Dark text on white tertiary
    outline: Color(0xFF9CA3AF), // For borders and outlines
    surfaceContainerHighest: Color(0xFFF3F4F6), // Alternative surface
    onSurfaceVariant: Color(0xFF6B7280), // Text on surface variant
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.3),
      foregroundColor: const Color(0xFFFFFFFF), // White text on buttons
      backgroundColor: const Color(0xFF1F2937), // Dark button background
    ),
  ),
  textTheme: TextTheme(
    bodyLarge: GoogleFonts.inter(color: const Color(0xFF1F2937)),
    bodyMedium: GoogleFonts.inter(color: const Color(0xFF1F2937)),
    bodySmall: GoogleFonts.inter(color: const Color(0xFF6B7280)),
    titleLarge: GoogleFonts.inter(
        color: const Color(0xFF1F2937), fontWeight: FontWeight.bold),
    titleMedium: GoogleFonts.inter(
        color: const Color(0xFF1F2937), fontWeight: FontWeight.w600),
    titleSmall: GoogleFonts.inter(
        color: const Color(0xFF1F2937), fontWeight: FontWeight.w500),
  ),
);
