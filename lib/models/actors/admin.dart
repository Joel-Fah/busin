import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:busin/models/actors/base_user.dart';
import 'package:busin/models/actors/roles.dart';
import 'package:busin/models/subscription.dart';

class Admin extends BaseUser {
  final List<String> scopes; // e.g., ['approve_subscription', 'manage_users']

  const Admin({
    required super.id,
    required super.name,
    required super.email,
    required super.status,
    this.scopes = const [],
    super.phone,
    super.photoUrl,
    super.gender,
    super.createdAt,
    super.lastSignInAt,
  }) : super(role: UserRole.admin);

  factory Admin.fromMap(Map<String, dynamic> map) {
    return Admin(
      id: map['id'] as String,
      name: (map['name'] as String?)?.trim() ?? '',
      email: (map['email'] as String?)?.trim() ?? '',
      status: AccountStatus.from((map['status'] as String?) ?? 'pending'),
      phone: (map['phone'] as String?)?.trim(),
      photoUrl: (map['photoUrl'] as String?)?.trim(),
      gender: Gender.fromString(map['gender'] as String?),
      createdAt: BaseUser.parseDate(map['createdAt']),
      lastSignInAt: BaseUser.parseDate(map['lastSignInAt']),
      scopes: (map['scopes'] as List?)?.cast<String>() ?? const [],
    );
  }

  Map<String, dynamic> toMap() => {
        ...toBaseMap(),
        'scopes': scopes,
      };

  factory Admin.fromFirebaseUser(
    fb_auth.User user, {
    AccountStatus status = AccountStatus.verified,
    List<String> scopes = const [],
  }) {
    BaseUser.assertGoogleOrgOrThrow(user);
    final displayName = (user.displayName ?? '').trim();
    final fallbackName = (user.email ?? '').split('@').first;
    return Admin(
      id: user.uid,
      name: displayName.isNotEmpty ? displayName : fallbackName,
      email: user.email ?? '',
      status: status,
      phone: user.phoneNumber,
      photoUrl: user.photoURL,
      createdAt: user.metadata.creationTime,
      lastSignInAt: user.metadata.lastSignInTime,
      scopes: scopes,
    );
  }

  bool get isSuperAdmin => scopes.contains('all');

  bool hasScope(String s) => isSuperAdmin || scopes.contains(s);

  // --- subscription helpers ---
  bool get canReviewSubscriptions => hasScope('approve_subscription');

  BusSubscription approve(BusSubscription s, {DateTime? startDate, DateTime? endDate}) {
    if (!canReviewSubscriptions) {
      throw StateError('Admin lacks approve_subscription scope');
    }
    return s.approve(reviewerUserId: id, startDate: startDate, endDate: endDate);
  }

  BusSubscription reject(BusSubscription s, {required String reason}) {
    if (!canReviewSubscriptions) {
      throw StateError('Admin lacks approve_subscription scope');
    }
    return s.reject(reviewerUserId: id, reason: reason);
  }

  Admin copyWith({
    String? id,
    String? name,
    String? email,
    AccountStatus? status,
    String? phone,
    String? photoUrl,
    List<String>? scopes,
    DateTime? createdAt,
    DateTime? lastSignInAt,
  }) =>
      Admin(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        status: status ?? this.status,
        phone: phone ?? this.phone,
        photoUrl: photoUrl ?? this.photoUrl,
        createdAt: createdAt ?? this.createdAt,
        lastSignInAt: lastSignInAt ?? this.lastSignInAt,
        scopes: scopes ?? this.scopes,
      );

  @override
  String toString() {
    return 'Admin(id: $id, name: $name, email: $email, status: ${status.name}, scopes: $scopes, createdAt: $createdAt, lastSignInAt: $lastSignInAt)';
  }
}
