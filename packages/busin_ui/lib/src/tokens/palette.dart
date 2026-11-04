import 'package:flutter/material.dart';

/// The colours of BusIn, the same as the admin portal's tokens (app/globals.css), so every tier
/// looks like one product. Read them from the theme (`BusinPalette.of(context)`); never hard-code
/// a colour in a widget. State is never carried by colour alone: pair it with a label or icon.
@immutable
class BusinPalette extends ThemeExtension<BusinPalette> {
  const BusinPalette({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.fg,
    required this.muted,
    required this.line,
    required this.brand,
    required this.onBrand,
    required this.accent,
    required this.onAccent,
    required this.link,
    required this.ok,
    required this.okBg,
    required this.warn,
    required this.warnBg,
    required this.bad,
    required this.badBg,
    required this.info,
    required this.infoBg,
  });

  /// Brand deep teal and brand orange.
  static const Color seed = Color(0xFF002A33);
  static const Color orange = Color(0xFFF5951F);

  static const BusinPalette light = BusinPalette(
    bg: Color(0xFFF4F8F8),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFE8F1F2),
    fg: Color(0xFF002A33),
    muted: Color(0xFF4D6A70),
    line: Color(0xFFD2E1E3),
    brand: Color(0xFF002A33),
    onBrand: Color(0xFFFFFFFF),
    accent: orange,
    onAccent: Color(0xFF002A33),
    link: Color(0xFF087282),
    ok: Color(0xFF0B7A43),
    okBg: Color(0xFFE2F4EA),
    warn: Color(0xFF8A6100),
    warnBg: Color(0xFFFBF0CF),
    bad: Color(0xFFB3261E),
    badBg: Color(0xFFFBE5E3),
    info: Color(0xFF1A56C4),
    infoBg: Color(0xFFE3ECFB),
  );

  static const BusinPalette dark = BusinPalette(
    bg: Color(0xFF00181D),
    surface: Color(0xFF002A33),
    surface2: Color(0xFF06404B),
    fg: Color(0xFFE6F4F4),
    muted: Color(0xFF9DBDC1),
    line: Color(0xFF14505C),
    brand: Color(0xFFE6F4F4),
    onBrand: Color(0xFF00181D),
    accent: orange,
    onAccent: Color(0xFF002A33),
    link: Color(0xFF54D8E8),
    ok: Color(0xFF4CD08A),
    okBg: Color(0xFF0C3A28),
    warn: Color(0xFFFFD24D),
    warnBg: Color(0xFF3D3208),
    bad: Color(0xFFFF8A80),
    badBg: Color(0xFF4A1714),
    info: Color(0xFF8AB4FF),
    infoBg: Color(0xFF14305E),
  );

  final Color bg;
  final Color surface;
  final Color surface2;
  final Color fg;
  final Color muted;
  final Color line;
  final Color brand;
  final Color onBrand;
  final Color accent;
  final Color onAccent;
  final Color link;
  final Color ok;
  final Color okBg;
  final Color warn;
  final Color warnBg;
  final Color bad;
  final Color badBg;
  final Color info;
  final Color infoBg;

  /// The palette of the current theme. Falls back to light when a theme was not built by BusinTheme.
  static BusinPalette of(BuildContext context) =>
      Theme.of(context).extension<BusinPalette>() ?? light;

  /// The text and background pairs that must reach WCAG AA (4.5:1). The tests check them.
  List<(String, Color, Color)> get textPairs => [
        ('fg on bg', fg, bg),
        ('fg on surface', fg, surface),
        ('muted on surface', muted, surface),
        ('muted on surface2', muted, surface2),
        ('on-brand on brand', onBrand, brand),
        ('on-accent on accent', onAccent, accent),
        ('link on surface', link, surface),
        ('ok on ok-bg', ok, okBg),
        ('warn on warn-bg', warn, warnBg),
        ('bad on bad-bg', bad, badBg),
        ('info on info-bg', info, infoBg),
      ];

  @override
  BusinPalette copyWith({Color? bg}) => BusinPalette(
        bg: bg ?? this.bg,
        surface: surface,
        surface2: surface2,
        fg: fg,
        muted: muted,
        line: line,
        brand: brand,
        onBrand: onBrand,
        accent: accent,
        onAccent: onAccent,
        link: link,
        ok: ok,
        okBg: okBg,
        warn: warn,
        warnBg: warnBg,
        bad: bad,
        badBg: badBg,
        info: info,
        infoBg: infoBg,
      );

  @override
  BusinPalette lerp(ThemeExtension<BusinPalette>? other, double t) {
    if (other is! BusinPalette) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return BusinPalette(
      bg: mix(bg, other.bg),
      surface: mix(surface, other.surface),
      surface2: mix(surface2, other.surface2),
      fg: mix(fg, other.fg),
      muted: mix(muted, other.muted),
      line: mix(line, other.line),
      brand: mix(brand, other.brand),
      onBrand: mix(onBrand, other.onBrand),
      accent: mix(accent, other.accent),
      onAccent: mix(onAccent, other.onAccent),
      link: mix(link, other.link),
      ok: mix(ok, other.ok),
      okBg: mix(okBg, other.okBg),
      warn: mix(warn, other.warn),
      warnBg: mix(warnBg, other.warnBg),
      bad: mix(bad, other.bad),
      badBg: mix(badBg, other.badBg),
      info: mix(info, other.info),
      infoBg: mix(infoBg, other.infoBg),
    );
  }
}

/// WCAG contrast ratio between two colours (1 to 21).
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}
