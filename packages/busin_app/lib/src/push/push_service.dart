import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Whether this phone will show notifications from BusIn.
enum PushPermission {
  /// Not asked yet.
  notAsked,
  granted,
  denied,
}

/// A notification the person tapped, or one that arrived while the app was open. Only what the server sends:
/// what kind of event, and the record it is about. No personal text travels this way.
class PushMessage {
  const PushMessage({required this.kind, this.refId});

  final String kind;
  final String? refId;
}

/// Firebase Cloud Messaging, behind an interface: the app never touches the SDK directly, so tests use a fake
/// and a build without Firebase configured simply has [available] false.
abstract interface class PushService {
  /// False when Firebase is not set up in this build (no google-services.json). Everything else then does nothing.
  bool get available;

  /// What the person has allowed so far, without asking.
  Future<PushPermission> permission();

  /// Asks, which may show the system dialog (Android 13 and later, iOS). Returns the answer.
  Future<PushPermission> requestPermission();

  /// This phone's token, or null when there is none (not allowed, or not available).
  Future<String?> token();

  /// A new token, when Firebase replaces the old one.
  Stream<String> get tokenRefreshes;

  /// The person tapped a notification while the app was in the background.
  Stream<PushMessage> get taps;

  /// The app was opened from a notification, if it was.
  Future<PushMessage?> launchedBy();

  /// A notification arrived while the app was open (the system does not show it then).
  Stream<PushMessage> get foreground;

  /// Throws away this phone's token, so the next person to sign in here gets their own.
  Future<void> forgetToken();
}

/// Used when Firebase is not configured: nothing is available and nothing happens.
class NoPushService implements PushService {
  const NoPushService();

  @override
  bool get available => false;

  @override
  Future<PushPermission> permission() async => PushPermission.notAsked;

  @override
  Future<PushPermission> requestPermission() async => PushPermission.denied;

  @override
  Future<String?> token() async => null;

  @override
  Stream<String> get tokenRefreshes => const Stream.empty();

  @override
  Stream<PushMessage> get taps => const Stream.empty();

  @override
  Future<PushMessage?> launchedBy() async => null;

  @override
  Stream<PushMessage> get foreground => const Stream.empty();

  @override
  Future<void> forgetToken() async {}
}

PushMessage? _messageFrom(RemoteMessage message) {
  final kind = message.data['kind'];
  if (kind is! String || kind.isEmpty) return null;
  final ref = message.data['ref_id'];
  return PushMessage(kind: kind, refId: ref is String ? ref : null);
}

PushPermission _permissionFrom(AuthorizationStatus status) => switch (status) {
      AuthorizationStatus.authorized || AuthorizationStatus.provisional => PushPermission.granted,
      AuthorizationStatus.denied || AuthorizationStatus.deniedPermanently => PushPermission.denied,
      AuthorizationStatus.notDetermined => PushPermission.notAsked,
    };

// firebase_messaging 17 deprecates getToken, onTokenRefresh and deleteToken in favour of register() and onRegistered,
// which hand out Firebase Installation IDs. The server sends to FCM registration tokens (HTTP v1 `message.token`), so this
// uses the documented token calls until a real device test shows an installation ID is accepted the same way.
// ignore_for_file: deprecated_member_use
class FirebasePushService implements PushService {
  FirebasePushService._();

  /// Starts Firebase, or gives back [NoPushService] when this build has no Firebase configuration. Never throws:
  /// a missing or broken configuration must not stop the app from starting.
  static Future<PushService> tryCreate() async {
    try {
      await Firebase.initializeApp();
      return FirebasePushService._();
    } catch (e) {
      if (kDebugMode) debugPrint('Push notifications are off: Firebase is not configured (${e.runtimeType}).');
      return const NoPushService();
    }
  }

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  @override
  bool get available => true;

  @override
  Future<PushPermission> permission() async => _permissionFrom((await _messaging.getNotificationSettings()).authorizationStatus);

  @override
  Future<PushPermission> requestPermission() async => _permissionFrom((await _messaging.requestPermission()).authorizationStatus);

  @override
  Future<String?> token() => _messaging.getToken();

  @override
  Stream<String> get tokenRefreshes => _messaging.onTokenRefresh;

  @override
  Stream<PushMessage> get taps => FirebaseMessaging.onMessageOpenedApp.map(_messageFrom).where((m) => m != null).cast<PushMessage>();

  @override
  Future<PushMessage?> launchedBy() async {
    final initial = await _messaging.getInitialMessage();
    return initial == null ? null : _messageFrom(initial);
  }

  @override
  Stream<PushMessage> get foreground => FirebaseMessaging.onMessage.map(_messageFrom).where((m) => m != null).cast<PushMessage>();

  @override
  Future<void> forgetToken() => _messaging.deleteToken();
}
