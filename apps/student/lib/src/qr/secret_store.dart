import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where the boarding secret lives on the phone. It is a key to the student's boarding codes, so it
/// belongs in the platform keystore, never in plain preferences (ADR 0006, ADR 0007).
abstract interface class SecretStore {
  /// The secret kept for [userId], or null. Each user has their own, so a second account on the same
  /// phone never sees the first one's.
  Future<Uint8List?> read(String userId);

  Future<void> write(String userId, Uint8List secret);

  /// Forgets every secret. Called on sign-out.
  Future<void> deleteAll();
}

class SecureSecretStore implements SecretStore {
  SecureSecretStore([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  static const _prefix = 'busin.qr.secret.';
  final FlutterSecureStorage _storage;

  @override
  Future<Uint8List?> read(String userId) async {
    final value = await _storage.read(key: '$_prefix$userId');
    if (value == null) return null;
    try {
      final bytes = base64.decode(value);
      return bytes.length == 32 ? Uint8List.fromList(bytes) : null;
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> write(String userId, Uint8List secret) => _storage.write(key: '$_prefix$userId', value: base64.encode(secret));

  @override
  Future<void> deleteAll() async {
    final all = await _storage.readAll();
    for (final key in all.keys.where((k) => k.startsWith(_prefix))) {
      await _storage.delete(key: key);
    }
  }
}
