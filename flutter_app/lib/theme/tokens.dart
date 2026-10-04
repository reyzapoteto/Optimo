import 'package:flutter/material.dart';

/// Design tokens mirrored from src/index.css / product.css.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    this.canvas = const Color(0xFF0B0B09),
    this.sidebar = const Color(0xFF0E0E0C),
    this.surface = const Color(0xFF131411),
    this.surface2 = const Color(0xFF181916),
    this.surface3 = const Color(0xFF1D1E1A),
    this.line = const Color(0xFF292A25),
    this.lineSoft = const Color(0xFF22231F),
    this.ivory = const Color(0xFFF0EEE5),
    this.muted = const Color(0xFF96988F),
    this.muted2 = const Color(0xFF696C64),
    this.yellow = const Color(0xFFF3E533),
    this.yellowSoft = const Color(0xFFC8BD31),
    this.green = const Color(0xFF75A88B),
    this.coral = const Color(0xFFD47A66),
    this.cyan = const Color(0xFF6D9DA3),
  });

  final Color canvas, sidebar, surface, surface2, surface3, line, lineSoft;
  final Color ivory, muted, muted2, yellow, yellowSoft, green, coral, cyan;

  static const Color chipActiveBg = Color(0xFF272718);
  static const Color chipActiveBorder = Color(0xFF504D25);
  static const Color badgeBorder = Color(0xFF4C4922);
  static const Color primaryHover = Color(0xFFFFF256);
  static const Color dangerHover = Color(0xFFE08B78);
  static const Color track = Color(0xFF262820);
  static const Color avatar = Color(0xFF2A2B26);
  static const Color filterBg = Color(0xFF1A1A10);
  static const Color filterBorder = Color(0xFF35331D);
  static const Color modebar = Color(0xFF10110E);
  static const Color onYellow = Color(0xFF11120D);

  static const double r8 = 8, r12 = 12, r16 = 16;

  @override
  AppTokens copyWith() => this;

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) => this;
}

const AppTokens kTokens = AppTokens();

extension TokensX on BuildContext {
  AppTokens get tk => Theme.of(this).extension<AppTokens>() ?? kTokens;
}

/// Operational tone used by pills, markers and charts.
enum Tone { ready, attention, critical, cleaning, muted }

Color toneColor(Tone t) {
  switch (t) {
    case Tone.ready:
      return kTokens.green;
    case Tone.attention:
      return kTokens.yellow;
    case Tone.critical:
      return kTokens.coral;
    case Tone.cleaning:
      return kTokens.cyan;
    case Tone.muted:
      return kTokens.muted;
  }
}
