// lib/theme/app_theme.dart

import 'package:flutter/material.dart';

/// Thème unifié pour l'application MIA CRM
/// Style : Propre, professionnel et élégant
class AppTheme {
  // ============================================
  // COULEURS PRINCIPALES
  // ============================================
  
  // Backgrounds
  static const Color backgroundPrimary = Color(0xFFF5F5F5); // Colors.grey[100]
  static const Color backgroundSecondary = Colors.white;
  static const Color backgroundCard = Colors.white;
  
  // Textes
  static const Color textPrimary = Color(0xFF212121); // Colors.black87
  static const Color textSecondary = Color(0xFF757575); // Colors.grey[600]
  static const Color textTertiary = Color(0xFF9E9E9E); // Colors.grey[500]
  static const Color textHint = Color(0xFFBDBDBD); // Colors.grey[400]
  
  // Accents (pour badges, icônes, etc.)
  static const Color accentBlue = Color(0xFF2196F3); // Colors.blue
  static const Color accentGreen = Color(0xFF4CAF50); // Colors.green
  static const Color accentOrange = Color(0xFFFF9800); // Colors.orange
  static const Color accentRed = Color(0xFFF44336); // Colors.red
  
  // Borders et séparateurs
  static const Color borderLight = Color(0xFFE0E0E0); // Colors.grey[300]
  static const Color divider = Color(0xFFE0E0E0);
  
  // ============================================
  // ESPACEMENTS
  // ============================================
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 12.0;
  static const double spacingL = 16.0;
  static const double spacingXL = 20.0;
  static const double spacingXXL = 24.0;
  static const double spacingXXXL = 32.0;
  
  // ============================================
  // BORDER RADIUS
  // ============================================
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 20.0;
  
  // ============================================
  // TYPOGRAPHIE
  // ============================================
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: -0.5,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.3,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimary,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textPrimary,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: textSecondary,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textSecondary,
    fontStyle: FontStyle.italic,
  );
  
  // ============================================
  // COMPOSANTS RÉUTILISABLES
  // ============================================
  
  /// Style pour l'AppBar standard
  static AppBarTheme get appBarTheme => const AppBarTheme(
    elevation: 0,
    backgroundColor: backgroundSecondary,
    iconTheme: IconThemeData(color: textPrimary),
    titleTextStyle: heading1,
    centerTitle: false,
  );
  
  /// Style pour les Cards standard
  static CardThemeData get cardTheme => CardThemeData(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusL),
    ),
    color: backgroundCard,
    margin: const EdgeInsets.only(bottom: spacingL),
  );
  
  /// Style pour les InputFields (SearchBar, TextField)
  static InputDecorationTheme get inputDecorationTheme => InputDecorationTheme(
    filled: true,
    fillColor: backgroundPrimary,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusM),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusM),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusM),
      borderSide: BorderSide(color: accentBlue, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusM),
      borderSide: BorderSide(color: accentRed, width: 1),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: spacingL,
      vertical: spacingM + 2,
    ),
    hintStyle: TextStyle(color: textTertiary),
  );
  
  /// Style pour les Dropdowns
  static BoxDecoration get dropdownDecoration => BoxDecoration(
    color: backgroundPrimary,
    borderRadius: BorderRadius.circular(radiusM),
  );
  
  /// Style pour les Badges de statut
  static BoxDecoration statusBadgeDecoration(Color color) => BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radiusS),
  );
  
  /// Style pour les boutons primaires
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: accentBlue,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(
      horizontal: spacingXL,
      vertical: spacingM,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusM),
    ),
    textStyle: bodyMedium.copyWith(
      fontWeight: FontWeight.w600,
    ),
  );
  
  /// Style pour les boutons secondaires
  static ButtonStyle get secondaryButtonStyle => OutlinedButton.styleFrom(
    foregroundColor: textPrimary,
    side: const BorderSide(color: borderLight),
    padding: const EdgeInsets.symmetric(
      horizontal: spacingXL,
      vertical: spacingM,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusM),
    ),
    textStyle: bodyMedium.copyWith(
      fontWeight: FontWeight.w600,
    ),
  );
  
  // ============================================
  // THÈME COMPLET
  // ============================================
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: accentBlue,
        secondary: accentGreen,
        surface: backgroundSecondary,
        background: backgroundPrimary,
        error: accentRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onBackground: textPrimary,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundPrimary,
      appBarTheme: appBarTheme,
      cardTheme: cardTheme,
      inputDecorationTheme: inputDecorationTheme,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: primaryButtonStyle,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: secondaryButtonStyle,
      ),
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(
        color: textSecondary,
        size: 24,
      ),
      textTheme: const TextTheme(
        displayLarge: heading1,
        displayMedium: heading2,
        displaySmall: heading3,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: bodyMedium,
        labelMedium: bodySmall,
        labelSmall: caption,
      ),
    );
  }
}
