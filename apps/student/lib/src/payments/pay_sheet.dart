import 'package:busin_core/busin_core.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../auth/access.dart';
import '../providers.dart';
import '../subscription/money.dart';
import 'operator_badge.dart';
import 'payment_providers.dart';
import 'payment_text.dart';

/// One payment, now and whenever it changes (Realtime on the student's own row).
final paymentStreamProvider = StreamProvider.autoDispose.family<Payment, String>(
  (ref, id) => ref.watch(paymentsRepositoryProvider).watch(id),
);

/// What the sheet ended with, for the screen behind it to reload.
enum PayOutcome { paid, receiptInstead, closed }

/// Pays a pending request (in full or its first part) or a later part by mobile money (ADR 0029): the number, the
/// operator recognised as it is typed, the price, the fee and the total; then the wait for the PIN, followed live; then
/// paid, or why not with Try again. Opened again on a payment still waiting ([resume]), it goes straight to the wait.
Future<PayOutcome> showPaySheet(
  BuildContext context, {
  required PaymentPurpose purpose,
  required String targetId,
  String? title,
  Payment? resume,
  bool offerReceipt = false,
}) async {
  final outcome = await showBusinSheet<PayOutcome>(
    context,
    isScrollControlled: true,
    builder: (sheet) => PayFlow(purpose: purpose, targetId: targetId, title: title, resume: resume, offerReceipt: offerReceipt),
  );
  return outcome ?? PayOutcome.closed;
}

class PayFlow extends ConsumerStatefulWidget {
  const PayFlow({super.key, required this.purpose, required this.targetId, this.title, this.resume, this.offerReceipt = false});

  final PaymentPurpose purpose;
  final String targetId;
  final String? title;
  final Payment? resume;

  /// A failed payment of a request may be replaced by a receipt.
  final bool offerReceipt;

  @override
  ConsumerState<PayFlow> createState() => _PayFlowState();
}

class _PayFlowState extends ConsumerState<PayFlow> {
  late final TextEditingController _phone;
  MobileMoneyOperator? _chosen;
  String? _paymentId;
  bool _busy = false;
  bool _checking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final access = ref.read(accessProvider);
    final own = access is Allowed ? access.profile.phone : null;
    final number = own == null ? null : MobileMoneyNumber.normalize(own);
    _phone = TextEditingController(text: number == null ? '' : MobileMoneyNumber.display(number));
    final resume = widget.resume;
    // A payment that may still finish is followed; a finished one is shown as it ended.
    if (resume != null && resume.status != PaymentStatus.failed) _paymentId = resume.id;
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  ({PaymentPurpose purpose, String targetId}) get _item => (purpose: widget.purpose, targetId: widget.targetId);

  MobileMoneyOperator? get _operator => _chosen ?? MobileMoneyNumber.guessOperator(_phone.text);

