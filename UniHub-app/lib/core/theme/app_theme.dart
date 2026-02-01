import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF7B1E3A),
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFF2CBD6),
      onPrimaryContainer: Color(0xFF3D1A10),
      secondary: Color(0xFFF4A261),
      onSecondary: Color(0xFF3A2515),
      secondaryContainer: Color(0xFFFFE3C7),
      onSecondaryContainer: Color(0xFF3A2515),
      tertiary: Color(0xFF6A994E),
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFDDEBCF),
      onTertiaryContainer: Color(0xFF21371A),
      error: Color(0xFFB3261E),
      onError: Colors.white,
      errorContainer: Color(0xFFF9DEDC),
      onErrorContainer: Color(0xFF410E0B),
      background: Color(0xFFFFF7F2),
      onBackground: Color(0xFF2B2118),
      surface: Color(0xFFFFF1E6),
      onSurface: Color(0xFF2B2118),
      surfaceVariant: Color(0xFFF5E4D8),
      onSurfaceVariant: Color(0xFF5B4A3E),
      outline: Color(0xFFB59A8A),
      outlineVariant: Color(0xFFD9C3B5),
      shadow: Color(0x33000000),
      scrim: Color(0x55000000),
      inverseSurface: Color(0xFF3A2C24),
      onInverseSurface: Color(0xFFFFF7F2),
      inversePrimary: Color(0xFFB85A74),
    );

    final textTheme = GoogleFonts.lexendTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.background,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onBackground,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: colorScheme.onBackground),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.background,
        indicatorColor: Colors.transparent,
        labelTextStyle: MaterialStateProperty.all(
          textTheme.labelMedium?.copyWith(color: colorScheme.onSurface),
        ),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          final isSelected = states.contains(MaterialState.selected);
          return IconThemeData(
            color: isSelected ? colorScheme.primary : const Color(0xFF8C8C8C),
            size: 26,
          );
        }),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceVariant,
        selectedColor: colorScheme.primaryContainer,
        labelStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onPrimaryContainer,
        ),
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
