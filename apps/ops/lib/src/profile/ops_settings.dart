import 'package:busin_app/busin_app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The staff member's choices for this phone. Harmless, so kept in plain preferences (never anything secret).
class OpsSettings {
  const OpsSettings({this.vibrate = true, this.sound = false, this.offerShare = true});

  /// A buzz on each scan result.
  final bool vibrate;

  /// A short sound on each scan result.
  final bool sound;

  /// Offer to share the bus position right after starting a trip the staff member shares.
  final bool offerShare;

  OpsSettings copyWith({bool? vibrate, bool? sound, bool? offerShare}) =>
      OpsSettings(vibrate: vibrate ?? this.vibrate, sound: sound ?? this.sound, offerShare: offerShare ?? this.offerShare);
}

const _vibrateKey = 'ops.vibrate';
const _soundKey = 'ops.sound';
const _offerShareKey = 'ops.offer_share';

class OpsSettingsNotifier extends Notifier<OpsSettings> {
  @override
  OpsSettings build() {
    final prefs = ref.read(appPreferencesProvider);
    return OpsSettings(
      vibrate: prefs?.getBool(_vibrateKey) ?? true,
      sound: prefs?.getBool(_soundKey) ?? false,
      offerShare: prefs?.getBool(_offerShareKey) ?? true,
    );
  }

  void setVibrate(bool on) => _save(_vibrateKey, on, state.copyWith(vibrate: on));
  void setSound(bool on) => _save(_soundKey, on, state.copyWith(sound: on));
  void setOfferShare(bool on) => _save(_offerShareKey, on, state.copyWith(offerShare: on));

  void _save(String key, bool value, OpsSettings next) {
    state = next;
    ref.read(appPreferencesProvider)?.setBool(key, value);
  }
}

final opsSettingsProvider = NotifierProvider<OpsSettingsNotifier, OpsSettings>(OpsSettingsNotifier.new);
