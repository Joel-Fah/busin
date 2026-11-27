import 'package:busin_app/busin_app.dart';
import 'package:busin_core/busin_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

/// The student's tabs, in the order of the shell's destinations.
abstract final class StudentTabs {
  static const subscription = 0;
  static const code = 1;
  static const bus = 2;
  static const profile = 3;
}

/// The tabs with news waiting (see [TabBadges]). Starts empty again for each person who signs in.
class StudentTabBadges extends TabBadges {
  @override
  Set<int> build() {
    ref.watch(authUserIdProvider);
    return super.build();
  }
}

final tabBadgesProvider = NotifierProvider<StudentTabBadges, Set<int>>(StudentTabBadges.new);

/// The tabs a subscription's new status concerns: always the subscription; the code too when it starts or stops working.
Set<int> tabsForStatus(SubscriptionStatus status) => switch (status) {
      SubscriptionStatus.approved || SubscriptionStatus.revoked => {StudentTabs.subscription, StudentTabs.code},
      SubscriptionStatus.rejected || SubscriptionStatus.expired => {StudentTabs.subscription},
      _ => const {},
    };

/// The tabs a notification that arrives while the app is open concerns.
Set<int> tabsForPush(String kind) => switch (kind) {
      'subscription_approved' || 'subscription_restored' || 'subscription_revoked' => {StudentTabs.subscription, StudentTabs.code},
      'subscription_rejected' || 'installment_paid' || 'installment_rejected' || 'installment_due' => {StudentTabs.subscription},
      'bus_near_stop' || 'trip_started' || 'bus_at_stop' || 'bus_left_stop' || 'bus_at_campus' => {StudentTabs.bus},
      _ => const {},
    };
