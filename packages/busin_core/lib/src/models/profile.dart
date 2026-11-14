import '../enums.dart';
import '../json.dart';
import 'academic.dart';
import 'billing.dart';
import '../value_object.dart';

/// A signed-in person. The role and status are set by the server; the app only reads them.
class Profile extends ValueObject {
  const Profile({
    required this.id,
    required this.schoolId,
    required this.email,
    required this.fullName,
    required this.role,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.avatarUrl,
    this.phone,
    this.matricule,
    this.department,
    this.program,
    this.departmentId,
    this.programId,
    this.streakOptIn = false,
    this.paymentPreference,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: reqString(json, 'id'),
        schoolId: optString(json, 'school_id'),
        email: reqString(json, 'email'),
        fullName: reqString(json, 'full_name'),
        avatarUrl: optString(json, 'avatar_url'),
        phone: optString(json, 'phone'),
        role: UserRole.parse(json['role']),
        status: AccountStatus.parse(json['status']),
        matricule: optString(json, 'matricule'),
        department: optString(json, 'department'),
        program: optString(json, 'program'),
        departmentId: optString(json, 'department_id'),
        programId: optString(json, 'program_id'),
        streakOptIn: json['streak_opt_in'] == true,
        paymentPreference: PaymentMode.tryParse(json['payment_preference']),
        createdAt: reqTimestamp(json, 'created_at'),
        updatedAt: reqTimestamp(json, 'updated_at'),
      );

  final String id;

  /// The school, or null for a student without a school email who has not asked to join one yet (ADR 0012).
  final String? schoolId;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final String? phone;
  final UserRole role;
  final AccountStatus status;
  final String? matricule;
  final String? department;
  final String? program;

  /// What the person chose from the school's lists. [department] and [program] are the readable names.
  final String? departmentId;
  final String? programId;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Whether the student keeps a streak (and so appears on the school's leaderboard).
  final bool streakOptIn;

  /// How the student prefers to pay (ADR 0022), used to fill in a request. Null until they choose.
  final PaymentMode? paymentPreference;

  bool get isVerified => status == AccountStatus.verified;

  /// A student has finished setting up when the school can recognise and reach them: a name, a student number and
  /// a phone number. Department and program are optional.
  bool get isSetupComplete => fullName.trim().isNotEmpty && (matricule ?? '').trim().isNotEmpty && (phone ?? '').trim().isNotEmpty;

  /// Up to two capital letters for an avatar placeholder.
  String get initials {
    final source = fullName.trim().isNotEmpty ? fullName.trim() : email.trim();
    if (source.isEmpty) return '?';
    final parts =
        source.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return (parts.first[0] + parts[1][0]).toUpperCase();
    }
    final word = parts.first;
    return (word.length >= 2 ? word.substring(0, 2) : word).toUpperCase();
  }

  /// The same shape the API returns, so [Profile.fromJson] reads it back (the app's saved copy for offline use).
  Map<String, dynamic> toJson() => {
        'id': id,
        'school_id': schoolId,
        'email': email,
        'full_name': fullName,
        'avatar_url': avatarUrl,
        'phone': phone,
        'role': role.name,
        'status': status.name,
        'matricule': matricule,
        'department': department,
        'program': program,
        'department_id': departmentId,
        'program_id': programId,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
        'streak_opt_in': streakOptIn,
        'payment_preference': paymentPreference?.name,
      };

  /// The only fields a user may change on their own profile.
  /// Role, status and school are never sent from a client.
  static Map<String, dynamic> editableJson({
    String? fullName,
    String? phone,
    String? matricule,
    AcademicChoice? academic,
  }) =>
      {
        'full_name': ?fullName,
        'phone': ?phone,
        'matricule': ?matricule,
        if (academic != null) 'department_id': academic.departmentId,
        if (academic != null) 'program_id': academic.programId,
      };

  @override
  List<Object?> get props => [
        id,
        schoolId,
        email,
        fullName,
        avatarUrl,
        phone,
        role,
        status,
        matricule,
        department,
        program,
        departmentId,
        programId,
        createdAt,
        updatedAt,
        paymentPreference,
      ];
}
