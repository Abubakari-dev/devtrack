import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  static const String fontFamily = 'Inter';
  static const String displayFont = 'Inter';

  // --- Display Styles (Finova Clean & Modern) ---
  
  /// Size: 36, Weight: 600 (SemiBold) - Main Balance Display
  static TextStyle get display => GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 36,
        letterSpacing: -1.0,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Size: 32, Weight: 600 (SemiBold) - Large Screen Titles (e.g., My Wallets)
  static TextStyle get h1 => GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 32,
        letterSpacing: -0.8,
      );

  /// Size: 28, Weight: 600 (SemiBold) - Secondary Headings
  static TextStyle get h2 => GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 28,
        letterSpacing: -0.5,
      );

  /// Size: 22, Weight: 600 (SemiBold) - Card Balances
  static TextStyle get h3 => GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 22,
        letterSpacing: -0.3,
      );

  /// Size: 20, Weight: 500 (Medium) - Item Names (e.g., Wallet Name)
  static TextStyle get h4 => GoogleFonts.inter(
        fontWeight: FontWeight.w500,
        fontSize: 20,
        letterSpacing: -0.2,
      );

  /// Size: 18, Weight: 500 (Medium) - Subtitles / Section Headers
  static TextStyle get subtitle => GoogleFonts.inter(
        fontWeight: FontWeight.w500,
        fontSize: 18,
      );

  static TextStyle get titleMedium => subtitle;
  static TextStyle get titleLarge => h4;
  static TextStyle get headlineMedium => h2;
  static TextStyle get headlineSmall => h3;

  static TextStyle get labelMono => GoogleFonts.robotoMono(
        fontWeight: FontWeight.w500,
        fontSize: 12,
      );

  // --- Functional Styles ---

  /// Size: 16, Weight: 400 (Regular) - Standard Body Text
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontWeight: FontWeight.w400,
        fontSize: 16,
      );

  /// Size: 14, Weight: 400 (Regular) - Small Body Text
  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontWeight: FontWeight.w400,
        fontSize: 14,
      );

  /// Size: 12, Weight: 500 (Medium) - Helper Text / Metadata (e.g., CASH)
  static TextStyle get bodySmall => GoogleFonts.inter(
        fontWeight: FontWeight.w500,
        fontSize: 12,
      );

  /// Size: 12, Weight: 400 (Regular) - Very Small Metadata (e.g., USD)
  static TextStyle get currency => GoogleFonts.inter(
        fontWeight: FontWeight.w400,
        fontSize: 12,
      );

  /// Size: 11, Weight: 500 (Medium) - Overline / Tabs
  static TextStyle get labelSmall => GoogleFonts.inter(
        fontWeight: FontWeight.w500,
        fontSize: 11,
        letterSpacing: 0.5,
      );

  static TextStyle get labelLarge => semiBold.copyWith(fontSize: 16);

  // --- Weight Helpers (Preferred: 400, 500, 600) ---
  static TextStyle get regular => GoogleFonts.inter(fontWeight: FontWeight.w400);
  static TextStyle get medium => GoogleFonts.inter(fontWeight: FontWeight.w500);
  static TextStyle get semiBold => GoogleFonts.inter(fontWeight: FontWeight.w600);
  
  static TextStyle get bold => GoogleFonts.inter(fontWeight: FontWeight.w700);
  static TextStyle get extraBold => GoogleFonts.inter(fontWeight: FontWeight.w800);

  // --- Material 3 TextTheme Generator ---
  static TextTheme getTextTheme(TextTheme base) {
    return GoogleFonts.interTextTheme(base).copyWith(
      displayLarge: display.copyWith(color: base.displayLarge?.color),
      displayMedium: h1.copyWith(color: base.displayMedium?.color),
      displaySmall: h2.copyWith(color: base.displaySmall?.color),
      headlineLarge: h1.copyWith(color: base.headlineLarge?.color),
      headlineMedium: h2.copyWith(color: base.headlineMedium?.color),
      headlineSmall: h3.copyWith(color: base.headlineSmall?.color),
      titleLarge: h4.copyWith(color: base.titleLarge?.color),
      titleMedium: subtitle.copyWith(color: base.titleMedium?.color),
      titleSmall: medium.copyWith(fontSize: 14, color: base.titleSmall?.color),
      bodyLarge: bodyLarge.copyWith(color: base.bodyLarge?.color),
      bodyMedium: bodyMedium.copyWith(color: base.bodyMedium?.color),
      bodySmall: bodySmall.copyWith(color: base.bodySmall?.color),
      labelLarge: semiBold.copyWith(fontSize: 16, color: base.labelLarge?.color),
      labelMedium: currency.copyWith(color: base.labelMedium?.color),
      labelSmall: labelSmall.copyWith(color: base.labelSmall?.color),
    );
  }
}