  Future<void> _pay() async {
    final number = MobileMoneyNumber.normalize(_phone.text);
    final l10n = BusinL10n.of(context);
    if (number == null) {
      setState(() => _error = l10n.payPhoneInvalid);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    HapticFeedback.selectionClick();
    try {
      final payment = await ref
          .read(paymentsRepositoryProvider)
          .start(
            purpose: widget.purpose,
            targetId: widget.targetId,
            phone: number,
            // Sent only when the student picked it; otherwise pawaPay recognises the number.
            operator: _chosen,
          );
      if (mounted) setState(() => _paymentId = payment.id);
    } catch (e) {
      if (mounted) setState(() => _error = refusalText(l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _checkAgain(String id) async {
    setState(() => _checking = true);
    try {
      await ref.read(paymentsRepositoryProvider).check(id);
      ref.invalidate(paymentStreamProvider(id));
    } on Offline {
      if (mounted) BusinToast.show(context, BusinL10n.of(context).errorOffline, tone: ToastTone.error);
    } catch (_) {
      // The live view keeps following it; the reconciler finishes it anyway.
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _retry() => setState(() {
    _paymentId = null;
    _error = null;
  });

  @override
  Widget build(BuildContext context) {
    final id = _paymentId;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(BusinSheetFrame.contentInset),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: id == null ? _form(context) : _following(context, id),
        ),
      ),
    );
  }

  Widget _form(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final palette = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final quotes = ref.watch(paymentQuoteProvider(_item));
    final operator = _operator;
    final valid = MobileMoneyNumber.normalize(_phone.text) != null;
    final available = quotes.value?.where((q) => q.available).toList() ?? const <PaymentQuote>[];
    final quote = operator == null ? available.firstOrNull : quotes.value?.where((q) => q.operator == operator).firstOrNull;
    final unavailable = operator != null && quote != null && !quote.available;
    final failed = widget.resume?.status == PaymentStatus.failed && _error == null ? widget.resume : null;

    return Column(
      key: const ValueKey('form'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.title ?? l10n.payTitleSubscription, style: text.titleLarge),
        const SizedBox(height: BusinSpace.x2),
        Text(l10n.payMethodMobileMoneyNote, style: text.bodyMedium?.copyWith(color: palette.muted)),
        if (failed != null) ...[
          const SizedBox(height: BusinSpace.x4),
          Notice(
            tone: StatusTone.bad,
            title: l10n.payFailedTitle,
            child: Text('${failureText(l10n, failed.failure ?? PaymentFailure.other)} ${l10n.payFailedNothingTaken}'),
          ),
        ],
        const SizedBox(height: BusinSpace.x5),
        BusinTextField(
          label: l10n.payPhoneLabel,
          icon: HugeIcons.strokeRoundedSmartPhone01,
          hint: l10n.payPhoneHint,
          controller: _phone,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          enabled: !_busy,
          onChanged: (_) => setState(() {
            // A new number is recognised again, unless the student picked the operator for this one.
            _error = null;
          }),
        ),
        const SizedBox(height: BusinSpace.x3),
        _OperatorRow(operator: operator, chosen: _chosen != null, onChoose: _busy ? null : (o) => setState(() => _chosen = o)),
        const SizedBox(height: BusinSpace.x5),
        quotes.when(
          loading: () => const Skeleton(height: 96),
          error: (e, _) => Notice(tone: StatusTone.bad, child: Text(refusalText(l10n, e))),
          data: (_) => quote == null || !quote.available
              ? (unavailable
                    ? Notice(tone: StatusTone.warn, child: Text(l10n.payOperatorUnavailable(operatorName(operator))))
                    : Notice(tone: StatusTone.warn, child: Text(l10n.payErrorUnavailable)))
              : _PriceLines(quote: quote),
        ),
        if (_error != null) ...[
          const SizedBox(height: BusinSpace.x4),
          Semantics(
            liveRegion: true,
            child: Notice(tone: StatusTone.bad, child: Text(_error!)),
          ),
        ],
        const SizedBox(height: BusinSpace.x5),
        BusinButton(
          label: quote?.totalXaf == null ? l10n.payNow : l10n.paySubmit(money(context, quote!.totalXaf!, 'XAF')),
          icon: HugeIcons.strokeRoundedWallet01,
          loading: _busy,
          expand: true,
          onPressed: valid && quote != null && quote.available && !_busy ? _pay : null,
        ),
        if (widget.offerReceipt) ...[
          const SizedBox(height: BusinSpace.x2),
          BusinButton(
            label: l10n.paySendReceiptInstead,
            variant: BusinButtonVariant.ghost,
            expand: true,
            onPressed: _busy ? null : () => Navigator.of(context).pop(PayOutcome.receiptInstead),
          ),
        ],
      ],
    );
  }

  Widget _following(BuildContext context, String id) {
    final l10n = BusinL10n.of(context);
    final payment = ref.watch(paymentStreamProvider(id));
    return payment.when(
      loading: () => _Waiting(payment: widget.resume, checking: _checking, onCheck: () => _checkAgain(id)),
      error: (_, _) => _Waiting(payment: widget.resume, checking: _checking, onCheck: () => _checkAgain(id)),
      data: (p) {
        if (p.status.waiting) return _Waiting(payment: p, checking: _checking, onCheck: () => _checkAgain(id));
        if (p.status == PaymentStatus.completed) {
          return _Ended(
            icon: HugeIcons.strokeRoundedCheckmarkCircle02,
            tone: p.refunded ? StatusTone.warn : StatusTone.ok,
            title: l10n.payDoneTitle,
            body: p.refunded
                ? l10n.payRefunding
                : (p.purpose == PaymentPurpose.installment ? l10n.payDoneInstallment : l10n.payDoneSubscription),
            payment: p,
            actions: [BusinButton(label: l10n.actionClose, expand: true, onPressed: () => Navigator.of(context).pop(PayOutcome.paid))],
          );
        }
        if (p.status == PaymentStatus.needsAttention) {
          return _Ended(
            icon: HugeIcons.strokeRoundedInformationCircle,
            tone: StatusTone.info,
            title: l10n.payWaitingTitle,
            body: l10n.payAttention,
            actions: [BusinButton(label: l10n.actionClose, expand: true, onPressed: () => Navigator.of(context).pop(PayOutcome.closed))],
          );
        }
        return _Ended(
          icon: HugeIcons.strokeRoundedCancelCircle,
          tone: StatusTone.bad,
          title: l10n.payFailedTitle,
          body: '${failureText(l10n, p.failure ?? PaymentFailure.other)} ${l10n.payFailedNothingTaken}',
          actions: [
            BusinButton(label: l10n.payRetry, icon: HugeIcons.strokeRoundedRefresh, expand: true, onPressed: _retry),
            if (widget.offerReceipt) ...[
              const SizedBox(height: BusinSpace.x2),
              BusinButton(
                label: l10n.paySendReceiptInstead,
                variant: BusinButtonVariant.ghost,
                expand: true,
                onPressed: () => Navigator.of(context).pop(PayOutcome.receiptInstead),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// The recognised operator, or a choice of the two when the number does not say; the student can always change it.
class _OperatorRow extends StatelessWidget {
  const _OperatorRow({required this.operator, required this.chosen, required this.onChoose});

  final MobileMoneyOperator? operator;
  final bool chosen;
  final ValueChanged<MobileMoneyOperator>? onChoose;

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final palette = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final current = operator;
    if (current == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.payOperatorPick, style: text.bodySmall?.copyWith(color: palette.muted)),
          const SizedBox(height: BusinSpace.x2),
          Wrap(
            spacing: BusinSpace.x2,
            children: [
              for (final o in MobileMoneyOperator.values)
                ActionChip(
                  label: OperatorBadge(operator: o, compact: true),
                  tooltip: operatorName(o),
                  onPressed: onChoose == null ? null : () => onChoose!(o),
                ),
            ],
          ),
        ],
      );
    }
    final other = MobileMoneyOperator.values.firstWhere((o) => o != current);
    return Row(
      children: [
        OperatorBadge(operator: current),
        const Spacer(),
        TextButton(onPressed: onChoose == null ? null : () => onChoose!(other), child: Text(l10n.payOperatorChange)),
      ],
    );
  }
}

class _PriceLines extends StatelessWidget {
  const _PriceLines({required this.quote});

  final PaymentQuote quote;

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final palette = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    Widget line(String label, int amount, {bool strong = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: BusinSpace.x1),
      child: Row(
        children: [
          Expanded(child: Text(label, style: strong ? text.titleSmall : text.bodyMedium)),
          Text(money(context, amount, 'XAF'), style: strong ? text.titleSmall : text.bodyMedium),
        ],
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(color: palette.surface2, borderRadius: BorderRadius.circular(BusinRadius.md)),
      child: Padding(
        padding: const EdgeInsets.all(BusinSpace.x4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            line(l10n.payLinePrice, quote.amountXaf),
            if ((quote.feeXaf ?? 0) > 0) line(l10n.payLineFee, quote.feeXaf!),
            Divider(color: palette.line, height: BusinSpace.x4),
            line(l10n.payLineTotal, quote.totalXaf!, strong: true),
            if ((quote.feeXaf ?? 0) > 0) ...[
              const SizedBox(height: BusinSpace.x1),
              Text(l10n.payFeeNote, style: text.bodySmall?.copyWith(color: palette.muted)),
            ],
          ],
        ),
      ),
    );
  }
}

class _Waiting extends StatelessWidget {
  const _Waiting({required this.payment, required this.checking, required this.onCheck});

  final Payment? payment;
  final bool checking;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final palette = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final p = payment;
    return Column(
      key: const ValueKey('waiting'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: BusinSpace.x2),
        Center(
          child: SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(strokeWidth: 3, color: palette.accent),
                HugeIcon(icon: HugeIcons.strokeRoundedSmartPhone01, size: 22, color: palette.fg),
              ],
            ),
          ),
        ),
        const SizedBox(height: BusinSpace.x4),
        Semantics(
          liveRegion: true,
          child: Text(l10n.payWaitingTitle, style: text.titleLarge, textAlign: TextAlign.center),
        ),
        if (p != null) ...[
          const SizedBox(height: BusinSpace.x2),
          Text(
            l10n.payWaitingBody(money(context, p.totalXaf, 'XAF'), operatorName(p.operator)),
            style: text.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: BusinSpace.x2),
        Text(
          l10n.payWaitingNote,
          style: text.bodySmall?.copyWith(color: palette.muted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: BusinSpace.x5),
        BusinButton(
          label: l10n.payWaitingCheck,
          variant: BusinButtonVariant.secondary,
          loading: checking,
          expand: true,
          onPressed: checking ? null : onCheck,
        ),
      ],
    );
  }
}

class _Ended extends StatelessWidget {
  const _Ended({required this.icon, required this.tone, required this.title, required this.body, required this.actions, this.payment});

  final List<List<dynamic>> icon;
  final StatusTone tone;
  final String title;
  final String body;
  final List<Widget> actions;
  final Payment? payment;

  @override
  Widget build(BuildContext context) {
    final palette = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final color = switch (tone) {
      StatusTone.ok => palette.ok,
      StatusTone.bad => palette.bad,
      StatusTone.warn => palette.warn,
      _ => palette.info,
    };
    return Column(
      key: ValueKey('ended-$title'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: HugeIcon(icon: icon, size: 48, color: color),
        ),
        const SizedBox(height: BusinSpace.x3),
        Semantics(
          liveRegion: true,
          child: Text(title, style: text.titleLarge, textAlign: TextAlign.center),
        ),
        const SizedBox(height: BusinSpace.x2),
        Text(
          body,
          style: text.bodyMedium?.copyWith(color: palette.muted),
          textAlign: TextAlign.center,
        ),
        if (payment != null) ...[const SizedBox(height: BusinSpace.x4), PaymentReceiptCard(payment: payment!)],
        const SizedBox(height: BusinSpace.x5),
        ...actions,
      ],
    );
  }
}

/// A paid payment as a receipt: BusIn's number, the amounts, the operator and number, the operator's reference.
class PaymentReceiptCard extends StatelessWidget {
  const PaymentReceiptCard({super.key, required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final palette = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final date = payment.completedAt ?? payment.createdAt;
    Widget row(String label, String value, {bool strong = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: text.bodySmall?.copyWith(color: palette.muted)),
          ),
          Text(value, style: strong ? text.labelLarge : text.bodySmall),
        ],
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(color: palette.surface2, borderRadius: BorderRadius.circular(BusinRadius.md)),
      child: Padding(
        padding: const EdgeInsets.all(BusinSpace.x4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                HugeIcon(icon: HugeIcons.strokeRoundedReceiptText, size: 18, color: palette.muted),
                const SizedBox(width: BusinSpace.x2),
                Expanded(
                  child: Text(
                    payment.receiptNo == null ? l10n.paymentsTitle : l10n.paymentReceiptNo(payment.receiptNo!),
                    style: text.labelLarge,
                  ),
                ),
                Text(
                  MaterialLocalizations.of(context).formatMediumDate(date.toLocal()),
                  style: text.bodySmall?.copyWith(color: palette.muted),
                ),
              ],
            ),
            const SizedBox(height: BusinSpace.x2),
            row(l10n.payLinePrice, money(context, payment.amountXaf, 'XAF')),
            if (payment.feeXaf > 0) row(l10n.payLineFee, money(context, payment.feeXaf, 'XAF')),
            row(l10n.payLineTotal, money(context, payment.totalXaf, 'XAF'), strong: true),
            const SizedBox(height: BusinSpace.x2),
            Text(
              l10n.paymentPaidWith(operatorName(payment.operator), payment.payerMasked),
              style: text.bodySmall?.copyWith(color: palette.muted),
            ),
            if (payment.providerTxn != null)
              Text(l10n.paymentTxn(payment.providerTxn!), style: text.bodySmall?.copyWith(color: palette.muted)),
          ],
        ),
      ),
    );
  }
}
