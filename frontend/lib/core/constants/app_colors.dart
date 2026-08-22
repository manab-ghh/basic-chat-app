import 'package:flutter/material.dart';

/// Centralized color palette. Keeping colors here (instead of scattering
/// hex codes across widgets) makes theming and future dark-mode tuning trivial.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF075E54); // WhatsApp-style deep teal
  static const Color primaryLight = Color(0xFF25D366);
  static const Color accent = Color(0xFF128C7E);

  static const Color background = Color(0xFFF5F5F5);
  static const Color chatBackground = Color(0xFFECE5DD);

  static const Color bubbleSent = Color(0xFFDCF8C6);
  static const Color bubbleReceived = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF667781);

  static const Color online = Color(0xFF25D366);
  static const Color error = Color(0xFFD32F2F);
  static const Color divider = Color(0xFFE0E0E0);
}
