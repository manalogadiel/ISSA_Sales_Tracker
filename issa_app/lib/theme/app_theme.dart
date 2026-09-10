import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ISSA Lavender Design System
/// Background: #F7F4FC | Primary: #B79CED | Accent: #D8CCF0 | Text: #3A2E52
abstract final class AppColors {
  static const background = Color(0xFFF7F4FC);
  static const surface = Color(0xFFFFFFFF);
  static const primary = Color(0xFFB79CED);
  static const primaryDeep = Color(0xFF9B87C4);
  static const accent = Color(0xFFD8CCF0);
  static const accentLight = Color(0xFFEDE8F8);
  static const textPrimary = Color(0xFF3A2E52);
  static const textSecondary = Color(0xFF7A6E8E);
  static const textHint = Color(0xFFAA9FC0);
  static const divider = Color(0xFFE8E0F5);
  static const error = Color(0xFFD94F4F);
  static const success = Color(0xFF4CAF82);
  static const warning = Color(0xFFE8A44B);
  static const chipBg = Color(0xFFEDE8F8);

  // Stat tile gradients
  static const List<Color> capitalGradient = [Color(0xFFB79CED), Color(0xFF9B87C4)];
  static const List<Color> soldGradient = [Color(0xFF84B5ED), Color(0xFF5B8ED9)];
  static const List<Color> profitGradient = [Color(0xFF82CBA4), Color(0xFF4CAF82)];
}

ThemeData buildAppTheme() {
  // Resolve Nunito font family name
  final f = GoogleFonts.nunito().fontFamily!;

  final textTheme = TextTheme(
    displayLarge: GoogleFonts.nunito(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
    displayMedium: GoogleFonts.nunito(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
    headlineLarge: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
    headlineMedium: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
    headlineSmall: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
    titleLarge: GoogleFonts.nunito(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
    titleMedium: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
    titleSmall: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
    bodyLarge: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
    bodyMedium: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
    bodySmall: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
    labelLarge: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
    labelMedium: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
    labelSmall: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textHint),
  );

  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    secondary: AppColors.accent,
    onSecondary: AppColors.textPrimary,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    error: AppColors.error,
    onError: Colors.white,
    surfaceContainerHighest: AppColors.accentLight,
    outline: AppColors.divider,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    fontFamily: f,
    scaffoldBackgroundColor: AppColors.background,

    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: AppColors.divider,
      centerTitle: false,
      titleTextStyle: GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    ),

    cardTheme: CardThemeData(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.divider),
      ),
      margin: EdgeInsets.zero,
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryDeep,
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryDeep,
        textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.accentLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      labelStyle: GoogleFonts.nunito(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
      hintStyle: GoogleFonts.nunito(color: AppColors.textHint, fontWeight: FontWeight.w400),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.accentLight,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.primaryDeep : AppColors.textSecondary,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? AppColors.primaryDeep : AppColors.textSecondary,
          size: 22,
        );
      }),
      elevation: 0,
      shadowColor: AppColors.divider,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: AppColors.chipBg,
      labelStyle: GoogleFonts.nunito(
        fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryDeep),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 1,
    ),

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: AppColors.textPrimary,
      contentTextStyle: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w500),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: GoogleFonts.nunito(
        fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      contentTextStyle: GoogleFonts.nunito(
        fontSize: 14, color: AppColors.textSecondary),
    ),

    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      minLeadingWidth: 0,
      titleTextStyle: GoogleFonts.nunito(
        fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      subtitleTextStyle: GoogleFonts.nunito(
        fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
    ),

    textTheme: textTheme,
  );
}
