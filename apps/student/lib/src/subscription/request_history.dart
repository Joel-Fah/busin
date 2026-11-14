import 'package:busin_core/busin_core.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../auth/access.dart';
import '../providers.dart';
import 'installments_section.dart';
import 'subscription_providers.dart';
import 'subscription_status_card.dart';

/// One line of a request's history: an operation on the subscription, or a step of a receipt for a part (ADR 0022).
sealed class HistoryEntry {
  const HistoryEntry();
  DateTime get at;
}

class EventEntry extends HistoryEntry {
  const EventEntry(this.event);
  final SubscriptionEvent event;
  @override
  DateTime get at => event.createdAt;
}

enum ReceiptStep { sent, paid, rejected }

class ReceiptEntry extends HistoryEntry {
  const ReceiptEntry(this.receipt, this.step);
  final InstallmentReceipt receipt;
  final ReceiptStep step;
  @override
  DateTime get at => step == ReceiptStep.sent ? receipt.sentAt : (receipt.decidedAt ?? receipt.sentAt);
}

/// One request of the semester with everything that happened to it, the latest operation first.
class RequestRecord {
  const RequestRecord({required this.subscription, required this.events, this.entries = const []});

  final Subscription subscription;
  final List<SubscriptionEvent> events;

  /// [events] and the receipts of its parts together, the latest first: what the history shows.
  final List<HistoryEntry> entries;
}

/// The steps of a receipt: sent (when it has a proof), then the school's decision.
List<ReceiptEntry> receiptSteps(InstallmentReceipt r) => [
      if (r.proofPath != null) ReceiptEntry(r, ReceiptStep.sent),
      if (r.decision == InstallmentStatus.paid) ReceiptEntry(r, ReceiptStep.paid),
      if (r.decision == InstallmentStatus.rejected) ReceiptEntry(r, ReceiptStep.rejected),
    ];

/// The student's requests with their operations: the latest request first, and inside each the latest operation first.
/// Every receipt sent for a part stays in its request's history. A request with no recorded operation (none should
/// exist) simply has an empty list.
List<RequestRecord> buildRequestHistory(List<Subscription> subscriptions, List<SubscriptionEvent> events, [List<InstallmentReceipt> receipts = const []]) {
  final requests = [...subscriptions]..sort((a, b) {
      final byDate = b.createdAt.compareTo(a.createdAt);
      return byDate != 0 ? byDate : b.id.compareTo(a.id);
    });
  return [
    for (final s in requests)
      _record(s, events, receipts),
  ];
}

RequestRecord _record(Subscription s, List<SubscriptionEvent> events, List<InstallmentReceipt> receipts) {
  final own = [
    for (final e in events)
      if (e.subscriptionId == s.id) e,
  ]..sort((a, b) {
      final byDate = b.createdAt.compareTo(a.createdAt);
      return byDate != 0 ? byDate : b.id.compareTo(a.id);
    });
  final entries = <HistoryEntry>[
    for (final e in own) EventEntry(e),
    for (final r in receipts)
      if (r.subscriptionId == s.id) ...receiptSteps(r),
  ]..sort((a, b) => b.at.compareTo(a.at));
  return RequestRecord(subscription: s, events: own, entries: entries);
}

/// The shown semester's requests, with their operations. It follows the overview: when that is read again (a request
/// was sent, the school decided) this is too.
final requestHistoryProvider = FutureProvider.autoDispose<List<RequestRecord>>((ref) async {
  final access = ref.watch(accessProvider);
  if (access is! Allowed) return const [];
  final overview = await ref.watch(subscriptionOverviewProvider.future);
  final semester = overview.semester;
  if (semester == null) return const [];
  final repository = ref.watch(subscriptionsRepositoryProvider);
  final all = await repository.listForStudent(access.profile.id, page: const PageRequest(limit: 50));
  final ofSemester = all.where((s) => s.semesterId == semester.id).toList();
  if (ofSemester.isEmpty) return const [];
  final events = await repository.eventsFor([for (final s in ofSemester) s.id]);
  // The receipts of parts, only when a request is paid in installments.
  final inParts = [for (final s in ofSemester) if (s.paymentMode == PaymentMode.installments) s.id];
  final receipts = inParts.isEmpty ? const <InstallmentReceipt>[] : await ref.watch(installmentsRepositoryProvider).receiptsFor(inParts);
  return buildRequestHistory(ofSemester, events, receipts);
}, retry: noAutomaticRetry);

