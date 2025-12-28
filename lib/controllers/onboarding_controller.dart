import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class OnboardingController extends GetxController {
  final GetStorage _storage = GetStorage();

  // Storage keys
  static const String _onboardingKey = 'onboarding_complete';
  static const String _welcomeModalKey = 'has_seen_welcome_modal';

  RxBool _isOnboardingComplete = false.obs;
  RxBool _hasSeenWelcomeModal = false.obs;

  // Getters
  bool get isOnboardingComplete => _isOnboardingComplete.value;
  bool get hasSeenWelcomeModal => _hasSeenWelcomeModal.value;

  @override
  void onInit() {
    super.onInit();
    _loadOnboardingState();
    _loadWelcomeModalState();
  }

  // Load onboarding state from storage
  void _loadOnboardingState() {
    _isOnboardingComplete.value = _storage.read(_onboardingKey) ?? false;
  }

  // Load welcome modal state from storage
  void _loadWelcomeModalState() {
    _hasSeenWelcomeModal.value = _storage.read(_welcomeModalKey) ?? false;
  }

  // Setters with persistent storage
  void setOnboardingComplete(bool value) {
    _isOnboardingComplete.value = value;
    _storage.write(_onboardingKey, value);
  }

  // Mark welcome modal as seen
  void markWelcomeModalAsSeen() {
    _hasSeenWelcomeModal.value = true;
    _storage.write(_welcomeModalKey, true);
  }

  // Reset onboarding state
  void resetOnboarding() {
    _isOnboardingComplete.value = false;
    _storage.remove(_onboardingKey);
  }

  // Reset welcome modal state
  void resetWelcomeModal() {
    _hasSeenWelcomeModal.value = false;
    _storage.remove(_welcomeModalKey);
  }

  // Check if user should skip onboarding
  bool shouldSkipOnboarding() {
    return isOnboardingComplete;
  }
}
