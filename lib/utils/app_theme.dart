import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand colors
  static const Color primary = Color(0xFF6366F1);
  static const Color primary2 = Color(0xFF818CF8);
  static const Color accent = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);
  static const Color danger = Color(0xFFEF4444);
  static const Color bg = Color(0xFF0F0F1A);
  static const Color bg2 = Color(0xFF1A1A2E);
  static const Color card = Color(0xFF1E1E32);
  static const Color border = Color(0xFF2A2A40);
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF475569);

  static ThemeData get dark => _build(Brightness.dark);
  static ThemeData get light => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final Color background = isDark ? bg : const Color(0xFFF8FAFC);
    final Color scaffoldBg = isDark ? bg : const Color(0xFFF1F5F9);
    final Color cardColor = isDark ? card : Colors.white;
    final Color borderColor = isDark ? border : const Color(0xFFE2E8F0);
    final Color textPrimaryColor =
        isDark ? textPrimary : const Color(0xFF0F172A);
    final Color textSecondaryColor =
        isDark ? textSecondary : const Color(0xFF475569);
    final Color textMutedColor = isDark ? textMuted : const Color(0xFF94A3B8);
    final Color inputFieldColor = isDark ? bg2 : const Color(0xFFFFFFFF);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: scaffoldBg,
      colorScheme: isDark
          ? const ColorScheme.dark(
              primary: primary,
              secondary: accent,
              surface: card,
              error: danger,
            )
          : const ColorScheme.light(
              primary: primary,
              secondary: accent,
              surface: Colors.white,
              error: danger,
            ),
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: textPrimaryColor,
        displayColor: textPrimaryColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimaryColor,
        ),
        iconTheme: IconThemeData(color: textPrimaryColor),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFieldColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        labelStyle: TextStyle(color: textSecondaryColor),
        hintStyle: TextStyle(color: textMutedColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: inputFieldColor,
        labelStyle: TextStyle(color: textSecondaryColor, fontSize: 12),
        side: BorderSide(color: borderColor),
      ),
      dividerTheme: DividerThemeData(color: borderColor, space: 1),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardColor,
        selectedItemColor: primary,
        unselectedItemColor: textMutedColor,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
