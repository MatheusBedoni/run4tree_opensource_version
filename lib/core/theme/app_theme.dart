import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryLight,
        primary: AppColors.primaryLight,
        secondary: AppColors.primaryDark,
        background: AppColors.background,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.montserratTextTheme().copyWith(
        displayLarge: GoogleFonts.bebasNeue(
          color: AppColors.textPrimary,
          letterSpacing: 1.2,
        ),
        displayMedium: GoogleFonts.bebasNeue(
          color: AppColors.textPrimary,
          letterSpacing: 1.2,
        ),
        displaySmall: GoogleFonts.bebasNeue(
          color: AppColors.textPrimary,
          letterSpacing: 1.2,
        ),
        headlineLarge: GoogleFonts.bebasNeue(
          color: AppColors.textPrimary,
          letterSpacing: 1.2,
        ),
        headlineMedium: GoogleFonts.bebasNeue(
          color: AppColors.textPrimary,
          letterSpacing: 1.0,
        ),
        headlineSmall: GoogleFonts.bebasNeue(
          color: AppColors.textPrimary,
          letterSpacing: 1.0,
        ),
        titleLarge: GoogleFonts.bebasNeue(
          color: AppColors.textPrimary,
          letterSpacing: 0.8,
        ),
        titleMedium: GoogleFonts.bebasNeue(
          color: AppColors.textPrimary,
          letterSpacing: 0.5,
        ),
        titleSmall: GoogleFonts.bebasNeue(
          color: AppColors.textPrimary,
          letterSpacing: 0.5,
        ),
        bodyLarge: GoogleFonts.bebasNeue(color: AppColors.textPrimary),
        bodyMedium: GoogleFonts.bebasNeue(color: AppColors.textSecondary),
        bodySmall: GoogleFonts.bebasNeue(color: AppColors.textSecondary),
        labelLarge: GoogleFonts.bebasNeue(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: Color(0xFFE0E0E0)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
