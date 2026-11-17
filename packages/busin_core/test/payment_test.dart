import 'package:busin_core/busin_core.dart';
import 'package:test/test.dart';

void main() {
  group('MobileMoneyNumber', () {
    test('reads numbers the way people type them, like the server', () {
      for (final typed in ['653456789', '6 53 45 67 89', '+237 653 456 789', '00237653456789', '237653456789']) {
        expect(MobileMoneyNumber.normalize(typed), '237653456789', reason: typed);
      }
      for (final bad in ['', '53456789', '233653456789', '2376534567890', '237253456789']) {
        expect(MobileMoneyNumber.normalize(bad), isNull, reason: bad);
      }
    });

    test('guesses the operator from the first digits, as they are typed', () {
      expect(MobileMoneyNumber.guessOperator('65'), isNull);
      expect(MobileMoneyNumber.guessOperator('653'), MobileMoneyOperator.mtn);
      expect(MobileMoneyNumber.guessOperator('67'), MobileMoneyOperator.mtn);
      expect(MobileMoneyNumber.guessOperator('+237 69'), MobileMoneyOperator.orange);
      expect(MobileMoneyNumber.guessOperator('655 00'), MobileMoneyOperator.orange);
      expect(MobileMoneyNumber.guessOperator('662'), isNull);
    });

    test('shows a number in groups', () {
      expect(MobileMoneyNumber.display('237653456789'), '6 53 45 67 89');
    });
  });

  group('Payment', () {
    final json = {
      'id': 'p1',
      'purpose': 'subscription',
      'subscription_id': 's1',
      'installment_id': null,
      'amount_xaf': 20000,
      'fee_xaf': 445,
      'total_xaf': 20445,
      'provider': 'ORANGE_CMR',
      'payer_masked': '2376*****789',
      'status': 'failed',
      'failure_code': 'INSUFFICIENT_BALANCE',
      'provider_txn': null,
      'receipt_no': null,
      'outcome': null,
      'created_at': '2026-11-17T08:00:00Z',
      'completed_at': null,
    };

    test('reads a row and gives it back the same', () {
      final payment = Payment.fromJson(json);
      expect(payment.operator, MobileMoneyOperator.orange);
      expect(payment.failure, PaymentFailure.insufficientBalance);
      expect(Payment.fromJson(payment.toJson()), payment);
    });

    test('a waiting payment has no failure; every pawaPay stage counts as waiting', () {
      for (final code in ['initiated', 'accepted', 'processing', 'in_reconciliation']) {
        final payment = Payment.fromJson({...json, 'status': code, 'failure_code': null});
        expect(payment.status.waiting, isTrue, reason: code);
        expect(payment.failure, isNull);
      }
      expect(PaymentStatus.parse('completed').waiting, isFalse);
      expect(PaymentStatus.parse('needs_attention').waiting, isFalse);
    });

    test('a completed payment the request could no longer take is being refunded', () {
      final payment = Payment.fromJson({...json, 'status': 'completed', 'failure_code': null, 'outcome': 'refunded', 'receipt_no': 'BI-2026-000001'});
      expect(payment.refunded, isTrue);
    });

    test('failure codes map to reasons, unknown ones to other', () {
      expect(PaymentFailure.fromCode('PAYMENT_NOT_APPROVED'), PaymentFailure.notApproved);
      expect(PaymentFailure.fromCode('PROVIDER_TEMPORARILY_UNAVAILABLE'), PaymentFailure.operatorDown);
      expect(PaymentFailure.fromCode('NOT_FOUND'), PaymentFailure.notReached);
      expect(PaymentFailure.fromCode('SOMETHING_NEW'), PaymentFailure.other);
      expect(PaymentFailure.fromCode(null), PaymentFailure.other);
    });
  });

  group('PriceLine', () {
    test('mobile money is offered when an operator has a line', () {
      final lines = [
        PriceLine.fromJson({'method': 'receipt', 'student_pays': 20700, 'busin_charge': 700, 'transaction_cost': 0, 'school_receives': 20000}),
        PriceLine.fromJson({'method': 'MTN_MOMO_CMR', 'student_pays': 21160, 'busin_charge': 700, 'transaction_cost': 419, 'school_receives': 20000}),
      ];
      expect(lines.offersMobileMoney, isTrue);
      expect(lines.receipt?.studentPays, 20700);
      expect(lines.forOperator(MobileMoneyOperator.mtn)?.studentPays, 21160);
      expect(lines.forOperator(MobileMoneyOperator.orange), isNull);
      expect([lines.first].offersMobileMoney, isFalse);
    });
  });

  group('Subscriptions paid by mobile money', () {
    test('a request without a receipt says so, and is sent without a proof', () {
      const request = NewSubscription(schoolId: 'sc', studentId: 'st', semesterId: 'se', stopId: 'sp', paymentMethod: PaymentMethod.mobileMoney);
      expect(request.toJson().containsKey('proof_path'), isFalse);
      expect(request.toJson()['payment_method'], 'mobile_money');
      const receipt = NewSubscription(schoolId: 'sc', studentId: 'st', semesterId: 'se', stopId: 'sp', proofPath: 'sc/st/r.jpg');
      expect(receipt.toJson().containsKey('payment_method'), isFalse);
    });
  });
}
