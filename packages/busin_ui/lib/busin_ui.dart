/// The BusIn design system for the Flutter apps: palette, shape scale, the Material 3 themes in
/// Plus Jakarta Sans, shared widgets and English and French strings.
///
/// It matches the admin portal (see the `/styleguide` page and docs/decisions/0009-design-system.md).
/// No data access lives here.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'src/l10n/busin_l10n.dart';

export 'src/l10n/busin_l10n.dart';
export 'src/l10n/labels.dart';
export 'src/brand/brand_intro.dart';
export 'src/brand/brand_paths.dart';
export 'src/layout/adaptive_scaffold.dart';
export 'src/layout/nav.dart';
export 'src/layout/nav_indicator.dart';
export 'src/painters/contour.dart';
export 'src/painters/grain.dart';
export 'src/painters/marked_text.dart';
export 'src/theme/busin_theme.dart';
export 'src/tokens/breakpoints.dart';
export 'src/tokens/elevation.dart';
export 'src/tokens/palette.dart';
export 'src/tokens/ramps.dart';
export 'src/tokens/shape.dart';
export 'src/widgets/busin_banner.dart';
export 'src/widgets/busin_button.dart';
export 'src/widgets/busin_card.dart';
export 'src/widgets/busin_sheet.dart';
export 'src/widgets/busin_text_field.dart';
export 'src/widgets/busin_toast.dart';
export 'src/widgets/segmented.dart';
export 'src/widgets/empty_state.dart';
export 'src/widgets/field_tile.dart';
export 'src/widgets/haptics.dart';
export 'src/widgets/illustration.dart';
export 'src/widgets/initials.dart';
export 'src/widgets/notice.dart';
export 'src/widgets/skeleton.dart';
export 'src/widgets/staggered_in.dart';
export 'src/widgets/step_line.dart';
export 'src/widgets/stat_card.dart';
export 'src/widgets/status_chip.dart';
export 'src/widgets/user_avatar.dart';

/// Everything an app passes to `MaterialApp` for BusIn's languages: its own strings and the
/// framework's, for English and French.
const List<LocalizationsDelegate<dynamic>> businLocalizationsDelegates = [
  BusinL10n.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

const List<Locale> businSupportedLocales = BusinL10n.supportedLocales;
