import 'package:busin_core/busin_core.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../auth/access.dart';
import '../providers.dart';
import 'billing_choices.dart';
import 'money.dart';
import 'pick_proof.dart';
import 'proof_picker.dart';
import 'stop_picker_sheet.dart';
import 'subscription_providers.dart';

/// The request form: a stop, a photo of the payment receipt, and Send. Nothing is sent until both are chosen. The school's
/// billing (ADR 0022) adds the price, the month for monthly billing, and how the student pays when the school offers
/// installments, filled in from their saved preference.
class SubscribeForm extends ConsumerStatefulWidget {
  const SubscribeForm({super.key, required this.semester, this.offline = false, this.live = const [], this.month, this.onSent});

  final Semester semester;

  /// The live requests of the semester, so a month already asked for is not offered again.
  final List<Subscription> live;

  /// The month to start with (asking for next month from the current one's card).
  final DateTime? month;

  /// Called once the request is sent, before the overview reloads.
  final VoidCallback? onSent;

  /// The screen is showing the copy saved on the phone: nothing can be sent until the phone is connected again.
  final bool offline;

  @override
  ConsumerState<SubscribeForm> createState() => _SubscribeFormState();
}

class _SubscribeFormState extends ConsumerState<SubscribeForm> {
  Stop? _stop;
  PickedProof? _proof;
  bool _busy = false;
  String? _error;
  DateTime? _month;
  PaymentMode? _mode;
  bool _modeMissing = false;

  @override
  void initState() {
    super.initState();
    _month = widget.month;
    final access = ref.read(accessProvider);
    // The saved way of paying fills the choice in; without one the student chooses.
    if (access is Allowed) _mode = access.profile.paymentPreference;
  }

  /// Whether the school offers installments for this request (semester billing with a plan).
  bool _offersInstallments(School? school) => school?.billingPeriod == BillingPeriod.semester && school?.installmentPlan != null;

  DateTime _today(School school) => ref.read(schoolClockProvider).today(school.timezone, now: ref.read(nowProvider)());

  Future<void> _chooseStop(List<Stop> stops) async {
    final stop = await showStopPicker(context, stops, selectedId: _stop?.id);
    if (stop != null && mounted) setState(() => _stop = stop);
  }

  Future<void> _chooseProof() async {
    final proof = await pickProof(context, ref, onProblem: (message) {
      if (mounted) setState(() => _error = message);
    });
    if (proof != null && mounted) {
      setState(() {
        _proof = proof;
        _error = null;
      });
    }
  }

