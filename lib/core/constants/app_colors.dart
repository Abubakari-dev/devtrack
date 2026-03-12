import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color bg = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF6F8FA);
  static const Color surface2 = Color(0xFFF0F2F4);
  static const Color surface3 = Color(0xFFE6E8EA);

  // Borders
  static const Color border = Color(0xFFD0D7DE);
  static const Color borderLight = Color(0xFFE1E4E8);

  // Accent Colors
  static const Color blue = Color(0xFF0969DA);
  static const Color blueDark = Color(0xFF0550AE);
  static const Color blueGlow = Color(0x150969DA);
  static const Color green = Color(0xFF1A7F37);
  static const Color greenGlow = Color(0x151A7F37);
  static const Color amber = Color(0xFF9A6700);
  static const Color amberGlow = Color(0x159A6700);
  static const Color red = Color(0xFFD1242F);
  static const Color redGlow = Color(0x15D1242F);
  static const Color purple = Color(0xFF8250DF);
  static const Color purpleGlow = Color(0x158250DF);
  static const Color orange = Color(0xFFBC4C00);
  static const Color gold = Color(0xFF876200);
  static const Color teal = Color(0xFF0969DA);
  
  // Additional colors
  static const Color indigo = Color(0xFF6366F1);
  static const Color indigoLight = Color(0xFFEEF2FF);
  static const Color indigoGlow = Color(0x156366F1);
  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldGlow = Color(0x1510B981);
  static const Color rose = Color(0xFFF43F5E);
  static const Color roseGlow = Color(0x15F43F5E);
  static const Color card = Color(0xFFFFFFFF);
  static const Color card2 = Color(0xFFF9FAFB);
  
  // Gradients
  static const LinearGradient indigoGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient amberGradient = LinearGradient(
    colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Text
  static const Color textPrimary = Color(0xFF1F2328);
  static const Color textSecondary = Color(0xFF656D76);
  static const Color textMuted = Color(0xFF8C959F);
  static const Color text = Color(0xFF1F2328);
  static const Color muted = Color(0xFF8C959F);
  static const Color subtle = Color(0xFFD0D7DE);

  // Priority
  static const Color critical = Color(0xFFD1242F);
  static const Color high = Color(0xFF9A6700);
  static const Color medium = Color(0xFF0969DA);
  static const Color low = Color(0xFF656D76);

  // Category Colors
  static const Map<String, Color> categoryColors = {
    'coding': blue,
    'review': green,
    'testing': Color(0xFF0550AE),
    'devops': amber,
    'learning': purple,
    'docs': Color(0xFF0969DA),
    'research': gold,
    'opensource': orange,
    'meeting': Color(0xFF656D76),
    'sideproject': Color(0xFF8250DF),
  };
}
