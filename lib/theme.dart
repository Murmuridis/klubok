import 'package:flutter/material.dart';

/// Палитра «шерстяных» цветов и стили текста.
class Wool {
  static const cream = Color(0xFFF4EBDD);
  static const oat = Color(0xFFE8DAC6);
  static const rose = Color(0xFFC9737F);
  static const berry = Color(0xFF8E3B4A);
  static const sage = Color(0xFF7F9C7A);
  static const mustard = Color(0xFFD9A441);
  static const denim = Color(0xFF5F7FA3);
  static const brown = Color(0xFF4B3A33);
  static const brownSoft = Color(0xFF7A675E);
  static const white = Color(0xFFFFFDF8);

  /// Цвета клубков для счётчиков (по кругу).
  static const counterColors = <Color>[rose, denim, sage, mustard];

  /// Цвета для образца пряжи.
  static const yarnPalette = <Color>[
    Color(0xFFFFFDF8),
    Color(0xFFF1E3C8),
    Color(0xFFD9C2A3),
    Color(0xFFD9A441),
    Color(0xFFD9793B),
    Color(0xFFB5583C),
    Color(0xFFC0392B),
    Color(0xFFB03060),
    Color(0xFFC9737F),
    Color(0xFFE8B4BC),
    Color(0xFFB59BC8),
    Color(0xFF7B5EA7),
    Color(0xFF34496B),
    Color(0xFF5F7FA3),
    Color(0xFFA9C7E0),
    Color(0xFF4FA3A5),
    Color(0xFF2E7D5B),
    Color(0xFF7F9C7A),
    Color(0xFF8A8B3A),
    Color(0xFF7A5540),
    Color(0xFFA8A8A8),
    Color(0xFF4A4A4F),
    Color(0xFF2B2B2B),
  ];

  static Color darker(Color c, [double amount = 0.14]) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  static Color lighter(Color c, [double amount = 0.14]) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  static bool isLight(Color c) => c.computeLuminance() > 0.55;

  static const title = TextStyle(
    fontFamily: 'Pacifico',
    fontSize: 30,
    height: 1.25,
    color: berry,
  );
  static const heading = TextStyle(
    fontFamily: 'Pacifico',
    fontSize: 21,
    height: 1.25,
    color: berry,
  );
  static const body = TextStyle(fontSize: 15, color: brown, height: 1.3);
  static const bodyBold = TextStyle(
    fontSize: 15,
    color: brown,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );
  static const soft = TextStyle(fontSize: 13.5, color: brownSoft, height: 1.3);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: Wool.rose,
    brightness: Brightness.light,
  ).copyWith(
    primary: Wool.rose,
    onPrimary: Wool.white,
    secondary: Wool.sage,
    onSecondary: Wool.white,
    surface: Wool.cream,
    onSurface: Wool.brown,
    error: Wool.berry,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Balsamiq',
    scaffoldBackgroundColor: Wool.cream,
  );

  OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: Wool.brown,
      displayColor: Wool.brown,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Wool.berry,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Pacifico',
        fontSize: 24,
        color: Wool.berry,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Wool.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border(Wool.oat, 1.5),
      enabledBorder: border(Wool.oat, 1.5),
      focusedBorder: border(Wool.rose, 2),
      labelStyle: const TextStyle(color: Wool.brownSoft),
      floatingLabelStyle: const TextStyle(color: Wool.berry),
      hintStyle: const TextStyle(color: Color(0xFFA8978D)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Wool.berry,
      behavior: SnackBarBehavior.floating,
      contentTextStyle: const TextStyle(
        fontFamily: 'Balsamiq',
        fontSize: 15,
        color: Wool.white,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Wool.cream,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      titleTextStyle: const TextStyle(
        fontFamily: 'Pacifico',
        fontSize: 22,
        color: Wool.berry,
      ),
      contentTextStyle: const TextStyle(
        fontFamily: 'Balsamiq',
        fontSize: 15,
        color: Wool.brown,
        height: 1.35,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Wool.cream,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: Wool.rose,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Wool.berry,
        textStyle: const TextStyle(
          fontFamily: 'Balsamiq',
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? Wool.white : Wool.brownSoft,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? Wool.rose : Wool.oat,
      ),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    iconTheme: const IconThemeData(color: Wool.berry),
    popupMenuTheme: PopupMenuThemeData(
      color: Wool.cream,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
