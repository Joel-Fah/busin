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
import 'subscription_providers.dart';

final installmentsRepositoryProvider = Provider<InstallmentsRepository>((ref) => ref.watch(repositoriesProvider).installments);

/// The parts of a subscription paid in installments (ADR 0022), read while its card is on screen.
final installmentsProvider = FutureProvider.autoDispose.family<List<Installment>, String>(
  (ref, subscriptionId) => ref.watch(installmentsRepositoryProvider).forSubscriptions([subscriptionId]),
  retry: noAutomaticRetry,
);

/// Each part with its amount, due date and where it stands; a later part that is not paid takes a proof from here.
class InstallmentsSection extends ConsumerStatefulWidget {
  const InstallmentsSection({super.key, required this.subscription});

  final Subscription subscription;

  @override
  ConsumerState<InstallmentsSection> createState() => _InstallmentsSectionState();
}

class _InstallmentsSectionState extends ConsumerState<InstallmentsSection> {
  String? _sending;

  Future<void> _sendProof(Installment part) async {
    final l10n = BusinL10n.of(context);
    final access = ref.read(accessProvider);
    if (access is! Allowed) return;
    final proof = await pickProof(context, ref, onProblem: (message) {
      if (mounted) BusinToast.show(context, message, tone: ToastTone.error);
    });
    if (proof == null || !mounted) return;
    setState(() => _sending = part.id);
    try {
      final path = await ref.read(proofsRepositoryProvider).upload(
            schoolId: access.profile.schoolId!,
            studentId: access.profile.id,
            bytes: proof.bytes,
            contentType: proof.contentType,
          );
      await ref.read(installmentsRepositoryProvider).submitProof(installmentId: part.id, proofPath: path);
      ref.invalidate(installmentsProvider(widget.subscription.id));
      if (mounted) BusinToast.show(context, l10n.partSent, tone: ToastTone.success);
    } on Offline {
      if (mounted) BusinToast.show(context, l10n.errorOffline, tone: ToastTone.error);
    } catch (_) {
      if (mounted) BusinToast.show(context, l10n.errorGeneric, tone: ToastTone.error);
    } finally {
      if (mounted) setState(() => _sending = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final parts = ref.watch(installmentsProvider(widget.subscription.id)).value;
    if (parts == null || parts.isEmpty) return const SizedBox.shrink();
    final l10n = BusinL10n.of(context);
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final material = MaterialLocalizations.of(context);
    final school = ref.watch(schoolProvider).value;
    final today = school == null ? null : calendarDay(ref.read(schoolClockProvider).today(school.timezone, now: ref.read(nowProvider)()));
    final canSend = widget.subscription.isLive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.partsTitle, style: text.titleMedium),
        const SizedBox(height: BusinSpace.x3),
        for (final part in parts) ...[
          DecoratedBox(
            decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(BusinRadius.md)),
            child: Padding(
              padding: const EdgeInsets.all(BusinSpace.x4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: BusinSpace.x2,
                    runSpacing: BusinSpace.x2,
                    children: [
                      Text('${l10n.partLabel('${part.seq}')} · ${money(context, part.amountXaf, school?.currency ?? 'XAF')}', style: text.titleSmall),
                      Wrap(
                        spacing: BusinSpace.x2,
                        children: [
                          StatusChip(label: _statusLabel(l10n, part.status), tone: _tone(part.status)),
                          if (today != null && part.overdue(today)) StatusChip(label: l10n.partLate, tone: StatusTone.bad),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: BusinSpace.x1),
                  Text(l10n.partDue(material.formatMediumDate(part.dueDate)), style: text.bodySmall?.copyWith(color: p.muted)),
                  if (part.status == InstallmentStatus.rejected && (part.reviewNote?.isNotEmpty ?? false)) ...[
                    const SizedBox(height: BusinSpace.x2),
                    Text(part.reviewNote!, style: text.bodySmall),
                  ],
                  if (part.open && canSend) ...[
                    const SizedBox(height: BusinSpace.x3),
                    BusinButton(
                      label: l10n.partSendProof,
                      icon: HugeIcons.strokeRoundedReceiptText,
                      variant: BusinButtonVariant.secondary,
                      loading: _sending == part.id,
                      onPressed: _sending == null ? () => _sendProof(part) : null,
                      expand: true,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: BusinSpace.x2),
        ],
      ],
    );
  }

  static String _statusLabel(BusinL10n l10n, InstallmentStatus status) => switch (status) {
        InstallmentStatus.due => l10n.partStatusDue,
        InstallmentStatus.submitted => l10n.partStatusSubmitted,
        InstallmentStatus.paid => l10n.partStatusPaid,
        InstallmentStatus.rejected => l10n.partStatusRejected,
      };

  static StatusTone _tone(InstallmentStatus status) => switch (status) {
        InstallmentStatus.due => StatusTone.neutral,
        InstallmentStatus.submitted => StatusTone.warn,
        InstallmentStatus.paid => StatusTone.ok,
        InstallmentStatus.rejected => StatusTone.bad,
      };
}
