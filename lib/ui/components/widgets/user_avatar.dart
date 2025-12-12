import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/auth_controller.dart';
import '../../../utils/constants.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, this.tag, this.radius=24.0});

  final String? tag;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    return authController.userProfileImage.isEmpty
        ? CircleAvatar(
            radius: radius ?? 24.0,
            backgroundColor: Colors.primaries.elementAt(
              Random().nextInt(Colors.primaries.length),
            ),
            child: Text(
              authController.currentUser.value!.initials,
              style: radius! > 24.0 ? AppTextStyles.h2.copyWith(color: lightColor) : AppTextStyles.h4.copyWith(color: lightColor),
            ),
          )
        : CachedNetworkImage(
            imageUrl: authController.userProfileImage,
            fit: BoxFit.cover,
            imageBuilder: (context, imageProvider) {
              if (tag != null && tag!.isNotEmpty) {
                return Hero(
                  tag: tag!,
                  child: CircleAvatar(
                    radius: radius ?? 24.0,
                    backgroundImage: imageProvider,
                    // backgroundColor: Colors.transparent,
                  ),
                );
              }
              return CircleAvatar(
                radius: radius ?? 24.0,
                backgroundImage: imageProvider,
                // backgroundColor: Colors.transparent,
              );
            },
            placeholder: (context, url) => CircleAvatar(
              radius: 24.0,
              backgroundColor: Colors.primaries.elementAt(
                Random().nextInt(Colors.primaries.length),
              ),
              child: Text(
                authController.currentUser.value!.initials,
                style: AppTextStyles.h4.copyWith(color: lightColor),
              ),
            ),
            errorWidget: (context, url, error) => CircleAvatar(
              radius: radius ?? 24.0,
              backgroundColor: Colors.primaries.elementAt(
                Random().nextInt(Colors.primaries.length),
              ),
              child: Text(
                authController.currentUser.value!.initials,
                style: radius! > 24.0 ? AppTextStyles.h2.copyWith(color: lightColor) : AppTextStyles.h4.copyWith(color: lightColor),
              ),
            ),
          );
  }
}
