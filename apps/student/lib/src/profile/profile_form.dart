import 'package:busin_core/busin_core.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../providers.dart';
import 'choice_sheet.dart';

/// The student's own details as a form: name, student number, phone, and optionally program, faculty and department
/// (picked from the lists the school set up). Used on
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
  String? _facultyId;
  String? _departmentId;
  String? _programId;
  bool _academicSeeded = false;
  bool _tried = false;
  bool _saving = false;
  Object? _error;

  @override
  void dispose() {
    for (final c in [_name, _matricule, _phone]) {
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
      ProfileValidation.phone(_phone.text) == null;

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
            // Only when the school has lists to choose from; otherwise whatever was saved stays as it is.
            academic: ref.read(academicUnitsProvider).value?.isEmpty ?? true ? null : AcademicChoice(departmentId: _departmentId, programId: _programId),
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

    final units = ref.watch(academicUnitsProvider).value ?? const AcademicUnits();
    if (!_academicSeeded && !units.isEmpty) {
      // Start from what the student saved: the faculty is the one their department belongs to.
      _academicSeeded = true;
      _departmentId = units.department(widget.profile.departmentId)?.id;
      _facultyId = units.facultyOfDepartment(_departmentId)?.id;
      _programId = units.program(widget.profile.programId)?.id;
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
          textInputAction: TextInputAction.done,
          keyboardType: TextInputType.phone,
          errorText: _message(l10n, ProfileValidation.phone(_phone.text)),
          onChanged: changed,
        ),
        const SizedBox(height: BusinSpace.x4),
        if (!units.isEmpty) ...[
          // Program first, then faculty and its department (the owner's order for setup).
          const SizedBox(height: BusinSpace.x4),
          FieldTile(
            label: l10n.fieldProgram,
            icon: HugeIcons.strokeRoundedMortarboard02,
            placeholder: l10n.fieldProgramHint,
            value: units.program(_programId)?.name,
            onTap: _saving
                ? null
                : () async {
                    final result = await showChoiceSheet(
                      context,
                      title: l10n.fieldProgram,
                      choices: [for (final x in units.programs) Choice(id: x.id, title: x.name)],
                      selectedId: _programId,
                      clearLabel: l10n.choiceNone,
                    );
                    if (result != null) setState(() => _programId = result.id);
                  },
          ),
          const SizedBox(height: BusinSpace.x4),
          FieldTile(
            label: l10n.fieldFaculty,
            icon: HugeIcons.strokeRoundedBuilding05,
            placeholder: l10n.fieldFacultyHint,
            value: units.faculties.where((x) => x.id == _facultyId).map((x) => x.name).firstOrNull,
            onTap: _saving
                ? null
                : () async {
                    final result = await showChoiceSheet(
                      context,
                      title: l10n.fieldFaculty,
                      choices: [for (final x in units.faculties) Choice(id: x.id, title: x.name, subtitle: x.code)],
                      selectedId: _facultyId,
                      clearLabel: l10n.choiceNone,
                    );
                    if (result == null || result.id == _facultyId) return;
                    // A new faculty means the old department no longer applies.
                    setState(() {
                      _facultyId = result.id;
                      _departmentId = null;
                    });
                  },
          ),
          const SizedBox(height: BusinSpace.x4),
          FieldTile(
            label: l10n.fieldDepartment,
            icon: HugeIcons.strokeRoundedBuilding03,
            placeholder: _facultyId == null ? l10n.fieldDepartmentFirst : l10n.fieldDepartmentHint,
            value: units.department(_departmentId)?.name,
            onTap: _saving || _facultyId == null
                ? null
                : () async {
                    final result = await showChoiceSheet(
                      context,
                      title: l10n.fieldDepartment,
                      choices: [for (final x in units.departmentsOf(_facultyId)) Choice(id: x.id, title: x.name, subtitle: x.code)],
                      selectedId: _departmentId,
                      clearLabel: l10n.choiceNone,
                    );
                    if (result != null) setState(() => _departmentId = result.id);
                  },
          ),
        ],
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
