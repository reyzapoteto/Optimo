import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

class AppFonts {
  static TextStyle body({bool arabic = false}) =>
      arabic ? GoogleFonts.notoSansArabic() : GoogleFonts.manrope();

  static TextStyle title(double size,
          {bool arabic = false, Color? color}) =>
      arabic
          ? GoogleFonts.notoSansArabic(
              fontSize: size - 6,
              fontWeight: FontWeight.w600,
              color: color ?? kTokens.ivory,
              height: 1.15)
          : GoogleFonts.cormorantGaramond(
              fontSize: size,
              fontWeight: FontWeight.w600,
              color: color ?? kTokens.ivory,
              height: 1.05);
}

ThemeData buildTheme({required bool arabic}) {
  const t = kTokens;
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: t.canvas,
    colorScheme: ColorScheme.dark(
      primary: t.yellow,
      onPrimary: AppTokens.onYellow,
      secondary: t.yellowSoft,
      surface: t.surface,
      onSurface: t.ivory,
      error: t.coral,
      outline: t.line,
    ),
    dividerColor: t.line,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: Colors.white.withOpacity(0.03),
    extensions: const [AppTokens()],
  );
  final textTheme = arabic
      ? GoogleFonts.notoSansArabicTextTheme(base.textTheme)
      : GoogleFonts.manropeTextTheme(base.textTheme);
  return base.copyWith(
    textTheme: textTheme.apply(bodyColor: t.ivory, displayColor: t.ivory),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: t.surface3,
        border: Border.all(color: t.line),
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: TextStyle(color: t.ivory, fontSize: 10),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStatePropertyAll(t.line),
      thickness: const WidgetStatePropertyAll(6),
    ),
    textSelectionTheme: TextSelectionThemeData(cursorColor: t.yellow),
  );
}
