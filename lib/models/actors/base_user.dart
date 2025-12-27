import 'package:busin/models/actors/roles.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

enum Gender {
  male,
  female,
  preferNotToSay;

  String get label {
    switch (this) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.preferNotToSay:
        return 'Prefer not to say';
    }
  }

  static Gender fromString(String? value) {
    if (value == null) return Gender.preferNotToSay;
    switch (value.toLowerCase()) {
      case 'male':
        return Gender.male;
      case 'female':
        return Gender.female;
      default:
        return Gender.preferNotToSay;
    }
  }
}

abstract class BaseUser {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? photoUrl;
  final UserRole role;
  final AccountStatus status;
  final Gender? gender;
  final DateTime? createdAt;
  final DateTime? lastSignInAt;

  const BaseUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.phone,
    this.photoUrl,
    this.gender,
    this.createdAt,
    this.lastSignInAt,
  });

  // ----- utilities -----

  bool get isVerified => status.isVerified;

  String get initials {
    final n = name.trim().isNotEmpty ? name.trim() : email.trim();
    if (n.isEmpty) return '??';
    final parts = n.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final letters = parts.map((p) => p[0]).join();
    if (letters.length >= 2) return letters.substring(0, 2).toUpperCase();
    if (letters.length == 1) {
      final first = letters;
      final firstPart = parts.isNotEmpty ? parts.first : n;
      final condensed = firstPart.replaceAll(RegExp(r'\s+'), '');
      final second = condensed.length >= 2
          ? condensed[1]
          : (n.replaceAll(RegExp(r'\s+'), '').length >= 2
                ? n.replaceAll(RegExp(r'\s+'), '')[1]
                : first);
      return (first + second).toUpperCase();
    }
    final condensed = n.replaceAll(RegExp(r'\s+'), '');
    if (condensed.length >= 2) return condensed.substring(0, 2).toUpperCase();
    if (condensed.length == 1) return (condensed + condensed).toUpperCase();
    return '??';
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
    'gender': gender?.name,
    'createdAt': createdAt?.toIso8601String(),
    'lastSignInAt': lastSignInAt?.toIso8601String(),
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

  /// Safe parse for date coming from map (String / int / DateTime / null)
  static DateTime? parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    if (value is int) {
      // treat as millisecondsSinceEpoch if large enough
      try {
        if (value > 1000000000) return DateTime.fromMillisecondsSinceEpoch(value);
      } catch (_) {}
    }
    return null;
  }

  /// Returns a short age (days since creation) if metadata available.
  int? get accountAgeDays => createdAt == null ? null : DateTime.now().difference(createdAt!).inDays;
}
