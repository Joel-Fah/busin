import 'package:busin/models/actors/roles.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

abstract class BaseUser {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? photoUrl;
  final UserRole role;
  final AccountStatus status;

  const BaseUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.phone,
    this.photoUrl,
  });

  // ----- utilities -----

  bool get isVerified => status.isVerified;

  String get initials {
    final n = name.trim().isNotEmpty ? name : email;
    final parts = n.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final first = parts.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  /// Base map (subclasses can add/override fields on top of this).
  Map<String, dynamic> toBaseMap() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'photoUrl': photoUrl,
    'role': role.name,
    'status': status.name,
  };

  /* ----- helpers for auth/domain/format ----- */

  static bool isAllowedOrgEmail(String? email) {
    if (email == null || email.isEmpty) return false;
    final parts = email.split('@');
    if (parts.length != 2) return false;
    return parts[1].toLowerCase() == 'ictuniversity.edu.cm';
  }

  static bool isGoogleOnly(fb_auth.User user) =>
      user.providerData.isNotEmpty &&
          user.providerData.every((p) => p.providerId == 'google.com');

  /* Throws if user is not Google-only or not from the allowed org domain. */
  static void assertGoogleOrgOrThrow(fb_auth.User user) {
    if (!isGoogleOnly(user)) {
      throw StateError('Authentication must be via Google only.');
    }
    if (!isAllowedOrgEmail(user.email)) {
      throw StateError('Only @ictuniversity.edu.cm accounts are allowed.');
    }
  }
}
