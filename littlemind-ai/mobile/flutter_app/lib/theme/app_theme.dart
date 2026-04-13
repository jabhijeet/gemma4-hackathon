import 'package:flutter/material.dart';

class AppTheme {
  // Light Theme - Gender Neutral Kid-Friendly Colors
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF4A90D9), // Friendly Blue
    scaffoldBackgroundColor: const Color(0xFFF0F8FF), // Alice Blue
    colorScheme: ColorScheme.light(
      primary: const Color(0xFF4A90D9), // Friendly Blue
      secondary: const Color(0xFF50C878), // Emerald Green
      surface: Colors.white,
      error: const Color(0xFFFF8A65), // Soft Coral
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: const Color(0xFF2C3E50), // Dark Blue-Gray
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF4A90D9), // Friendly Blue
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: Color(0xFF2C3E50),
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(
        color: Color(0xFF2C3E50),
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: Color(0xFF7F8C8D),
        fontSize: 14,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF4A90D9)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF4A90D9), width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4A90D9),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF4A90D9),
        side: const BorderSide(color: Color(0xFF4A90D9)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.all(const Color(0xFF4A90D9)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF50C878);
        }
        return Colors.grey;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF50C878).withValues(alpha: 0.5);
        }
        return Colors.grey.shade300;
      }),
    ),
  );

  // Dark Theme - Based on #232D3F
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF5BA4E6), // Lighter Blue for dark bg
    scaffoldBackgroundColor: const Color(0xFF232D3F), // Dark Navy (user specified)
    colorScheme: ColorScheme.dark(
      primary: const Color(0xFF5BA4E6), // Lighter Blue
      secondary: const Color(0xFF66D9A0), // Lighter Green
      surface: const Color(0xFF344258), // Card background
      error: const Color(0xFFE57373), // Soft Red
      onPrimary: const Color(0xFF1A1A2E),
      onSecondary: const Color(0xFF1A1A2E),
      onSurface: const Color(0xFFE8E8E8), // Light Gray
      onError: const Color(0xFF1A1A2E),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF2D3A4F), // Slightly lighter navy
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Color(0xFFE8E8E8),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: Color(0xFFE8E8E8)),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF344258),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: Color(0xFFE8E8E8),
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(
        color: Color(0xFFE8E8E8),
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: Color(0xFFA0AAB5),
        fontSize: 14,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF5BA4E6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF5BA4E6), width: 2),
      ),
      filled: true,
      fillColor: const Color(0xFF2D3A4F),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF5BA4E6),
        foregroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF5BA4E6),
        side: const BorderSide(color: Color(0xFF5BA4E6)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.all(const Color(0xFF5BA4E6)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF66D9A0);
        }
        return Colors.grey;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF66D9A0).withValues(alpha: 0.5);
        }
        return Colors.grey.shade700;
      }),
    ),
  );
}
