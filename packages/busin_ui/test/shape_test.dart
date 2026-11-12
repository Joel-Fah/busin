import 'package:busin_ui/busin_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the radius scale is the portal\'s, on a 4 pixel grid', () {
    expect([BusinRadius.xs, BusinRadius.sm, BusinRadius.md, BusinRadius.lg, BusinRadius.xl], [8, 16, 20, 28, 36]);
    for (final r in [BusinRadius.xs, BusinRadius.sm, BusinRadius.md, BusinRadius.lg, BusinRadius.xl]) {
      expect(r % 4, 0);
    }
  });

  test('nested corners stay concentric and never go negative', () {
    expect(BusinRadius.innerRadius(28, 12), 16);
    expect(BusinRadius.innerRadius(8, 12), 0);
    expect(BusinRadius.outerRadius(16, 12), 28);
    expect(BusinRadius.outerRadius(BusinRadius.innerRadius(28, 12), 12), 28);
  });
}
