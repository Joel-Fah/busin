import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../../utils/constants.dart';

Future<dynamic> buildLoadingIndicator(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) {
      return Material(
        color: Colors.transparent,
        type: MaterialType.transparency,
        child: Stack(
          children: [
            ModalBarrier(dismissible: false),
            Animate(
              effects: [FadeEffect(), MoveEffect()],
              child:
                  Center(
                    child: Column(
                      spacing: 8.0,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const LoadingIndicator(),
                        Text(
                          'Loading, please wait...',
                          style: AppTextStyles.body.copyWith(
                            color: lightColor.withValues(alpha: 0.75),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fade().scale().move(
                    begin: const Offset(0, 50),
                    end: const Offset(0, 0),
                    duration: 500.ms,
                  ),
            ),
          ],
        ),
      );
    },
  );
}

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key, this.size = 50.0});

  final double? size;

  @override
  Widget build(BuildContext context) {
    return LoadingAnimationWidget.flickr(
      leftDotColor: accentPalette.shade200,
      rightDotColor: accentColor,
      size: size ?? 50.0,
    );
  }
}
