import 'package:busin_core/busin_core.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../auth/access.dart';
import '../providers.dart';
import '../subscription/subscription_providers.dart';

/// How the student prefers to pay (ADR 0022), used to fill in the request form. Shown only where the school offers
/// installments: otherwise there is nothing to choose. It brings its own space above it.
class PaymentPreferenceCard extends ConsumerStatefulWidget {
  const PaymentPreferenceCard({super.key});

  @override
  ConsumerState<PaymentPreferenceCard> createState() => _PaymentPreferenceCardState();
}

class _PaymentPreferenceCardState extends ConsumerState<PaymentPreferenceCard> {
  bool _busy = false;

  Future<void> _set(PaymentMode? mode) async {
    final l10n = BusinL10n.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(profileRepositoryProvider).setPaymentPreference(mode);
      ref.invalidate(profileProvider);
      if (mounted) BusinToast.show(context, l10n.preferenceSaved, tone: ToastTone.success);
    } on Offline {
      if (mounted) BusinToast.show(context, l10n.errorOffline, tone: ToastTone.error);
    } catch (_) {
      if (mounted) BusinToast.show(context, l10n.errorGeneric, tone: ToastTone.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final school = ref.watch(schoolProvider).value;
    final access = ref.watch(accessProvider);
    if (access is! Allowed || school?.billingPeriod != BillingPeriod.semester || school?.installmentPlan == null) return const SizedBox.shrink();
    final l10n = BusinL10n.of(context);
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: BusinSpace.x4),
      child: StaggeredIn(
        index: 2,
        child: BusinCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(BusinRadius.sm)),
                    child: Padding(padding: const EdgeInsets.all(BusinSpace.x3), child: HugeIcon(icon: HugeIcons.strokeRoundedWallet01, size: 20, color: p.fg)),
                  ),
                  const SizedBox(width: BusinSpace.x3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.profilePaymentTitle, style: text.titleMedium),
                        Text(l10n.profilePaymentHint, style: text.bodySmall?.copyWith(color: p.muted)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: BusinSpace.x4),
              BusinSegmented<PaymentMode?>(
                groupLabel: l10n.profilePaymentTitle,
                // In full is the default while nothing is saved.
                selected: access.profile.paymentPreference ?? PaymentMode.full,
                segments: [
                  BusinSegment(value: PaymentMode.full, label: l10n.paymentFull),
                  BusinSegment(value: PaymentMode.installments, label: l10n.paymentInstallments),
                ],
                onChanged: (mode) {
                  if (!_busy && mode != (access.profile.paymentPreference ?? PaymentMode.full)) _set(mode);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
