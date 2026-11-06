import 'package:flutter/services.dart';

/// Small physical feedback for the moments that deserve it. A failure to vibrate is never an error.
class BusinHaptics {
  const BusinHaptics._();

  /// Moving between choices: tabs, pickers.
  static void selection() => _run(HapticFeedback.selectionClick);

  /// Confirming a press.
  static void light() => _run(HapticFeedback.lightImpact);

  /// Something happened that the person should feel: a code refreshing, a decision arriving.
  static void medium() => _run(HapticFeedback.mediumImpact);

  static void _run(Future<void> Function() feedback) {
    try {
      feedback();
    } catch (_) {}
  }
}
