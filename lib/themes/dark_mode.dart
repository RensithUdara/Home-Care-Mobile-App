import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData darkMode = ThemeData(
  fontFamily: GoogleFonts.inter().fontFamily,
  colorScheme: ColorScheme.dark(
    surface: const Color(0xFF121212), // Dark background
    primary: const Color(0xFF1E1E1E), // Dark container
    secondary: const Color(0xFF2E2E2E), // Medium dark
    tertiary: const Color(0xFF1E1E1E), // Dark container variant
    inversePrimary: const Color(0xFFE5E7EB), // Light text for dark mode
    inverseSurface: const Color(0xFFD1D5DB), // Light gray
    // Added custom colors for consistency
    onSurface: const Color(0xFFE5E7EB), // Light text on dark surface
    onPrimary: const Color(0xFFE5E7EB), // Light text on dark primary
    onSecondary: const Color(0xFFFFFFFF), // White text on secondary
    onTertiary: const Color(0xFFE5E7EB), // Light text on dark tertiary
    outline: const Color(0xFF6B7280), // For borders and outlines
    surfaceVariant: const Color(0xFF2E2E2E), // Alternative dark surface
    onSurfaceVariant: const Color(0xFF9CA3AF), // Text on dark surface variant
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.5),
      foregroundColor: const Color(0xFF121212), // Dark text on light buttons
      backgroundColor: const Color(0xFFE5E7EB), // Light button background in dark mode
    ),
  ),
  textTheme: TextTheme(
    bodyLarge: GoogleFonts.inter(color: const Color(0xFFE5E7EB)),
    bodyMedium: GoogleFonts.inter(color: const Color(0xFFE5E7EB)),
    bodySmall: GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
    titleLarge: GoogleFonts.inter(color: const Color(0xFFE5E7EB), fontWeight: FontWeight.bold),
    titleMedium: GoogleFonts.inter(color: const Color(0xFFE5E7EB), fontWeight: FontWeight.w600),
    titleSmall: GoogleFonts.inter(color: const Color(0xFFE5E7EB), fontWeight: FontWeight.w500),
  ),
);
