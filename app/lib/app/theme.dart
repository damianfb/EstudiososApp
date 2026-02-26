import 'package:flutter/material.dart';

/// Colores primarios de la aplicación.
const kPrimaryColor = Color(0xFF1565C0);
const kSecondaryColor = Color(0xFF42A5F5);
const kErrorColor = Color(0xFFD32F2F);

/// Tema global de EstudiososApp.
abstract class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: kPrimaryColor,
        error: kErrorColor,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(const Radius.circular(8)),
          ),
        ),
      ),
    );
  }
}
