import 'package:flutter/material.dart';

class AppColors {
  static const indigo = Color(0xFF4F46E5); // doctor
  static const indigoDark = Color(0xFF4338CA);
  static const emerald = Color(0xFF059669); // caregiver
  static const purple = Color(0xFF7C3AED); // patient
  static const teal = Color(0xFF0D9488);

  static const patientBg = Color(0xFFFAF7F2);
  static const patientBorder = Color(0xFFE8E0D6);
  static const patientText = Color(0xFF1A1A1A);
  static const patientSubtext = Color(0xFF888888);
  static const patientAmber = Color(0xFFD97706);

  // Status / semantic
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFD97706);
  static const danger = Color(0xFFDC2626);
  static const info = Color(0xFF6366F1);

  static const greyBg = Color(0xFFF9FAFB);
  static const cardWhite = Colors.white;
}

class AppSizes {
  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 24;
  static const double minTouchTarget = 56;
  static const double minTouchTargetSm = 44;
}

const Map<int, String> moodLabels = {
  1: 'Very Sad',
  2: 'Sad',
  3: 'Neutral',
  4: 'Happy',
  5: 'Very Happy',
};

const Map<int, Color> moodColors = {
  1: Color(0xFFEF4444),
  2: Color(0xFFF97316),
  3: Color(0xFFEAB308),
  4: Color(0xFF84CC16),
  5: Color(0xFF22C55E),
};

IconData moodIcon(int mood) {
  switch (mood) {
    case 1:
    case 2:
      return Icons.sentiment_very_dissatisfied;
    case 3:
      return Icons.sentiment_neutral;
    case 4:
      return Icons.sentiment_satisfied;
    default:
      return Icons.sentiment_very_satisfied;
  }
}