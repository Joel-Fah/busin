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
import '../../../components/widgets/primary_button.dart';

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
    if (_selectedYear == null) {
      ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(
        buildSnackBar(
          prefixIcon: const Icon(Icons.error, color: lightColor),
          label: const Text('Please select a year first'),
          backgroundColor: errorColor,
        ),
      );
      return;
    }

    if (_selectedSemester == null) {
      ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(
        buildSnackBar(
          prefixIcon: const Icon(Icons.error, color: lightColor),
          label: const Text('Please select a semester first'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          buildSnackBar(
            prefixIcon: const Icon(Icons.error, color: lightColor),
            label: Text('Start date must be in $_selectedYear'),
            backgroundColor: errorColor,
          ),
        );
        return;
      }

      // Validate date year for end date
      if (!isStartDate && picked.year != _selectedYear && picked.year != _selectedYear! + 1) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(
          buildSnackBar(
            prefixIcon: const Icon(Icons.error, color: lightColor),
            label: Text('End date must be in $_selectedYear or ${_selectedYear! + 1}'),
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
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSemester == null) {
      ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(
        buildSnackBar(
          prefixIcon: const Icon(Icons.error, color: lightColor),
          label: const Text('Please select a semester'),
          backgroundColor: errorColor,
        ),
      );
      return;
    }

    if (_selectedYear == null) {
      ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(
        buildSnackBar(
          prefixIcon: const Icon(Icons.error, color: lightColor),
          label: const Text('Please select a year'),
          backgroundColor: errorColor,
        ),
      );
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(
        buildSnackBar(
          prefixIcon: const Icon(Icons.error, color: lightColor),
          label: const Text('Please select start and end dates'),
          backgroundColor: errorColor,
        ),
      );
      return;
    }

    if (_startDate!.isAfter(_endDate!)) {
      ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(
        buildSnackBar(
          prefixIcon: const Icon(Icons.error, color: lightColor),
          label: const Text('Start date must be before end date'),
          backgroundColor: errorColor,
        ),
      );
      return;
    }

    // Validate that start date year matches selected year
    if (_startDate!.year != _selectedYear) {
      ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(
        buildSnackBar(
          prefixIcon: const Icon(Icons.error, color: lightColor),
          label: Text('Start date must be in $_selectedYear'),
          backgroundColor: errorColor,
        ),
      );
      return;
    }

    // Validate that end date year matches selected year (or can be in next year for some semesters)
    if (_endDate!.year != _selectedYear && _endDate!.year != _selectedYear! + 1) {
      ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(
        buildSnackBar(
          prefixIcon: const Icon(Icons.error, color: lightColor),
          label: Text('End date must be in $_selectedYear or ${_selectedYear! + 1}'),
          backgroundColor: errorColor,
        ),
      );
      return;
    }

    // Validate semester duration is reasonable (at least 30 days)
    final duration = _endDate!.difference(_startDate!).inDays;
    if (duration < 30) {
      ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(
        buildSnackBar(
          prefixIcon: const Icon(Icons.error, color: lightColor),
          label: const Text('Semester must be at least 30 days long'),
          backgroundColor: errorColor,
        ),
      );
      return;
    }

    // Validate semester duration is reasonable (maximum 6 months)
    if (duration > 183) {
      ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(
        buildSnackBar(
          prefixIcon: const Icon(Icons.error, color: lightColor),
          label: const Text('Semester cannot be longer than 6 months'),
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
      ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(
        buildSnackBar(
          prefixIcon: const Icon(Icons.check_circle, color: lightColor),
          label: Text(
            isEditing
                ? 'Semester updated successfully'
                : 'Semester created successfully',
          ),
          backgroundColor: successColor,
        ),
      );
    } else {
      ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(
        buildSnackBar(
          prefixIcon: const Icon(Icons.error, color: lightColor),
          label: Text(
            _semesterController.error.value.isNotEmpty
                ? _semesterController.error.value
                : isEditing
                ? 'Failed to update semester'
                : 'Failed to create semester',
          ),
          backgroundColor: errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Edit Semester' : 'Add Semester'),
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
                            ? 'Update the date range for this semester. Changes will affect all subscriptions using these dates.'
                            : 'Define the start and end dates for a semester. These dates will be used for subscription validity periods.',
                        style: AppTextStyles.body.copyWith(color: infoColor),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(24.0),

              // Form title
              Text('Semester Details', style: AppTextStyles.h2),
              const Gap(16.0),

              // Semester selection
              Text(
                'Semester Type',
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
                            ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(
                              buildSnackBar(
                                prefixIcon: const HugeIcon(
                                  icon: warningIcon,
                                  color: lightColor,
                                ),
                                label: Text(
                                  '${semester.label} is already registered for $_selectedYear',
                                ),
                                backgroundColor: warningColor,
                              ),
                            );
                          }
                        : null,
                    side: BorderSide(
                      color: isSelected
                          ? seedPalette.shade700
                          : !exists
                          ? seedPalette.shade900
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
                            ? seedPalette.shade800
                            : seedPalette.shade900;
                      }
                      if (states.contains(WidgetState.pressed)) {
                        return seedPalette.shade900.withValues(alpha: 0.2);
                      }
                      return seedPalette.shade50;
                    }),
                    avatar: exists
                        ? HugeIcon(
                            icon: HugeIcons.strokeRoundedUnavailable,
                            size: 20.0,
                            color: Colors.grey.shade900,
                          )
                        : null,
                  );
                }).toList(),
              ),
              if (_selectedSemester == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                  child: Text(
                    'Please select a semester',
                    style: AppTextStyles.body.copyWith(color: errorColor, fontSize: 14.0),
                  ),
                ),
              const Gap(16.0),

              // Year selection
              Text(
                'Year',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
              const Gap(8.0),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: List.generate(4, (index) {
                  final year = DateTime.now().year - 1 + index;
                  final exists = !isEditing &&
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
                                  final span =
                                      _selectedSemester!.defaultSpanForYear(year);
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
                                ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(
                                  buildSnackBar(
                                    prefixIcon: const HugeIcon(
                                      icon: warningIcon,
                                      color: lightColor,
                                    ),
                                    label: Text(
                                      '${_selectedSemester!.label} is already registered for $year',
                                    ),
                                    backgroundColor: warningColor,
                                  ),
                                );
                              }
                            : null,
                    side: BorderSide(
                      color: isSelected
                          ? seedPalette.shade700
                          : !exists
                              ? seedPalette.shade900
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
                    color: WidgetStateProperty.resolveWith<Color?>(
                      (states) {
                        if (states.contains(WidgetState.disabled)) {
                          return greyColor.withValues(alpha: 0.2);
                        }
                        if (states.contains(WidgetState.selected)) {
                          return themeController.isDark
                              ? seedPalette.shade800
                              : seedPalette.shade900;
                        }
                        if (states.contains(WidgetState.pressed)) {
                          return seedPalette.shade900.withValues(alpha: 0.2);
                        }
                        return seedPalette.shade50;
                      },
                    ),
                    avatar: exists
                        ? HugeIcon(
                            icon: HugeIcons.strokeRoundedUnavailable,
                            size: 20.0,
                            color: Colors.grey.shade900,
                          )
                        : null,
                  );
                }).toList(),
              ),
              if (_selectedYear == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                  child: Text(
                    'Please select a year',
                    style: AppTextStyles.small.copyWith(color: errorColor),
                  ),
                ),
              const Gap(24.0),

              // Date range
              Text('Date Range', style: AppTextStyles.h2),
              const Gap(16.0),

              // Start date
              Text(
                'Start Date',
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
                        ? Colors.grey.shade800
                        : seedPalette.shade50.withValues(alpha: 0.5),
                    border: Border.all(
                      color: themeController.isDark
                          ? Colors.grey.shade700
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
                              : 'Select start date',
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
                'End Date',
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
                        ? Colors.grey.shade800
                        : seedPalette.shade50.withValues(alpha: 0.5),
                    border: Border.all(
                      color: themeController.isDark
                          ? Colors.grey.shade700
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
                              : 'Select end date',
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
                              'Duration',
                              style: AppTextStyles.small.copyWith(
                                color: infoColor,
                              ),
                            ),
                            Text(
                              '${_endDate!.difference(_startDate!).inDays} days',
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
                label: isEditing ? 'Update Semester' : 'Create Semester',
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
