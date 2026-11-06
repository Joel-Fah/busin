import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers.dart';
import 'push_service.dart';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) => SharedPreferences.getInstance());

const _dismissedKey = 'push.prompt.dismissed';

/// What the person has allowed, read when asked (not cached: they can change it in the phone's settings).
final pushPermissionProvider = FutureProvider.autoDispose<PushPermission>((ref) => ref.watch(pushServiceProvider).permission());

/// Whether to offer to turn notifications on: only when Firebase is set up, the person has not allowed them, and
/// they have not said "not now". Asked once and remembered; the system dialog is only ever shown after they say yes.
final showPushPromptProvider = FutureProvider.autoDispose<bool>((ref) async {
  final push = ref.watch(pushServiceProvider);
  if (!push.available) return false;
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  if (prefs.getBool(_dismissedKey) ?? false) return false;
  return await ref.watch(pushPermissionProvider.future) != PushPermission.granted;
});

Future<void> dismissPushPrompt(WidgetRef ref) async {
  final prefs = await ref.read(sharedPreferencesProvider.future);
  await prefs.setBool(_dismissedKey, true);
  ref.invalidate(showPushPromptProvider);
}
