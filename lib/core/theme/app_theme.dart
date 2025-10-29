import 'package:flutter/material.dart';

// TODO: dark mode and light mode

class AppTheme {
  // Primary Colors - From your palette
  static const Color primaryColor = Color(0xFF24465F); // Dark blue
  static const Color primaryLight = Color(0xFF508396); // Light blue
  static const Color primaryDark = Color(0xFF1A3143); // Darker blue

  // Accent Colors - From your palette
  static const Color accentColor = Color(0xFF5BC448); // Green
  static const Color accentLight = Color(0xFF6DCD56); // Light green

  // Semantic Colors
  static const Color successColor = Color(0xFF5BC448); // Green from palette
  static const Color warningColor = Color(0xFFF59E0B); // Amber
  static const Color dangerColor = Color(0xFFEF4444); // Red
  static const Color infoColor = Color(0xFF508396); // Blue from palette

  // Neutral Colors - From your palette
  static const Color backgroundColor = Color(0xFFF5F2EE); // Cream white
  static const Color surfaceColor = Color(0xFFFFFFFF); // Pure white
  static const Color surfaceVariantColor = Color(0xFFDADCCA); // Light beige
  static const Color onSurfaceColor = Color(0xFF24465F); // Dark blue text
  static const Color onSurfaceVariantColor = Color(0xFF6B7280); // Gray text

