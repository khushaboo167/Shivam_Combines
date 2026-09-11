import 'package:flutter/material.dart';

class C {
  static const black = Color(0xFF0A0A0B);
  static const charcoal = Color(0xFF151517);
  static const teal = Color(0xFF2F9E90);
  static const gold = Color(0xFFE3AE2E);
  static const bg = Color(0xFFF5F3EF);
  static const ink = Color(0xFF1B1C1E);
  static const muted = Color(0xFF6E747A);
  static const line = Color(0xFFE4E1DA);
  static const danger = Color(0xFFD2483F);
  static const successBg = Color(0xFFE4F3F0);
}

ThemeData buildTheme() {
  return ThemeData(
    scaffoldBackgroundColor: C.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: C.teal,
      primary: C.teal,
      secondary: C.gold,
      background: C.bg,
    ),
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: C.black,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: C.gold,
        foregroundColor: C.black,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: C.line),
      ),
    ),
    useMaterial3: true,
  );
}

BoxDecoration cardDecoration() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: C.line),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 6)),
      ],
    );
