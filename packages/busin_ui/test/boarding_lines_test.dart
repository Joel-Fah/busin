import 'package:busin_ui/busin_ui.dart';
import 'package:flutter_test/flutter_test.dart';

final _emoji = RegExp(r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}]', unicode: true);

void main() {
  test('both languages have as many lines, short, with no emoji', () {
    final en = allBoardingLines('en');
    final fr = allBoardingLines('fr');
    expect(en.length, fr.length);
    expect(en.length, greaterThanOrEqualTo(85));
    for (final line in [...en, ...fr]) {
      expect(line.trim(), isNotEmpty);
      expect(line.length, lessThanOrEqualTo(90), reason: line);
      expect(_emoji.hasMatch(line), isFalse, reason: line);
    }
    expect(en.toSet().length, en.length, reason: 'no line twice');
  });

  test('a milestone ride gets its own line', () {
    final moment = BoardingMoment(at: DateTime(2026, 11, 11, 7, 30), rideNumber: 10);
    expect(boardingLine(moment, seed: 'a', languageCode: 'en'), 'Ten rides this semester. You know the way by now.');
    expect(boardingLine(moment, seed: 'a', languageCode: 'fr'), 'Dix trajets ce semestre. Vous connaissez la route.');
  });

  test('the same boarding always gets the same line, and different boardings vary', () {
    final moment = BoardingMoment(at: DateTime(2026, 11, 11, 7, 30), rideNumber: 7);
    final first = boardingLine(moment, seed: 'scan-1', languageCode: 'en');
    expect(boardingLine(moment, seed: 'scan-1', languageCode: 'en'), first);
    final picks = {for (var i = 0; i < 40; i++) boardingLine(moment, seed: 'scan-$i', languageCode: 'en')};
    expect(picks.length, greaterThan(10));
  });

  test('the line fits the moment: an evening Friday line never talks about the morning', () {
    final evening = BoardingMoment(at: DateTime(2026, 11, 13, 17, 45));
    final lines = {for (var i = 0; i < 200; i++) boardingLine(evening, seed: 'e$i', languageCode: 'en')};
    expect(lines.any((l) => l.contains('Good morning')), isFalse);
    expect(lines.contains('Friday ride. The weekend is close.'), isTrue);
  });

  test('semester phases and parts of the day', () {
    expect(phaseOf(DateTime(2026, 9, 5), DateTime(2026, 9, 1), DateTime(2027, 1, 31)), SemesterPhase.start);
    expect(phaseOf(DateTime(2027, 1, 25), DateTime(2026, 9, 1), DateTime(2027, 1, 31)), SemesterPhase.end);
    expect(phaseOf(DateTime(2026, 11, 11), DateTime(2026, 9, 1), DateTime(2027, 1, 31)), SemesterPhase.middle);
    expect(BoardingMoment(at: DateTime(2026, 1, 1, 6, 50)).dayPart, DayPart.early);
    expect(BoardingMoment(at: DateTime(2026, 1, 1, 12)).dayPart, DayPart.midday);
  });
}
