import 'dart:typed_data';

import 'package:busin_core/busin_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/access.dart';
import '../providers.dart';
import 'screen_security.dart';
import 'secret_store.dart';

final qrRepositoryProvider = Provider<QrRepository>((ref) => ref.watch(repositoriesProvider).qr);

final screenSecurityProvider = Provider<ScreenSecurity>((ref) => MethodChannelScreenSecurity());

/// Whether this session has already reminded the student to keep the code private.
class QrPrivacyTold extends Notifier<bool> {
  @override
  bool build() => false;

  void told() => state = true;
}

final qrPrivacyToldProvider = NotifierProvider<QrPrivacyTold, bool>(QrPrivacyTold.new);

/// The current time. The boarding code is a function of it; tests replace it to move through windows.
final nowProvider = Provider<DateTime Function()>((ref) => DateTime.now);

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
  Future<Uint8List> secretFor(String userId) async {
    final Uint8List fresh;
    try {
      fresh = await _qr.fetchSecret();
    } on NotAllowed {
      await _store.delete(userId);
      rethrow;
    } on Offline {
      final cached = await _store.read(userId);
      if (cached != null) return cached;
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
  return ref.watch(boardingCodeServiceProvider).secretFor(access.profile.id);
}, retry: noAutomaticRetry);
