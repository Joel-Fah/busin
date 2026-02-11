import 'package:busin/ui/components/modals/welcome_modal.dart';
import 'package:busin/ui/screens/home/analytics_tab.dart';
import 'package:busin/ui/screens/home/people_tab.dart';
import 'package:busin/ui/screens/home/scanner.dart';
import 'package:busin/ui/screens/home/scannings_tab.dart';
import 'package:busin/ui/screens/home/subscriptions_tab.dart';
import 'package:busin/ui/screens/home/updates_tab.dart';
import 'package:busin/ui/screens/onboarding/verification.dart';
import 'package:busin/ui/screens/profile/subscriptions_admin.dart';
import 'package:busin/utils/constants.dart';
import 'package:busin/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../controllers/auth_controller.dart';
import '../../../controllers/update_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/actors/roles.dart';
import 'home_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const String routeName = '/home';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  // GetX Controllers
  final AuthController authController = Get.find<AuthController>();
  final UpdateController updateController = Get.find<UpdateController>();

  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();

    // Check if user is pending verification and redirect, then show welcome modal
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVerificationStatus();
      _showWelcomeModal();
    });

    // 3 tabs for admin/staff, 4 tabs for students (Home, Subscriptions, Updates, Scannings)
    _tabController = TabController(
      length: authController.isStudent ? 4 : 3,
      vsync: this,
    );
  }

  void _checkVerificationStatus() {
    final user = authController.currentUser.value;
    if (user != null &&
        (user.role == UserRole.staff || user.role == UserRole.admin) &&
        user.status == AccountStatus.pending) {
      // User is pending verification, redirect to verification page
      context.goNamed(removeLeadingSlash(VerificationPage.routeName));
    }
  }

  Future<void> _showWelcomeModal() async {
    // Only show if user is not pending verification
    final user = authController.currentUser.value;
    if (user != null && user.status != AccountStatus.pending) {
      await WelcomeModal.showIfNeeded(context);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> _tabLabels = [
      if (authController.isAdmin || authController.isStaff)
        AppLocalizations.of(context)!.homeNav_analyticsTab,
      if (authController.isStudent)
        AppLocalizations.of(context)!.homeNav_studentHomeTab,
      AppLocalizations.of(context)!.homeNav_subscriptionsTab,
      if (authController.isStudent)
        localeController.locale.languageCode == 'en' ? 'Updates' : 'Actus',
      if (authController.isStudent)
        AppLocalizations.of(context)!.homeNav_scanningsTab,
      if (authController.isAdmin || authController.isStaff)
        AppLocalizations.of(context)!.homeNav_peopleTab,
    ];

    final List<List<List<dynamic>>> _tabIcons = [
      if (authController.isAdmin || authController.isStaff)
        HugeIcons.strokeRoundedDashboardSquare03,
      if (authController.isStudent) HugeIcons.strokeRoundedHome01,
      HugeIcons.strokeRoundedStickyNote02,
      if (authController.isStudent) HugeIcons.strokeRoundedNotification03,
      if (authController.isAdmin || authController.isStaff)
        HugeIcons.strokeRoundedUserMultiple,
      if (authController.isStudent) HugeIcons.strokeRoundedUserIdVerification,
    ];

    // Determine the Updates tab index for students (it's after Home + Subscriptions = index 2)
    final int? updatesTabIndex = authController.isStudent ? 2 : null;

    List<Widget> _buildTabs() {
      return List<Widget>.generate(_tabLabels.length, (index) {
        final bool isUpdatesTab =
            updatesTabIndex != null && index == updatesTabIndex;

        Widget icon = HugeIcon(icon: _tabIcons[index]);

        // Wrap the Updates icon with badge
        if (isUpdatesTab) {
          icon = Obx(() {
            final hasUnseen = updateController.hasUnseenUpdates;
            return Badge(
              isLabelVisible: hasUnseen && _currentIndex != updatesTabIndex,
              backgroundColor: Colors.redAccent,
              smallSize: 8,
              child: HugeIcon(icon: _tabIcons[index]),
            );
          });
        }

        if (_currentIndex != index) {
          return AnimatedContainer(duration: duration, child: icon);
        }

        return AnimatedContainer(
          duration: duration,
          child: Row(spacing: 4.0, children: [icon, Text(_tabLabels[index])]),
        );
      });
    }

    final List<Widget> _pages = [
      if (authController.isAdmin || authController.isStaff) AnalyticsTab(),
      if (authController.isStudent) HomeTab(),
      if (authController.isStudent) SubscriptionsTab(),
      if (authController.isAdmin || authController.isStaff)
        SubscriptionsAdminPage(),
      if (authController.isStudent) UpdatesTab(),
      if (authController.isStudent) ScanningsTab(),
      if (authController.isAdmin || authController.isStaff) PeopleTab(),
    ];

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentIndex != 0) {
          _tabController.animateTo(0);
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        extendBody: true,
        body: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              controller: _tabController,
              children: _pages,
            ),
            Positioned(
              bottom: MediaQuery.viewPaddingOf(context).bottom + 8.0,
              left: 0,
              right: 0,
              child: Obx(() {
                final shouldHide = updateController.isInputFocused.value;
                return AnimatedSlide(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  offset: shouldHide ? const Offset(0, 2) : Offset.zero,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    opacity: shouldHide ? 0.0 : 1.0,
                    child: IgnorePointer(
                      ignoring: shouldHide,
                      child: Material(
                        color: Colors.transparent,
                        type: MaterialType.transparency,
                        child: SizedBox(
                          height: 80.0,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Row(
                              spacing: 10.0,
                              children: [
                                Expanded(
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      color: themeController.isDark
                                          ? seedPalette.shade800
                                          : seedColor,
                                      borderRadius: borderRadius * 3.75,
                                    ),
                                    child: TabBar(
                                      tabs: _buildTabs(),
                                      isScrollable:
                                          authController.isAdmin ||
                                              authController.isStaff
                                          ? false
                                          : true,
                                      tabAlignment: TabAlignment.center,
                                      controller: _tabController,
                                      physics: const BouncingScrollPhysics(),
                                      padding: EdgeInsetsGeometry.all(12.0),
                                      onTap: (value) {
                                        setState(() {
                                          HapticFeedback.selectionClick();
                                          _currentIndex = value;
                                        });
                                        // Clear badge when user taps Updates tab
                                        if (updatesTabIndex != null &&
                                            value == updatesTabIndex) {
                                          updateController.markAsSeen();
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                if (authController.isAdmin ||
                                    authController.isStaff)
                                  SizedBox(
                                    height: double.infinity,
                                    width: 80.0,
                                    child: IconButton.filled(
                                      onPressed: () {
                                        HapticFeedback.heavyImpact();
                                        context.pushNamed(
                                          removeLeadingSlash(
                                            ScannerPage.routeName,
                                          ),
                                        );
                                      },
                                      color: lightColor,
                                      style: IconButton.styleFrom(
                                        backgroundColor: accentColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: borderRadius * 3.25,
                                        ),
                                      ),
                                      icon: HugeIcon(
                                        icon: HugeIcons.strokeRoundedQrCode01,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
