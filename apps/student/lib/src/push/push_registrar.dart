import 'package:busin_core/busin_core.dart';
import 'package:flutter/foundation.dart';

import 'push_service.dart';

/// Keeps the server's list of this phone's token right: registers it when the person allows notifications and when
/// Firebase replaces it, and forgets it on sign-out. Every failure is swallowed: a notification is a convenience,
/// and a flaky network must never get in the way of signing in or out.
class PushRegistrar {
  PushRegistrar({required this.push, required this.tokens, required this.languageCode, required this.platform});

  final PushService push;
  final DeviceTokensRepository tokens;
  final String Function() languageCode;
  final TargetPlatform platform;

  /// The token last registered, so sign-out can remove exactly that one.
  String? _registered;

  bool get available => push.available;

  /// The language the server should word notifications in: French if the phone is French, otherwise English.
  String get locale => languageCode() == 'fr' ? 'fr' : 'en';

  String get _platformName => platform == TargetPlatform.iOS ? 'ios' : 'android';

  /// Registers the token if the person has already allowed notifications. Never asks.
  Future<void> syncIfAllowed() async {
    if (!push.available) return;
    try {
      if (await push.permission() != PushPermission.granted) return;
      await _register(await push.token());
    } catch (_) {
      // Try again next time the app starts.
    }
  }

  /// Asks the person, and registers the token if they say yes. Returns what they decided: a server that cannot be
  /// reached right now does not turn their yes into a no (the token is registered the next time the app starts).
  Future<PushPermission> enable() async {
    if (!push.available) return PushPermission.denied;
    final PushPermission answer;
    try {
      answer = await push.requestPermission();
    } catch (_) {
      return PushPermission.denied;
    }
    if (answer == PushPermission.granted) {
      try {
        await _register(await push.token());
      } catch (_) {}
    }
    return answer;
  }

  /// Firebase replaced the token: tell the server.
  Future<void> tokenChanged(String token) async {
    try {
      await _register(token);
    } catch (_) {}
  }

  Future<void> _register(String? token) async {
    if (token == null || token.isEmpty) return;
    await tokens.register(token: token, platform: _platformName, locale: locale);
    _registered = token;
  }

  /// Sign-out: remove this phone from the server, and throw the token away so the next person here gets a fresh one.
  Future<void> forget() async {
    if (!push.available) return;
    final token = _registered ?? await _safeToken();
    try {
      if (token != null) await tokens.unregister(token);
    } catch (_) {
      // Offline at sign-out: the server drops a dead token itself the next time a send fails.
    }
    try {
      await push.forgetToken();
    } catch (_) {}
    _registered = null;
  }

  Future<String?> _safeToken() async {
    try {
      return await push.token();
    } catch (_) {
      return null;
    }
  }
}

/// Where a tapped notification should take the person. Null for a kind this version does not know.
String? routeForPush(PushMessage message) => switch (message.kind) {
      'subscription_approved' || 'subscription_rejected' => '/subscription',
      _ => null,
    };

/// The phone's own language code, for choosing the notification wording.
String systemLanguageCode() => PlatformDispatcher.instance.locale.languageCode;
