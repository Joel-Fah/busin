import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bus/bus_providers.dart';
import '../providers.dart';
import '../qr/qr_providers.dart';
import '../subscription/subscription_providers.dart';
import 'offline_providers.dart';

/// Reads again everything the app keeps a saved copy of, so the answers (and any decision the school made while the phone was
/// offline, such as taking the subscription back) replace the copy.
void refreshFromServer(WidgetRef ref) {
  ref.invalidate(profileProvider);
  ref.invalidate(schoolProvider);
  ref.invalidate(subscriptionOverviewProvider);
  ref.invalidate(qrSecretProvider);
  ref.invalidate(canFollowBusesProvider);
}

/// Asks the server again when the network comes back, and when the app is opened again, but only while something on screen is
/// a saved copy. Mounted once, inside the signed-in frame.
class OfflineBinder extends ConsumerStatefulWidget {
  const OfflineBinder({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<OfflineBinder> createState() => _OfflineBinderState();
}

class _OfflineBinderState extends ConsumerState<OfflineBinder> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool get _showingSavedCopy => ref.read(offlineProvider).isNotEmpty;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _showingSavedCopy) refreshFromServer(ref);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(connectivityProvider, (previous, next) {
      final wasOnline = previous?.value ?? false;
      if (next.value == true && !wasOnline && _showingSavedCopy) refreshFromServer(ref);
    });
    return widget.child;
  }
}
