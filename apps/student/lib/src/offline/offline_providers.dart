import 'dart:async';

import 'package:busin_core/busin_core.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which reads are being answered from the copy saved on the phone because the server could not be reached, and since when
/// that copy dates. Empty means everything on screen is fresh.
class OfflineState extends Notifier<Map<String, DateTime>> {
  @override
  Map<String, DateTime> build() => const {};

  void served(String source, DateTime savedAt) => state = {...state, source: savedAt};

  void fresh(String source) {
    if (!state.containsKey(source)) return;
    state = {...state}..remove(source);
  }

  void reset() => state = const {};
}

final offlineProvider = NotifierProvider<OfflineState, Map<String, DateTime>>(OfflineState.new);

/// When the oldest copy in use was saved, or null while everything is fresh.
final offlineSinceProvider = Provider<DateTime?>((ref) {
  final served = ref.watch(offlineProvider);
  if (served.isEmpty) return null;
  return served.values.reduce((a, b) => a.isBefore(b) ? a : b);
});

/// How long the opening reads wait for the server before the saved copy is used. A phone that is online but with a stalled
/// connection would otherwise sit on the loading screen. Null means no limit (tests that wait on purpose). Longer than the loading screen's own "taking longer" message (10 s), so
/// that message gets its moment; with no connection at all the failure is immediate and this never matters. Tests shorten it.
final gateTimeoutProvider = Provider<Duration?>((ref) => const Duration(seconds: 15));

/// True while the phone has a network connection, as the system reports it (a connection is not proof the server is
/// reachable, so this only decides when to try again). Tests replace the stream.
final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  bool online(List<ConnectivityResult> results) => results.any((r) => r != ConnectivityResult.none);
  yield online(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(online);
});

/// Reads [live] from the server and keeps a copy with [save]. When the server cannot be reached ([Offline], or no answer
/// within the gate timeout) the copy from [saved] is returned instead, and [offlineProvider] says so. Anything else, a refusal
/// above all, is passed on untouched: old data never hides what the server decided.
Future<T> serverOrSaved<T>(
  Ref ref, {
  required String source,
  required Future<T> Function() live,
  required Future<void> Function(T value) save,
  required Future<({T value, DateTime savedAt})?> Function() saved,
}) async {
  final timeout = ref.read(gateTimeoutProvider);
  void tell(void Function(OfflineState state) change) {
    // A provider cannot be changed while another is being built.
    Future.microtask(() {
      if (ref.mounted) change(ref.read(offlineProvider.notifier));
    });
  }

  try {
    final pending = live();
    final value = timeout == null ? await pending : await pending.timeout(timeout, onTimeout: () => throw const Offline('No answer from the server in time.'));
    await save(value);
    tell((state) => state.fresh(source));
    return value;
  } on Offline {
    final copy = await saved();
    if (copy == null) rethrow;
    tell((state) => state.served(source, copy.savedAt));
    return copy.value;
  }
}
