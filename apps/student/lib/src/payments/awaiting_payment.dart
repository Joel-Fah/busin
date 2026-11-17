import 'package:busin_core/busin_core.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../auth/access.dart';
import '../providers.dart';
import '../subscription/money.dart';
import '../subscription/pick_proof.dart';
import '../subscription/request_history.dart';
import '../subscription/subscription_providers.dart';
import 'pay_sheet.dart';
import 'payment_providers.dart';
import 'payment_text.dart';

/// Reads everything a payment changes: the overview, the payments, the history.
void refreshAfterPayment(WidgetRef ref) {
  ref.invalidate(subscriptionOverviewProvider);
  ref.invalidate(myPaymentsProvider);
  ref.invalidate(myRefundsProvider);
  ref.invalidate(requestHistoryProvider);
}

/// Sends a receipt for a pending mobile money request whose payment did not go through (ADR 0029). True once sent.
Future<bool> sendReceiptInstead(BuildContext context, WidgetRef ref, Subscription subscription) async {
  final l10n = BusinL10n.of(context);
  final access = ref.read(accessProvider);
  if (access is! Allowed) return false;
  final proof = await pickProof(
    context,
    ref,
    onProblem: (message) {
      if (context.mounted) BusinToast.show(context, message, tone: ToastTone.error);
    },
  );
  if (proof == null || !context.mounted) return false;
  try {
    final path = await ref
        .read(proofsRepositoryProvider)
        .upload(schoolId: access.profile.schoolId!, studentId: access.profile.id, bytes: proof.bytes, contentType: proof.contentType);
    await ref.read(subscriptionsRepositoryProvider).attachProof(subscriptionId: subscription.id, proofPath: path);
    refreshAfterPayment(ref);
    if (context.mounted) BusinToast.show(context, l10n.partSent, tone: ToastTone.success);
    return true;
  } on Offline {
    if (context.mounted) BusinToast.show(context, l10n.errorOffline, tone: ToastTone.error);
  } on Conflict catch (e) {
    if (context.mounted) {
      BusinToast.show(context, e.reason == 'payment_in_progress' ? l10n.payErrorInProgress : l10n.payErrorNotPayable, tone: ToastTone.error);
    }
    refreshAfterPayment(ref);
  } catch (_) {
    if (context.mounted) BusinToast.show(context, l10n.errorGeneric, tone: ToastTone.error);
  }
  return false;
}

/// Opens the payment of a request (or picks up the one still waiting), then reloads what it changed; a student who
/// would rather send a receipt goes on to that.
Future<void> payRequest(BuildContext context, WidgetRef ref, Subscription subscription, {Payment? latest}) async {
  final outcome = await showPaySheet(
    context,
    purpose: PaymentPurpose.subscription,
    targetId: subscription.id,
    resume: latest,
    offerReceipt: true,
  );
  refreshAfterPayment(ref);
  if (outcome == PayOutcome.receiptInstead && context.mounted) await sendReceiptInstead(context, ref, subscription);
}

/// On a pending request to be paid by mobile money: where its payment stands, Pay now (or follow the one waiting), and
/// a receipt instead.
class AwaitingPaymentPanel extends ConsumerWidget {
  const AwaitingPaymentPanel({super.key, required this.subscription});

  final Subscription subscription;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = BusinL10n.of(context);
    final payments = ref.watch(myPaymentsProvider).value ?? const <Payment>[];
    final latest = latestPaymentFor(payments, subscriptionId: subscription.id);
    final waiting = latest != null && latest.status.waiting;
    final failure = latest?.failure;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (waiting)
          Notice(tone: StatusTone.info, title: l10n.payWaitingTitle, child: Text(l10n.payWaitingNote))
        else if (failure != null)
          Notice(
            tone: StatusTone.bad,
            title: l10n.payFailedTitle,
            child: Text('${failureText(l10n, failure)} ${l10n.payFailedNothingTaken}'),
          )
        else if (latest?.status == PaymentStatus.needsAttention)
          Notice(tone: StatusTone.info, child: Text(l10n.payAttention)),
        if (waiting || failure != null || latest?.status == PaymentStatus.needsAttention) const SizedBox(height: BusinSpace.x4),
        if (latest?.status != PaymentStatus.needsAttention) ...[
          BusinButton(
            label: waiting ? l10n.payWaitingTitle : (failure != null ? l10n.payRetry : l10n.payNow),
            icon: waiting ? HugeIcons.strokeRoundedSmartPhone01 : HugeIcons.strokeRoundedWallet01,
            expand: true,
            onPressed: () => payRequest(context, ref, subscription, latest: latest),
          ),
          if (!waiting) ...[
            const SizedBox(height: BusinSpace.x2),
            BusinButton(
              label: l10n.paySendReceiptInstead,
              icon: HugeIcons.strokeRoundedReceiptText,
              variant: BusinButtonVariant.ghost,
              expand: true,
              onPressed: () => sendReceiptInstead(context, ref, subscription),
            ),
          ],
        ],
      ],
    );
  }
}

