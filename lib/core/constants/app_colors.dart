import 'package:flutter/material.dart';

class AppColors {
  static const Color primary        = Color(0xFFE65100);
  static const Color primaryDark    = Color(0xFFBF360C);
  static const Color primaryLight   = Color(0xFFFFF3E0);
  static const Color accent         = Color(0xFFFFB300);
  static const Color accentLight    = Color(0xFFFFF8E1);

  static const Color bgLight        = Color(0xFFF0F2F5);
  static const Color bgDark         = Color(0xFF0D0D0D);
  static const Color surfaceLight   = Color(0xFFFFFFFF);
  static const Color surfaceDark    = Color(0xFF1A1A1A);
  static const Color cardLight      = Color(0xFFFFFFFF);
  static const Color cardDark       = Color(0xFF242424);

  static const Color sidebarBg      = Color(0xFF1C1C2E);
  static const Color sidebarActive  = Color(0xFFE65100);
  static const Color sidebarHover   = Color(0xFF2A2A3E);

  static const Color textDark       = Color(0xFF1A1A2E);
  static const Color textMedium     = Color(0xFF555577);
  static const Color textLight      = Color(0xFFFFFFFF);
  static const Color textMuted      = Color(0xFF9999BB);

  static const Color success        = Color(0xFF00C853);
  static const Color successLight   = Color(0xFFE8F5E9);
  static const Color warning        = Color(0xFFFF6D00);
  static const Color warningLight   = Color(0xFFFFF3E0);
  static const Color info           = Color(0xFF0288D1);
  static const Color infoLight      = Color(0xFFE1F5FE);
  static const Color error          = Color(0xFFD50000);
  static const Color errorLight     = Color(0xFFFFEBEE);

  static const Color statusPaid     = Color(0xFF00C853);
  static const Color statusPending  = Color(0xFFFF6D00);
  static const Color statusPartial  = Color(0xFF0288D1);
  static const Color statusCanceled = Color(0xFFD50000);

  static const Color dividerLight   = Color(0xFFE0E0E0);
  static const Color dividerDark    = Color(0xFF333344);

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.07),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> cardShadowDark = [
    BoxShadow(
      color: Colors.black.withOpacity(0.35),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
}
