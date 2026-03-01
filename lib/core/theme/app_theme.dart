import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.blue600,
      scaffoldBackgroundColor: AppColors.gray50,
      colorScheme: const ColorScheme.light(
        primary: AppColors.blue600,
        secondary: AppColors.emerald500,
        surface: Colors.white,
        error: AppColors.red500,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme)
          .copyWith(
            bodyLarge: GoogleFonts.inter(color: AppColors.gray900),
            bodyMedium: GoogleFonts.inter(color: AppColors.gray600),
            titleLarge: GoogleFonts.inter(
              color: AppColors.gray900,
              fontWeight: FontWeight.bold,
            ),
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent, // Blured later via backdrop
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: AppColors.gray900),
        titleTextStyle: TextStyle(
          color: AppColors.gray900,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.gray200, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.gray200,
        thickness: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.blue500,
      scaffoldBackgroundColor: AppColors.gray950,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.blue500,
        secondary: AppColors.emerald400,
        surface: AppColors.gray900, // Equivalent to specific cards in web
        error: AppColors.red400,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme)
          .copyWith(
            bodyLarge: GoogleFonts.inter(color: AppColors.gray100),
            bodyMedium: GoogleFonts.inter(color: AppColors.gray400),
            titleLarge: GoogleFonts.inter(
              color: AppColors.gray100,
              fontWeight: FontWeight.bold,
            ),
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent, // Blured later via backdrop
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: AppColors.gray100),
        titleTextStyle: TextStyle(
          color: AppColors.gray100,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF151920), // Exact match from web dark card bg
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.gray800, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.gray800,
        thickness: 1,
      ),
    );
  }
}
