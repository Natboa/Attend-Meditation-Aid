import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTextStyles {
  // Serif — Lora — for poems, headings, display text
  static TextStyle display(BuildContext context) =>
      GoogleFonts.lora(fontSize: 32, fontWeight: FontWeight.w600, height: 1.3);

  static TextStyle heading(BuildContext context) =>
      GoogleFonts.lora(fontSize: 22, fontWeight: FontWeight.w600, height: 1.4);

  static TextStyle poem(BuildContext context) =>
      GoogleFonts.lora(fontSize: 17, fontWeight: FontWeight.w400, height: 1.75);

  static TextStyle poemLarge(BuildContext context) =>
      GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w400, height: 1.8);

  // Sans — Nunito — for UI labels, body, metadata
  static TextStyle body(BuildContext context) =>
      GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w400, height: 1.5);

  static TextStyle bodyMedium(BuildContext context) =>
      GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w600, height: 1.5);

  static TextStyle label(BuildContext context) =>
      GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w500, height: 1.4);

  static TextStyle caption(BuildContext context) =>
      GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w400, height: 1.4);

  static TextStyle timerDisplay(BuildContext context) =>
      GoogleFonts.nunito(fontSize: 56, fontWeight: FontWeight.w200, height: 1.1, letterSpacing: -1);

  static TextTheme textTheme() => TextTheme(
        displayLarge: GoogleFonts.lora(fontSize: 57, fontWeight: FontWeight.w400),
        displayMedium: GoogleFonts.lora(fontSize: 45, fontWeight: FontWeight.w400),
        displaySmall: GoogleFonts.lora(fontSize: 36, fontWeight: FontWeight.w400),
        headlineLarge: GoogleFonts.lora(fontSize: 32, fontWeight: FontWeight.w600),
        headlineMedium: GoogleFonts.lora(fontSize: 28, fontWeight: FontWeight.w600),
        headlineSmall: GoogleFonts.lora(fontSize: 24, fontWeight: FontWeight.w600),
        titleLarge: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600),
        titleSmall: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w400),
        bodyMedium: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w400),
        bodySmall: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w400),
        labelLarge: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600),
        labelMedium: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w500),
        labelSmall: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w500),
      );
}
