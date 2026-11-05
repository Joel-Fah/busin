import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Keeps the screen out of screenshots, screen recordings and the recent-apps preview while the boarding
/// code is showing. On Android this is the window's secure flag. iOS cannot block screenshots, so there it
/// does nothing and says so ([supported] is false), and the app does not claim otherwise.
abstract interface class ScreenSecurity {
  bool get supported;

  Future<void> setSecure(bool secure);
}

class MethodChannelScreenSecurity implements ScreenSecurity {
  MethodChannelScreenSecurity();

  static const _channel = MethodChannel('app.busin/screen_security');

  @override
  bool get supported => defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<void> setSecure(bool secure) async {
    if (!supported) return;
    try {
      await _channel.invokeMethod<void>('setSecure', secure);
    } on PlatformException {
      // Failing to change the flag must never stop the code from showing.
    } on MissingPluginException {
      // Not running on a build that has the channel (for example a test).
    }
  }
}