  // Password Strength Colors
  static const Color weakPasswordColor = Color(0xFFEF4444);
  static const Color mediumPasswordColor = Color(0xFFFFB84D);
  static const Color strongPasswordColor = Color(0xFF5BC448);

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        primaryContainer: primaryLight,
        secondary: accentColor,
        secondaryContainer: accentLight,
        surface: surfaceColor,
        surfaceContainerHighest: surfaceVariantColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: onSurfaceColor,
        onSurfaceVariant: onSurfaceVariantColor,
        error: dangerColor,
        onError: Colors.white,
      ),
      textTheme: _textTheme,
      elevatedButtonTheme: _elevatedButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      textButtonTheme: _textButtonTheme,
      inputDecorationTheme: _inputDecorationThemeLight,
      cardTheme: _cardTheme,
      appBarTheme: _appBarTheme,
      bottomNavigationBarTheme: _bottomNavigationBarTheme,
      floatingActionButtonTheme: _floatingActionButtonTheme,
      snackBarTheme: _snackBarTheme,
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        primaryContainer: primaryLight,
        secondary: accentColor,
        secondaryContainer: accentLight,
        surface: Color(0xFF1F2937),
        surfaceContainerHighest: Color(0xFF374151),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFFF9FAFB),
        onSurfaceVariant: Color(0xFFD1D5DB),
        error: dangerColor,
        onError: Colors.white,
      ),
      textTheme: _textTheme.apply(
        bodyColor: const Color(0xFFF9FAFB),
        displayColor: const Color(0xFFF9FAFB),
      ),
      elevatedButtonTheme: _elevatedButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      textButtonTheme: _textButtonTheme,
      inputDecorationTheme: _inputDecorationThemeDark,
      cardTheme: _cardTheme,
      appBarTheme: _appBarTheme,
      bottomNavigationBarTheme: _bottomNavigationBarTheme,
      floatingActionButtonTheme: _floatingActionButtonTheme,
      snackBarTheme: _snackBarTheme,
    );
  }

  // Text Theme
  static TextTheme get _textTheme {
    return const TextTheme(
      // Titles - Lexend
      displayLarge: TextStyle(
        fontFamily: 'Lexend',
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Lexend',
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.25,
      ),
      displaySmall: TextStyle(
        fontFamily: 'Lexend',
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'Lexend',
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Lexend',
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Lexend',
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Lexend',
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Lexend',
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        fontFamily: 'Lexend',
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      // Body Text - Zalando
      bodyLarge: TextStyle(
        fontFamily: 'Zalando',
        fontSize: 16,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.15,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Zalando',
        fontSize: 14,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.25,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Zalando',
        fontSize: 12,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.4,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Zalando',
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Zalando',
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Zalando',
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  // Button Themes
  static ElevatedButtonThemeData get _elevatedButtonTheme {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 2,
        shadowColor: primaryColor.withValues(alpha: 0.3),
      ),
    );
  }

  static OutlinedButtonThemeData get _outlinedButtonTheme {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        side: const BorderSide(color: primaryColor, width: 2),
      ),
    );
  }

  static TextButtonThemeData get _textButtonTheme {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }

  // Input Decoration Theme (Light Mode)
  static InputDecorationTheme get _inputDecorationThemeLight {
    return InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: onSurfaceVariantColor, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: onSurfaceVariantColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: dangerColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: TextStyle(
        color: onSurfaceColor.withValues(alpha: 0.5),
        fontSize: 16,
        fontFamily: 'Zalando',
      ),
      labelStyle: TextStyle(
        color: onSurfaceColor.withValues(alpha: 0.7),
        fontSize: 16,
        fontFamily: 'Zalando',
      ),
      helperStyle: TextStyle(
        color: onSurfaceColor.withValues(alpha: 0.7),
        fontFamily: 'Zalando',
      ),
      prefixIconColor: onSurfaceColor.withValues(alpha: 0.7),
      suffixIconColor: onSurfaceColor.withValues(alpha: 0.7),
    );
  }

  // Input Decoration Theme (Dark Mode)
  static InputDecorationTheme get _inputDecorationThemeDark {
    return InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1F2937),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF374151), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF374151), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: dangerColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: TextStyle(
        color: const Color(0xFFD1D5DB).withValues(alpha: 0.5),
        fontSize: 16,
        fontFamily: 'Zalando',
      ),
      labelStyle: TextStyle(
        color: const Color(0xFFD1D5DB).withValues(alpha: 0.7),
        fontSize: 16,
        fontFamily: 'Zalando',
      ),
      helperStyle: TextStyle(
        color: const Color(0xFFD1D5DB).withValues(alpha: 0.7),
        fontFamily: 'Zalando',
      ),
      prefixIconColor: const Color(0xFFD1D5DB).withValues(alpha: 0.7),
      suffixIconColor: const Color(0xFFD1D5DB).withValues(alpha: 0.7),
    );
  }

  // Card Theme
  static CardThemeData get _cardTheme {
    return CardThemeData(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(8),
    );
  }

  // App Bar Theme
  static AppBarTheme get _appBarTheme {
    return AppBarTheme(
      elevation: 0,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        fontFamily: 'Lexend',
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // Bottom Navigation Bar Theme
  static BottomNavigationBarThemeData get _bottomNavigationBarTheme {
    return const BottomNavigationBarThemeData(
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    );
  }

  // Floating Action Button Theme
  static FloatingActionButtonThemeData get _floatingActionButtonTheme {
    return FloatingActionButtonThemeData(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  // SnackBar Theme
  static SnackBarThemeData get _snackBarTheme {
    return const SnackBarThemeData(
      backgroundColor: Color(0xFF1F2937),
      contentTextStyle: TextStyle(
        fontFamily: 'Zalando',
        fontSize: 14,
        color: Color(0xFFF9FAFB),
      ),
      actionTextColor: successColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    );
  }

  // Custom Colors for specific use cases
  static const Map<String, Color> tagColors = {
    'work': Color(0xFF3B82F6),
    'personal': Color(0xFF10B981),
    'finance': Color(0xFFF59E0B),
    'social': Color(0xFFEC4899),
    'entertainment': Color(0xFF8B5CF6),
    'shopping': Color(0xFFEF4444),
    'utilities': Color(0xFF6B7280),
    'travel': Color(0xFF06B6D4),
  };

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentColor, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [successColor, Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [dangerColor, Color(0xFFF87171)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
