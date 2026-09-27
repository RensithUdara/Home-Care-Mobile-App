import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:home_care/themes/app_colors.dart';

ThemeData buildAppTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final background =
      isDark ? AppColors.darkBackground : AppColors.lightBackground;
  final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
  final surfaceAlt =
      isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt;
  final text = isDark ? AppColors.darkText : AppColors.lightText;
  final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
  final outline = isDark ? AppColors.darkOutline : AppColors.lightOutline;

  final scheme = ColorScheme(
    brightness: brightness,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.primary.withValues(alpha: 0.14),
    onPrimaryContainer:
        isDark ? const Color(0xFFC7C8FF) : AppColors.primaryDark,
    secondary: AppColors.secondary,
    onSecondary: Colors.white,
    tertiary: AppColors.accent,
    onTertiary: Colors.black,
    error: AppColors.danger,
    onError: Colors.white,
    surface: surface,
    onSurface: text,
    onSurfaceVariant: muted,
    surfaceContainerHighest: surfaceAlt,
    outline: outline,
    outlineVariant: outline,
    inversePrimary: text,
    inverseSurface: text,
    onInverseSurface: background,
    shadow: Colors.black,
  );

  final baseText = GoogleFonts.plusJakartaSansTextTheme(
    isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
  ).apply(bodyColor: text, displayColor: text);

  final radius = BorderRadius.circular(16);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    textTheme: baseText.copyWith(
      headlineMedium: baseText.headlineMedium
          ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
      headlineSmall: baseText.headlineSmall
          ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3),
      titleLarge: baseText.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: baseText.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      bodySmall: baseText.bodySmall?.copyWith(color: muted),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      foregroundColor: text,
      systemOverlayStyle:
          isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: text,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor:
          isDark ? surfaceAlt.withValues(alpha: 0.6) : const Color(0xFFF5F6FC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: TextStyle(color: muted, fontWeight: FontWeight.w500),
      labelStyle: TextStyle(color: muted, fontWeight: FontWeight.w500),
      prefixIconColor: muted,
      border: OutlineInputBorder(
          borderRadius: radius, borderSide: BorderSide(color: outline)),
      enabledBorder: OutlineInputBorder(
          borderRadius: radius, borderSide: BorderSide(color: outline)),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.danger, width: 1.8),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(Colors.white),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? AppColors.primary : outline),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    dividerTheme: DividerThemeData(color: outline, thickness: 1, space: 1),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: AppColors.primary),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: AppColors.primary,
      headerForegroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    }),
  );
}
