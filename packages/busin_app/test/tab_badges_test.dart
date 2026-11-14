import 'package:busin_app/busin_app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _badges = NotifierProvider<TabBadges, Set<int>>(TabBadges.new);

void main() {
  test('news for another tab marks it; opening the tab clears it', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final badges = container.read(_badges.notifier);
    badges.opened(2);
    badges.mark([0, 1]);
    expect(container.read(_badges), {0, 1});
    badges.opened(0);
    expect(container.read(_badges), {1});
  });

  test('news for the tab on screen is not marked: it is in view', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final badges = container.read(_badges.notifier);
    badges.opened(1);
    badges.mark([1]);
    expect(container.read(_badges), isEmpty);
  });
}
