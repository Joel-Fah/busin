import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class OnboardingController extends GetxController {
  final GetStorage _storage = GetStorage();

  // Storage keys
  static const String _onboardingKey = 'onboarding_complete';

  RxBool _isOnboardingComplete = false.obs;

  // Getters
  bool get isOnboardingComplete => _isOnboardingComplete.value;

  @override
  void onInit() {
    super.onInit();
    _loadOnboardingState();
  }

  // Load onboarding state from storage
  void _loadOnboardingState() {
    _isOnboardingComplete.value = _storage.read(_onboardingKey) ?? false;
  }

  // Setters with persistent storage
  void setOnboardingComplete(bool value) {
    _isOnboardingComplete.value = value;
    _storage.write(_onboardingKey, value);
  }

  // Reset onboarding state
  void resetOnboarding() {
    _isOnboardingComplete.value = false;
    _storage.remove(_onboardingKey);
  }

  // Check if user should skip onboarding
  bool shouldSkipOnboarding() {
    return isOnboardingComplete;
  }
}
