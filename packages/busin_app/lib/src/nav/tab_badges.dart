import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The navigation tabs with something new waiting on them while the app is open: a decision on a subscription, a code
/// ready, a trip to drive. The app's shell shows a dot on those tabs and clears one when its tab is opened. News for the
/// tab on screen is not marked: it is already in view. Kept in memory only; a fresh start begins with none.
class TabBadges extends Notifier<Set<int>> {
  int _current = 0;

  /// The tab last opened.
  int get current => _current;

  @override
  Set<int> build() => const <int>{};

  /// The tab on screen now, which clears its badge.
  void opened(int tab) {
    _current = tab;
    if (state.contains(tab)) state = {...state}..remove(tab);
  }

  /// Something new for [tabs]; the one on screen is left alone.
  void mark(Iterable<int> tabs) {
    final next = {...state, ...tabs.where((t) => t != _current)};
    if (next.length != state.length) state = next;
  }
}
