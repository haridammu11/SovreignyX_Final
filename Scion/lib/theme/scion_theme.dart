import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScionTheme {
  // Scion Prime Palette (Cyan & Void)
  static const Color primaryCyan = Color(0xFF00E5FF); // Electric Cyan
  static const Color primaryRed = Color(0xFF00E5FF); // Kept usage name for compatibility but changed color
  static const Color darkBackground = Color(0xFF000000); // Pure Black
  static const Color darkSurface = Color(0xFF121212); // Material Dark Surface
  static const Color darkCard = Color(0xFF1E1E1E); // Lighter Surface
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGrey = Color(0xFFB3B3B3);
  static const Color accentGold = Color(0xFFFFD700); // For achievements

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryRed,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: primaryRed,
        secondary: primaryRed, // Monochromatic accent
        tertiary: Color(0xFF00B8D4), // Darker Cyan
        primaryContainer: Color(0xFF004D40), // Deep Teal
        secondaryContainer: Color(0xFF006064), // Deep Cyan
        tertiaryContainer: Color(0xFF01579B), // Deep Blue
        surface: darkSurface,
        background: darkBackground,
        error: Color(0xFFCF6679),
        onPrimary: Colors.black, // Cyan is bright, text should be black
        onSurface: textWhite,
        onBackground: textWhite,
        brightness: Brightness.dark,
      ),
      
      // Typography
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.dark().textTheme.copyWith(
          displayLarge: const TextStyle(fontWeight: FontWeight.bold, color: textWhite),
          titleLarge: const TextStyle(fontWeight: FontWeight.w600, color: textWhite),
          bodyLarge: const TextStyle(color: textWhite),
          bodyMedium: const TextStyle(color: textGrey),
        ),
      ),

      // App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 24, 
          fontWeight: FontWeight.bold,
          color: textWhite,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: textWhite),
      ),

      // Cards
      cardTheme: CardTheme(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryRed, width: 2),
        ),
        labelStyle: const TextStyle(color: textGrey),
        hintStyle: TextStyle(color: textGrey.withOpacity(0.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRed,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: primaryRed.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      
      // Icon Buttons
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textWhite,
        ),
      ),

      // Bottom Nav
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: primaryRed,
        unselectedItemColor: textGrey,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.outfit(),
      ),
    );
  }
}