/// The receipts of the payments made in the app for a subscription (its request and its parts), newest first.
class SubscriptionPayments extends ConsumerWidget {
  const SubscriptionPayments({super.key, required this.subscriptionId});

  final String subscriptionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = BusinL10n.of(context);
    final palette = BusinPalette.of(context);
    final payments = ref.watch(myPaymentsProvider).value ?? const <Payment>[];
    final refunds = ref.watch(myRefundsProvider).value ?? const <Refund>[];
    final paid = [
      for (final p in payments)
        if (p.subscriptionId == subscriptionId && p.status == PaymentStatus.completed) p,
    ];
    if (paid.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.paymentsTitle, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: BusinSpace.x3),
        for (final p in paid) ...[
          PaymentReceiptCard(payment: p),
          if (p.refunded) ...[
            const SizedBox(height: BusinSpace.x1),
            Text(l10n.payRefunding, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: palette.warn)),
          ],
          // The newest refund of this payment, and asking for one while none is under way (ADR 0029).
          for (final r in refunds.where((r) => r.paymentId == p.id).take(1)) ...[
            const SizedBox(height: BusinSpace.x2),
            RefundLine(refund: r),
          ],
          if (canAskRefund(p, refunds))
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(onPressed: () => askRefund(context, ref, p), child: Text(l10n.refundAsk)),
            ),
          const SizedBox(height: BusinSpace.x2),
        ],
      ],
    );
  }
}

/// Where the newest refund of a payment stands, in the student's words.
class RefundLine extends StatelessWidget {
  const RefundLine({super.key, required this.refund});

  final Refund refund;

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final amount = money(context, refund.totalXaf, 'XAF');
    final (tone, text) = switch (refund.status) {
      RefundStatus.requested => (StatusTone.info, l10n.refundRequested),
      RefundStatus.onItsWay => (StatusTone.info, l10n.refundOnItsWay(amount)),
      RefundStatus.completed => (StatusTone.ok, l10n.refundDone(amount)),
      RefundStatus.declined => (StatusTone.bad, l10n.refundDeclined),
      RefundStatus.failed => (StatusTone.warn, l10n.refundDelayed),
    };
    final note = refund.status == RefundStatus.declined ? refund.decisionNote : null;
    final small = Theme.of(context).textTheme.bodySmall;
    return Notice(
      tone: tone,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text),
          if (note != null && note.isNotEmpty) Text(note, style: small),
          if (refund.receiptNo != null) Text(l10n.refundReceiptNo(refund.receiptNo!), style: small),
        ],
      ),
    );
  }
}

/// Asks the school to refund a payment, with a reason (ADR 0029).
Future<void> askRefund(BuildContext context, WidgetRef ref, Payment payment) async {
  final sent = await showBusinSheet<bool>(context, isScrollControlled: true, builder: (sheet) => _RefundForm(payment: payment));
  if (sent == true) {
    ref.invalidate(myRefundsProvider);
    if (context.mounted) BusinToast.show(context, BusinL10n.of(context).refundSent, tone: ToastTone.success);
  }
}

class _RefundForm extends ConsumerStatefulWidget {
  const _RefundForm({required this.payment});

  final Payment payment;

  @override
  ConsumerState<_RefundForm> createState() => _RefundFormState();
}

class _RefundFormState extends ConsumerState<_RefundForm> {
  final _reason = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l10n = BusinL10n.of(context);
    final reason = _reason.text.trim();
    if (reason.length < 10) {
      setState(() => _error = l10n.refundReasonShort);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(paymentsRepositoryProvider).requestRefund(paymentId: widget.payment.id, reason: reason);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = switch (e) {
            Offline() => l10n.errorOffline,
            Conflict(reason: 'not_refundable') => l10n.refundNotRefundable,
            Invalid(reason: 'reason_too_short' || 'reason_required') => l10n.refundReasonShort,
            _ => l10n.errorGeneric,
          });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(BusinSheetFrame.contentInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.refundAskTitle, style: text.titleLarge),
            const SizedBox(height: BusinSpace.x2),
            Text(l10n.refundAskBody, style: text.bodyMedium?.copyWith(color: BusinPalette.of(context).muted)),
            const SizedBox(height: BusinSpace.x5),
            BusinTextField(
              label: l10n.refundReasonLabel,
              icon: HugeIcons.strokeRoundedNote,
              hint: l10n.refundReasonHint,
              controller: _reason,
              maxLines: 4,
              enabled: !_busy,
              errorText: _error,
            ),
            const SizedBox(height: BusinSpace.x5),
            BusinButton(label: l10n.refundSend, loading: _busy, expand: true, onPressed: _busy ? null : _send),
          ],
        ),
      ),
    );
  }
}
