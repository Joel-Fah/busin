import 'package:busin/models/actors/roles.dart';
import 'package:busin/ui/components/widgets/home/appbar_list_tile.dart';
import 'package:busin/ui/screens/home/scannings_tab.dart';
import 'package:busin/ui/screens/home/subscriptions_tab.dart';
import 'package:busin/utils/constants.dart';
import 'package:busin/utils/utils.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../controllers/auth_controller.dart';
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
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> _tabLabels = ["Home", "Subscriptions", "Scannings"];

    final List<List<List<dynamic>>> _tabIcons = [
      HugeIcons.strokeRoundedHome01,
      HugeIcons.strokeRoundedStickyNote02,
      HugeIcons.strokeRoundedUserIdVerification,
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

    return Scaffold(
      extendBody: true,
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            controller: _tabController,
            children: [HomeTab(), SubscriptionsTab(), ScanningsTab()],
          ),
          Positioned(
            bottom: MediaQuery.viewPaddingOf(context).bottom,
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
                            color: seedColor,
                            borderRadius: borderRadius * 3.75,
                          ),
                          child: TabBar(
                            tabs: _buildTabs(),
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
                      SizedBox(
                        height: double.infinity,
                        width: 80.0,
                        child: IconButton.filled(
                          onPressed: () {
                            HapticFeedback.heavyImpact();
                          },
                          color: lightColor,
                          style: IconButton.styleFrom(
                            backgroundColor: accentColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: borderRadius * 3.25,
                            ),
                          ),
                          icon: HugeIcon(icon: HugeIcons.strokeRoundedQrCode01),
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
