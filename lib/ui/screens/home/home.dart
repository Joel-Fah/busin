import 'package:busin/ui/components/modals/welcome_modal.dart';
import 'package:busin/ui/screens/home/analytics_tab.dart';
import 'package:busin/ui/screens/home/people_tab.dart';
import 'package:busin/ui/screens/home/scanner.dart';
import 'package:busin/ui/screens/home/scannings_tab.dart';
import 'package:busin/ui/screens/home/subscriptions_tab.dart';
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

    _tabController = TabController(length: 3, vsync: this);
  }

  void _checkVerificationStatus() {
    final user = authController.currentUser.value;
    if (user != null &&
        (user.role == UserRole.staff || user.role == UserRole.admin) &&
        user.status == AccountStatus.pending) {
      // User is pending verification, redirect to verification page
      context.go(VerificationPage.routeName);
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
      if (authController.isAdmin || authController.isStaff) "Analytics",
      if (authController.isStudent) "Home",
      "Subscriptions",
      if (authController.isStudent) "Scannings",
      if (authController.isAdmin || authController.isStaff) "People",
    ];

    final List<List<List<dynamic>>> _tabIcons = [
      if (authController.isAdmin || authController.isStaff) HugeIcons.strokeRoundedDashboardSquare03,
      if (authController.isStudent) HugeIcons.strokeRoundedHome01,
      HugeIcons.strokeRoundedStickyNote02,
      if (authController.isAdmin || authController.isStaff) HugeIcons.strokeRoundedUserMultiple,
      if (authController.isStudent) HugeIcons.strokeRoundedUserIdVerification,
    ];

    List<Widget> _buildTabs() {
      return List<Widget>.generate(_tabLabels.length, (index) {
        if (_currentIndex != index) {
          return AnimatedContainer(
            duration: duration,
            child: HugeIcon(icon: _tabIcons[index]),
          );
        }

        return AnimatedContainer(
          duration: duration,
          child: Row(
            spacing: 4.0,
            children: [
              HugeIcon(icon: _tabIcons[index]),
              Text(_tabLabels[index]),
            ],
          ),
        );
      });
    }

    final List<Widget> _pages = [
      if (authController.isAdmin || authController.isStaff) AnalyticsTab(),
      if (authController.isStudent) HomeTab(),
      if (authController.isStudent) SubscriptionsTab(),
      if (authController.isAdmin || authController.isStaff) SubscriptionsAdminPage(),
      if (authController.isStudent) ScanningsTab(),
      if (authController.isAdmin || authController.isStaff) PeopleTab(),
    ];

    return Scaffold(
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
            child: Material(
              color: Colors.transparent,
              type: MaterialType.transparency,
              child: SizedBox(
                height: 80.0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                            isScrollable: authController.isAdmin || authController.isStaff ? false : true,
                            tabAlignment: TabAlignment.center,
                            controller: _tabController,
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsetsGeometry.all(12.0),
                            onTap: (value) {
                              setState(() {
                                HapticFeedback.selectionClick();
                                _currentIndex = value;
                              });
                            },
                          ),
                        ),
                      ),
                      if (authController.isAdmin || authController.isStaff)
                        SizedBox(
                          height: double.infinity,
                          width: 80.0,
                          child: IconButton.filled(
                            onPressed: () {
                              HapticFeedback.heavyImpact();
                              context.pushNamed(
                                removeLeadingSlash(ScannerPage.routeName),
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
        ],
      ),
    );
  }
}
