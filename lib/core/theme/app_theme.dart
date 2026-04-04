import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static const PageTransitionsTheme _pageTransitionsTheme = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
    },
  );

  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.accentLight,
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFD8F3DC),
      onSecondaryContainer: AppColors.primaryDark,
      tertiary: Color(0xFF673AB7),
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFEDE7F6),
      onTertiaryContainer: Color(0xFF311B92),
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: Color(0xFFFFEBEE),
      onErrorContainer: AppColors.error,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textPrimaryLight,
      surfaceContainerHighest: AppColors.backgroundLight,
      onSurfaceVariant: AppColors.textSecondaryLight,
      outline: AppColors.dividerLight,
      outlineVariant: Color(0xFFEEEEEE),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: AppColors.textPrimaryLight,
      onInverseSurface: Colors.white,
      inversePrimary: AppColors.accentLight,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      textTheme: GoogleFonts.interTextTheme(),
      pageTransitionsTheme: _pageTransitionsTheme,
      cardTheme: CardThemeData(
        color: AppColors.cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.dividerLight.withValues(alpha: 0.5)),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.dividerLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.dividerLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 2.0),
        ),
        hintStyle: const TextStyle(color: AppColors.textHintLight, fontSize: 15),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimaryLight),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryLight,
          letterSpacing: -0.5,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHintLight,
        elevation: 16,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.backgroundLight,
        selectedColor: AppColors.primary,
        labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: AppColors.dividerLight)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimaryLight,
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerLight,
        thickness: 1,
        space: 24,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceLight,
        modalBackgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
    );
  }

  static ThemeData get dark {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.accent,
      onPrimary: Colors.black,
      primaryContainer: AppColors.primaryLight,
      onPrimaryContainer: Colors.white,
      secondary: AppColors.accentLight,
      onSecondary: Colors.black,
      secondaryContainer: AppColors.primaryDark,
      onSecondaryContainer: AppColors.accentLight,
      tertiary: Color(0xFFB39DDB),
      onTertiary: Colors.black,
      tertiaryContainer: Color(0xFF4527A0),
      onTertiaryContainer: Color(0xFFEDE7F6),
      error: Color(0xFFEF9A9A),
      onError: Colors.black,
      errorContainer: Color(0xFFB71C1C),
      onErrorContainer: Colors.white,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimaryDark,
      surfaceContainerHighest: AppColors.backgroundDark,
      onSurfaceVariant: AppColors.textSecondaryDark,
      outline: AppColors.dividerDark,
      outlineVariant: Color(0xFF2A3D2B),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: AppColors.textPrimaryDark,
      onInverseSurface: Colors.black,
      inversePrimary: AppColors.primaryLight,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      pageTransitionsTheme: _pageTransitionsTheme,
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.dividerDark),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.dividerDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.dividerDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 2.0),
        ),
        hintStyle: const TextStyle(color: AppColors.textHintDark, fontSize: 15),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: const BorderSide(color: AppColors.accent, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryDark,
          letterSpacing: -0.5,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textHintDark,
        elevation: 16,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedColor: AppColors.primaryLight,
        labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: AppColors.dividerDark)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.cardDark,
        contentTextStyle: GoogleFonts.inter(color: AppColors.textPrimaryDark, fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerDark,
        thickness: 1,
        space: 24,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceDark,
        modalBackgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
    );
  }
}
