import 'package:flutter/widgets.dart';

/// How much room the app has. Layouts are chosen by width, never by device name, so a foldable, a split-screen
/// window and a tablet in landscape all do the right thing.
enum BusinLayout {
  /// Phones: one column, navigation in a floating bar.
  compact,

  /// Portrait tablets and large phones in landscape: one comfortable column (capped width), floating bar.
  medium,

  /// Landscape tablets and bigger: a side rail for navigation and room for two panes.
  expanded;

  /// Narrower than this is [compact].
  static const double mediumFrom = 600;

  /// This wide or wider is [expanded].
  static const double expandedFrom = 840;

  /// The widest a single reading column grows, so lines stay short on a tablet.
  static const double maxColumn = 640;

  /// The layout for a width in logical pixels.
  static BusinLayout forWidth(double width) {
    if (width >= expandedFrom) return BusinLayout.expanded;
    if (width >= mediumFrom) return BusinLayout.medium;
    return BusinLayout.compact;
  }

  /// The layout for the window the app is in now.
  static BusinLayout of(BuildContext context) => forWidth(MediaQuery.sizeOf(context).width);

  bool get isExpanded => this == BusinLayout.expanded;
  bool get isCompact => this == BusinLayout.compact;
}
