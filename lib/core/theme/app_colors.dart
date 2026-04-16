import 'package:flutter/material.dart';

class AppColors {
  // ── Base palette ────────────────────────────────────────────────────────────
  static const Color background   = Color(0xFF1A1A1A); // page background
  static const Color surface      = Color(0xFF242424); // board area
  static const Color columnBg     = Color(0xFF2C2C2C); // column card
  static const Color cardBg       = Color(0xFF333333); // task card
  static const Color cardBorder   = Color(0xFF404040);
  static const Color divider      = Color(0xFF3A3A3A);

  // ── Text ────────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFE8E8E8);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color textMuted     = Color(0xFF6B6B6B);

  // ── Accent / status ─────────────────────────────────────────────────────────
  static const Color primary      = Color(0xFF2D2D2D);
  static const Color primaryLight = Color(0xFF3D3D3D);
  static const Color accent       = Color(0xFF707070);
  static const Color error        = Color(0xFFCF6679);
  static const Color success      = Color(0xFF4CAF7D);

  // ── AppBar gradient ──────────────────────────────────────────────────────────
  static const Color appBarTop    = Color(0xFF1A1A1A);
  static const Color appBarBottom = Color(0xFF252525);

  // ── Column header accents (vivid, dark-friendly) ────────────────────────────
  static const List<Color> columnColors = [
    Color(0xFF4DA6FF), // bright blue
    Color(0xFF3DD68C), // bright green
    Color(0xFFFFAA2C), // bright amber
    Color(0xFFBB86FC), // bright purple
    Color(0xFF26D4D4), // bright cyan
    Color(0xFFFF6B9D), // bright pink
    Color(0xFF7B9EFF), // bright indigo
    Color(0xFF4DDFB0), // bright teal
  ];
}
