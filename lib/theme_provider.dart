import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeProvider with ChangeNotifier {
  ThemeData _themeData;

  ThemeProvider() : _themeData = _darkTheme;

  ThemeData get themeData => _themeData;

  bool get isDarkMode => _themeData.brightness == Brightness.dark;

  void toggleTheme() {
    _themeData = isDarkMode ? _colorfulTheme : _darkTheme;
    notifyListeners();
  }

  static final ThemeData _darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF007BFF),
      brightness: Brightness.dark,
      primary: const Color(0xFF007BFF),
      secondary: const Color(0xFFE91E63),
      surface: const Color(0xFF1E1E1E),
      onSurface: Colors.white,
      background: const Color(0xFF121212),
      onBackground: Colors.white,
    ),
    textTheme: GoogleFonts.cairoTextTheme(
      const TextTheme(
        headlineMedium: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(color: Colors.white),
        labelLarge: TextStyle(color: Colors.white70),
      ),
    ),
    iconTheme: const IconThemeData(color: Colors.white70),
    cardTheme: CardThemeData(
      elevation: 0,
      color: const Color(0xFF2C2C2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
      ),
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
  );

  static final ThemeData _colorfulTheme = ThemeData(
    brightness: Brightness.light, // Treat this as a "light" theme for logic
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFAD1457), // Hot Pink
      brightness:
          Brightness.light, // CORRECTED: Must match ThemeData brightness
      primary: const Color(0xFF00BFFF), // Deep Sky Blue
      secondary: const Color(0xFFAD1457), // Hot Pink
      surface: Colors.white, // White cards
      onSurface: Colors.black, // Black text on cards
      background: const Color(0xFF1A0A3A), // Deep purple
      onBackground: Colors.white, // White text on purple bg
    ),
    textTheme: GoogleFonts.cairoTextTheme(
      const TextTheme(
        headlineMedium: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          color: Colors.black,
        ), // Text inside dropdowns/cards
        labelLarge: TextStyle(color: Colors.white70),
      ),
    ),
    iconTheme: const IconThemeData(
      color: Colors.white70,
    ), // Icons on background
    cardTheme: CardThemeData(
      elevation: 5,
      shadowColor: const Color(0xFFAD1457).withOpacity(0.5),
      color: Colors.white, // Card background is white
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    scaffoldBackgroundColor: const Color(0xFF1A0A3A),
  );
}
