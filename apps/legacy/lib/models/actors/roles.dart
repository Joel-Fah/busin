import 'package:busin/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';

enum UserRole {
  student,
  staff,
  admin;

  String get label {
    switch (this) {
      case UserRole.student:
        return 'Student';
      case UserRole.staff:
        return 'Staff';
      case UserRole.admin:
        return 'Admin';
    }
  }

  String getDisplayLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (this) {
      case UserRole.student:
        return l10n.roleStudent;
      case UserRole.staff:
        return l10n.roleStaff;
      case UserRole.admin:
        return l10n.roleAdmin;
    }
  }

  bool get canScanQr => this == UserRole.staff;

  bool get isAdmin => this == UserRole.admin;
  bool get isStaff => this == UserRole.staff;
  bool get isStudent => this == UserRole.student;

  static UserRole from(String value) {
    final s = value.trim().toLowerCase();
    return UserRole.values.firstWhere(
          (e) => e.name.toLowerCase() == s || e.label.toLowerCase() == s,
      orElse: () => UserRole.student,
    );
  }
}

enum AccountStatus {
  pending,
  verified,
  suspended;

  String get label {
    switch (this) {
      case AccountStatus.pending:
        return 'Pending';
      case AccountStatus.verified:
        return 'Verified';
      case AccountStatus.suspended:
        return 'Suspended';
    }
  }

  String getDisplayLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (this) {
      case AccountStatus.pending:
        return l10n.accountPending;
      case AccountStatus.verified:
        return l10n.accountVerified;
      case AccountStatus.suspended:
        return l10n.accountSuspended;
    }
  }

  bool get isVerified => this == AccountStatus.verified;

  bool get isPending => this == AccountStatus.pending;

  bool get isSuspended => this == AccountStatus.suspended;

  static AccountStatus from(String value) {
    final s = value.trim().toLowerCase();
    return AccountStatus.values.firstWhere(
          (e) => e.name.toLowerCase() == s || e.label.toLowerCase() == s,
      orElse: () => AccountStatus.pending,
    );
  }
}
