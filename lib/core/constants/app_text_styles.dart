import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const String fontFamily = 'Inter';
  static const String displayFont = 'Inter';
  static const String monoFont = 'Inter';

  // --- Base Style Constants (Internal) ---
  static final TextStyle _displayLarge = GoogleFonts.inter(
    fontSize: 40,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -1.5,
    height: 1.1,
  );

  static final TextStyle _displayMedium = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -1.0,
    height: 1.2,
  );

  static final TextStyle _headlineLarge = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static final TextStyle _headlineMedium = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static final TextStyle _headlineSmall = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static final TextStyle _titleLarge = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static final TextStyle _titleMedium = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static final TextStyle _bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static final TextStyle _bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static final TextStyle _bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.4,
  );

  static final TextStyle _labelLarge = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );

  static final TextStyle _labelMedium = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );

  static final TextStyle _labelSmall = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
    letterSpacing: 1.0,
  );

  static final TextStyle _labelMono = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 1.0,
  );

  static final TextStyle _caption = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );

  // --- Public Semantic Accessors ---
  static TextStyle h1(BuildContext context) => _headlineLarge;
  static TextStyle h2(BuildContext context) => _headlineMedium;
  static TextStyle h3(BuildContext context) => _headlineSmall;
  static TextStyle display(BuildContext context) => _displayMedium;
  static TextStyle body(BuildContext context) => _bodyMedium;
  static TextStyle bodyLarge(BuildContext context) => _bodyLarge;
  static TextStyle bodyMedium(BuildContext context) => _bodyMedium.copyWith(fontWeight: FontWeight.w500, color: AppColors.textPrimary);
  static TextStyle bodySmall(BuildContext context) => _bodySmall;
  static TextStyle label(BuildContext context) => _labelMedium;
  static TextStyle labelSmall(BuildContext context) => _labelSmall;
  static TextStyle labelMono(BuildContext context) => _labelMono;
  static TextStyle caption(BuildContext context) => _caption;
  static TextStyle titleLarge(BuildContext context) => _titleLarge;
  static TextStyle titleMedium(BuildContext context) => _titleMedium;
  static TextStyle displayLarge(BuildContext context) => _displayLarge;
  static TextStyle displayMedium(BuildContext context) => _displayMedium;
  static TextStyle headlineLarge(BuildContext context) => _headlineLarge;
  static TextStyle headlineMedium(BuildContext context) => _headlineMedium;
  static TextStyle headlineSmall(BuildContext context) => _headlineSmall;
  static TextStyle labelLarge(BuildContext context) => _labelLarge;
  static TextStyle labelMedium(BuildContext context) => _labelMedium;
  static TextStyle mono(BuildContext context) => GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary);

  // --- Numeric / Stat Styles ---
  static final TextStyle counterHero = GoogleFonts.inter(
    fontSize: 64,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -3,
  );

  static final TextStyle counterLarge = GoogleFonts.inter(
    fontSize: 52,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -2,
  );

  static final TextStyle counterMedium = GoogleFonts.inter(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -1.5,
  );
}