/// "Your requests this semester": an accordion for each request, the latest open, with what happened to it inside. It
/// says nothing while loading and shows nothing if the history cannot be read (the card above says what matters).
class RequestHistorySection extends ConsumerWidget {
  const RequestHistorySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(requestHistoryProvider).value;
    if (records == null || records.isEmpty) return const SizedBox.shrink();
    final l10n = BusinL10n.of(context);
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final material = MaterialLocalizations.of(context);
    final use24 = MediaQuery.alwaysUse24HourFormatOf(context);

    String when(DateTime at) {
      final local = at.toLocal();
      return '${material.formatMediumDate(local)}, ${material.formatTimeOfDay(TimeOfDay.fromDateTime(local), alwaysUse24HourFormat: use24)}';
    }

    (String, List<List<dynamic>>, Color) look(SubscriptionEventAction action) => switch (action) {
          SubscriptionEventAction.requested => (l10n.requestEventRequested, HugeIcons.strokeRoundedSent, p.info),
          SubscriptionEventAction.approved => (l10n.requestEventApproved, HugeIcons.strokeRoundedCheckmarkCircle02, p.ok),
          SubscriptionEventAction.rejected => (l10n.requestEventRejected, HugeIcons.strokeRoundedCancelCircle, p.bad),
          SubscriptionEventAction.revoked => (l10n.requestEventRevoked, HugeIcons.strokeRoundedAlert02, p.bad),
          SubscriptionEventAction.reinstated => (l10n.requestEventReinstated, HugeIcons.strokeRoundedCheckmarkCircle02, p.ok),
        };

    return Padding(
      padding: const EdgeInsets.only(top: BusinSpace.x6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.requestsTitle, style: text.titleLarge),
          const SizedBox(height: BusinSpace.x1),
          Text(l10n.requestsHint, style: text.bodyMedium?.copyWith(color: p.muted)),
          const SizedBox(height: BusinSpace.x4),
          for (var i = 0; i < records.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: BusinSpace.x3),
              child: BusinAccordion(
                // The latest request is the one that matters now.
                initiallyOpen: i == 0,
                title: Text(l10n.requestOf(material.formatMediumDate(records[i].subscription.createdAt.toLocal())), style: text.titleSmall),
                trailing: StatusChip(label: l10n.subscriptionStatus(records[i].subscription.status), tone: subscriptionTone(records[i].subscription.status)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final entry in records[i].entries.isEmpty ? [for (final e in records[i].events) EventEntry(e)] : records[i].entries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: BusinSpace.x3),
                        child: Builder(builder: (context) {
                          final (label, icon, color, note, proof) = switch (entry) {
                            EventEntry(:final event) => (look(event.action).$1, look(event.action).$2, look(event.action).$3, event.note, null),
                            ReceiptEntry(:final receipt, step: ReceiptStep.sent) =>
                              (l10n.receiptSent('${receipt.seq}'), HugeIcons.strokeRoundedReceiptText, p.info, null, receipt.proofPath),
                            ReceiptEntry(:final receipt, step: ReceiptStep.paid) =>
                              (l10n.receiptPaid('${receipt.seq}'), HugeIcons.strokeRoundedCheckmarkCircle02, p.ok, null, null),
                            ReceiptEntry(:final receipt, step: ReceiptStep.rejected) =>
                              (l10n.receiptRejected('${receipt.seq}'), HugeIcons.strokeRoundedCancelCircle, p.bad, receipt.note, null),
                          };
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              HugeIcon(icon: icon, size: 22, color: color),
                              const SizedBox(width: BusinSpace.x3),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(label, style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                                    Text(when(entry.at), style: text.bodySmall?.copyWith(color: p.muted)),
                                    if (note != null && note.trim().isNotEmpty)
                                      Padding(padding: const EdgeInsets.only(top: BusinSpace.x1), child: Text(note, style: text.bodyMedium)),
                                    if (proof != null) Padding(padding: const EdgeInsets.only(top: BusinSpace.x2), child: StoredProofPreview(path: proof)),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
