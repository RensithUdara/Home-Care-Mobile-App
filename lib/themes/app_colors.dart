import 'package:flutter/material.dart';

/// Brand palette and depth recipes shared by every screen.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF5B5BF7);
  static const Color primaryDark = Color(0xFF3F3DCB);
  static const Color secondary = Color(0xFF9B5CF6);
  static const Color accent = Color(0xFF22D3EE);

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Light surfaces
  static const Color lightBackground = Color(0xFFF1F3FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFE8EBF7);
  static const Color lightText = Color(0xFF151837);
  static const Color lightTextMuted = Color(0xFF6B7094);
  static const Color lightOutline = Color(0xFFDADDEF);

  // Dark surfaces
  static const Color darkBackground = Color(0xFF0B0D1A);
  static const Color darkSurface = Color(0xFF161932);
  static const Color darkSurfaceAlt = Color(0xFF20244A);
  static const Color darkText = Color(0xFFF1F2FF);
  static const Color darkTextMuted = Color(0xFF9A9EC4);
  static const Color darkOutline = Color(0xFF2C3160);

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFA855F7)],
  );

  static const LinearGradient oceanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
  );

  static const LinearGradient sunsetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
  );

  static const LinearGradient mintGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF34D399), Color(0xFF059669)],
  );

  /// Builds a two-tone gradient from a single color, lighter at the top-left,
  /// which is what gives flat fills their "lit from above" 3D look.
  static LinearGradient shade(Color color) {
    final hsl = HSLColor.fromColor(color);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        hsl.withLightness((hsl.lightness + 0.08).clamp(0.0, 1.0)).toColor(),
        hsl.withLightness((hsl.lightness - 0.10).clamp(0.0, 1.0)).toColor(),
      ],
    );
  }

  static Color darken(Color color, [double amount = 0.15]) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }
}

/// Layered shadows that simulate a key light above-left plus soft ambient
/// occlusion — the core of the raised 3D look.
class AppShadows {
  AppShadows._();

  static List<BoxShadow> raised(BuildContext context,
      {Color? glow, double depth = 1.0}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: (glow ?? (isDark ? Colors.black : const Color(0xFF3C4380)))
            .withValues(alpha: isDark ? 0.45 : (glow != null ? 0.28 : 0.14)),
        blurRadius: 24 * depth,
        offset: Offset(0, 12 * depth),
        spreadRadius: -4 * depth,
      ),
      BoxShadow(
        color: (isDark ? Colors.black : const Color(0xFF3C4380))
            .withValues(alpha: isDark ? 0.35 : 0.06),
        blurRadius: 6 * depth,
        offset: Offset(0, 2 * depth),
      ),
    ];
  }

  static List<BoxShadow> pressed(BuildContext context, {Color? glow}) =>
      raised(context, glow: glow, depth: 0.35);

  static List<BoxShadow> glow(Color color, {double strength = 1.0}) => [
        BoxShadow(
          color: color.withValues(alpha: 0.40 * strength),
          blurRadius: 22,
          offset: const Offset(0, 10),
          spreadRadius: -6,
        ),
      ];
}

extension ThemeX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get textPrimary => isDark ? AppColors.darkText : AppColors.lightText;
  Color get textMuted =>
      isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
  Color get surface => isDark ? AppColors.darkSurface : AppColors.lightSurface;
  Color get surfaceAlt =>
      isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt;
  Color get outline => isDark ? AppColors.darkOutline : AppColors.lightOutline;
  Color get background =>
      isDark ? AppColors.darkBackground : AppColors.lightBackground;
}
