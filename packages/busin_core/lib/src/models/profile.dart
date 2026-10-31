import '../enums.dart';
import '../json.dart';
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
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: reqString(json, 'id'),
        schoolId: reqString(json, 'school_id'),
        email: reqString(json, 'email'),
        fullName: reqString(json, 'full_name'),
        avatarUrl: optString(json, 'avatar_url'),
        phone: optString(json, 'phone'),
        role: UserRole.parse(json['role']),
        status: AccountStatus.parse(json['status']),
        matricule: optString(json, 'matricule'),
        department: optString(json, 'department'),
        program: optString(json, 'program'),
        createdAt: reqTimestamp(json, 'created_at'),
        updatedAt: reqTimestamp(json, 'updated_at'),
      );

  final String id;
  final String schoolId;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final String? phone;
  final UserRole role;
  final AccountStatus status;
  final String? matricule;
  final String? department;
  final String? program;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isVerified => status == AccountStatus.verified;

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

  /// The only fields a user may change on their own profile.
  /// Role, status and school are never sent from a client.
  static Map<String, dynamic> editableJson({
    String? fullName,
    String? phone,
    String? matricule,
    String? department,
    String? program,
  }) =>
      {
        'full_name': ?fullName,
        'phone': ?phone,
        'matricule': ?matricule,
        'department': ?department,
        'program': ?program,
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
        createdAt,
        updatedAt,
      ];
}
