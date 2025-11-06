import 'package:busin/utils/constants.dart';
import 'package:busin/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoadingPage extends StatelessWidget {
  static const String routeName = '/loading';

  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16.0,
          children: [
            SvgPicture.asset(
                  themeController.isDark ? whiteLogo : cyanLogo,
                  width: 100.0,
                )
                .animate(
                  onInit: (controller) => controller.repeat(reverse: true),
                  onPlay: (controller) => controller.repeat(reverse: true),
                )
                .shimmer(color: Colors.grey, duration: 2000.ms),
            Text(
              'Loading your journey...',
              style: AppTextStyles.body.copyWith(
                color: themeController.isDark ? Colors.white70 : Colors.black87,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
