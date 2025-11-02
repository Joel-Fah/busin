import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:busin/models/actors/base_user.dart';
import 'package:busin/models/actors/roles.dart';
import 'package:busin/models/subscription.dart';

/// Staff covers personnel who can scan QR codes or manage on-ground operations.
class Staff extends BaseUser {
  final String? staffId; // Optional internal staff identifier
  final List<String> permissions; // e.g., ['scan_qr', 'verify_subscription']

  const Staff({
    required super.id,
    required super.name,
    required super.email,
    required super.status,
    this.staffId,
    this.permissions = const [],
    super.phone,
    super.photoUrl,
  }) : super(role: UserRole.staff);

  factory Staff.fromMap(Map<String, dynamic> map) {
    return Staff(
      id: map['id'] as String,
      name: (map['name'] as String?)?.trim() ?? '',
      email: (map['email'] as String?)?.trim() ?? '',
      status: AccountStatus.from((map['status'] as String?) ?? 'pending'),
      phone: (map['phone'] as String?)?.trim(),
      photoUrl: (map['photoUrl'] as String?)?.trim(),
      staffId: (map['staffId'] as String?)?.trim(),
      permissions: (map['permissions'] as List?)?.cast<String>() ?? const [],
    );
  }

  Map<String, dynamic> toMap() => {
        ...toBaseMap(),
        'staffId': staffId,
        'permissions': permissions,
      };

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
      staffId: staffId,
      permissions: permissions,
    );
  }

  bool get canScanQr => role.canScanQr && isVerified;

  bool hasPermission(String p) => permissions.contains(p);

  // --- subscription helpers ---
  bool get canReviewSubscriptions => hasPermission('verify_subscription');

  Subscription approve(Subscription s, {DateTime? startDate, DateTime? endDate}) {
    if (!canReviewSubscriptions) {
      throw StateError('Staff lacks verify_subscription permission');
    }
    return s.approve(reviewerUserId: id, startDate: startDate, endDate: endDate);
  }

  Subscription reject(Subscription s, {required String reason}) {
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
    String? staffId,
    List<String>? permissions,
  }) => Staff(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        status: status ?? this.status,
        phone: phone ?? this.phone,
        photoUrl: photoUrl ?? this.photoUrl,
        staffId: staffId ?? this.staffId,
        permissions: permissions ?? this.permissions,
      );

  @override
  String toString() {
    return 'Staff(id: $id, name: $name, email: $email, status: ${status.label}, staffId: $staffId, permissions: $permissions)';
  }
}
