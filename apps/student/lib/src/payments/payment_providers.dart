import 'package:busin_core/busin_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

/// Mobile money payments (ADR 0029): what paying costs, and the student's own payments.
final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) => ref.watch(repositoriesProvider).payments);

/// What a subscription costs at the student's school, by receipt and by each operator. No mobile money line means the
/// school does not offer it (or it cannot be used now): then the form asks for a receipt as before. A failure counts as
/// no mobile money, so a receipt can always be sent.
final priceLinesProvider = FutureProvider.autoDispose<List<PriceLine>>((ref) async {
  try {
    return await ref.watch(paymentsRepositoryProvider).priceBreakdown();
  } on RepositoryException {
    return const [];
  }
}, retry: noAutomaticRetry);

/// What paying one thing costs with each operator.
final paymentQuoteProvider = FutureProvider.autoDispose.family<List<PaymentQuote>, ({PaymentPurpose purpose, String targetId})>(
  (ref, item) => ref.watch(paymentsRepositoryProvider).quote(purpose: item.purpose, targetId: item.targetId),
  retry: noAutomaticRetry,
);

/// The student's recent payments, newest first, to pick a waiting one up again and to show receipts.
final myPaymentsProvider = FutureProvider.autoDispose<List<Payment>>(
  (ref) => ref.watch(paymentsRepositoryProvider).mine(page: const PageRequest(limit: 30)),
  retry: noAutomaticRetry,
);

/// The refunds of the student's payments, newest first.
final myRefundsProvider = FutureProvider.autoDispose<List<Refund>>(
  (ref) => ref.watch(paymentsRepositoryProvider).myRefunds(page: const PageRequest(limit: 30)),
  retry: noAutomaticRetry,
);

/// The newest payment for a request (in full or its first part) or for a part, among [payments].
Payment? latestPaymentFor(List<Payment> payments, {String? subscriptionId, String? installmentId}) {
  for (final p in payments) {
    if (installmentId != null
        ? p.installmentId == installmentId
        : (p.subscriptionId == subscriptionId && p.purpose == PaymentPurpose.subscription)) {
      return p;
    }
  }
  return null;
}
