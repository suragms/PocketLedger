import 'package:flutter/material.dart';

class AppTypography {
  static const String primaryFont = 'Inter';

  static TextStyle displayLarge(Color color) => TextStyle(
        fontFamily: primaryFont,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: color,
      );

  static TextStyle displayMedium(Color color) => TextStyle(
        fontFamily: primaryFont,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: color,
      );

  static TextStyle headlineMedium(Color color) => TextStyle(
        fontFamily: primaryFont,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle titleMedium(Color color) => TextStyle(
        fontFamily: primaryFont,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle bodyLarge(Color color) => TextStyle(
        fontFamily: primaryFont,
        fontSize: 15,
        fontWeight: FontWeight.normal,
        color: color,
      );

  static TextStyle bodyMedium(Color color) => TextStyle(
        fontFamily: primaryFont,
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: color,
      );

  static TextStyle labelSmall(Color color) => TextStyle(
        fontFamily: primaryFont,
        fontSize: 12,
        color: color,
      );
}
