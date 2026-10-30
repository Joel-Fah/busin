import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends GetxController with WidgetsBindingObserver {
  static const String _storageKey = 'theme_mode';

  ThemeController({GetStorage? box}) : _box = box ?? GetStorage();

  final GetStorage _box;

  // Reactive theme mode (what the user selected)
  final Rx<ThemeMode> _mode = ThemeMode.system.obs;

  // Reactive system brightness (used when mode == ThemeMode.system)
  final Rx<Brightness> _systemBrightness =
      WidgetsBinding.instance.platformDispatcher.platformBrightness.obs;

  // Public getters
  ThemeMode get themeMode => _mode.value;
  Brightness get systemBrightness => _systemBrightness.value;

  /// Effective Brightness the UI should consider (accounts for system mode)
  Brightness get effectiveBrightness => _mode.value == ThemeMode.system
      ? _systemBrightness.value
      : (_mode.value == ThemeMode.dark ? Brightness.dark : Brightness.light);

  bool get isDark => effectiveBrightness == Brightness.dark;

  /// Optional convenience stream to react to mode changes
  Stream<ThemeMode> get modeStream => _mode.stream;

  /// Ensure GetStorage is initialized before using the controller.
  static Future<void> ensureStorageInitialized({String? container}) async {
    // If GetStorage.init is already called, calling again is a no-op.
    if (container == null || container.isEmpty) {
      await GetStorage.init();
    } else {
      await GetStorage.init(container);
    }
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _loadFromStorage();

    // Persist and apply any subsequent changes
    ever<ThemeMode>(_mode, (m) {
      _persist(m);
      _applyToApp(m);
    });
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangePlatformBrightness() {
    // Update system brightness for reactive dependents
    _systemBrightness.value =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    // If following system, ensure the app reflects it
    if (_mode.value == ThemeMode.system) {
      _applyToApp(ThemeMode.system);
    }
  }

  // Public API --------------------------------------------------------------

  void setThemeMode(ThemeMode mode) {
    _mode.value = mode;
    // ever() will persist and apply
  }

  void setSystem() => setThemeMode(ThemeMode.system);
  void setLight() => setThemeMode(ThemeMode.light);
  void setDark() => setThemeMode(ThemeMode.dark);

  /// Toggle between dark and light (ignores system mode for the toggle)
  void toggleDarkLight() {
    final next = isDark ? ThemeMode.light : ThemeMode.dark;
    setThemeMode(next);
  }

  /// Cycle through: system -> light -> dark -> system
  void cycleNext() {
    switch (_mode.value) {
      case ThemeMode.system:
        setLight();
        break;
      case ThemeMode.light:
        setDark();
        break;
      case ThemeMode.dark:
        setSystem();
        break;
    }
  }

  // Internal helpers --------------------------------------------------------

  void _applyToApp(ThemeMode m) {
    // If the app uses GetMaterialApp, this will update themeMode live
    Get.changeThemeMode(m);
  }

  void _loadFromStorage() {
    try {
      final String? stored = _box.read<String>(_storageKey);
      final ThemeMode initial = _parseMode(stored) ?? ThemeMode.system;
      _mode.value = initial;
      _applyToApp(initial);
    } catch (_) {
      // In case storage isn't ready or another issue occurs, default to system
      _mode.value = ThemeMode.system;
      _applyToApp(ThemeMode.system);
    }
  }

  void _persist(ThemeMode m) {
    try {
      _box.write(_storageKey, m.name); // 'system' | 'light' | 'dark'
    } catch (_) {
      // Ignore persistence errors silently
    }
  }

  ThemeMode? _parseMode(String? raw) {
    switch (raw) {
      case 'system':
        return ThemeMode.system;
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return null;
    }
  }
}
