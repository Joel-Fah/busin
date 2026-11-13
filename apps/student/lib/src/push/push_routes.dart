import 'package:busin_app/busin_app.dart';

/// Where a tapped notification should take the student. Null for a kind this version does not know.
String? routeForPush(PushMessage message) => switch (message.kind) {
      'subscription_approved' || 'subscription_rejected' || 'subscription_revoked' => '/subscription',
      'bus_near_stop' => '/bus',
      _ => null,
    };
