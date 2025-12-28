import 'package:flutter/material.dart';

/// Professional Color Palette for Enterprise ATS Application
/// Inspired by modern enterprise platforms like Greenhouse, Lever, and Workday
class ATSColors {
  // ============================================================================
  // PRIMARY BRAND COLORS
  // ============================================================================
  
  /// Primary brand color - Indigo (Professional & Trustworthy)
  static const primary = Color(0xFF6366F1);
  static const primaryDark = Color(0xFF4F46E5);
  static const primaryLight = Color(0xFF818CF8);
  
  // ============================================================================
  // SUCCESS SPECTRUM (Green/Emerald)
  // ============================================================================
  
  static const success = Color(0xFF10B981);
  static const successDark = Color(0xFF059669);
  static const successLight = Color(0xFF34D399);
  static const successBg = Color(0xFFD1FAE5);
  
  // ============================================================================
  // WARNING SPECTRUM (Amber/Orange)
  // ============================================================================
  
  static const warning = Color(0xFFF59E0B);
  static const warningDark = Color(0xFFD97706);
  static const warningLight = Color(0xFFFBBF24);
  static const warningBg = Color(0xFFFEF3C7);
  
  // ============================================================================
  // DANGER SPECTRUM (Red)
  // ============================================================================
  
  static const danger = Color(0xFFEF4444);
  static const dangerDark = Color(0xFFDC2626);
  static const dangerLight = Color(0xFFF87171);
  static const dangerBg = Color(0xFFFEE2E2);
  
  // ============================================================================
  // NEUTRAL SPECTRUM (Professional Grays)
  // ============================================================================
  
  static const neutral50 = Color(0xFFFAFAFA);
  static const neutral100 = Color(0xFFF5F5F5);
  static const neutral200 = Color(0xFFE5E5E5);
  static const neutral300 = Color(0xFFD4D4D4);
  static const neutral400 = Color(0xFFA3A3A3);
  static const neutral500 = Color(0xFF737373);
  static const neutral600 = Color(0xFF525252);
  static const neutral700 = Color(0xFF404040);
  static const neutral800 = Color(0xFF262626);
  static const neutral900 = Color(0xFF171717);
  
  // ============================================================================
  // BACKGROUND COLORS
  // ============================================================================
  
  static const bgPrimary = Color(0xFFFFFFFF);
  static const bgSecondary = Color(0xFFF9FAFB);
  static const bgTertiary = Color(0xFFF3F4F6);
  
  // ============================================================================
  // GRADIENT COLORS
  // ============================================================================
  
  static const gradientStart = Color(0xFFF0F9FF); // Sky blue
  static const gradientEnd = Color(0xFFFAF5FF); // Purple tint
  
  // ============================================================================
  // HELPER METHODS
  // ============================================================================
  
  /// Get color based on score (0-100)
  static Color getScoreColor(int score) {
    if (score >= 80) return success;
    if (score >= 60) return warning;
    return danger;
  }
  
  /// Get background color based on score
  static Color getScoreBgColor(int score) {
    if (score >= 80) return successBg;
    if (score >= 60) return warningBg;
    return dangerBg;
  }
  
  /// Get status color
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'approved':
      case 'completed':
      case 'offer':
        return success;
      case 'pending':
      case 'review':
      case 'interview':
        return warning;
      case 'rejected':
      case 'failed':
      case 'inactive':
        return danger;
      case 'draft':
        return neutral500;
      default:
        return primary;
    }
  }
  
  /// Get status background color
  static Color getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'approved':
      case 'completed':
      case 'offer':
        return successBg;
      case 'pending':
      case 'review':
      case 'interview':
        return warningBg;
      case 'rejected':
      case 'failed':
      case 'inactive':
        return dangerBg;
      case 'draft':
        return neutral100;
      default:
        return primary.withOpacity(0.1);
    }
  }
}

/// Professional Text Styles for Enterprise Application
class ATSTextStyles {
  // Headers
  static const h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: ATSColors.neutral900,
    letterSpacing: -0.5,
  );
  
  static const h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: ATSColors.neutral800,
    letterSpacing: -0.3,
  );
  
  static const h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: ATSColors.neutral800,
  );
  
  static const h4 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: ATSColors.neutral800,
  );
  
  // Body Text
  static const bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: ATSColors.neutral700,
    height: 1.5,
  );
  
  static const bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: ATSColors.neutral700,
    height: 1.5,
  );
  
  static const bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: ATSColors.neutral600,
    height: 1.4,
  );
  
  // Labels
  static const labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: ATSColors.neutral800,
  );
  
  static const labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: ATSColors.neutral700,
  );
  
  static const labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: ATSColors.neutral600,
    letterSpacing: 0.5,
  );
  
  // Subtle Text
  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: ATSColors.neutral500,
  );
  
  static const overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: ATSColors.neutral500,
    letterSpacing: 1.5,
  );
}

/// Professional Component Decorations
class ATSDecorations {
  /// Standard card decoration
  static BoxDecoration card({Color? color}) => BoxDecoration(
    color: color ?? ATSColors.bgPrimary,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: ATSColors.neutral200, width: 1),
  );
  
  /// Card with shadow
  static BoxDecoration cardWithShadow({Color? color}) => BoxDecoration(
    color: color ?? ATSColors.bgPrimary,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: ATSColors.neutral200, width: 1),
    boxShadow: [
      BoxShadow(
        color: ATSColors.neutral900.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
  /// Input field decoration
  static InputDecoration inputDecoration({
    required String label,
    String? hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) => InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: ATSColors.neutral400) : null,
    suffixIcon: suffixIcon,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: ATSColors.neutral300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: ATSColors.neutral300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: ATSColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: ATSColors.danger),
    ),
    filled: true,
    fillColor: ATSColors.bgPrimary,
  );
  
  /// Button style
  static ButtonStyle primaryButton() => ElevatedButton.styleFrom(
    backgroundColor: ATSColors.primary,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    elevation: 0,
  );
  
  static ButtonStyle secondaryButton() => ElevatedButton.styleFrom(
    backgroundColor: ATSColors.neutral100,
    foregroundColor: ATSColors.neutral800,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    elevation: 0,
  );
  
  static ButtonStyle dangerButton() => ElevatedButton.styleFrom(
    backgroundColor: ATSColors.danger,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    elevation: 0,
  );
}
