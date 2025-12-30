import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:busin/models/actors/base_user.dart';
import 'package:busin/models/actors/roles.dart';
import 'package:busin/models/subscription.dart';

/// Staff covers personnel who can scan QR codes or manage on-ground operations.
class Staff extends BaseUser {
  final List<String> permissions; // e.g., ['scan_qr', 'verify_subscription']

  const Staff({
    required super.id,
    required super.name,
    required super.email,
    required super.status,
    this.permissions = const [],
    super.phone,
    super.photoUrl,
    super.gender,
    super.createdAt,
    super.lastSignInAt,
    super.updatedAt,
  }) : super(role: UserRole.staff);

  factory Staff.fromMap(Map<String, dynamic> map) {
    return Staff(
      id: map['id'] as String,
      name: (map['name'] as String?)?.trim() ?? '',
      email: (map['email'] as String?)?.trim() ?? '',
      status: AccountStatus.from((map['status'] as String?) ?? 'pending'),
      phone: (map['phone'] as String?)?.trim(),
      photoUrl: (map['photoUrl'] as String?)?.trim(),
      gender: Gender.fromString(map['gender'] as String?),
      createdAt: BaseUser.parseDate(map['createdAt']),
      lastSignInAt: BaseUser.parseDate(map['lastSignInAt']),
      updatedAt: BaseUser.parseDate(map['updatedAt']),
      permissions: (map['permissions'] as List?)?.cast<String>() ?? const [],
    );
  }

  Map<String, dynamic> toMap() => {...toBaseMap(), 'permissions': permissions};

  factory Staff.fromFirebaseUser(
    fb_auth.User user, {
    AccountStatus status = AccountStatus.verified,
    String? staffId,
    List<String> permissions = const [],
  }) {
    BaseUser.assertGoogleOrgOrThrow(user);
    final displayName = (user.displayName ?? '').trim();
    final fallbackName = (user.email ?? '').split('@').first;
    return Staff(
      id: user.uid,
      name: displayName.isNotEmpty ? displayName : fallbackName,
      email: user.email ?? '',
      status: status,
      phone: user.phoneNumber,
      photoUrl: user.photoURL,
      createdAt: user.metadata.creationTime,
      lastSignInAt: user.metadata.lastSignInTime,
      updatedAt: user.metadata.creationTime, // Initially same as createdAt
      permissions: permissions,
    );
  }

  bool get canScanQr => role.canScanQr && isVerified;

  bool hasPermission(String p) => permissions.contains(p);

  // --- subscription helpers ---
  bool get canReviewSubscriptions => hasPermission('verify_subscription');

  BusSubscription approve(
    BusSubscription s, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    if (!canReviewSubscriptions) {
      throw StateError('Staff lacks verify_subscription permission');
    }
    return s.approve(
      reviewerUserId: id,
      startDate: startDate,
      endDate: endDate,
    );
  }

  BusSubscription reject(BusSubscription s, {required String reason}) {
    if (!canReviewSubscriptions) {
      throw StateError('Staff lacks verify_subscription permission');
    }
    return s.reject(reviewerUserId: id, reason: reason);
  }

  Staff copyWith({
    String? id,
    String? name,
    String? email,
    AccountStatus? status,
    String? phone,
    String? photoUrl,
    Gender? gender,
    String? staffId,
    DateTime? createdAt,
    DateTime? lastSignInAt,
    DateTime? updatedAt,
    List<String>? permissions,
  }) => Staff(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
    status: status ?? this.status,
    phone: phone ?? this.phone,
    photoUrl: photoUrl ?? this.photoUrl,
    gender: gender ?? this.gender,
    createdAt: createdAt ?? this.createdAt,
    lastSignInAt: lastSignInAt ?? this.lastSignInAt,
    updatedAt: updatedAt ?? this.updatedAt,
    permissions: permissions ?? this.permissions,
  );

  @override
  String toString() {
    return 'Staff(id: $id, name: $name, email: $email, status: ${status.label}, permissions: $permissions, createdAt: $createdAt, lastSignInAt: $lastSignInAt)';
  }
}
