import 'package:flutter/material.dart';

/// YouScout Design System — Color Palette
///
/// Near-black dark theme inspired by Apple Fitness × TikTok.
/// Electric cyan primary, Instagram-red likes, soft purple for skills.
class AppColors {
  AppColors._();

  // ── Backgrounds ──────────────────────────────────────────
  static const Color background      = Color(0xFF09090B);   // near-black
  static const Color surfaceCard     = Color(0xFF141416);   // dark card
  static const Color surfaceElevated = Color(0xFF1C1C1F);   // elevated surface
  static const Color surfaceOverlay  = Color(0xFF232328);   // modal/sheet bg

  // ── Brand ────────────────────────────────────────────────
  static const Color primary         = Color(0xFF00D4FF);   // electric cyan
  static const Color primaryGlow     = Color(0x3300D4FF);   // glow effect
  static const Color secondary       = Color(0xFF7B61FF);   // soft purple (skills)

  // ── Accent ───────────────────────────────────────────────
  static const Color like            = Color(0xFFFF3B5C);   // Instagram-red
  static const Color gold            = Color(0xFFFFD60A);   // ratings, gold
  static const Color success         = Color(0xFF30D158);   // confirm green

  // ── Text ─────────────────────────────────────────────────
  static const Color textPrimary     = Color(0xFFF5F5F7);   // almost-white
  static const Color textSecondary   = Color(0xFF8E8E93);   // muted gray
  static const Color textTertiary    = Color(0xFF48484A);   // very muted

  // ── Borders ──────────────────────────────────────────────
  static const Color borderSubtle    = Color(0xFF2C2C2E);
  static const Color borderDefault   = Color(0xFF3A3A3C);
}
