import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PlokitchTheme {
  // Brand Colors
  static const Color primary = Color(0xFF895100);
  static const Color primaryContainer = Color(0xFFFF9B04);
  static const Color secondary = Color(0xFF924A34);
  static const Color secondaryContainer = Color(0xFFFDA186);
  static const Color tertiary = Color(0xFF72594D);
  static const Color tertiaryContainer = Color(0xFFCBAC9D);
  
  // Custom Colors not natively in ColorScheme but heavily used in Stitch
  static const Color warmBrown = Color(0xFF642714);
  static const Color surfaceContainer = Color(0xFFF7EED1);
  static const Color surfaceContainerHigh = Color(0xFFF1E8CC);
  static const Color inverseSurface = Color(0xFF35301D);
  
  // Backgrounds & Surfaces
  static const Color background = Color(0xFFFFF9EC);
  static const Color surface = Color(0xFFFFF9EC);

  static TextTheme _buildTextTheme(Color color) {
    return GoogleFonts.lilitaOneTextTheme().copyWith(
      displayLarge: GoogleFonts.lilitaOne(fontSize: 48, fontWeight: FontWeight.w400, color: color),
      displayMedium: GoogleFonts.lilitaOne(fontSize: 38, fontWeight: FontWeight.w400, color: color),
      displaySmall: GoogleFonts.lilitaOne(fontSize: 30, fontWeight: FontWeight.w400, color: color),
      headlineLarge: GoogleFonts.lilitaOne(fontSize: 28, fontWeight: FontWeight.w400, letterSpacing: 0.02, color: color),
      headlineMedium: GoogleFonts.lilitaOne(fontSize: 20, fontWeight: FontWeight.w400, color: color),
      headlineSmall: GoogleFonts.lilitaOne(fontSize: 18, fontWeight: FontWeight.w400, color: color),
      titleLarge: GoogleFonts.lilitaOne(fontSize: 18, fontWeight: FontWeight.w400, color: color),
      titleMedium: GoogleFonts.lilitaOne(fontSize: 14, fontWeight: FontWeight.w500, color: color),
      titleSmall: GoogleFonts.lilitaOne(fontSize: 12, fontWeight: FontWeight.w500, color: color),
      bodyLarge: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: color),
      bodyMedium: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w400, color: color),
      bodySmall: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w400, color: color),
      labelLarge: GoogleFonts.lilitaOne(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.05, color: color),
      labelSmall: GoogleFonts.lilitaOne(fontSize: 10, fontWeight: FontWeight.w400, color: color),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: Color(0xFFFFFFFF),
        primaryContainer: primaryContainer,
        onPrimaryContainer: Color(0xFF663B00),
        secondary: secondary,
        onSecondary: Color(0xFFFFFFFF),
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: Color(0xFF773621),
        tertiary: tertiary,
        onTertiary: Color(0xFFFFFFFF),
        tertiaryContainer: tertiaryContainer,
        onTertiaryContainer: Color(0xFF564034),
        error: Color(0xFFBA1A1A),
        onError: Color(0xFFFFFFFF),
        errorContainer: Color(0xFFFFDAD6),
        surface: surface,
        onSurface: Color(0xFF000000), // Updated to stark black
        outline: Color(0xFF877361),
        outlineVariant: Color(0xFFDAC2AD),
      ),
      textTheme: _buildTextTheme(const Color(0xFF000000)),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: primaryContainer, // Brighter for dark mode
        onPrimary: Color(0xFF4A2B00),
        primaryContainer: primary,
        onPrimaryContainer: Color(0xFFFFDDB3),
        secondary: secondaryContainer,
        onSecondary: Color(0xFF59200D),
        secondaryContainer: secondary,
        onSecondaryContainer: Color(0xFFFFDAD0),
        tertiary: tertiaryContainer,
        onTertiary: Color(0xFF3F2B20),
        tertiaryContainer: tertiary,
        onTertiaryContainer: Color(0xFFE8C7B8),
        error: Color(0xFFFFB4AB),
        onError: Color(0xFF690005),
        errorContainer: Color(0xFF93000A),
        surface: Color(0xFF14120E),
        onSurface: Color(0xFFEAE2D4),
        surfaceContainerHigh: Color(0xFF2E2B25),
        outline: Color(0xFF9E8D7F),
        outlineVariant: Color(0xFF51443A),
      ),
      textTheme: _buildTextTheme(const Color(0xFFEAE2D4)),
      scaffoldBackgroundColor: const Color(0xFF14120E),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF14120E),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
