import 'dart:async';

import 'package:busin_core/busin_core.dart';
import 'package:flutter/widgets.dart';

/// Whether the server's copy of the signed-in person's profile differs from [current] in what decides access: the role,
/// the status (suspended, pending) or the school. Null when it cannot be read right now (no connection, a server
/// problem): then nothing is assumed and the app carries on as it was.
Future<bool?> accountChanged({required ProfileRepository repository, required Profile current}) async {
  try {
    final fresh = await repository.getProfile(current.id);
    return fresh.role != current.role || fresh.status != current.status || fresh.schoolId != current.schoolId;
  } on RepositoryException {
    return null;
  } catch (_) {
    return null;
  }
}

/// Keeps the app's view of who the person is (role, status, school) up to date while it runs, so that an administrator
/// suspending an account or changing a role takes effect without restarting the app. It asks [onChanged] to look again
/// when the app comes back after being in the background (not on a mere focus blip, such as a system dialog or the
/// screenshot flag changing), and whenever the server reports a change to the person's own profile row.
/// [watch] gives that stream (the first value, the row as it is now, is skipped: it is not news).
class AccountWatcher extends StatefulWidget {
  const AccountWatcher({super.key, required this.userId, required this.watch, required this.onChanged, required this.child});

  /// The signed-in person, or null when nobody is.
  final String? userId;

  /// Changes of this person's profile as they happen.
  final Stream<Object?> Function(String userId) watch;

  /// Look again at the profile (the app decides whether anything changed).
  final VoidCallback onChanged;

  final Widget child;

  @override
  State<AccountWatcher> createState() => _AccountWatcherState();
}

class _AccountWatcherState extends State<AccountWatcher> with WidgetsBindingObserver {
  StreamSubscription<Object?>? _subscription;
  final _away = AwayTracker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscribe();
  }

  @override
  void didUpdateWidget(AccountWatcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) _subscribe();
  }

  void _subscribe() {
    _subscription?.cancel();
    _subscription = null;
    final id = widget.userId;
    if (id == null) return;
    // Without a connection the stream may fail; the foreground check still covers it, so errors are not shown.
    _subscription = widget.watch(id).skip(1).listen((_) => widget.onChanged(), onError: (Object _) {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_away.cameBack(state) && widget.userId != null) widget.onChanged();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Tells a real return from the background apart from a focus blip. Android reports a resume whenever the window gets its
/// focus back (a system dialog, the notification shade, the screenshot flag changing), and acting on each one makes the app
/// reload over and over; only a resume after the app was hidden or paused counts.
class AwayTracker {
  bool _away = false;

  /// Feed every lifecycle change; true once, when the app is back after being away.
  bool cameBack(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden || state == AppLifecycleState.paused) _away = true;
    if (state != AppLifecycleState.resumed || !_away) return false;
    _away = false;
    return true;
  }
}
