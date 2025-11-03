import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:busin/models/actors/base_user.dart';
import 'package:busin/models/actors/roles.dart';

class Student extends BaseUser {
  final String? matricule; // Student ID number (optional)
  final String? department; // Optional department/program
  final String? program; // Optional program/major
  final String? currentSubscriptionId; // Track active subscription id if any
  final List<String> subscriptionIds; // history of subscription ids
  final String? address; // For research purposes

  const Student({
    required super.id,
    required super.name,
    required super.email,
    required super.status,
    this.matricule,
    this.department,
    this.program,
    this.currentSubscriptionId,
    this.subscriptionIds = const [],
    this.address,
    super.phone,
    super.photoUrl,
  }) : super(role: UserRole.student);

  // ---- factories ----

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] as String,
      name: (map['name'] as String?)?.trim() ?? '',
      email: (map['email'] as String?)?.trim() ?? '',
      status: AccountStatus.from((map['status'] as String?) ?? 'verified'),
      phone: (map['phone'] as String?)?.trim(),
      photoUrl: (map['photoUrl'] as String?)?.trim(),
      matricule: (map['matricule'] as String?)?.trim(),
      department: (map['department'] as String?)?.trim(),
      program: (map['program'] as String?)?.trim(),
      currentSubscriptionId: (map['currentSubscriptionId'] as String?)?.trim(),
      subscriptionIds: (map['subscriptionIds'] as List?)?.cast<String>() ?? const [],
      address: (map['address'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toMap() => {
        ...toBaseMap(),
        'matricule': matricule,
        'department': department,
        'program': program,
        'currentSubscriptionId': currentSubscriptionId,
        'subscriptionIds': subscriptionIds,
        'address': address,
      };

  /// Build a Student from a Firebase user. Enforces Google-only + org domain.
  factory Student.fromFirebaseUser(
    fb_auth.User user, {
    AccountStatus status = AccountStatus.verified,
    String? matricule,
    String? department,
    String? program,
    String? currentSubscriptionId,
    List<String> subscriptionIds = const [],
    String? address,
  }) {
    BaseUser.assertGoogleOrgOrThrow(user);
    final displayName = (user.displayName ?? '').trim();
    final fallbackName = (user.email ?? '').split('@').first;
    return Student(
      id: user.uid,
      name: displayName.isNotEmpty ? displayName : fallbackName,
      email: user.email ?? '',
      status: status,
      phone: user.phoneNumber,
      photoUrl: user.photoURL,
      matricule: matricule,
      department: department,
      program: program,
      currentSubscriptionId: currentSubscriptionId,
      subscriptionIds: subscriptionIds,
      address: address,
    );
  }

  // ---- convenience ----

  bool get hasActiveSubscription =>
      (currentSubscriptionId != null && currentSubscriptionId!.isNotEmpty);

  /// Simple boarding rule for now: must be verified and have an active subscription id.
  bool get canBoard => isVerified && hasActiveSubscription;

  /// Human-readable subscription status for quick UI labels.
  String get subscriptionStatusLabel =>
      hasActiveSubscription ? 'Active' : 'None';

  /// Immutable update helpers
  Student copyWith({
    String? id,
    String? name,
    String? email,
    AccountStatus? status,
    String? phone,
    String? photoUrl,
    String? matricule,
    String? department,
    String? program,
    String? currentSubscriptionId,
    List<String>? subscriptionIds,
    String? address,
  }) => Student(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        status: status ?? this.status,
        phone: phone ?? this.phone,
        photoUrl: photoUrl ?? this.photoUrl,
        matricule: matricule ?? this.matricule,
        department: department ?? this.department,
        program: program ?? this.program,
        currentSubscriptionId: currentSubscriptionId ?? this.currentSubscriptionId,
        subscriptionIds: subscriptionIds ?? this.subscriptionIds,
        address: address ?? this.address,
      );

  /// Returns a new Student with the provided active subscription id and adds to history.
  Student withSubscription(String subscriptionId) => copyWith(
        currentSubscriptionId: subscriptionId,
        subscriptionIds: {
          ...subscriptionIds,
        }.toList()..add(subscriptionId),
      );

  /// Returns a new Student with no active subscription.
  Student withoutSubscription() => copyWith(currentSubscriptionId: '');

  /// Replace or add subscription id in history
  Student upsertSubscriptionId(String id) {
    final list = List<String>.from(subscriptionIds);
    if (!list.contains(id)) list.add(id);
    return copyWith(subscriptionIds: list);
  }

  @override
  String toString() {
    return 'Student(id: $id, name: $name, email: $email, status: ${status.label}, matricule: $matricule, department: $department, program: $program, currentSubscriptionId: $currentSubscriptionId, address: $address)';
  }
}
