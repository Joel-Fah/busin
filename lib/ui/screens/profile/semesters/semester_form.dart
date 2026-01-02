import 'package:busin/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../controllers/semester_controller.dart';
import '../../../../models/semester_config.dart';
import '../../../../models/subscription.dart';
import '../../../../utils/constants.dart';
import '../../../../utils/utils.dart';
import '../../../components/widgets/default_snack_bar.dart';
import '../../../components/widgets/buttons/primary_button.dart';

class SemesterFormPage extends StatefulWidget {
  final SemesterConfig? semester;

  const SemesterFormPage({super.key, this.semester});

  static const String routeName = '/semester-form';

  @override
  State<SemesterFormPage> createState() => _SemesterFormPageState();
}

class _SemesterFormPageState extends State<SemesterFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final SemesterController _semesterController = Get.find<SemesterController>();

  // Form fields
  Semester? _selectedSemester;
  int? _selectedYear;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSubmitting = false;

  bool get isEditing => widget.semester != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _selectedSemester = widget.semester!.semester;
      _selectedYear = widget.semester!.year;
      _startDate = widget.semester!.startDate;
      _endDate = widget.semester!.endDate;
    } else {
      _selectedYear = DateTime.now().year;
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedYear == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          buildSnackBar(
            prefixIcon: const Icon(Icons.error, color: lightColor),
            label: Text(l10n.semesterFormPage_selectYear_null),
            backgroundColor: errorColor,
          ),
        );
      return;
    }

    if (_selectedSemester == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          buildSnackBar(
            prefixIcon: const Icon(Icons.error, color: lightColor),
            label: Text(l10n.semesterFormPage_selectSemester_null),
            backgroundColor: errorColor,
          ),
        );
      return;
    }

    final initialDate = isStartDate
        ? (_startDate ?? DateTime(_selectedYear!))
        : (_endDate ?? _startDate ?? DateTime(_selectedYear!));

    // Set date range based on selected year
    final firstDate = DateTime(_selectedYear!, 1, 1);
    final lastDate = DateTime(_selectedYear! + 1, 12, 31);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(firstDate)
          ? firstDate
          : initialDate.isAfter(lastDate)
          ? lastDate
          : initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      // Validate date year for start date
      if (isStartDate && picked.year != _selectedYear) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            buildSnackBar(
              prefixIcon: HugeIcon(icon: errorIcon, color: lightColor),
              label: Text(
                '${l10n.semesterFormPage_pickedDate_null} $_selectedYear',
              ),
              backgroundColor: errorColor,
            ),
          );
        return;
      }

      // Validate date year for end date
      if (!isStartDate &&
          picked.year != _selectedYear &&
          picked.year != _selectedYear! + 1) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            buildSnackBar(
              prefixIcon: const HugeIcon(icon: errorIcon, color: lightColor),
              label: Text(
                l10n.semesterFormPage_validateDate(
                  _selectedYear.toString(),
                  (_selectedYear! + 1).toString(),
                ),
              ),
              backgroundColor: errorColor,
            ),
          );
        return;
      }

      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // Auto-adjust end date if it's before start date
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _handleSubmit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    if (_selectedYear == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          buildSnackBar(
            prefixIcon: const HugeIcon(icon: errorIcon, color: lightColor),
            label: Text(l10n.semesterFormPage_handleSubmit_yearNull),
            backgroundColor: errorColor,
          ),
        );
      return;
    }

    if (_selectedSemester == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          buildSnackBar(
            prefixIcon: const HugeIcon(icon: errorIcon, color: lightColor),
            label: Text(l10n.semesterFormPage_handleSubmit_semesterNull),
            backgroundColor: errorColor,
          ),
        );
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          buildSnackBar(
            prefixIcon: const HugeIcon(icon: errorIcon, color: lightColor),
            label: Text(l10n.semesterFormPage_handleSubmit_datesNull),
            backgroundColor: errorColor,
          ),
        );
      return;
    }

    if (_startDate!.isAfter(_endDate!)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          buildSnackBar(
            prefixIcon: const HugeIcon(icon: errorIcon, color: lightColor),
            label: Text(l10n.semesterFormPage_handleSubmit_startIsAfter),
            backgroundColor: errorColor,
          ),
        );
      return;
    }

    // Validate that start date year matches selected year
    if (_startDate!.year != _selectedYear) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          buildSnackBar(
            prefixIcon: const HugeIcon(icon: errorIcon, color: lightColor),
            label: Text(
              '${l10n.semesterFormPage_pickedDate_null} $_selectedYear',
            ),
            backgroundColor: errorColor,
          ),
        );
      return;
    }

    // Validate that end date year matches selected year (or can be in next year for some semesters)
    if (_endDate!.year != _selectedYear &&
        _endDate!.year != _selectedYear! + 1) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          buildSnackBar(
            prefixIcon: const HugeIcon(icon: errorIcon, color: lightColor),
            label: Text(
              l10n.semesterFormPage_validateDate(
                _selectedYear.toString(),
                (_selectedYear! + 1).toString(),
              ),
            ),
            backgroundColor: errorColor,
          ),
        );
      return;
    }

    // Validate semester duration is reasonable (at least 30 days)
    final duration = _endDate!.difference(_startDate!).inDays;
    if (duration < 30) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          buildSnackBar(
            prefixIcon: const HugeIcon(icon: errorIcon, color: lightColor),
            label: Text(
              l10n.semesterFormPage_handleSubmit_semesterDurationDays,
            ),
            backgroundColor: errorColor,
          ),
        );
      return;
    }

    // Validate semester duration is reasonable (maximum 6 months)
    if (duration > 183) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          buildSnackBar(
            prefixIcon: const HugeIcon(icon: errorIcon, color: lightColor),
            label: Text(
              l10n.semesterFormPage_handleSubmit_semesterDurationMonths,
            ),
            backgroundColor: errorColor,
          ),
        );
      return;
    }

    setState(() => _isSubmitting = true);

    SemesterConfig? result;

    if (isEditing) {
      // Update existing semester
      final updatedConfig = widget.semester!.copyWith(
        startDate: _startDate,
        endDate: _endDate,
      );
      result = await _semesterController.updateSemester(config: updatedConfig);
    } else {
      // Create new semester
      final newConfig = SemesterConfig(
        id: SemesterConfig.generateId(_selectedSemester!, _selectedYear!),
        semester: _selectedSemester!,
        year: _selectedYear!,
        startDate: _startDate!,
        endDate: _endDate!,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: '',
      );
      result = await _semesterController.createSemester(config: newConfig);
    }

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (result != null) {
      context.pop();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          buildSnackBar(
            prefixIcon: const Icon(Icons.check_circle, color: lightColor),
            label: Text(
              isEditing
                  ? l10n.semesterFormPage_handleSubmit_successUpdated
                  : l10n.semesterFormPage_handleSubmit_successCreated,
            ),
            backgroundColor: successColor,
          ),
        );
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          buildSnackBar(
            prefixIcon: const Icon(Icons.error, color: lightColor),
            label: Text(
              _semesterController.error.value.isNotEmpty
                  ? _semesterController.error.value
                  : isEditing
                  ? l10n.semesterFormPage_handleSubmit_failedUpdated
                  : l10n.semesterFormPage_handleSubmit_failedCreated,
            ),
            backgroundColor: errorColor,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: FittedBox(
            fit: BoxFit.contain,
            child: Text(
              isEditing
                  ? l10n.semesterFormPage_appBar_titleEdit
                  : l10n.semesterFormPage_appBar_titleCreate,
            ),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0).copyWith(bottom: 80.0),
            children: [
              // Image
              Image.asset(semester, height: 200.0),
              const Gap(16.0),

              // Info banner
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: infoColor.withValues(alpha: 0.1),
                  borderRadius: borderRadius * 2.5,
                ),
                child: Row(
                  spacing: 8.0,
                  children: [
                    HugeIcon(icon: infoIcon, color: infoColor),
                    Expanded(
                      child: Text(
                        isEditing
                            ? l10n.semesterFormPage_infoBanner_update
                            : l10n.semesterFormPage_infoBanner_create,
                        style: AppTextStyles.body.copyWith(color: infoColor),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(24.0),

              // Form title
              Text(
                l10n.semesterFormPage_sectionHeader_semesterDetails,
                style: AppTextStyles.h2,
              ),
              const Gap(16.0),

              // Semester selection
              Text(
                l10n.semesterFormPage_semesterDetails_type,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
              const Gap(8.0),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: Semester.values.map((semester) {
                  final exists =
                      !isEditing &&
                      _semesterController.semesterExists(
                        semester.nameLower,
                        _selectedYear ?? DateTime.now().year,
                      );
                  final isSelected = _selectedSemester == semester;
                  final isEnabled = isEditing
                      ? semester == _selectedSemester
                      : !exists;

                  return ChoiceChip(
                    label: Text(
                      semester.label,
                      style: AppTextStyles.body.copyWith(
                        color: isSelected
                            ? lightColor
                            : isEnabled
                            ? null
                            : themeController.isDark
                            ? lightColor.withValues(alpha: 0.5)
                            : Colors.grey.shade900,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: isEnabled && !isEditing
                        ? (selected) {
                            if (selected) {
                              setState(() {
                                _selectedSemester = semester;
                                // Auto-fill dates based on default span
                                if (_selectedYear != null) {
                                  final span = semester.defaultSpanForYear(
                                    _selectedYear!,
                                  );
                                  _startDate = span.start;
                                  _endDate = span.end;
                                } else {
                                  // Clear dates if year not selected
                                  _startDate = null;
                                  _endDate = null;
                                }
                              });
                            }
                          }
                        : exists && !isEditing
                        ? (selected) {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                buildSnackBar(
                                  prefixIcon: const HugeIcon(
                                    icon: warningIcon,
                                    color: seedColor,
                                  ),
                                  label: Text(
                                    '${semester.label} ${l10n.semesterFormPage_semesterDetails_semesterSelected} $_selectedYear',
                                  ),
                                  backgroundColor: warningColor,
                                  foregroundColor: seedColor,
                                ),
                              );
                          }
                        : null,
                    side: BorderSide(
                      color: isSelected
                          ? themeController.isDark
                                ? seedPalette.shade500
                                : seedPalette.shade700
                          : !exists
                          ? seedPalette.shade900
                          : themeController.isDark
                          ? Colors.grey.shade600
                          : Colors.grey.shade900,
                      width: isSelected ? 2.0 : 1.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: borderRadius * 2,
                    ),
                    labelPadding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 4.0,
                    ),
                    checkmarkColor: lightColor,
                    color: WidgetStateProperty.resolveWith<Color?>((states) {
                      if (states.contains(WidgetState.disabled)) {
                        return greyColor.withValues(alpha: 0.2);
                      }
                      if (states.contains(WidgetState.selected)) {
                        return themeController.isDark
                            ? seedPalette.shade700
                            : seedPalette.shade900;
                      }
                      if (states.contains(WidgetState.pressed)) {
                        return seedPalette.shade900.withValues(alpha: 0.2);
                      }
                      return themeController.isDark
                          ? seedPalette.shade900
                          : seedPalette.shade50;
                    }),
                    avatar: exists
                        ? HugeIcon(
                            icon: HugeIcons.strokeRoundedUnavailable,
                            size: 20.0,
                            color: themeController.isDark
                                ? lightColor.withValues(alpha: 0.5)
                                : Colors.grey.shade900,
                          )
                        : null,
                  );
                }).toList(),
              ),
              if (_selectedSemester == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                  child: Text(
                    l10n.semesterFormPage_handleSubmit_semesterNull,
                    style: AppTextStyles.body.copyWith(
                      color: errorColor,
                      fontSize: 14.0,
                    ),
                  ),
                ),
              const Gap(16.0),

              // Year selection
              Text(
                l10n.year,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
              const Gap(8.0),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: List.generate(4, (index) {
                  final year = DateTime.now().year - 1 + index;
                  final exists =
                      !isEditing &&
                      _selectedSemester != null &&
                      _semesterController.semesterExists(
                        _selectedSemester!.nameLower,
                        year,
                      );
                  final isSelected = _selectedYear == year;
                  final isEnabled = isEditing ? year == _selectedYear : !exists;

                  return ChoiceChip(
                    label: Text(
                      year.toString(),
                      style: AppTextStyles.body.copyWith(
                        color: isSelected
                            ? lightColor
                            : isEnabled
                            ? null
                            : themeController.isDark
                            ? lightColor.withValues(alpha: 0.5)
                            : Colors.grey.shade900,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: isEnabled && !isEditing
                        ? (selected) {
                            if (selected) {
                              setState(() {
                                _selectedYear = year;
                                // Auto-fill dates based on default span
                                if (_selectedSemester != null) {
                                  final span = _selectedSemester!
                                      .defaultSpanForYear(year);
                                  _startDate = span.start;
                                  _endDate = span.end;
                                } else {
                                  // Clear dates if semester not selected
                                  _startDate = null;
                                  _endDate = null;
                                }
                              });
                            }
                          }
                        : exists && !isEditing
                        ? (selected) {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                buildSnackBar(
                                  prefixIcon: const HugeIcon(
                                    icon: warningIcon,
                                    color: lightColor,
                                  ),
                                  label: Text(
                                    '${_selectedSemester!.label} ${l10n.semesterFormPage_semesterDetails_semesterSelected} $year',
                                  ),
                                  backgroundColor: warningColor,
                                ),
                              );
                          }
                        : null,
                    side: BorderSide(
                      color: isSelected
                          ? themeController.isDark
                                ? seedPalette.shade500
                                : seedPalette.shade700
                          : !exists
                          ? seedPalette.shade900
                          : themeController.isDark
                          ? Colors.grey.shade600
                          : Colors.grey.shade900,
                      width: isSelected ? 2.0 : 1.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: borderRadius * 2,
                    ),
                    labelPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 4.0,
                    ),
                    checkmarkColor: lightColor,
                    color: WidgetStateProperty.resolveWith<Color?>((states) {
                      if (states.contains(WidgetState.disabled)) {
                        return greyColor.withValues(alpha: 0.2);
                      }
                      if (states.contains(WidgetState.selected)) {
                        return themeController.isDark
                            ? seedPalette.shade700
                            : seedPalette.shade900;
                      }
                      if (states.contains(WidgetState.pressed)) {
                        return seedPalette.shade900.withValues(alpha: 0.2);
                      }
                      return themeController.isDark
                          ? seedPalette.shade900
                          : seedPalette.shade50;
                    }),
                    avatar: exists
                        ? HugeIcon(
                            icon: HugeIcons.strokeRoundedUnavailable,
                            size: 20.0,
                            color: themeController.isDark
                                ? lightColor.withValues(alpha: 0.5)
                                : Colors.grey.shade900,
                          )
                        : null,
                  );
                }).toList(),
              ),
              if (_selectedYear == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                  child: Text(
                    l10n.semesterFormPage_handleSubmit_yearNull,
                    style: AppTextStyles.small.copyWith(color: errorColor),
                  ),
                ),
              const Gap(24.0),

              // Date range
              Text(
                l10n.semesterFormPage_sectionHeader_dateRange,
                style: AppTextStyles.h2,
              ),
              const Gap(16.0),

              // Start date
              Text(
                l10n.semesterFormPage_dateRange_startDate,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
              const Gap(8.0),
              InkWell(
                onTap: () => _selectDate(context, true),
                borderRadius: borderRadius * 2,
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: themeController.isDark
                        ? seedPalette.shade900
                        : seedPalette.shade50.withValues(alpha: 0.5),
                    border: Border.all(
                      color: themeController.isDark
                          ? seedPalette.shade700
                          : seedPalette.shade900,
                    ),
                    borderRadius: borderRadius * 2,
                  ),
                  child: Row(
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedCalendarCheckIn01,
                      ),
                      const Gap(12.0),
                      Expanded(
                        child: Text(
                          _startDate != null
                              ? dateFormatter(_startDate!)
                              : l10n.semesterFormPage_dateRange_startDateHint,
                          style: AppTextStyles.body.copyWith(
                            color: _startDate != null ? null : Colors.grey,
                          ),
                        ),
                      ),
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowDown01,
                        size: 20.0,
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(16.0),

              // End date
              Text(
                l10n.semesterFormPage_dateRange_endDate,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
              const Gap(8.0),
              InkWell(
                onTap: () => _selectDate(context, false),
                borderRadius: borderRadius * 2,
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: themeController.isDark
                        ? seedPalette.shade900
                        : seedPalette.shade50.withValues(alpha: 0.5),
                    border: Border.all(
                      color: themeController.isDark
                          ? seedPalette.shade700
                          : seedPalette.shade900,
                    ),
                    borderRadius: borderRadius * 2,
                  ),
                  child: Row(
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedCalendarCheckOut01,
                      ),
                      const Gap(12.0),
                      Expanded(
                        child: Text(
                          _endDate != null
                              ? dateFormatter(_endDate!)
                              : l10n.semesterFormPage_dateRange_endDateHint,
                          style: AppTextStyles.body.copyWith(
                            color: _endDate != null ? null : Colors.grey,
                          ),
                        ),
                      ),
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowDown01,
                        size: 20.0,
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(16.0),

              // Duration preview
              if (_startDate != null && _endDate != null)
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: infoColor.withValues(alpha: 0.1),
                    borderRadius: borderRadius * 2.5,
                  ),
                  child: Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedTime04,
                        color: infoColor,
                      ),
                      const Gap(12.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.semesterFormPage_sectionHeader_durationPreview,
                              style: AppTextStyles.small.copyWith(
                                color: infoColor,
                              ),
                            ),
                            Text(
                              _endDate!.difference(_startDate!).inDays > 1
                                  ? '${_endDate!.difference(_startDate!).inDays} ${l10n.days}'
                                  : '${_endDate!.difference(_startDate!).inDays} ${l10n.days.substring(0, l10n.days.length - 1)}',
                              style: AppTextStyles.h3.copyWith(
                                color: infoColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const Gap(32.0),

              // Submit button
              PrimaryButton.label(
                label: isEditing
                    ? l10n.semesterFormPage_submit_update
                    : l10n.semesterFormPage_submit_create,
                onPressed: _isSubmitting ? null : _handleSubmit,
                bgColor: _isSubmitting ? Colors.grey : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
