import 'package:busin_core/busin_core.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/access.dart';
import '../greeting.dart';
import '../providers.dart';
import '../push/push_prompt_card.dart';
import '../qr/qr_providers.dart';
import '../router.dart';
import '../subscription/how_it_works_card.dart';
import '../subscription/subscribe_form.dart';
import '../subscription/subscription_providers.dart';
import '../subscription/subscription_status_card.dart';

/// The first tab: a banner that greets the student and names the semester, then either the request form or where the
/// request stands. On a wide screen (a tablet in landscape) the form or status sits on the left and a short guide on the right.
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

  /// The student's avatar in the banner's corner: it opens their profile.
  Widget? _profileButton(BusinL10n l10n) {
    final access = ref.watch(accessProvider);
    if (access is! Allowed) return null;
    return Semantics(
      button: true,
      label: l10n.profileOpen,
      child: GestureDetector(
        onTap: () {
          BusinHaptics.light();
          context.push(Routes.profile);
        },
        child: DecoratedBox(
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2)),
          child: ExcludeSemantics(child: UserAvatar(name: access.profile.fullName, imageUrl: access.profile.avatarUrl, size: 40)),
        ),
      ),
    );
  }

  /// The greeting for the hour it is at the school, with the student's first name.
  String _greeting(BusinL10n l10n) {
    final access = ref.watch(accessProvider);
    final school = ref.watch(schoolProvider).value;
    final now = ref.watch(nowProvider)();
    final hour = school == null ? now.toLocal().hour : ref.watch(schoolClockProvider).wallClock(school.timezone, now).hour;
    final base = switch (greetingForHour(hour)) {
      Greeting.morning => l10n.greetMorning,
      Greeting.afternoon => l10n.greetAfternoon,
      Greeting.evening => l10n.greetEvening,
    };
    final name = access is Allowed ? firstNameOf(access.profile.fullName) : '';
    return name.isEmpty ? base : '$base, $name';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final layout = BusinLayout.of(context);
    final overview = ref.watch(subscriptionOverviewProvider);
    final inset = BusinScope.of(context).bottomInset;
    final padding = EdgeInsets.fromLTRB(BusinSpace.x5, BusinSpace.x5, BusinSpace.x5, BusinSpace.x5 + inset);

    return ContentColumn(
      maxWidth: layout.isExpanded ? 1100 : BusinLayout.maxColumn,
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: overview.when(
          loading: () => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: padding,
            // The shape of what is coming: the banner, then a card.
            children: const [Skeleton(height: 188, radius: BusinRadius.lg), SizedBox(height: BusinSpace.x4), Skeleton(height: 280, radius: BusinRadius.lg)],
          ),
          error: (error, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: padding,
            children: [
              const SizedBox(height: 40),
              EmptyState(
                illustration: BusinIllustration.waiting,
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
                padding: padding,
                children: [
                  BusinBanner(title: _greeting(l10n), eyebrow: MaterialLocalizations.of(context).formatFullDate(DateTime.now()), art: BusinIllustration.semester, trailing: _profileButton(l10n)),
                  const SizedBox(height: BusinSpace.x4),
                  EmptyState(illustration: BusinIllustration.semester, title: l10n.subscriptionNoSemesterTitle, body: l10n.subscriptionNoSemesterBody),
                ],
              );
            }

            final subscription = data.subscription;
            final showForm = subscription == null || (_requestAgain && !subscription.isLive);
            final name = l10n.semester(semester.name, semester.year);
            final material = MaterialLocalizations.of(context);

            final art = showForm
                ? BusinIllustration.ticket
                : switch (subscription.status) {
                    SubscriptionStatus.approved => BusinIllustration.verified,
                    SubscriptionStatus.pending => BusinIllustration.waiting,
                    SubscriptionStatus.rejected => BusinIllustration.papers,
                    SubscriptionStatus.expired => BusinIllustration.semester,
                  };

            final banner = BusinBanner(
              eyebrow: material.formatFullDate(DateTime.now()),
              title: _greeting(l10n),
              body: [showForm ? l10n.subscribeHeading(name) : name, if (data.upcoming) l10n.subscriptionStarts(material.formatMediumDate(semester.startDate))].join('\n'),
              art: art,
              trailing: _profileButton(l10n),
            );

            final main = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                banner,
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
                // The moment there is something to wait for is the moment to offer to tell them.
                if (!showForm && subscription.status == SubscriptionStatus.pending) const PushPromptCard(),
              ],
            );

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: padding,
              children: [layout.isExpanded ? SplitView(primary: main, secondary: const HowItWorksCard(), primaryFlex: 6, secondaryFlex: 4) : main],
            );
          },
        ),
      ),
    );
  }
}
