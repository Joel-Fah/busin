import 'package:busin_core/busin_core.dart';
import 'package:test/test.dart';

void main() {
  group('fullName', () {
    test('needs something real', () {
      expect(ProfileValidation.fullName(null), ProfileFieldProblem.empty);
      expect(ProfileValidation.fullName('   '), ProfileFieldProblem.empty);
      expect(ProfileValidation.fullName('A'), ProfileFieldProblem.tooShort);
      expect(ProfileValidation.fullName('Ada Lovelace'), isNull);
      expect(ProfileValidation.fullName('x' * 81), ProfileFieldProblem.tooLong);
    });
  });

  group('matricule', () {
    test('accepts student numbers as schools write them', () {
      for (final ok in ['ICT2026-0001', 'ict/22/0457', 'A1.23', '20230457']) {
        expect(ProfileValidation.matricule(ok), isNull, reason: ok);
      }
    });

    test('refuses empty, tiny, huge and odd characters', () {
      expect(ProfileValidation.matricule(''), ProfileFieldProblem.empty);
      expect(ProfileValidation.matricule('A1'), ProfileFieldProblem.tooShort);
      expect(ProfileValidation.matricule('A' * 33), ProfileFieldProblem.tooLong);
      expect(ProfileValidation.matricule('ICT<script>'), ProfileFieldProblem.invalid);
      expect(ProfileValidation.matricule('-123'), ProfileFieldProblem.invalid);
    });
  });

  group('phone', () {
    test('accepts a real number typed with or without its country code (ADR 0024)', () {
      for (final ok in ['677 12 34 56', '+237 677-123-456', '0677123456', '+33 6 12 34 56 78']) {
        expect(ProfileValidation.phone(ok, 'CM'), isNull, reason: ok);
      }
    });

    test('refuses empty, letters and numbers that do not exist', () {
      expect(ProfileValidation.phone('', 'CM'), ProfileFieldProblem.empty);
      expect(ProfileValidation.phone('call me', 'CM'), ProfileFieldProblem.invalid);
      expect(ProfileValidation.phone('12345', 'CM'), ProfileFieldProblem.invalid);
      expect(ProfileValidation.phone('1' * 16, 'CM'), ProfileFieldProblem.invalid);
    });

    test('is stored as E.164', () {
      expect(ProfileValidation.normalizePhone('+237 677-123-456', 'CM'), '+237677123456');
      expect(ProfileValidation.normalizePhone('677 12 34 56', 'CM'), '+237677123456');
    });
  });

  test('department and program are optional but bounded', () {
    expect(ProfileValidation.optionalText(null), isNull);
    expect(ProfileValidation.optionalText('  '), isNull);
    expect(ProfileValidation.optionalText('Computer science'), isNull);
    expect(ProfileValidation.optionalText('x' * 81), ProfileFieldProblem.tooLong);
  });

  test('setup is complete with a name, a student number and a phone', () {
    Profile build({String name = 'Ada', String? matricule, String? phone}) => Profile(
          id: 'u',
          schoolId: 's',
          email: 'a@b.c',
          fullName: name,
          role: UserRole.student,
          status: AccountStatus.verified,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
          matricule: matricule,
          phone: phone,
        );
    expect(build().isSetupComplete, isFalse);
    expect(build(matricule: 'ICT1').isSetupComplete, isFalse);
    expect(build(matricule: 'ICT1', phone: '677123456').isSetupComplete, isTrue);
    expect(build(name: ' ', matricule: 'ICT1', phone: '677123456').isSetupComplete, isFalse);
    expect(build(matricule: '  ', phone: '677123456').isSetupComplete, isFalse);
  });
}
