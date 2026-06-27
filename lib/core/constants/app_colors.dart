import 'package:flutter/material.dart';
import '../theme/theme_provider.dart';

class AppColors {
  // Light Theme Colors
  static const Color bgLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF6F8FA);
  static const Color textPrimaryLight = Color(0xFF1F2328);
  static const Color textMutedLight = Color(0xFF8C959F);
  static const Color borderLight_ = Color(0xFFD0D7DE);

  // Dark Theme Colors
  static const Color bgDark = Color(0xFF0F1115);
  static const Color surfaceDark = Color(0xFF17191E);
  static const Color textPrimaryDark = Color(0xFFF0F6FC);
  static const Color textMutedDark = Color(0xFF6E7681);
  static const Color borderDark = Color(0xFF2D3139);

  static bool get isDark => ThemeProvider.isDark;

  // Dynamic getters for widgets
  static Color get bg => isDark ? bgDark : bgLight;
  static Color get surface => isDark ? surfaceDark : surfaceLight;
  static Color get card => isDark ? surfaceDark : bgLight;
  static Color get textPrimary => isDark ? textPrimaryDark : textPrimaryLight;
  static Color get textSecondary => isDark ? const Color(0xFF8B949E) : const Color(0xFF656D76);
  static Color get textMuted => isDark ? textMutedDark : textMutedLight;
  static Color get border => isDark ? borderDark : borderLight_;
  static Color get borderLight => isDark ? const Color(0xFF252930) : const Color(0xFFE1E4E8);

  // Constants that don't change much
  static const Color indigo = Color(0xFF6366F1);
  static const Color emerald = Color(0xFF10B981);
  static const Color rose = Color(0xFFF43F5E);
  static const Color blue = Color(0xFF0969DA);
  static const Color green = Color(0xFF1A7F37);
  static const Color amber = Color(0xFF9A6700);
  static const Color red = Color(0xFFD1242F);
  static const Color orange = Color(0xFFBC4C00);
  static const Color purple = Color(0xFF8250DF);
  
  // Aliases
  static Color get text => textPrimary;
  static Color get muted => textMuted;
  static Color get surface2 => isDark ? const Color(0xFF1E2127) : const Color(0xFFF0F2F4);

  static const Color critical = Color(0xFFD1242F);
  static const Color high = Color(0xFF9A6700);
  static const Color medium = Color(0xFF0969DA);
  static const Color low = Color(0xFF656D76);

  static const LinearGradient indigoGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Map<String, Color> categoryColors = {
    'coding': blue,
    'review': green,
    'testing': Color(0xFF0550AE),
    'devops': amber,
    'learning': purple,
    'docs': Color(0xFF0969DA),
    'research': Color(0xFF876200),
    'opensource': Color(0xFFBC4C00),
    'meeting': Color(0xFF656D76),
    'sideproject': Color(0xFF8250DF),
  };
}
