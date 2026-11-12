import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Set<String> keysOf(String path) => (jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>)
    .keys
    .where((k) => !k.startsWith('@'))
    .toSet();

void main() {
  test('English and French have exactly the same strings', () {
    final en = keysOf('lib/src/l10n/busin_en.arb');
    final fr = keysOf('lib/src/l10n/busin_fr.arb');
    expect(fr.difference(en), isEmpty, reason: 'only in French');
    expect(en.difference(fr), isEmpty, reason: 'only in English');
  });

  test('no string holds an emoji', () {
    final emoji = RegExp(r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]', unicode: true);
    for (final file in ['busin_en.arb', 'busin_fr.arb']) {
      expect(emoji.hasMatch(File('lib/src/l10n/$file').readAsStringSync()), isFalse, reason: file);
    }
  });
}
