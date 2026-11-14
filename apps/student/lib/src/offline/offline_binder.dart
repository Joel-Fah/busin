import 'package:busin_app/busin_app.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bus/bus_providers.dart';
import '../providers.dart';
import '../qr/qr_providers.dart';
import '../subscription/subscription_providers.dart';

/// Reads again everything the app keeps a saved copy of, so the answers (and any decision the school made while the phone was
/// offline, such as taking the subscription back) replace the copy.
void refreshFromServer(WidgetRef ref) {
  ref.invalidate(profileProvider);
  ref.invalidate(schoolProvider);
  ref.invalidate(subscriptionOverviewProvider);
  ref.invalidate(qrSecretProvider);
  // The payment proof's link failed while offline and was remembered as failed: ask again.
  ref.invalidate(proofUrlProvider);
  ref.invalidate(canFollowBusesProvider);
}

/// Reads the main screens again when the network is lost. With no network each answers from its saved copy at once (see
/// `serverOrSaved`), which raises the offline banner straight away.
void showSavedCopy(WidgetRef ref) {
  ref.invalidate(profileProvider);
  ref.invalidate(schoolProvider);
  ref.invalidate(subscriptionOverviewProvider);
}

/// Asks the server again when the network comes back, and when the app comes back from the background (not on a focus
/// blip), but only while something on screen is a saved copy. Mounted once, inside the signed-in frame.
class OfflineBinder extends ConsumerStatefulWidget {
  const OfflineBinder({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<OfflineBinder> createState() => _OfflineBinderState();
}

class _OfflineBinderState extends ConsumerState<OfflineBinder> with WidgetsBindingObserver {
  final _away = AwayTracker();

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
    if (_away.cameBack(state) && _showingSavedCopy) refreshFromServer(ref);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(connectivityProvider, (previous, next) {
      final wasOnline = previous?.value ?? false;
      if (next.value == true && !wasOnline && _showingSavedCopy) refreshFromServer(ref);
      // The network just went (airplane mode, out of coverage): read the main screens again. With no network they answer
      // from the saved copy at once, so the banner says so now instead of at the next read.
      if (next.value == false && previous?.value == true) showSavedCopy(ref);
    });
    return widget.child;
  }
}
