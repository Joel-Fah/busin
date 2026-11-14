import 'package:busin_core/busin_core.dart';
import 'package:test/test.dart';

void main() {
  group('reading a typed number for its country', () {
    test('a Cameroonian number, typed in any usual way, is stored in one form', () {
      for (final typed in ['677 12 34 56', '677123456', '0677123456', '+237 677-123-456', '+237677123456']) {
        expect(PhoneNumbers.parse(typed, 'CM').e164, '+237677123456', reason: typed);
      }
    });

    test('a number starting with + keeps its own country, whatever the field says', () {
      expect(PhoneNumbers.parse('+33 6 12 34 56 78', 'CM').e164, '+33612345678');
    });

    test('a national trunk 0 is dropped where the country uses one', () {
      expect(PhoneNumbers.parse('06 12 34 56 78', 'FR').e164, '+33612345678');
      expect(PhoneNumbers.parse('07400 123456', 'GB').e164, '+447400123456');
      // +44 is shared by several places: a Guernsey mobile typed with the UK chosen is still kept.
      expect(PhoneNumbers.parse('07911 123456', 'GB').e164, '+447911123456');
    });

    test('empty, letters or a number that does not exist are refused', () {
      expect(PhoneNumbers.parse('  ', 'CM').problem, PhoneProblem.empty);
      expect(PhoneNumbers.parse('call me', 'CM').problem, PhoneProblem.invalid);
      expect(PhoneNumbers.parse('12345', 'CM').problem, PhoneProblem.invalid);
      expect(PhoneNumbers.parse('1' * 16, 'CM').problem, PhoneProblem.invalid);
    });
  });

  test('a stored number is shown with spaces, in international form', () {
    expect(PhoneNumbers.display('+237677123456'), startsWith('+237 6'));
    expect(PhoneNumbers.display('+237677123456').replaceAll(' ', ''), '+237677123456');
    expect(PhoneNumbers.display('nonsense'), 'nonsense');
  });

  test('the stored form is checked and its country read', () {
    expect(PhoneNumbers.isE164('+237677123456'), isTrue);
    expect(PhoneNumbers.isE164('677123456'), isFalse);
    expect(PhoneNumbers.isE164('+237 677 12 34 56'), isFalse);
    expect(PhoneNumbers.countryOf('+33612345678'), 'FR');
    expect(PhoneNumbers.callingCode('CM'), '237');
  });

  test('typing is formatted the way the country writes it', () {
    expect(PhoneNumbers.formatTyping('677123456', 'CM').replaceAll(' ', ''), '677123456');
    expect(PhoneNumbers.formatTyping('677123456', 'CM'), contains(' '));
  });

  test('the field starts on the saved number, the school, the device, then the fallback', () {
    expect(PhoneNumbers.defaultCountry(saved: '+33612345678', schoolPhone: '+237677123456'), 'FR');
    expect(PhoneNumbers.defaultCountry(schoolPhone: '+237677123456', deviceRegion: 'US'), 'CM');
    expect(PhoneNumbers.defaultCountry(deviceRegion: 'ng'), 'NG');
    expect(PhoneNumbers.defaultCountry(), 'CM');
  });
}
