import 'package:busin_core/busin_core.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'subscription_providers.dart';

/// Where the student's request stands, with what they need to know next.
class SubscriptionStatusCard extends ConsumerWidget {
  const SubscriptionStatusCard({super.key, required this.subscription, required this.stopName, this.onShowCode, this.onRequestAgain});

  final Subscription subscription;
  final String stopName;

  /// For an approved subscription: go to the boarding code.
  final VoidCallback? onShowCode;

  /// For a rejected or expired one: show the form again.
  final VoidCallback? onRequestAgain;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = BusinL10n.of(context);
    final palette = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final status = subscription.status;

    final (title, body) = switch (status) {
      SubscriptionStatus.pending => (l10n.statusPendingTitle, l10n.statusPendingBody),
      SubscriptionStatus.approved => (l10n.statusApprovedTitle, l10n.statusApprovedBody(stopName)),
      SubscriptionStatus.rejected => (l10n.statusRejectedTitle, null),
      SubscriptionStatus.expired => (l10n.statusExpiredTitle, l10n.statusExpiredBody),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(BusinRadius.lg),
        border: Border.all(color: palette.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BusinSpace.x5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                StatusChip(label: l10n.subscriptionStatus(status), tone: subscriptionTone(status)),
                const Spacer(),
                Text(
                  l10n.subscriptionSent(MaterialLocalizations.of(context).formatMediumDate(subscription.createdAt.toLocal())),
                  style: text.bodySmall?.copyWith(color: palette.muted),
                ),
              ],
            ),
            const SizedBox(height: BusinSpace.x4),
            Text(title, style: text.titleLarge),
            if (body != null) ...[
              const SizedBox(height: BusinSpace.x2),
              Text(body, style: text.bodyMedium?.copyWith(color: palette.muted)),
            ],
            if (status == SubscriptionStatus.rejected) ...[
              const SizedBox(height: BusinSpace.x3),
              Text(l10n.statusRejectedReason, style: text.labelMedium?.copyWith(color: palette.muted)),
              const SizedBox(height: 2),
              Text(
                (subscription.reviewNote?.trim().isNotEmpty ?? false) ? subscription.reviewNote! : l10n.statusRejectedNoReason,
                style: text.bodyMedium,
              ),
            ],
            const SizedBox(height: BusinSpace.x4),
            Text(l10n.subscriptionStop, style: text.labelMedium?.copyWith(color: palette.muted)),
            Text(stopName, style: text.bodyLarge),
            if (subscription.proofPath != null) ...[
              const SizedBox(height: BusinSpace.x4),
              _ProofPreview(path: subscription.proofPath!),
            ],
            if (status == SubscriptionStatus.approved && onShowCode != null) ...[
              const SizedBox(height: BusinSpace.x5),
              BusinButton(label: l10n.statusApprovedAction, onPressed: onShowCode, expand: true),
            ],
            if ((status == SubscriptionStatus.rejected || status == SubscriptionStatus.expired) && onRequestAgain != null) ...[
              const SizedBox(height: BusinSpace.x5),
              BusinButton(label: l10n.statusRequestAgain, onPressed: onRequestAgain, expand: true),
            ],
          ],
        ),
      ),
    );
  }
}

/// The stored proof, shown through a short-lived signed address. If it cannot be loaded the card simply goes without it.
class _ProofPreview extends ConsumerWidget {
  const _ProofPreview({required this.path});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = BusinL10n.of(context);
    final url = ref.watch(proofUrlProvider(path));
    return url.maybeWhen(
      data: (address) => ClipRRect(
        borderRadius: BorderRadius.circular(BusinRadius.xs),
        child: Image.network(
          address,
          height: 140,
          fit: BoxFit.cover,
          semanticLabel: l10n.subscriptionProofTitle,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}
