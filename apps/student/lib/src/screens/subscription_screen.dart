import 'package:busin_core/busin_core.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../router.dart';
import '../subscription/subscribe_form.dart';
import '../subscription/subscription_providers.dart';
import '../subscription/subscription_status_card.dart';

/// The first tab: the semester that matters now, and either the request form or where the request stands.
class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  /// After a rejection the student can ask for the form again without leaving the page.
  bool _requestAgain = false;

  Future<void> _refresh() async {
    ref.invalidate(subscriptionOverviewProvider);
    await ref.read(subscriptionOverviewProvider.future).catchError((_) => const SubscriptionOverview.none());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final overview = ref.watch(subscriptionOverviewProvider);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: overview.when(
        loading: () => ListView(physics: const AlwaysScrollableScrollPhysics(), children: const [SizedBox(height: 240), Center(child: CircularProgressIndicator())]),
        error: (error, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 80),
            EmptyState(
              icon: HugeIcons.strokeRoundedWifiDisconnected01,
              title: error is RepositoryException ? l10n.failure(error) : l10n.errorGeneric,
              action: BusinButton(label: l10n.actionRetry, onPressed: () => ref.invalidate(subscriptionOverviewProvider)),
            ),
          ],
        ),
        data: (data) {
          final semester = data.semester;
          if (semester == null) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 80),
                EmptyState(icon: HugeIcons.strokeRoundedCalendar02, title: l10n.subscriptionNoSemesterTitle, body: l10n.subscriptionNoSemesterBody),
              ],
            );
          }

          final subscription = data.subscription;
          final showForm = subscription == null || (_requestAgain && !subscription.isLive);
          final name = l10n.semester(semester.name, semester.year);
          final text = Theme.of(context).textTheme;

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(BusinSpace.x5),
            children: [
              Text(showForm ? l10n.subscribeHeading(name) : name, style: text.headlineSmall),
              if (data.upcoming) ...[
                const SizedBox(height: BusinSpace.x1),
                Text(
                  l10n.subscriptionStarts(MaterialLocalizations.of(context).formatMediumDate(semester.startDate)),
                  style: text.bodyMedium?.copyWith(color: BusinPalette.of(context).muted),
                ),
              ],
              const SizedBox(height: BusinSpace.x5),
              if (showForm)
                SubscribeForm(semester: semester)
              else
                SubscriptionStatusCard(
                  subscription: subscription,
                  stopName: data.stop?.name ?? '',
                  onShowCode: () => context.go(Routes.qr),
                  onRequestAgain: () => setState(() => _requestAgain = true),
                ),
            ],
          );
        },
      ),
    );
  }
}
