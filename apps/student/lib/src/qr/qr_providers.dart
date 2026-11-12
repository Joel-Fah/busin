import 'dart:typed_data';

import 'package:busin_core/busin_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/access.dart';
import '../providers.dart';
import '../subscription/subscription_providers.dart';
import 'screen_security.dart';
import 'secret_store.dart';

export '../providers.dart' show nowProvider;

final qrRepositoryProvider = Provider<QrRepository>((ref) => ref.watch(repositoriesProvider).qr);

final screenSecurityProvider = Provider<ScreenSecurity>((ref) => MethodChannelScreenSecurity());

/// Whether this session has already reminded the student to keep the code private.
class QrPrivacyTold extends Notifier<bool> {
  @override
  bool build() => false;

  void told() => state = true;
}

final qrPrivacyToldProvider = NotifierProvider<QrPrivacyTold, bool>(QrPrivacyTold.new);

/// Gets the boarding secret. The server is asked every time, because only it knows whether the student still has an
/// approved subscription: a refusal deletes the secret kept on the phone and the code is gone. Only when there is no
/// connection at all does the phone use the secret it kept, so the code keeps working underground; the scan itself is
/// checked by the server again, so a revoked code is refused at the door either way.
class BoardingCodeService {
  BoardingCodeService(this._qr, this._store);

  final QrRepository _qr;
  final SecretStore _store;

  /// Throws [NotAllowed] when the student has no approved subscription (now, or no longer), and [Offline] when there is
  /// no connection and nothing on the phone to use instead.
  ///
  /// [offlineAllowed] is asked only when there is no connection: it says whether the saved pass may still be shown (the
  /// semester it was approved for must be running). Without it the kept secret is always used offline.
  Future<Uint8List> secretFor(String userId, {bool Function()? offlineAllowed}) async {
    final Uint8List fresh;
    try {
      fresh = await _qr.fetchSecret();
    } on NotAllowed {
      await _store.delete(userId);
      rethrow;
    } on Offline {
      final cached = await _store.read(userId);
      if (cached != null && (offlineAllowed?.call() ?? true)) return cached;
      rethrow;
    }
    final cached = await _store.read(userId);
    if (cached == null || !_same(cached, fresh)) await _store.write(userId, fresh);
    return fresh;
  }

  static bool _same(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

final boardingCodeServiceProvider = Provider<BoardingCodeService>(
  (ref) => BoardingCodeService(ref.watch(qrRepositoryProvider), ref.watch(secretStoreProvider)),
);

/// The student's secret for the boarding code. Reloaded when asked (pull down, or the tab opens after a failure).
final qrSecretProvider = FutureProvider.autoDispose<Uint8List>((ref) {
  final access = ref.watch(accessProvider);
  if (access is! Allowed) throw StateError('The boarding code is only for an allowed student.');
  final userId = access.profile.id;
  final keeper = ref.watch(snapshotKeeperProvider);
  final clock = ref.watch(schoolClockProvider);
  final now = ref.read(nowProvider);
  return ref.watch(boardingCodeServiceProvider).secretFor(
        userId,
        // Offline, the saved pass counts only while its semester is running at the school.
        offlineAllowed: () {
          final snapshot = keeper.peek(userId);
          final saved = snapshot?.overview;
          if (snapshot == null || saved == null) return true;
          final today = clock.today(snapshot.school?.timezone ?? 'UTC', now: now());
          return SubscriptionOverview.fromJson(saved, savedAt: snapshot.savedAt).passUsable(today);
        },
      );
}, retry: noAutomaticRetry);
