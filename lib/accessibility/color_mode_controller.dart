import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stephenscalender2024/constants.dart';

enum AppColorMode {
  standard,
  highContrast,
  darkHighContrast,
}

extension AppColorModeDetails on AppColorMode {
  String get storageValue => name;

  String get label {
    switch (this) {
      case AppColorMode.standard:
        return 'Standard';
      case AppColorMode.highContrast:
        return 'High contrast';
      case AppColorMode.darkHighContrast:
        return 'Dark high contrast';
    }
  }

  String get description {
    switch (this) {
      case AppColorMode.standard:
        return 'Default campus colors';
      case AppColorMode.highContrast:
        return 'Sharper text and stronger outlines';
      case AppColorMode.darkHighContrast:
        return 'Dark background with bright text';
    }
  }

  static AppColorMode fromStorageValue(String? value) {
    return AppColorMode.values.firstWhere(
      (mode) => mode.storageValue == value,
      orElse: () => AppColorMode.standard,
    );
  }
}

class ColorModeController extends ChangeNotifier {
  static const _preferenceKey = 'appColorMode';

  AppColorMode _mode = AppColorMode.standard;
  bool _isLoaded = false;

  AppColorMode get mode => _mode;
  bool get isLoaded => _isLoaded;
  bool get usesHighContrast => _mode != AppColorMode.standard;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _mode = AppColorModeDetails.fromStorageValue(
      prefs.getString(_preferenceKey),
    );
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setMode(AppColorMode mode) async {
    final prefs = await SharedPreferences.getInstance();

    if (_mode == mode && _isLoaded) {
      await prefs.setString(_preferenceKey, mode.storageValue);
      return;
    }

    _mode = mode;
    _isLoaded = true;
    notifyListeners();

    await prefs.setString(_preferenceKey, mode.storageValue);
  }
}

class AppColorThemes {
  static ThemeData forMode(AppColorMode mode) {
    switch (mode) {
      case AppColorMode.standard:
        return _buildTheme(
          colorScheme: ColorScheme.fromSeed(
            seedColor: kPrimaryColor,
          ),
          scaffoldBackgroundColor: Colors.white,
          cardColor: Colors.white,
          dividerColor: Colors.black12,
          brightness: Brightness.light,
          highContrast: false,
        );
      case AppColorMode.highContrast:
        return _buildTheme(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF003B73),
            onPrimary: Colors.white,
            secondary: Color(0xFF8A4F00),
            onSecondary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black,
            secondaryContainer: Color(0xFFFFD166),
            onSecondaryContainer: Colors.black,
            error: Color(0xFFB00020),
            onError: Colors.white,
          ),
          scaffoldBackgroundColor: Colors.white,
          cardColor: Colors.white,
          dividerColor: Colors.black,
          brightness: Brightness.light,
          highContrast: true,
        );
      case AppColorMode.darkHighContrast:
        return _buildTheme(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFFFD166),
            onPrimary: Colors.black,
            secondary: Color(0xFF7FDBFF),
            onSecondary: Colors.black,
            surface: Color(0xFF050505),
            onSurface: Colors.white,
            secondaryContainer: Color(0xFF103D5C),
            onSecondaryContainer: Colors.white,
            error: Color(0xFFFF6B6B),
            onError: Colors.black,
          ),
          scaffoldBackgroundColor: Colors.black,
          cardColor: const Color(0xFF050505),
          dividerColor: Colors.white,
          brightness: Brightness.dark,
          highContrast: true,
        );
    }
  }

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Color scaffoldBackgroundColor,
    required Color cardColor,
    required Color dividerColor,
    required Brightness brightness,
    required bool highContrast,
  }) {
    final isDark = brightness == Brightness.dark;
    final outlineWidth = highContrast ? 1.4 : 1.0;

    return ThemeData(
      primaryColor: colorScheme.primary,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      colorScheme: colorScheme,
      brightness: brightness,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: dividerColor, width: outlineWidth),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surface,
        selectedColor: colorScheme.secondaryContainer,
        labelStyle: TextStyle(color: colorScheme.onSurface),
        secondaryLabelStyle: TextStyle(color: colorScheme.onSecondaryContainer),
        side: BorderSide(color: dividerColor, width: outlineWidth),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerTheme:
          DividerThemeData(color: dividerColor, thickness: outlineWidth),
      drawerTheme: DrawerThemeData(
        backgroundColor: scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: dividerColor, width: outlineWidth),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: dividerColor, width: outlineWidth),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurface,
        textColor: colorScheme.onSurface,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.secondaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: colorScheme.primary, width: outlineWidth),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? Colors.white : Colors.black,
        contentTextStyle: TextStyle(
          color: isDark ? Colors.black : Colors.white,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primaryContainer;
          }
          return colorScheme.surfaceContainerHighest;
        }),
      ),
      textTheme: _textThemeFor(brightness).apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
    );
  }

  static TextTheme _textThemeFor(Brightness brightness) {
    final baseTheme = brightness == Brightness.dark
        ? ThemeData.dark(useMaterial3: true).textTheme
        : ThemeData.light(useMaterial3: true).textTheme;

    return baseTheme.copyWith(
      bodyMedium: baseTheme.bodyMedium?.copyWith(height: 1.35),
      bodyLarge: baseTheme.bodyLarge?.copyWith(height: 1.35),
      titleMedium: baseTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      titleLarge: baseTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}
