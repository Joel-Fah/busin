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

/// Gets the boarding secret: from the keystore if this phone already has it, otherwise from the server
/// once. Once stored, codes need no connection.
class BoardingCodeService {
  BoardingCodeService(this._qr, this._store);

  final QrRepository _qr;
  final SecretStore _store;

  /// Throws [NotAllowed] when the student has no approved subscription yet, and [Offline] when the
  /// secret is not on the phone and there is no connection to fetch it.
  Future<Uint8List> secretFor(String userId) async {
    final cached = await _store.read(userId);
    if (cached != null) return cached;
    final fresh = await _qr.fetchSecret();
    await _store.write(userId, fresh);
    return fresh;
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
});
