import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'whatsapp_palette.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => _buildLight();
  static ThemeData get darkTheme => _buildDark();

  static ThemeData _buildLight() {
    const seed = WhatsAppPalette.tealBar;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
      primary: WhatsAppPalette.tealBar,
      onPrimary: Colors.white,
      secondary: WhatsAppPalette.accentGreen,
      onSecondary: Colors.white,
      surface: WhatsAppPalette.listBackground,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: WhatsAppPalette.listBackground,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: WhatsAppPalette.tealBar,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Color(0xFFB2DFDB),
        indicatorColor: Colors.white,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: WhatsAppPalette.accentGreen,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        minLeadingWidth: 56,
        titleTextStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: Color(0xFF111B21)),
        subtitleTextStyle: TextStyle(fontSize: 14, color: WhatsAppPalette.subtitleGrey),
      ),
      dividerTheme: const DividerThemeData(color: WhatsAppPalette.divider, thickness: 1, space: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: WhatsAppPalette.accentGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      inputDecorationTheme: _inputDecorationThemeLight(),
    );
  }

  static ThemeData _buildDark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: WhatsAppPalette.darkAppBar,
      brightness: Brightness.dark,
      primary: const Color(0xFF00A884),
      onPrimary: Colors.white,
      secondary: WhatsAppPalette.accentGreen,
      surface: WhatsAppPalette.darkBackground,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: WhatsAppPalette.darkBackground,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: WhatsAppPalette.darkAppBar,
        foregroundColor: Color(0xFFE9EDEF),
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: Color(0xFFE9EDEF),
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
        iconTheme: IconThemeData(color: Color(0xFFE9EDEF)),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Color(0xFFE9EDEF),
        unselectedLabelColor: Color(0xFF8696A0),
        indicatorColor: Color(0xFF00A884),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: WhatsAppPalette.accentGreen,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        minLeadingWidth: 56,
        titleTextStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: Color(0xFFE9EDEF)),
        subtitleTextStyle: TextStyle(fontSize: 14, color: Color(0xFF8696A0)),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF2A3942), thickness: 1, space: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: WhatsAppPalette.accentGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      inputDecorationTheme: _inputDecorationThemeDark(),
    );
  }

  static InputDecorationTheme _inputDecorationThemeLight() {
    const radius = BorderRadius.all(Radius.circular(8));
    return InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      border: const OutlineInputBorder(borderRadius: radius),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: Color(0xFFCCCCCC), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: WhatsAppPalette.tealBar, width: 1.5),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: Colors.red, width: 1.2),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  static InputDecorationTheme _inputDecorationThemeDark() {
    const radius = BorderRadius.all(Radius.circular(8));
    return InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: const Color(0xFF2A3942),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      border: const OutlineInputBorder(borderRadius: radius),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: Colors.grey.shade700, width: 1),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: Color(0xFF00A884), width: 1.5),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: Colors.red, width: 1.2),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: Colors.red, width: 1.5),
      ),
      labelStyle: const TextStyle(color: Color(0xFF8696A0)),
      hintStyle: const TextStyle(color: Color(0xFF8696A0)),
    );
  }
}
