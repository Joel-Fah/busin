import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/auth_controller.dart';
import '../../../models/actors/base_user.dart';
import '../../../utils/constants.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.tag,
    this.radius = 24.0,
    this.user,
  });

  final String? tag;
  final double? radius;
  final BaseUser? user; // Optional user to display, defaults to current user

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    // Use provided user or fall back to current user
    final displayUser = user ?? authController.currentUser.value;
    final photoUrl = user?.photoUrl ?? authController.userProfileImage;

    if (displayUser == null) {
      // Fallback if no user is available
      return CircleAvatar(
        radius: radius ?? 24.0,
        backgroundColor: Colors.grey,
        child: Icon(Icons.person, color: lightColor),
      );
    }

    return photoUrl.isEmpty
        ? CircleAvatar(
            radius: radius ?? 24.0,
            backgroundColor: Colors.primaries.elementAt(
              displayUser.initials.hashCode.abs() % Colors.primaries.length,
            ),
            child: Text(
              displayUser.initials,
              style: radius! > 24.0
                  ? AppTextStyles.h2.copyWith(color: lightColor)
                  : AppTextStyles.h4.copyWith(color: lightColor),
            ),
          )
        : CachedNetworkImage(
            imageUrl: photoUrl,
            fit: BoxFit.cover,
            imageBuilder: (context, imageProvider) {
              if (tag != null && tag!.isNotEmpty) {
                return Hero(
                  tag: tag!,
                  child: CircleAvatar(
                    radius: radius ?? 24.0,
                    backgroundImage: imageProvider,
                  ),
                );
              }
              return CircleAvatar(
                radius: radius ?? 24.0,
                backgroundImage: imageProvider,
              );
            },
            placeholder: (context, url) => CircleAvatar(
              radius: 24.0,
              backgroundColor: Colors.primaries.elementAt(
                displayUser.initials.hashCode.abs() % Colors.primaries.length,
              ),
              child: Text(
                displayUser.initials,
                style: AppTextStyles.h4.copyWith(color: lightColor),
              ),
            ),
            errorWidget: (context, url, error) => CircleAvatar(
              radius: radius ?? 24.0,
              backgroundColor: Colors.primaries.elementAt(
                displayUser.initials.hashCode.abs() % Colors.primaries.length,
              ),
              child: Text(
                displayUser.initials,
                style: radius! > 24.0
                    ? AppTextStyles.h2.copyWith(color: lightColor)
                    : AppTextStyles.h4.copyWith(color: lightColor),
              ),
            ),
          );
  }
}
