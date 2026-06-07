import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color background = Color(0xFF08090A);
  static const Color surface = Color.fromARGB(255, 16, 16, 20);
  static const Color surfaceElevated = Color.fromARGB(255, 19, 21, 24);
  static const Color border = Color.fromARGB(255, 32, 33, 37);
  static const Color onSurface = Color(0xFFF7F8F8);
  static const Color muted = Color(0xFF8A8F98);
  static const Color primary = Color(0xFFFFFFFF);
  static const Color primaryMuted = Color(0xFFCCCCCC);
}

class TicketColor {
  final String label;
  final Color background;
  final Color foreground;
  final Color border;

  const TicketColor(this.label, this.background, this.foreground, this.border);
}

class TaskColors {
  static Color status(String status) {
    switch (status) {
      case 'doing':  return const Color(0xFF6E9FFF);
      case 'todo': return const Color(0xFFE8A44A);
      case 'done':   return const Color(0xFF4DC98A);
      default:       return AppColors.muted;
    }
  }

  static Color priority(String priority) {
    switch (priority) {
      case 'high':   return const Color(0xFFFF8585);
      case 'medium': return const Color(0xFFE8A44A);
      case 'low':    return const Color(0xFF4DC98A);
      default:       return AppColors.muted;
    }
  }
}


class TicketColors {
  const TicketColors._();

  static const TicketColor gray = TicketColor(
    'Gray',
    Color(0xFF2C2D31),
    Color(0xFFB5B7BC),
    Color(0xFF3A3B40),
  );
  static const TicketColor red = TicketColor(
    'Red',
    Color(0xFF3E1F22),
    Color(0xFFFF8585),
    Color(0xFF5A2A2E),
  );
  static const TicketColor orange = TicketColor(
    'Orange',
    Color(0xFF3F2A18),
    Color(0xFFFFAA6B),
    Color(0xFF5C3A1F),
  );
  static const TicketColor yellow = TicketColor(
    'Yellow',
    Color(0xFF3D3618),
    Color(0xFFF5D86B),
    Color(0xFF564B1F),
  );
  static const TicketColor green = TicketColor(
    'Green',
    Color(0xFF1B3328),
    Color(0xFF7AD49F),
    Color(0xFF274838),
  );
  static const TicketColor blue = TicketColor(
    'Blue',
    Color(0xFF1B2E4A),
    Color(0xFF8AB8FF),
    Color(0xFF2A4267),
  );
  static const TicketColor purple = TicketColor(
    'Purple',
    Color(0xFF2E2444),
    Color(0xFFB79CFF),
    Color(0xFF40345E),
  );
  static const TicketColor pink = TicketColor(
    'Pink',
    Color(0xFF3D2034),
    Color(0xFFFF9CCB),
    Color(0xFF572E4A),
  );

  static const List<TicketColor> all = [
    gray,
    red,
    orange,
    yellow,
    green,
    blue,
    purple,
    pink,
  ];

}
