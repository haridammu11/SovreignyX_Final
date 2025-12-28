import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CompanyTheme {
  // Sovereign Prime Palette (Royal & Gold)
  static const Color primaryPurple = Color(0xFF6D28D9); // Violet 700
  static const Color deepBackground = Color(0xFF0F172A); // Slate 900
  static const Color surfaceDark = Color(0xFF1E293B); // Slate 800
  static const Color surfaceCard = Color(0xFF334155); // Slate 700
  static const Color accentGold = Color(0xFFF59E0B); // Amber 500
  static const Color errorRed = Color(0xFFEF4444); // Red 500
  static const Color successGreen = Color(0xFF10B981); // Emerald 500
  
  static const Color textLight = Color(0xFFF8FAFC); // Slate 50
  static const Color textDim = Color(0xFF94A3B8); // Slate 400

  // Light Mode Colors (Clean Corporate)
  static const Color lightBackground = Color(0xFFF1F5F9); // Slate 100
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF0F172A); // Slate 900

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryPurple,
      scaffoldBackgroundColor: deepBackground,
      cardColor: surfaceDark,
      
      colorScheme: const ColorScheme.dark(
        primary: primaryPurple,
        secondary: accentGold,
        surface: surfaceDark,
        background: deepBackground,
        error: errorRed,
        onPrimary: Colors.white,
        onSurface: textLight,
      ),

      // Typography - Plus Jakarta Sans for Executive feel
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.dark().textTheme.copyWith(
          displayLarge: const TextStyle(fontWeight: FontWeight.w800, color: textLight, letterSpacing: -1.0),
          headlineSmall: const TextStyle(fontWeight: FontWeight.bold, color: textLight),
          bodyLarge: const TextStyle(color: textLight),
          bodyMedium: const TextStyle(color: textDim),
        ),
      ),

      // App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: deepBackground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textLight,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: textLight),
      ),

      // Cards
      cardTheme: CardTheme(
        color: surfaceDark,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // Button shape
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      
      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: surfaceCard),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryPurple, width: 2),
        ),
        labelStyle: const TextStyle(color: textDim),
        prefixIconColor: textDim,
      ),

      // Nav Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: deepBackground,
        selectedItemColor: accentGold, // Gold for active
        unselectedItemColor: textDim,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryPurple,
      scaffoldBackgroundColor: lightBackground,
      cardColor: lightSurface,
      
      colorScheme: const ColorScheme.light(
        primary: primaryPurple,
        secondary: accentGold,
        surface: lightSurface,
        background: lightBackground,
        error: errorRed,
      ),

      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.light().textTheme.apply(
          bodyColor: lightText,
          displayColor: lightText,
        ),
      ),
      
      appBarTheme: AppBarTheme(
        backgroundColor: lightSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: lightText,
        ),
        iconTheme: const IconThemeData(color: lightText),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryPurple, width: 2),
        ),
      ),
      
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: lightSurface,
        selectedItemColor: primaryPurple,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
