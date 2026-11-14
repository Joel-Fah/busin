import 'package:busin_core/busin_core.dart';
import 'package:test/test.dart';

void main() {
  group('installment plans', () {
    test('are read and written by their stored code', () {
      for (final plan in InstallmentPlan.values) {
        expect(InstallmentPlan.parse(plan.code), plan);
        expect(plan.percents.fold(0, (a, b) => a + b), 100, reason: plan.code);
      }
      expect(() => InstallmentPlan.parse('20-80'), throwsFormatException);
      expect(InstallmentPlan.tryParse(null), isNull);
    });

    test('split a price into parts that add up exactly, the last taking what is left', () {
      expect(InstallmentPlan.thirds.split(30000), [12000, 9000, 9000]);
      expect(InstallmentPlan.halves.split(25001), [12500, 12501]);
      expect(InstallmentPlan.smallLast.split(10001), [3000, 6000, 1001]);
      for (final plan in InstallmentPlan.values) {
        for (final total in [1, 7, 99, 12345, 9999999]) {
          expect(plan.split(total).fold(0, (a, b) => a + b), total, reason: '${plan.code} of $total');
        }
      }
    });
  });

  test('a school with billing set, and one without', () {
    final json = {'id': 's1', 'name': 'School', 'timezone': 'Africa/Douala', 'status': 'active'};
    expect(School.fromJson(json).billingSet, isFalse);
    final set = School.fromJson({...json, 'billing_period': 'semester', 'price_xaf': 30000, 'installment_plan': '40-30-30', 'currency': 'XAF'});
    expect(set.billingSet, isTrue);
    expect(set.installmentPlan, InstallmentPlan.thirds);
    expect(School.fromJson(set.toJson()), set);
  });

  group('subscriptions', () {
    final base = {
      'id': 'sub1',
      'school_id': 's1',
      'student_id': 'u1',
      'semester_id': 'sem1',
      'stop_id': 'stop1',
      'status': 'approved',
      'created_at': '2026-11-01T08:00:00Z',
      'updated_at': '2026-11-01T08:00:00Z',
    };
    final start = DateTime.utc(2026, 9, 1);
    final end = DateTime.utc(2027, 1, 31);

    test('an older one, without billing, covers its semester and pays in full', () {
      final sub = Subscription.fromJson(base);
      expect(sub.paymentMode, PaymentMode.full);
      expect(sub.amountXaf, isNull);
      expect(sub.covers(DateTime.utc(2026, 12, 15), semesterStart: start, semesterEnd: end), isTrue);
      expect(sub.coversUntil(end), end);
    });

    test('a monthly one covers its month only', () {
      final sub = Subscription.fromJson({...base, 'billing_period': 'month', 'amount_xaf': 5000, 'period_start': '2026-11-01', 'period_end': '2026-11-30'});
      expect(sub.covers(DateTime.utc(2026, 11, 30), semesterStart: start, semesterEnd: end), isTrue);
      expect(sub.covers(DateTime.utc(2026, 12, 1), semesterStart: start, semesterEnd: end), isFalse);
      expect(sub.coversUntil(end), DateTime.utc(2026, 11, 30));
      expect(Subscription.fromJson(sub.toJson()), sub);
    });

    test('a request sends how the student pays and the month, never a price', () {
      final json = NewSubscription(schoolId: 's1', studentId: 'u1', semesterId: 'sem1', stopId: 'stop1', proofPath: 's1/u1/a.jpg', periodStart: DateTime.utc(2026, 12, 1)).toJson();
      expect(json['payment_mode'], 'full');
      expect(json['period_start'], '2026-12-01');
      expect(json.containsKey('amount_xaf'), isFalse);
      expect(NewSubscription(schoolId: 's1', studentId: 'u1', semesterId: 'sem1', stopId: 'stop1', proofPath: 'p', paymentMode: PaymentMode.installments).toJson().containsKey('period_start'), isFalse);
    });
  });

  test('a profile keeps its payment preference', () {
    final json = {
      'id': 'u1',
      'email': 'a@b.c',
      'full_name': 'Ada',
      'role': 'student',
      'status': 'verified',
      'created_at': '2026-11-01T08:00:00Z',
      'updated_at': '2026-11-01T08:00:00Z',
      'payment_preference': 'installments',
    };
    final profile = Profile.fromJson(json);
    expect(profile.paymentPreference, PaymentMode.installments);
    expect(Profile.fromJson(profile.toJson()).paymentPreference, PaymentMode.installments);
  });
}