  Future<void> _submit() async {
    final l10n = BusinL10n.of(context);
    final access = ref.read(accessProvider);
    final stop = _stop;
    final proof = _proof;
    if (access is! Allowed || stop == null || proof == null) return;

    // A form left open past the semester's last day would send a request for a semester that is over. Check the
    // school's own day first, and reload what is open.
    final school = await ref.read(schoolProvider.future);
    final today = _today(school);
    final offers = _offersInstallments(school);
    if (offers && _mode == null) {
      setState(() => _modeMissing = true);
      return;
    }
    final monthly = school.billingPeriod == BillingPeriod.month;
    if (widget.semester.endDate.isBefore(calendarDay(today))) {
      ref.invalidate(subscriptionOverviewProvider);
      if (mounted) setState(() => _error = l10n.subscribeErrorEnded);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final mode = offers ? _mode! : PaymentMode.full;
      await ref.read(subscriptionServiceProvider).submit(
            profile: access.profile,
            semester: widget.semester,
            stop: stop,
            proof: proof,
            paymentMode: mode,
            month: monthly ? _month : null,
            refresh: false,
          );
      // A first choice of how to pay may become the student's preference, if they want.
      if (offers && access.profile.paymentPreference == null && mounted) await _offerPreference(mode);
      // The overview reloads and replaces this form with the pending card.
      widget.onSent?.call();
      ref.invalidate(subscriptionOverviewProvider);
    } catch (e) {
      if (!mounted) return;
      final failure = failureFor(e);
      // What was on screen is out of date: read again what is open, so the student can choose again.
      if (failure == SubscribeFailure.unavailable || failure == SubscribeFailure.semesterEnded || failure == SubscribeFailure.periodEnded) {
        ref.invalidate(subscriptionOverviewProvider);
        ref.invalidate(schoolProvider);
      }
      setState(() {
        _error = switch (failure) {
          SubscribeFailure.alreadyRequested => l10n.subscribeErrorExists,
          SubscribeFailure.offline => l10n.errorOffline,
          SubscribeFailure.rejectedFile => l10n.subscribeErrorType,
          SubscribeFailure.proofRequired => l10n.subscribeErrorProof,
          SubscribeFailure.semesterEnded => l10n.subscribeErrorEnded,
          SubscribeFailure.periodEnded => l10n.subscribeErrorPeriodEnded,
          SubscribeFailure.billingNotSet => l10n.subscribeBillingNotSet,
          SubscribeFailure.unavailable => l10n.subscribeErrorUnavailable,
          SubscribeFailure.other => l10n.errorGeneric,
        };
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Asks once, after a request is sent, whether to keep this way of paying for the next ones.
  Future<void> _offerPreference(PaymentMode mode) async {
    final l10n = BusinL10n.of(context);
    final label = mode == PaymentMode.installments ? l10n.paymentInstallments : l10n.paymentFull;
    final save = await showBusinSheet<bool>(
      context,
      builder: (sheet) => Padding(
        padding: EdgeInsets.all(BusinSheetFrame.contentInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.preferenceSaveTitle, style: Theme.of(sheet).textTheme.titleLarge),
            const SizedBox(height: BusinSpace.x2),
            Text(l10n.preferenceSaveBody(label), style: Theme.of(sheet).textTheme.bodyMedium?.copyWith(color: BusinPalette.of(sheet).muted)),
            const SizedBox(height: BusinSpace.x5),
            BusinButton(label: l10n.preferenceSave, expand: true, onPressed: () => Navigator.of(sheet).pop(true)),
            const SizedBox(height: BusinSpace.x2),
            BusinButton(label: l10n.preferenceNotNow, variant: BusinButtonVariant.ghost, expand: true, onPressed: () => Navigator.of(sheet).pop(false)),
          ],
        ),
      ),
    );
    if (save != true) return;
    try {
      await ref.read(profileRepositoryProvider).setPaymentPreference(mode);
      ref.invalidate(profileProvider);
      if (mounted) BusinToast.show(context, l10n.preferenceSaved, tone: ToastTone.success);
    } catch (_) {
      // The request is sent; the preference can be set from the profile.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final palette = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final stops = ref.watch(stopsProvider);
    final school = ref.watch(schoolProvider).value;
    final billingMissing = school != null && !school.billingSet;
    final monthly = school?.billingPeriod == BillingPeriod.month;
    final offers = _offersInstallments(school);
    final months = monthly ? monthChoices(semester: widget.semester, today: _today(school!), live: widget.live) : const <DateTime>[];
    // The month starts on the first one offered, unless one was asked for.
    final month = monthly ? (months.any((m) => _month != null && sameMonth(m, _month!)) ? _month : (months.isEmpty ? null : months.first)) : null;
    if (month != _month && monthly) _month = month;
    final ready = _stop != null && _proof != null && !_busy && school != null && !billingMissing && (!monthly || month != null);
    final price = school?.priceXaf;
    final currency = school?.currency ?? 'XAF';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.subscribeIntro, style: text.bodyMedium?.copyWith(color: palette.muted)),
        const SizedBox(height: BusinSpace.x5),
        if (billingMissing) ...[
          Notice(tone: StatusTone.warn, child: Text(l10n.subscribeBillingNotSet)),
          const SizedBox(height: BusinSpace.x4),
        ] else if (price != null) ...[
          Text(
            monthly ? l10n.subscribePriceMonth(money(context, price, currency)) : l10n.subscribePriceSemester(money(context, price, currency)),
            style: text.titleMedium,
          ),
          const SizedBox(height: BusinSpace.x4),
        ],
        if (monthly && months.isNotEmpty) ...[
          Text(l10n.subscribeMonthLabel, style: text.labelLarge),
          const SizedBox(height: BusinSpace.x2),
          BusinSegmented<DateTime?>(
            groupLabel: l10n.subscribeMonthLabel,
            selected: month,
            segments: [for (final m in months) BusinSegment(value: m, label: monthName(context, m))],
            onChanged: _busy ? (_) {} : (m) => setState(() => _month = m),
          ),
          const SizedBox(height: BusinSpace.x4),
        ],
        if (offers && price != null) ...[
          Text(l10n.subscribePaymentLabel, style: text.labelLarge),
          const SizedBox(height: BusinSpace.x2),
          BusinSegmented<PaymentMode?>(
            groupLabel: l10n.subscribePaymentLabel,
            selected: _mode,
            segments: [
              BusinSegment(value: PaymentMode.full, label: l10n.paymentFull),
              BusinSegment(value: PaymentMode.installments, label: l10n.paymentInstallments),
            ],
            onChanged: _busy
                ? (_) {}
                : (mode) => setState(() {
                      _mode = mode;
                      _modeMissing = false;
                    }),
          ),
          if (_mode != null) ...[
            const SizedBox(height: BusinSpace.x2),
            Text(
              _mode == PaymentMode.installments
                  ? l10n.subscribeInstallmentsNote(school!.installmentPlan!.split(price).map((part) => money(context, part, currency)).join(', '))
                  : l10n.subscribeFullNote(money(context, price, currency)),
              style: text.bodySmall?.copyWith(color: palette.muted),
            ),
          ],
          if (_modeMissing) ...[
            const SizedBox(height: BusinSpace.x2),
            Text(l10n.subscribePaymentRequired, style: text.bodySmall?.copyWith(color: palette.bad)),
          ],
          const SizedBox(height: BusinSpace.x4),
        ],
        StaggeredIn(
          child: FieldTile(
            label: l10n.subscribeStopLabel,
            icon: HugeIcons.strokeRoundedFlag02,
            value: _stop?.name,
            placeholder: l10n.subscribeStopHint,
            onTap: stops.hasValue && !_busy ? () => _chooseStop(stops.requireValue) : null,
          ),
        ),
        if (stops.hasError) ...[
          const SizedBox(height: BusinSpace.x2),
          Notice(
            tone: StatusTone.bad,
            child: Row(
              children: [
                Expanded(child: Text(l10n.errorGeneric)),
                TextButton(onPressed: () => ref.invalidate(stopsProvider), child: Text(l10n.actionRetry)),
              ],
            ),
          ),
        ],
        const SizedBox(height: BusinSpace.x4),
        StaggeredIn(
          index: 1,
          child: FieldTile(
            label: l10n.subscribeProofLabel,
            icon: HugeIcons.strokeRoundedReceiptText,
            value: _proof == null ? null : l10n.proofAdded,
            placeholder: l10n.subscribeProofHint,
            onTap: _busy ? null : _chooseProof,
            preview: _proof == null ? null : Image.memory(_proof!.bytes, height: 180, fit: BoxFit.cover, semanticLabel: l10n.subscribeProofLabel),
          ),
        ),
        const SizedBox(height: BusinSpace.x3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.only(top: 2), child: HugeIcon(icon: HugeIcons.strokeRoundedShield01, size: 16, color: palette.muted)),
            const SizedBox(width: BusinSpace.x2),
            Expanded(child: Text(l10n.subscribeProofPrivacy, style: text.bodySmall?.copyWith(color: palette.muted))),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: BusinSpace.x4),
          Notice(tone: StatusTone.bad, child: Text(_error!)),
        ],
        const SizedBox(height: BusinSpace.x6),
        BusinButton(label: l10n.subscribeSubmit, onPressed: ready && !widget.offline ? _submit : null, loading: _busy, expand: true),
        if (widget.offline) ...[
          const SizedBox(height: BusinSpace.x2),
          Text(l10n.offlineNeedsConnection, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: BusinPalette.of(context).muted), textAlign: TextAlign.center),
        ],
      ],
    );
  }
}
