import 'package:flutter/widgets.dart';

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

/// Motion, the same lengths and easing as the admin portal (app/theme.css): 160 ms for presses, 280 ms for
/// menus, tabs and cards, 520 ms for larger moves, all on one soft curve. Under the platform's reduced-motion
/// setting every duration collapses (use [of]), so nothing moves.
class BusinMotion {
  const BusinMotion._();

  static const Duration fast = Duration(milliseconds: 160);
  static const Duration normal = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 520);

  /// The portal's `--ease-soft`: cubic-bezier(0.22, 1, 0.36, 1).
  static const Curve soft = Cubic(0.22, 1, 0.36, 1);

  /// True when the person has asked the system for less motion.
  static bool reduced(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [duration], or no time at all when motion is reduced.
  static Duration of(BuildContext context, Duration duration) => reduced(context) ? Duration.zero : duration;
}
