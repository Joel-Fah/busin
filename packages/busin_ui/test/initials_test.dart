import 'package:busin_ui/busin_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('two words give the first letters of each', () {
    expect(initialsOf('Ada Lovelace'), 'AL');
    expect(initialsOf('  grace   hopper  '), 'GH');
  });

  test('falls back to the email, then one word, then a placeholder', () {
    expect(initialsOf('', 'ada.lovelace@school.edu'), 'AL');
    expect(initialsOf('Cher'), 'CH');
    expect(initialsOf('X'), 'X');
    expect(initialsOf(null, null), '?');
    expect(initialsOf('  ', ''), '?');
  });
}
