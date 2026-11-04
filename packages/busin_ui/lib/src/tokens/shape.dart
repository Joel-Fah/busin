/// The shape scale, the same as the admin portal: rounded beyond normal, never a pill and never a
/// squircle. A shape drawn inside another uses [innerRadius], so corners stay concentric.
class BusinRadius {
  const BusinRadius._();

  static const double xs = 8;
  static const double sm = 16;
  static const double md = 20;
  static const double lg = 28;
  static const double xl = 36;

  /// The radius of a shape drawn [gap] logical pixels inside a shape of radius [outer].
  static double innerRadius(double outer, double gap) => (outer - gap).clamp(0, outer);

  /// The radius a container needs to wrap a shape of radius [inner] with [gap] of padding.
  static double outerRadius(double inner, double gap) => inner + gap;
}

/// Spacing on a 4 pixel grid.
class BusinSpace {
  const BusinSpace._();

  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x8 = 32;
  static const double x10 = 40;
  static const double x12 = 48;
}

/// Motion lengths, shared so screens feel alike. Honour the platform's reduced motion setting.
class BusinMotion {
  const BusinMotion._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
}
