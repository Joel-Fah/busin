import 'package:busin_core/busin_core.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../providers.dart';

/// The student's own details as a form: name, student number, phone, and optionally department and program. Used on
/// the first-login setup page and in the profile's edit sheet. It checks what it can on the phone (kindly, after the
/// first try), saves through the repository (the server decides what is accepted) and then reloads the profile.
class ProfileForm extends ConsumerStatefulWidget {
  const ProfileForm({super.key, required this.profile, required this.submitLabel, this.onSaved});

  final Profile profile;
  final String submitLabel;

  /// Called after the details are saved and the profile has been reloaded.
  final VoidCallback? onSaved;

  @override
  ConsumerState<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<ProfileForm> {
  late final _name = TextEditingController(text: widget.profile.fullName);
  late final _matricule = TextEditingController(text: widget.profile.matricule ?? '');
  late final _phone = TextEditingController(text: widget.profile.phone ?? '');
  late final _department = TextEditingController(text: widget.profile.department ?? '');
  late final _program = TextEditingController(text: widget.profile.program ?? '');
  bool _tried = false;
  bool _saving = false;
  Object? _error;

  @override
  void dispose() {
    for (final c in [_name, _matricule, _phone, _department, _program]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _message(BusinL10n l10n, ProfileFieldProblem? problem) {
    if (!_tried || problem == null) return null;
    return switch (problem) {
      ProfileFieldProblem.empty => l10n.fieldRequired,
      ProfileFieldProblem.tooShort => l10n.fieldTooShort,
      ProfileFieldProblem.tooLong => l10n.fieldTooLong,
      ProfileFieldProblem.invalid => l10n.fieldInvalid,
    };
  }

  bool get _valid =>
      ProfileValidation.fullName(_name.text) == null &&
      ProfileValidation.matricule(_matricule.text) == null &&
      ProfileValidation.phone(_phone.text) == null &&
      ProfileValidation.optionalText(_department.text) == null &&
      ProfileValidation.optionalText(_program.text) == null;

  Future<void> _save() async {
    setState(() {
      _tried = true;
      _error = null;
    });
    if (!_valid) return;
    setState(() => _saving = true);
    try {
      await ref.read(profileRepositoryProvider).updateProfile(
            widget.profile.id,
            fullName: _name.text.trim(),
            matricule: _matricule.text.trim(),
            phone: ProfileValidation.normalizePhone(_phone.text),
            department: _department.text.trim(),
            program: _program.text.trim(),
          );
      // The access rules read the profile: reloading it is what lets a new student in.
      ref.invalidate(profileProvider);
      await ref.read(profileProvider.future);
      if (!mounted) return;
      widget.onSaved?.call();
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    void changed(String _) {
      if (_tried) setState(() {});
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        BusinTextField(
          label: l10n.fieldFullName,
          hint: l10n.fieldFullNameHint,
          icon: HugeIcons.strokeRoundedUser,
          controller: _name,
          enabled: !_saving,
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.name,
          errorText: _message(l10n, ProfileValidation.fullName(_name.text)),
          onChanged: changed,
        ),
        const SizedBox(height: BusinSpace.x4),
        BusinTextField(
          label: l10n.fieldMatricule,
          hint: l10n.fieldMatriculeHint,
          icon: HugeIcons.strokeRoundedIdVerified,
          controller: _matricule,
          enabled: !_saving,
          textInputAction: TextInputAction.next,
          errorText: _message(l10n, ProfileValidation.matricule(_matricule.text)),
          onChanged: changed,
        ),
        const SizedBox(height: BusinSpace.x4),
        BusinTextField(
          label: l10n.fieldPhone,
          hint: l10n.fieldPhoneHint,
          icon: HugeIcons.strokeRoundedSmartPhone01,
          controller: _phone,
          enabled: !_saving,
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.phone,
          errorText: _message(l10n, ProfileValidation.phone(_phone.text)),
          onChanged: changed,
        ),
        const SizedBox(height: BusinSpace.x4),
        BusinTextField(
          label: l10n.fieldDepartment,
          hint: l10n.fieldDepartmentHint,
          icon: HugeIcons.strokeRoundedBuilding03,
          controller: _department,
          enabled: !_saving,
          textInputAction: TextInputAction.next,
          errorText: _message(l10n, ProfileValidation.optionalText(_department.text)),
          onChanged: changed,
        ),
        const SizedBox(height: BusinSpace.x4),
        BusinTextField(
          label: l10n.fieldProgram,
          hint: l10n.fieldProgramHint,
          icon: HugeIcons.strokeRoundedMortarboard02,
          controller: _program,
          enabled: !_saving,
          textInputAction: TextInputAction.done,
          errorText: _message(l10n, ProfileValidation.optionalText(_program.text)),
          onChanged: changed,
          onSubmitted: (_) => _save(),
        ),
        if (_error != null) ...[
          const SizedBox(height: BusinSpace.x4),
          Notice(tone: StatusTone.bad, child: Text(_error is RepositoryException ? l10n.failure(_error as RepositoryException) : l10n.errorGeneric)),
        ],
        const SizedBox(height: BusinSpace.x5),
        BusinButton(label: widget.submitLabel, expand: true, loading: _saving, onPressed: _saving ? null : _save),
      ],
    );
  }
}
