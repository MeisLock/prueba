//Creo un archivo para el temas con los colores y tipografía predefinida para el proyecto
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── Colores ──────────────────────────────────────────────────────────────
  static const Color deepNavy   = Color(0xFF0A2342);
  static const Color oceanBlue  = Color(0xFF2CA58D);
  static const Color pearlWhite = Color(0xFFF4F7F5);
  static const Color sunsetGold = Color(0xFFE8A020);
  static const Color alertRed   = Color(0xFFE53935);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: pearlWhite,
      colorScheme: const ColorScheme.light(
        primary:   deepNavy,
        secondary: oceanBlue,
        error:     alertRed,
        surface:   pearlWhite,
      ),

      // Añadimos la tipografía Montserrat
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 24, color: deepNavy),
        headlineMedium: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 18, color: deepNavy),
        headlineSmall: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 14, color: deepNavy),
        titleLarge: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 24, color: deepNavy),

        // La otra tipografía predefinida para el cuerpo
        bodyLarge:  GoogleFonts.openSans(fontSize: 18, color: deepNavy),
        bodyMedium: GoogleFonts.openSans(fontSize: 16, color: Colors.grey),
        bodySmall: GoogleFonts.openSans(fontSize: 14, color: Colors.grey)
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: deepNavy,
        foregroundColor: Colors.white,
        centerTitle: true,
        titleTextStyle: GoogleFonts.montserrat(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: Colors.white,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: deepNavy,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}