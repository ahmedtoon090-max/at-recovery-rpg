import 'package:flutter/material.dart';

/// Dark-Fantasy Semantic Color Tokens ("Twilight Obsidian × Sovereign Ember").
abstract final class AppColors {
  static const Color bgVoid = Color(0xFF090B10);
  static const Color bgObsidian = Color(0xFF0D0F14);
  static const Color bgElevated = Color(0xFF151922);

  /// Rich atmospheric dark-fantasy twilight surfaces (replacing flat black boxes).
  static const Color twilightDeep = Color(0xFF0C1020);
  static const Color twilightMid = Color(0xFF141A30);
  static const Color twilightIndigo = Color(0xFF0B1026);
  static const Color torchAmber = Color(0xFFFF9F43);
  static const Color moltenGold = Color(0xFFF5B942);
  static const Color arcaneEmerald = Color(0xFF10E8A0);

  static const Color borderSubtle = Color.fromRGBO(255, 255, 255, 0.10);
  static const Color borderHighlight = Color.fromRGBO(255, 255, 255, 0.18);
  static const Color borderGold = Color(0x66F5B942);

  static const Color accentEmerald = Color(0xFF10B981);
  static const Color accentEmeraldGlow = Color(0xFF10E8A0);
  static const Color accentGold = Color(0xFFF5B942);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentIndigo = Color(0xFF6366F1);

  /// Reserved exclusively for Mirage Ambush CTA, Boss threats & high-risk alerts.
  static const Color accentCrimson = Color(0xFFEF4444);

  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFFA5B4CC);
  static const Color textMuted = Color(0xFF64748B);

  static const Color glassFill = Color.fromRGBO(16, 22, 42, 0.78);
}
