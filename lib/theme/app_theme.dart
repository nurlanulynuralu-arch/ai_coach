import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF246BFD);
  static const Color deepBlue = Color(0xFF123B8A);
  static const Color mint = Color(0xFF1FBE8A);
  static const Color aqua = Color(0xFF57D5C0);
  static const Color canvas = Color(0xFFF6FAFF);
  static const Color ink = Color(0xFF132238);
  static const Color mutedText = Color(0xFF66768D);
  static const Color softSurface = Color(0xFFFFFFFF);
  static const Color deepSlate = Color(0xFF102139);
  static const Color line = Color(0xFFD8E3F2);
  static const Color blueSoft = Color(0xFFE8F0FF);
  static const Color greenSoft = Color(0xFFE6FAF5);
  static const Color success = Color(0xFF1FBE8A);
  static const Color danger = Color(0xFFE45D5D);

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.manropeTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.light,
      ).copyWith(
        primary: primaryBlue,
        secondary: mint,
        tertiary: aqua,
        surface: softSurface,
        onSurface: ink,
        outline: line,
        onPrimary: Colors.white,
        error: danger,
      ),
      scaffoldBackgroundColor: canvas,
      textTheme: baseTextTheme.copyWith(
        headlineLarge: GoogleFonts.sora(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: ink,
          height: 1.05,
        ),
        headlineMedium: GoogleFonts.sora(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: ink,
          height: 1.08,
        ),
        headlineSmall: GoogleFonts.sora(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: ink,
          letterSpacing: -0.2,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: ink,
        ),
        titleSmall: baseTextTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: ink,
          height: 1.5,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: mutedText,
          height: 1.48,
          fontWeight: FontWeight.w500,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: mutedText,
          height: 1.4,
          fontWeight: FontWeight.w600,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: ink,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: softSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: const WidgetStatePropertyAll(primaryBlue),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(58)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          ),
          elevation: const WidgetStatePropertyAll(0),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
          ),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: const WidgetStatePropertyAll(primaryBlue),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(52)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll(ink),
          backgroundColor: const WidgetStatePropertyAll(softSurface),
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(52)),
          side: const WidgetStatePropertyAll(
            BorderSide(color: line),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: mutedText),
        labelStyle: const TextStyle(color: mutedText),
        prefixIconColor: mutedText,
        suffixIconColor: mutedText,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: danger, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: danger, width: 1.6),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        side: const BorderSide(color: line, width: 1.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        fillColor: WidgetStateProperty.resolveWith<Color?>(
          (states) => states.contains(WidgetState.selected) ? primaryBlue : null,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: blueSoft,
        side: const BorderSide(color: line),
        labelStyle: const TextStyle(
          color: ink,
          fontWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      dividerColor: line,
      iconTheme: const IconThemeData(color: ink),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryBlue,
        linearTrackColor: blueSoft,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: deepSlate,
        contentTextStyle: GoogleFonts.manrope(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: softSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
      ),
    );
  }
}
