import 'dart:io';

import 'package:busin/controllers/auth_controller.dart';
import 'package:busin/controllers/semester_controller.dart';
import 'package:busin/controllers/subscriptions_controller.dart';
import 'package:busin/l10n/app_localizations.dart';
import 'package:busin/models/semester_config.dart';
import 'package:busin/models/subscription.dart';
import 'package:busin/ui/components/widgets/default_snack_bar.dart';
import 'package:busin/ui/components/widgets/form_fields/select_image.dart';
import 'package:busin/utils/constants.dart';
import 'package:busin/utils/utils.dart';
import 'package:busin/utils/supabase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import '../../../controllers/bus_stops_controller.dart';
import '../../../models/value_objects/bus_stop_selection.dart';
import '../../components/widgets/bus_loading_overlay.dart';
import '../../components/widgets/loading_indicator.dart';

// Schedule presets for quick selection
enum _ScheduleMode { everyday, normalWeek, custom }

class NewSubscriptionPage extends StatefulWidget {
  const NewSubscriptionPage({super.key});

  static const String routeName = "/new-subscription";

  @override
  State<NewSubscriptionPage> createState() => _NewSubscriptionPageState();
}

class _NewSubscriptionPageState extends State<NewSubscriptionPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // GetX Controllers
  final AuthController authController = Get.find<AuthController>();
  final BusStopsController busStopController = Get.find<BusStopsController>();
  final BusSubscriptionsController subscriptionsController =
      Get.find<BusSubscriptionsController>();
  final SemesterController semesterController = Get.find<SemesterController>();

  // Form fields
  int _currentStep = 0;
  static const TimeOfDay _minMorningTime = TimeOfDay(hour: 6, minute: 30);
  static const TimeOfDay _maxClosingTime = TimeOfDay(hour: 17, minute: 0);
  String? _proofPath;
  String? _selectedStopId;

  // Weekly schedules
  List<BusSubscriptionSchedule> _schedules = [];
  _ScheduleMode _scheduleMode = _ScheduleMode.normalWeek;

  // Term - Use SemesterConfig from Firestore
  SemesterConfig? _selectedSemesterConfig;

  // Text Editing Controllers - No longer need year controller
  // Validation
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    // Load active semesters from Firestore
    semesterController.fetchSemesters();

    // Default schedule mode -> normal week
    _applyScheduleMode(_scheduleMode);

    // keep proof url if passed via navigation or previous step
    _proofPath = null;
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _applyScheduleMode(_ScheduleMode mode) {
    const defaultStart = '07:00';
    const defaultEnd = '17:00';
    List<BusSubscriptionSchedule> gen;
    switch (mode) {
      case _ScheduleMode.everyday:
        gen = List.generate(
          6,
          (i) => BusSubscriptionSchedule(
            weekday: i + 1,
            morningTime: defaultStart,
            closingTime: defaultEnd,
          ),
        );
        break;
      case _ScheduleMode.normalWeek:
        gen = List.generate(
          5,
          (i) => BusSubscriptionSchedule(
            weekday: i + 1,
            morningTime: defaultStart,
            closingTime: defaultEnd,
          ),
        );
        break;
      case _ScheduleMode.custom:
        gen = List.of(_schedules);
        break;
    }
    setState(() {
      _scheduleMode = mode;
      _schedules = _uniqueSortedSchedules(gen);
    });
  }

  List<BusSubscriptionSchedule> _uniqueSortedSchedules(
    List<BusSubscriptionSchedule> list,
  ) {
    final map = <int, BusSubscriptionSchedule>{};
    for (var s in list) {
      map[s.weekday] = s;
    }
    final sortedKeys = map.keys.toList()..sort();
    return sortedKeys.map((k) => map[k]!).toList();
  }

  int? _nextAvailableWeekday() {
    final present = _schedules.map((s) => s.weekday).toSet();
    for (var i = 1; i <= 6; i++) {
      if (!present.contains(i)) return i;
    }
    return null;
  }

  void _addEmptySchedule() {
    final pick = _nextAvailableWeekday();
    if (pick == null) return;
    final newItem = BusSubscriptionSchedule(
      weekday: pick,
      morningTime: '07:00',
      closingTime: '17:00',
    );
    setState(() {
      _schedules = _uniqueSortedSchedules(List.of(_schedules)..add(newItem));
      _scheduleMode = _ScheduleMode.custom;
    });
  }

  TimeOfDay _timeOfDayFromString(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  bool _isBefore(TimeOfDay a, TimeOfDay b) =>
      a.hour < b.hour || (a.hour == b.hour && a.minute < b.minute);

  bool _isAfter(TimeOfDay a, TimeOfDay b) =>
      a.hour > b.hour || (a.hour == b.hour && a.minute > b.minute);

  void _showScheduleError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        buildSnackBar(
          backgroundColor: errorColor,
          prefixIcon: HugeIcon(
            icon: HugeIcons.strokeRoundedCalendarRemove02,
            color: lightColor,
          ),
          label: Text(message),
        ),
      );
  }

  Future<TimeOfDay?> _pickTime(BuildContext ctx, String initial) async {
    final parts = initial.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 7,
      minute: int.tryParse(parts[1]) ?? 0,
    );
    return showTimePicker(context: ctx, initialTime: initialTime);
  }

  void _editScheduleTime(int index, {bool morning = true}) async {
    final l10n = AppLocalizations.of(context)!;
    final s = _schedules[index];
    final current = morning ? s.morningTime : s.closingTime;
    final picked = await _pickTime(context, current);
    if (picked == null) return;

    if (morning) {
      if (_isBefore(picked, _minMorningTime)) {
        _showScheduleError(l10n.newSubscriptionPage_scheduleTime_earlyError);
        return;
      }
      if (_isAfter(picked, _timeOfDayFromString(s.closingTime))) {
        _showScheduleError(l10n.newSubscriptionPage_scheduleTime_morningError);
        return;
      }
    } else {
      if (_isAfter(picked, _maxClosingTime)) {
        _showScheduleError(l10n.newSubscriptionPage_scheduleTime_latestError);
        return;
      }
      if (_isBefore(picked, _timeOfDayFromString(s.morningTime))) {
        _showScheduleError(l10n.newSubscriptionPage_scheduleTime_closingError);
        return;
      }
    }

    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() {
      final list = List.of(_schedules);
      list[index] = BusSubscriptionSchedule(
        weekday: s.weekday,
        morningTime: morning ? formatted : s.morningTime,
        closingTime: morning ? s.closingTime : formatted,
      );
      _schedules = _uniqueSortedSchedules(list);
      _scheduleMode = _ScheduleMode.custom;
    });
  }

  void _removeSchedule(int index) {
    setState(() {
      final list = List.of(_schedules)..removeAt(index);
      _schedules = _uniqueSortedSchedules(list);
    });
  }

  bool _validateStep(int step) {
    final l10n = AppLocalizations.of(context)!;
    switch (step) {
      case 0:
        if (_proofPath == null) {
          _showScheduleError(l10n.newSubscriptionPage_validateStep_proofUpload);
          return false;
        }
        return true;
      case 1:
        if (_selectedSemesterConfig == null) {
          _showScheduleError(l10n.newSubscriptionPage_validateStep_semester);
          return false;
        }
        return true;
      case 2:
        if (_selectedStopId == null) {
          _showScheduleError(l10n.newSubscriptionPage_validateStep_stop);
          return false;
        }
        return true;
      case 3:
        if (_schedules.isEmpty) {
          _showScheduleError(l10n.newSubscriptionPage_validateStep_schedule);
          return false;
        }
        for (final s in _schedules) {
          if (!s.isValidTimes) {
            _showScheduleError(
              l10n.newSubscriptionPage_validateStep_scheduleInvalid,
            );
            return false;
          }
        }
        return true;
      default:
        return true;
    }
  }

  void _onStepContinue() {
    if (!_validateStep(_currentStep)) return;
    if (_currentStep < 4) {
      setState(() => _currentStep += 1);
    } else {
      _submit();
    }
  }

  void _onStepCancel() {
    if (_currentStep == 0) return context.pop();
    setState(() => _currentStep -= 1);
  }

  void _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_isSubmitting) return;
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid ||
        _proofPath == null ||
        _selectedStopId == null ||
        _schedules.isEmpty ||
        _selectedSemesterConfig == null) {
      _showScheduleError(l10n.newSubscriptionPage_submit_validateSteps);
      return;
    }

    final stop = _findSelectedStop();
    if (stop == null) {
      _showScheduleError(l10n.newSubscriptionPage_submit_validateStop);
      return;
    }

    // Create subscription with actual semester dates from config
    final now = DateTime.now();
    var newSub = BusSubscription(
      id: '',
      studentId: authController.currentUser.value!.id,
      semesterConfig: _selectedSemesterConfig!,
      status: BusSubscriptionStatus.pending,
      createdAt: now,
      updatedAt: now,
      stop: stop,
      schedules: _schedules,
    );

    setState(() => _isSubmitting = true);

    String? proofUrl;
    try {
      final proofFile = File(_proofPath!);
      if (!proofFile.existsSync()) {
        throw Exception(
          l10n.newSubscriptionPage_validateStep_proofUploadException,
        );
      }
      final uniqueName =
          '${DateTime.now().millisecondsSinceEpoch}_${p.basename(proofFile.path)}';
      final objectPath =
          'subscriptions/${authController.currentUser.value!.email}/$uniqueName';
      proofUrl = await uploadFileToSupabaseStorage(
        file: proofFile,
        bucket: 'busin-bucket',
        objectPath: objectPath,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          buildSnackBar(
            backgroundColor: errorColor,
            prefixIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedAlert02,
              color: lightColor,
            ),
            label: Text(
              '${l10n.newSubscriptionPage_validateStep_proofUploadMessage} $error',
            ),
          ),
        );
      setState(() => _isSubmitting = false);
      return;
    }

    try {
      final saved = await subscriptionsController.createSubscription(
        subscription: newSub,
        proofUrl: proofUrl,
      );
      if (!mounted) return;

      // Refresh the subscriptions list to ensure the new subscription appears
      await subscriptionsController.refreshCurrentFilters();

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          buildSnackBar(
            backgroundColor: successColor,
            prefixIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedTaskDone01,
              color: lightColor,
            ),
            label: Text(l10n.newSubscriptionPage_submit_success),
          ),
        );
      context.pop(saved);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          buildSnackBar(
            backgroundColor: errorColor,
            prefixIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedAlert02,
              color: lightColor,
            ),
            label: Text('${l10n.newSubscriptionPage_submit_failed} $error'),
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final nextWeekday = _nextAvailableWeekday();
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: FittedBox(
            fit: BoxFit.contain,
            child: Text(l10n.newSubscriptionPage_appBar_title),
          ),
        ),
        body: Stack(
          children: [
            ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Image.asset(newSubscription),
                ),
                Form(
                  key: _formKey,
                  child: Stepper(
                    currentStep: _currentStep,
                    onStepContinue: _onStepContinue,
                    onStepCancel: _onStepCancel,
                    onStepTapped: (index) {
                      if (index <= _currentStep) {
                        setState(() => _currentStep = index);
                      }
                    },
                    physics: const ClampingScrollPhysics(),
                    controlsBuilder: (context, details) {
                      // Show refresh button for semester (step 1) and stop (step 2) selection
                      final bool showRefreshButton =
                          _currentStep == 1 || _currentStep == 2;

                      return Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: Row(
                          children: [
                            ElevatedButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : details.onStepContinue,
                              child: Text(
                                _currentStep == 4 ? l10n.submit : l10n.next,
                                style: AppTextStyles.body,
                              ),
                            ),
                            const Gap(8.0),
                            TextButton(
                              onPressed: details.onStepCancel,
                              style: TextButton.styleFrom(
                                overlayColor: accentColor.withValues(
                                  alpha: 0.1,
                                ),
                              ),
                              child: Text(
                                l10n.backButton,
                                style: AppTextStyles.body,
                              ),
                            ),
                            if (showRefreshButton) ...[
                              const Spacer(),
                              IconButton(
                                onPressed: _isSubmitting
                                    ? null
                                    : () async {
                                        if (_currentStep == 1) {
                                          // Refresh semesters
                                          await semesterController
                                              .fetchSemesters();
                                          if (mounted) {
                                            ScaffoldMessenger.of(context)
                                              ..hideCurrentSnackBar()
                                              ..showSnackBar(
                                                buildSnackBar(
                                                  backgroundColor: successColor,
                                                  prefixIcon: HugeIcon(
                                                    icon: HugeIcons
                                                        .strokeRoundedCheckmarkCircle02,
                                                    color: lightColor,
                                                  ),
                                                  label: Text(
                                                    l10n.newSubscriptionPage_semesterStep_refreshSuccess,
                                                  ),
                                                ),
                                              );
                                          }
                                        } else if (_currentStep == 2) {
                                          // Refresh bus stops
                                          await busStopController
                                              .fetchBusStops();
                                          if (mounted) {
                                            ScaffoldMessenger.of(context)
                                              ..hideCurrentSnackBar()
                                              ..showSnackBar(
                                                buildSnackBar(
                                                  backgroundColor: successColor,
                                                  prefixIcon: HugeIcon(
                                                    icon: HugeIcons
                                                        .strokeRoundedCheckmarkCircle02,
                                                    color: lightColor,
                                                  ),
                                                  label: Text(
                                                    l10n.newSubscriptionPage_stopStep_refreshSuccess,
                                                  ),
                                                ),
                                              );
                                          }
                                        }
                                      },
                                icon: HugeIcon(
                                  icon: HugeIcons.strokeRoundedRefresh,
                                  color: _isSubmitting
                                      ? greyColor
                                      : themeController.isDark
                                      ? seedPalette.shade50
                                      : seedColor,
                                ),
                                tooltip: _currentStep == 1
                                    ? l10n.newSubscriptionPage_semesterStep_refresh
                                    : l10n.newSubscriptionPage_stopStep_refresh,
                                style: IconButton.styleFrom(
                                  overlayColor: accentColor.withValues(
                                    alpha: 0.1,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                    steps: [
                      Step(
                        stepStyle: StepStyle(
                          color: _currentStep >= 0
                              ? themeController.isDark
                                    ? seedPalette.shade800
                                    : seedColor
                              : greyColor,
                          indexStyle: AppTextStyles.body.copyWith(
                            color: lightColor,
                          ),
                        ),
                        title: Text(
                          l10n.newSubscriptionPage_proofStep_title,
                          style: AppTextStyles.body.copyWith(
                            color: _currentStep >= 0
                                ? themeController.isDark
                                      ? lightColor
                                      : seedColor
                                : greyColor,
                          ),
                        ),
                        state: _currentStep > 0
                            ? StepState.complete
                            : StepState.indexed,
                        isActive: _currentStep >= 0,
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.newSubscriptionPage_proofStep_subtitle,
                              style: AppTextStyles.body.copyWith(
                                color: themeController.isDark
                                    ? seedPalette.shade50
                                    : greyColor,
                                fontSize: 14.0,
                              ),
                            ),
                            const Gap(8.0),
                            ImageBox(
                              onImageSelected: (filePath) => setState(() {
                                _proofPath = filePath;
                              }),
                              label:
                                  l10n.newSubscriptionPage_proofStep_imageBox,
                            ),
                          ],
                        ),
                      ),
                      Step(
                        stepStyle: StepStyle(
                          color: _currentStep >= 1
                              ? themeController.isDark
                                    ? seedPalette.shade800
                                    : seedColor
                              : greyColor,
                          indexStyle: AppTextStyles.body.copyWith(
                            color: lightColor,
                          ),
                        ),
                        title: Text(
                          l10n.semester,
                          style: AppTextStyles.body.copyWith(
                            color: _currentStep >= 1
                                ? themeController.isDark
                                      ? lightColor
                                      : seedColor
                                : greyColor,
                          ),
                        ),
                        state: _currentStep > 1
                            ? StepState.complete
                            : StepState.indexed,
                        isActive: _currentStep >= 1,
                        content: GetX<SemesterController>(
                          builder: (controller) {
                            if (controller.isLoading.value &&
                                controller.semesters.isEmpty) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24.0),
                                  child: LoadingIndicator(),
                                ),
                              );
                            }

                            final activeSemester =
                                controller.activeSemester.value;

                            if (activeSemester == null) {
                              return Container(
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  color: warningColor.withValues(alpha: 0.1),
                                  borderRadius: borderRadius * 2,
                                  border: Border.all(
                                    color: warningColor.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    HugeIcon(
                                      icon: HugeIcons.strokeRoundedAlert02,
                                      color: warningColor,
                                    ),
                                    const Gap(12.0),
                                    Expanded(
                                      child: Text(
                                        l10n.newSubscriptionPage_semesterStep_emptyActive,
                                        style: AppTextStyles.body.copyWith(
                                          color: warningColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            // Auto-select the active semester if not already selected
                            if (_selectedSemesterConfig == null) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                setState(() {
                                  _selectedSemesterConfig = activeSemester;
                                });
                              });
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 16.0,
                              children: [
                                // Active semester card
                                Container(
                                  padding: const EdgeInsets.all(16.0),
                                  decoration: BoxDecoration(
                                    gradient: themeController.isDark
                                        ? darkGradient
                                        : lightGradient,
                                    borderRadius: borderRadius * 2.5,
                                    border: Border.all(
                                      color: successColor,
                                      width: 2.0,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    spacing: 12.0,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8.0),
                                            decoration: BoxDecoration(
                                              color: successColor.withValues(
                                                alpha: 0.1,
                                              ),
                                              borderRadius: borderRadius * 1.5,
                                            ),
                                            child: HugeIcon(
                                              icon: HugeIcons
                                                  .strokeRoundedCalendar02,
                                              color: successColor,
                                            ),
                                          ),
                                          const Gap(12.0),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  l10n.newSubscriptionPage_semesterStep_activeSemester,
                                                  style: AppTextStyles.small
                                                      .copyWith(
                                                        color: successColor,
                                                      ),
                                                ),
                                                Text(
                                                  '${activeSemester.semester.label} ${activeSemester.year}',
                                                  style: AppTextStyles.h3,
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (_selectedSemesterConfig?.id ==
                                              activeSemester.id)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12.0,
                                                    vertical: 6.0,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: successColor,
                                                borderRadius:
                                                    borderRadius * 1.5,
                                              ),
                                              child: Text(
                                                l10n.selected,
                                                style: AppTextStyles.small
                                                    .copyWith(
                                                      color: lightColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const Divider(),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            spacing: 8.0,
                                            children: [
                                              HugeIcon(
                                                icon: HugeIcons
                                                    .strokeRoundedCalendarCheckIn01,
                                                size: 16.0,
                                                color: themeController.isDark
                                                    ? seedPalette.shade50
                                                    : greyColor,
                                              ),
                                              Text(
                                                dateFormatter(
                                                  activeSemester.startDate,
                                                ),
                                                style: AppTextStyles.body
                                                    .copyWith(
                                                      color:
                                                          themeController.isDark
                                                          ? seedPalette.shade50
                                                          : greyColor,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            spacing: 8.0,
                                            children: [
                                              HugeIcon(
                                                icon: HugeIcons
                                                    .strokeRoundedCalendarCheckOut01,
                                                size: 16.0,
                                                color: themeController.isDark
                                                    ? seedPalette.shade50
                                                    : greyColor,
                                              ),
                                              Text(
                                                dateFormatter(
                                                  activeSemester.endDate,
                                                ),
                                                style: AppTextStyles.body
                                                    .copyWith(
                                                      color:
                                                          themeController.isDark
                                                          ? seedPalette.shade50
                                                          : greyColor,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Info message
                                Container(
                                  padding: const EdgeInsets.all(12.0),
                                  decoration: BoxDecoration(
                                    color: infoColor.withValues(alpha: 0.1),
                                    borderRadius: borderRadius * 1.5,
                                  ),
                                  child: Row(
                                    children: [
                                      HugeIcon(
                                        icon: HugeIcons
                                            .strokeRoundedInformationCircle,
                                        color: infoColor,
                                        size: 20.0,
                                      ),
                                      const Gap(12.0),
                                      Expanded(
                                        child: Text(
                                          l10n.newSubscriptionPage_semesterStep_infoBubble,
                                          style: AppTextStyles.small.copyWith(
                                            color: infoColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      Step(
                        stepStyle: StepStyle(
                          color: _currentStep >= 2
                              ? themeController.isDark
                                    ? seedPalette.shade800
                                    : seedColor
                              : greyColor,
                          indexStyle: AppTextStyles.body.copyWith(
                            color: lightColor,
                          ),
                        ),
                        title: Text(
                          l10n.newSubscriptionPage_stopStep_title,
                          style: AppTextStyles.body.copyWith(
                            color: _currentStep >= 2
                                ? themeController.isDark
                                      ? lightColor
                                      : seedColor
                                : greyColor,
                          ),
                        ),
                        state: _currentStep > 2
                            ? StepState.complete
                            : StepState.indexed,
                        isActive: _currentStep >= 2,
                        content: GetX<BusStopsController>(
                          builder: (controller) {
                            final stops = controller.busStops.toList(
                              growable: false,
                            );
                            final selectedStop = _findSelectedStop();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _selectedStopId,
                                    items: stops
                                        .map(
                                          (s) => DropdownMenuItem(
                                            value: s.id,
                                            child: Text(
                                              s.name,
                                              style: AppTextStyles.body
                                                  .copyWith(
                                                    color:
                                                        themeController.isDark
                                                        ? lightColor
                                                        : seedColor,
                                                  ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    style: AppTextStyles.body.copyWith(
                                      color: seedColor,
                                    ),
                                    isExpanded: true,
                                    dropdownColor: themeController.isDark
                                        ? seedPalette.shade800
                                        : seedPalette.shade50,
                                    onChanged: (v) =>
                                        setState(() => _selectedStopId = v),
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                    validator: (value) =>
                                        value == null || value.isEmpty
                                        ? l10n.newSubscriptionPage_stopStep_validatorEmpty
                                        : null,
                                    icon: const HugeIcon(
                                      icon: HugeIcons.strokeRoundedArrowDown01,
                                    ),
                                    borderRadius: borderRadius * 2.5,
                                    decoration: InputDecoration(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 12.0,
                                            horizontal: 16.0,
                                          ),
                                      labelText: l10n
                                          .newSubscriptionPage_stopStep_label,
                                      labelStyle: AppTextStyles.body.copyWith(
                                        color: themeController.isDark
                                            ? lightColor
                                            : seedColor,
                                      ),
                                      hintText: l10n
                                          .newSubscriptionPage_stopStep_label,
                                      hintStyle: AppTextStyles.body.copyWith(
                                        color: themeController.isDark
                                            ? lightColor.withValues(alpha: 0.6)
                                            : seedColor.withValues(alpha: 0.6),
                                      ),
                                      border: AppInputBorders.border,
                                      focusedBorder:
                                          AppInputBorders.focusedBorder,
                                      errorBorder: AppInputBorders.errorBorder,
                                      focusedErrorBorder:
                                          AppInputBorders.focusedErrorBorder,
                                      enabledBorder:
                                          AppInputBorders.enabledBorder,
                                      disabledBorder:
                                          AppInputBorders.disabledBorder,
                                    ),
                                  ),
                                ),

                                // Preview section
                                if (selectedStop != null) ...[
                                  const Gap(16.0),
                                  _StopPreview(stop: selectedStop),
                                ],
                              ],
                            );
                          },
                        ),
                      ),
                      Step(
                        stepStyle: StepStyle(
                          color: _currentStep >= 3
                              ? themeController.isDark
                                    ? seedPalette.shade800
                                    : seedColor
                              : greyColor,
                          indexStyle: AppTextStyles.body.copyWith(
                            color: lightColor,
                          ),
                        ),
                        title: Text(
                          l10n.newSubscriptionPage_scheduleStep_title,
                          style: AppTextStyles.body.copyWith(
                            color: _currentStep >= 3
                                ? themeController.isDark
                                      ? lightColor
                                      : seedColor
                                : greyColor,
                          ),
                        ),
                        state: _currentStep > 3
                            ? StepState.complete
                            : StepState.indexed,
                        isActive: _currentStep >= 3,
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  ChoiceChip(
                                    label: Text(
                                      l10n.newSubscriptionPage_scheduleStep_optionEveryday,
                                      style: AppTextStyles.body,
                                    ),
                                    selected:
                                        _scheduleMode == _ScheduleMode.everyday,
                                    onSelected: (_) => _applyScheduleMode(
                                      _ScheduleMode.everyday,
                                    ),
                                    checkmarkColor: themeController.isDark
                                        ? lightColor
                                        : seedColor,
                                  ),
                                  const Gap(8.0),
                                  ChoiceChip(
                                    label: Text(
                                      l10n.newSubscriptionPage_scheduleStep_optionNormal,
                                      style: AppTextStyles.body,
                                    ),
                                    selected:
                                        _scheduleMode ==
                                        _ScheduleMode.normalWeek,
                                    onSelected: (_) => _applyScheduleMode(
                                      _ScheduleMode.normalWeek,
                                    ),
                                    checkmarkColor: themeController.isDark
                                        ? lightColor
                                        : seedColor,
                                  ),
                                  const Gap(8.0),
                                  ChoiceChip(
                                    label: Text(
                                      l10n.newSubscriptionPage_scheduleStep_optionCustom,
                                      style: AppTextStyles.body,
                                    ),
                                    selected:
                                        _scheduleMode == _ScheduleMode.custom,
                                    onSelected: (_) => _applyScheduleMode(
                                      _ScheduleMode.custom,
                                    ),
                                    checkmarkColor: themeController.isDark
                                        ? lightColor
                                        : seedColor,
                                  ),
                                ],
                              ),
                            ),
                            const Gap(8.0),
                            if (_schedules.isEmpty)
                              Container(
                                decoration: BoxDecoration(
                                  color: themeController.isDark
                                      ? seedPalette.shade50.withValues(
                                          alpha: 0.1,
                                        )
                                      : greyColor.withValues(alpha: 0.1),
                                  borderRadius: borderRadius * 2,
                                ),
                                child: DottedBorder(
                                  options: RoundedRectDottedBorderOptions(
                                    color: themeController.isDark
                                        ? seedPalette.shade50
                                        : greyColor,
                                    strokeWidth: 1.0,
                                    strokeCap: StrokeCap.round,
                                    dashPattern: const [4, 6, 8, 10],
                                    radius: const Radius.circular(16.0),
                                    padding: const EdgeInsets.all(20.0),
                                  ),
                                  child: Text(
                                    l10n.newSubscriptionPage_scheduleStep_empty,
                                    style: AppTextStyles.body.copyWith(
                                      color: themeController.isDark
                                          ? seedPalette.shade50
                                          : greyColor,
                                    ),
                                  ),
                                ),
                              ),
                            for (var i = 0; i < _schedules.length; i++)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4.0,
                                ),
                                child: Animate(
                                  key: ValueKey(_schedules[i].weekday),
                                  effects: const [
                                    FadeEffect(
                                      duration: Duration(milliseconds: 220),
                                    ),
                                    SlideEffect(
                                      begin: Offset(0, 0.05),
                                      duration: Duration(milliseconds: 220),
                                    ),
                                  ],
                                  child: Container(
                                    padding: EdgeInsets.all(
                                      12.0,
                                    ).copyWith(top: 4.0),
                                    decoration: BoxDecoration(
                                      borderRadius: borderRadius * 2.5,
                                      color: themeController.isDark
                                          ? seedPalette.shade50.withValues(
                                              alpha: 0.1,
                                            )
                                          : seedPalette.shade50.withValues(
                                              alpha: 0.5,
                                            ),
                                      border: Border.all(
                                        color: themeController.isDark
                                            ? seedPalette.shade600.withValues(
                                                alpha: 0.3,
                                              )
                                            : seedPalette.shade800.withValues(
                                                alpha: 0.15,
                                              ),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          spacing: 8.0,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                _weekdayLabelLong(
                                                  _schedules[i].weekday,
                                                  context,
                                                ),
                                                style: AppTextStyles.h4,
                                              ),
                                            ),
                                            IconButton(
                                              tooltip:
                                                  '${l10n.remove} ${_weekdayLabelLong(_schedules[i].weekday, context)}',
                                              style: IconButton.styleFrom(
                                                overlayColor: errorColor
                                                    .withValues(alpha: 0.12),
                                              ),
                                              onPressed: () =>
                                                  _removeSchedule(i),
                                              icon: HugeIcon(
                                                icon: HugeIcons
                                                    .strokeRoundedDelete03,
                                                color: errorColor,
                                                size: 20.0,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          spacing: 8.0,
                                          children: [
                                            Expanded(
                                              child: InkWell(
                                                borderRadius:
                                                    borderRadius * 1.5,
                                                onTap: () => _editScheduleTime(
                                                  i,
                                                  morning: true,
                                                ),
                                                child: InputDecorator(
                                                  decoration: InputDecoration(
                                                    labelText: l10n.morning,
                                                    labelStyle: AppTextStyles
                                                        .body
                                                        .copyWith(
                                                          color:
                                                              themeController
                                                                  .isDark
                                                              ? seedPalette
                                                                    .shade50
                                                              : seedColor,
                                                        ),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          borderRadius * 1.5,
                                                      borderSide: BorderSide(
                                                        color:
                                                            themeController
                                                                .isDark
                                                            ? seedPalette
                                                                  .shade50
                                                            : seedColor,
                                                      ),
                                                    ),
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                          borderRadius:
                                                              borderRadius *
                                                              1.5,
                                                          borderSide: BorderSide(
                                                            color:
                                                                themeController
                                                                    .isDark
                                                                ? seedPalette
                                                                      .shade50
                                                                : seedColor,
                                                          ),
                                                        ),
                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                          borderRadius:
                                                              borderRadius *
                                                              1.5,
                                                          borderSide: BorderSide(
                                                            color:
                                                                themeController
                                                                    .isDark
                                                                ? seedPalette
                                                                      .shade50
                                                                : seedColor,
                                                          ),
                                                        ),
                                                    contentPadding:
                                                        EdgeInsets.symmetric(
                                                          vertical: 8.0,
                                                          horizontal: 10.0,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    _schedules[i].morningTime,
                                                    style: AppTextStyles.body,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: InkWell(
                                                borderRadius:
                                                    borderRadius * 1.5,
                                                onTap: () => _editScheduleTime(
                                                  i,
                                                  morning: false,
                                                ),
                                                child: InputDecorator(
                                                  decoration: InputDecoration(
                                                    labelText: l10n.closing,
                                                    labelStyle: AppTextStyles
                                                        .body
                                                        .copyWith(
                                                          color:
                                                              themeController
                                                                  .isDark
                                                              ? seedPalette
                                                                    .shade50
                                                              : seedColor,
                                                        ),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          borderRadius * 1.5,
                                                      borderSide: BorderSide(
                                                        color:
                                                            themeController
                                                                .isDark
                                                            ? seedPalette
                                                                  .shade50
                                                            : seedColor,
                                                      ),
                                                    ),
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                          borderRadius:
                                                              borderRadius *
                                                              1.5,
                                                          borderSide: BorderSide(
                                                            color:
                                                                themeController
                                                                    .isDark
                                                                ? seedPalette
                                                                      .shade50
                                                                : seedColor,
                                                          ),
                                                        ),
                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                          borderRadius:
                                                              borderRadius *
                                                              1.5,
                                                          borderSide: BorderSide(
                                                            color:
                                                                themeController
                                                                    .isDark
                                                                ? seedPalette
                                                                      .shade50
                                                                : seedColor,
                                                          ),
                                                        ),
                                                    contentPadding:
                                                        EdgeInsets.symmetric(
                                                          vertical: 8.0,
                                                          horizontal: 10.0,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    _schedules[i].closingTime,
                                                    style: AppTextStyles.body,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            if (nextWeekday == null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: infoColor.withValues(alpha: 0.1),
                                    borderRadius: borderRadius * 2,
                                  ),
                                  child: DottedBorder(
                                    options: RoundedRectDottedBorderOptions(
                                      color: themeController.isDark
                                          ? seedPalette.shade50
                                          : infoColor,
                                      strokeWidth: 1.0,
                                      strokeCap: StrokeCap.round,
                                      dashPattern: const [4, 6, 8, 10],
                                      radius: const Radius.circular(16.0),
                                      padding: const EdgeInsets.all(20.0),
                                    ),
                                    child: Text(
                                      l10n.newSubscriptionPage_scheduleStep_maxReached,
                                      style: AppTextStyles.body.copyWith(
                                        color: themeController.isDark
                                            ? seedPalette.shade50
                                            : infoColor,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            else
                              Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: TextButton.icon(
                                    onPressed: _addEmptySchedule,
                                    style: TextButton.styleFrom(
                                      overlayColor: accentColor.withValues(
                                        alpha: 0.12,
                                      ),
                                    ),
                                    icon: const HugeIcon(
                                      icon: HugeIcons.strokeRoundedAdd01,
                                      size: 20.0,
                                    ),
                                    label: Text(
                                      '${l10n.add} ${_weekdayLabelLong(nextWeekday, context)}',
                                      style: AppTextStyles.body,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Step(
                        stepStyle: StepStyle(
                          color: _currentStep >= 4
                              ? themeController.isDark
                                    ? seedPalette.shade800
                                    : seedColor
                              : greyColor,
                          indexStyle: AppTextStyles.body.copyWith(
                            color: lightColor,
                          ),
                        ),
                        title: Text(
                          l10n.newSubscriptionPage_reviewStep_title,
                          style: AppTextStyles.body.copyWith(
                            color: _currentStep >= 4
                                ? themeController.isDark
                                      ? lightColor
                                      : seedColor
                                : greyColor,
                          ),
                        ),
                        state: _currentStep == 4
                            ? StepState.editing
                            : StepState.indexed,
                        isActive: _currentStep >= 4,
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 16.0,
                          children: [
                            // Header with icon
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12.0),
                                  decoration: BoxDecoration(
                                    gradient: themeController.isDark
                                        ? darkGradient
                                        : lightGradient,
                                    borderRadius: borderRadius * 2,
                                  ),
                                  child: HugeIcon(
                                    icon: HugeIcons.strokeRoundedFileValidation,
                                    size: 28.0,
                                  ),
                                ),
                                const Gap(12.0),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.newSubscriptionPage_reviewStep_subtitle,
                                        style: AppTextStyles.h3,
                                      ),
                                      Text(
                                        l10n.newSubscriptionPage_reviewStep_description,
                                        style: AppTextStyles.small.copyWith(
                                          color: greyColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // Student Info Card
                            Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                gradient: themeController.isDark
                                    ? darkGradient
                                    : lightGradient,
                                borderRadius: borderRadius * 2.5,
                                border: Border.all(color: seedPalette.shade700),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                spacing: 12.0,
                                children: [
                                  Row(
                                    children: [
                                      HugeIcon(
                                        icon: HugeIcons.strokeRoundedUser,
                                      ),
                                      const Gap(8.0),
                                      Text(
                                        l10n.newSubscriptionPage_reviewStep_studentInfo,
                                        style: AppTextStyles.body.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Divider(color: seedPalette.shade700),
                                  _SummaryRow(
                                    icon: HugeIcons.strokeRoundedUserCircle,
                                    label: l10n
                                        .newSubscriptionPage_reviewStep_studentName,
                                    value: authController.userDisplayName,
                                  ),
                                  _SummaryRow(
                                    icon: HugeIcons.strokeRoundedMail01,
                                    label: l10n
                                        .newSubscriptionPage_reviewStep_studentEmail,
                                    value:
                                        authController
                                            .currentUser
                                            .value
                                            ?.email ??
                                        l10n.naLabel,
                                  ),
                                ],
                              ),
                            ),

                            // Semester Card
                            Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                gradient: themeController.isDark
                                    ? darkGradient
                                    : lightGradient,
                                borderRadius: borderRadius * 2.5,
                                border: Border.all(
                                  color: successColor.withValues(alpha: 0.5),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                spacing: 12.0,
                                children: [
                                  Row(
                                    children: [
                                      HugeIcon(
                                        icon: HugeIcons.strokeRoundedCalendar02,
                                        color: successColor,
                                        size: 20.0,
                                      ),
                                      const Gap(8.0),
                                      Text(
                                        l10n.newSubscriptionPage_reviewStep_semesterDetails,
                                        style: AppTextStyles.body.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: successColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Divider(
                                    color: successColor.withValues(alpha: 0.3),
                                  ),
                                  if (_selectedSemesterConfig != null) ...[
                                    _SummaryRow(
                                      icon: HugeIcons.strokeRoundedCalendar03,
                                      label: l10n.semester,
                                      value:
                                          '${_selectedSemesterConfig!.semester.label} ${_selectedSemesterConfig!.year}',
                                      valueColor: successColor,
                                    ),
                                    _SummaryRow(
                                      icon: HugeIcons
                                          .strokeRoundedCalendarCheckIn01,
                                      label: l10n
                                          .semestersPage_detailRow_startDate,
                                      value: dateFormatter(
                                        _selectedSemesterConfig!.startDate,
                                      ),
                                    ),
                                    _SummaryRow(
                                      icon: HugeIcons
                                          .strokeRoundedCalendarCheckOut01,
                                      label:
                                          l10n.semestersPage_detailRow_endDate,
                                      value: dateFormatter(
                                        _selectedSemesterConfig!.endDate,
                                      ),
                                    ),
                                    _SummaryRow(
                                      icon: HugeIcons.strokeRoundedTimer02,
                                      label:
                                          l10n.semestersPage_detailRow_duration,
                                      value:
                                          _selectedSemesterConfig!
                                                  .durationInDays >
                                              1
                                          ? '${_selectedSemesterConfig!.durationInDays} ${l10n.days}'
                                          : '${_selectedSemesterConfig!.durationInDays} ${l10n.days.substring(0, l10n.days.length - 1)}',
                                    ),
                                  ] else
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8.0,
                                      ),
                                      child: Text(
                                        l10n.newSubscriptionPage_reviewStep_semesterEmpty,
                                        style: AppTextStyles.body.copyWith(
                                          color: errorColor,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Bus Stop Card
                            GetBuilder<BusStopsController>(
                              builder: (controller) {
                                BusStop? stop;
                                if (_selectedStopId != null) {
                                  try {
                                    stop = controller.busStops.firstWhere(
                                      (s) => s.id == _selectedStopId,
                                    );
                                  } catch (_) {
                                    stop = null;
                                  }
                                }

                                return Container(
                                  padding: const EdgeInsets.all(16.0),
                                  decoration: BoxDecoration(
                                    gradient: themeController.isDark
                                        ? darkGradient
                                        : lightGradient,
                                    borderRadius: borderRadius * 2.5,
                                    border: Border.all(
                                      color: infoColor.withValues(alpha: 0.5),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    spacing: 12.0,
                                    children: [
                                      Row(
                                        children: [
                                          HugeIcon(
                                            icon: HugeIcons
                                                .strokeRoundedLocationUser04,
                                            color: infoColor,
                                            size: 20.0,
                                          ),
                                          const Gap(8.0),
                                          Text(
                                            l10n.newSubscriptionPage_reviewStep_stopTitle,
                                            style: AppTextStyles.body.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: infoColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Divider(
                                        color: infoColor.withValues(alpha: 0.3),
                                      ),
                                      if (stop != null) ...[
                                        _SummaryRow(
                                          icon:
                                              HugeIcons.strokeRoundedLocation06,
                                          label: l10n
                                              .newSubscriptionPage_reviewStep_stopName,
                                          value: stop.name,
                                          valueColor: infoColor,
                                        ),
                                      ] else
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8.0,
                                          ),
                                          child: Text(
                                            l10n.newSubscriptionPage_reviewStep_stopEmpty,
                                            style: AppTextStyles.body.copyWith(
                                              color: errorColor,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),

                            // Schedules Card
                            Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                gradient: themeController.isDark
                                    ? darkGradient
                                    : lightGradient,
                                borderRadius: borderRadius * 2.5,
                                border: Border.all(
                                  color: warningColor.withValues(alpha: 0.5),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                spacing: 12.0,
                                children: [
                                  Row(
                                    children: [
                                      HugeIcon(
                                        icon: HugeIcons.strokeRoundedClock01,
                                        color: warningColor,
                                        size: 20.0,
                                      ),
                                      const Gap(8.0),
                                      Expanded(
                                        child: Text(
                                          l10n.newSubscriptionPage_reviewStep_weeklyScheduleTitle,
                                          style: AppTextStyles.body.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: warningColor,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12.0,
                                          vertical: 4.0,
                                        ),
                                        decoration: BoxDecoration(
                                          color: warningColor.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: borderRadius * 1.5,
                                        ),
                                        child: Text(
                                          _schedules.length > 1
                                              ? "${_schedules.length} ${l10n.days}"
                                              : "${_schedules.length} ${l10n.days.substring(0, l10n.days.length - 1)}",
                                          style: AppTextStyles.small.copyWith(
                                            color: warningColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Divider(
                                    color: warningColor.withValues(alpha: 0.3),
                                  ),
                                  if (_schedules.isNotEmpty) ...[
                                    Container(
                                      decoration: BoxDecoration(
                                        color: themeController.isDark
                                            ? Colors.black.withValues(
                                                alpha: 0.2,
                                              )
                                            : Colors.white.withValues(
                                                alpha: 0.5,
                                              ),
                                        borderRadius: borderRadius * 1.5,
                                      ),
                                      child: Table(
                                        columnWidths: const {
                                          0: FlexColumnWidth(2),
                                          1: FlexColumnWidth(2),
                                          2: FlexColumnWidth(2),
                                        },
                                        defaultVerticalAlignment:
                                            TableCellVerticalAlignment.middle,
                                        children: [
                                          TableRow(
                                            decoration: BoxDecoration(
                                              color: warningColor.withValues(
                                                alpha: 0.1,
                                              ),
                                              borderRadius: BorderRadius.only(
                                                topLeft: (borderRadius * 1.5)
                                                    .topLeft,
                                                topRight: (borderRadius * 1.5)
                                                    .topRight,
                                              ),
                                            ),
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.all(
                                                  12.0,
                                                ),
                                                child: Text(
                                                  l10n.newSubscriptionPage_reviewStep_weeklyScheduleDay,
                                                  style: AppTextStyles.body
                                                      .copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.all(
                                                  12.0,
                                                ),
                                                child: Row(
                                                  spacing: 4.0,
                                                  children: [
                                                    HugeIcon(
                                                      icon: HugeIcons
                                                          .strokeRoundedSun03,
                                                      size: 16.0,
                                                      color: warningColor,
                                                    ),
                                                    Text(
                                                      l10n.morning,
                                                      style: AppTextStyles.body
                                                          .copyWith(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.all(
                                                  12.0,
                                                ),
                                                child: Row(
                                                  spacing: 4.0,
                                                  children: [
                                                    HugeIcon(
                                                      icon: HugeIcons
                                                          .strokeRoundedMoon02,
                                                      size: 16.0,
                                                      color: warningColor,
                                                    ),
                                                    Text(
                                                      l10n.closing,
                                                      style: AppTextStyles.body
                                                          .copyWith(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          ..._schedules.map(
                                            (s) => TableRow(
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.all(
                                                    12.0,
                                                  ),
                                                  child: Text(
                                                    _weekdayLabelLong(
                                                      s.weekday,
                                                      context,
                                                    ),
                                                    style: AppTextStyles.body
                                                        .copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.all(
                                                    12.0,
                                                  ),
                                                  child: Text(
                                                    s.morningTime,
                                                    style: AppTextStyles.body,
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.all(
                                                    12.0,
                                                  ),
                                                  child: Text(
                                                    s.closingTime,
                                                    style: AppTextStyles.body,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ] else
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8.0,
                                      ),
                                      child: Text(
                                        l10n.newSubscriptionPage_reviewStep_weeklyScheduleEmpty,
                                        style: AppTextStyles.body.copyWith(
                                          color: errorColor,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Info Banner
                            Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: infoColor.withValues(alpha: 0.1),
                                borderRadius: borderRadius * 2,
                                border: Border.all(
                                  color: infoColor.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  HugeIcon(
                                    icon: HugeIcons
                                        .strokeRoundedInformationCircle,
                                    color: infoColor,
                                    size: 24.0,
                                  ),
                                  const Gap(12.0),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      spacing: 4.0,
                                      children: [
                                        Text(
                                          l10n.newSubscriptionPage_reviewStep_infoBubbleTitle,
                                          style: AppTextStyles.body.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: infoColor,
                                          ),
                                        ),
                                        Text(
                                          l10n.newSubscriptionPage_reviewStep_infoBubbleDescription,
                                          style: AppTextStyles.small.copyWith(
                                            color: infoColor.withValues(
                                              alpha: 0.8,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            BusLoadingOverlay(
              visible: _isSubmitting,
              title: l10n.newSubscriptionPage_overlay_title,
              message: l10n.newSubscriptionPage_overlay_subtitle,
            ),
          ],
        ),
      ),
    );
  }

  static String _weekdayLabelLong(int w, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (w) {
      case 1:
        return l10n.weekday_monday;
      case 2:
        return l10n.weekday_tuesday;
      case 3:
        return l10n.weekday_wednesday;
      case 4:
        return l10n.weekday_thursday;
      case 5:
        return l10n.weekday_friday;
      case 6:
        return l10n.weekday_saturday;
      default:
        return 'Day';
    }
  }

  BusStop? _findSelectedStop() {
    if (_selectedStopId == null) return null;
    try {
      return busStopController.busStops.firstWhere(
        (s) => s.id == _selectedStopId,
      );
    } catch (_) {
      return null;
    }
  }
}

// Widget for stop preview with image and Google Maps button
class _StopPreview extends StatelessWidget {
  final BusStop stop;

  const _StopPreview({required this.stop});

  void _openInGoogleMaps(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    if (stop.mapEmbedUrl == null || stop.mapEmbedUrl!.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          buildSnackBar(
            backgroundColor: warningColor,
            prefixIcon: const HugeIcon(
              icon: HugeIcons.strokeRoundedAlert01,
              color: lightColor,
              size: 20,
            ),
            label: Text(l10n.newSubscriptionPage_stopPreview_noLink),
          ),
        );
      return;
    }

    try {
      final uri = Uri.parse(stop.mapEmbedUrl!);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        if (context.mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              buildSnackBar(
                backgroundColor: successColor,
                prefixIcon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                  color: lightColor,
                  size: 20,
                ),
                label: Text(
                  l10n.subscriptionDetailPage_mapView_openMessageSuccess,
                ),
              ),
            );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            buildSnackBar(
              backgroundColor: errorColor,
              prefixIcon: const HugeIcon(
                icon: HugeIcons.strokeRoundedAlert02,
                color: lightColor,
                size: 20,
              ),
              label: Text(l10n.subscriptionDetailPage_mapView_openMessageError),
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius * 2.5,
        border: Border.all(
          color: themeController.isDark
              ? seedPalette.shade700
              : seedPalette.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section with Google Maps button overlay
          if (stop.hasImage || stop.hasMapEmbed)
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: Stack(
                children: [
                  // Image or map background
                  if (stop.hasImage)
                    CachedNetworkImage(
                      imageUrl: stop.pickupImageUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 200,
                        color: themeController.isDark
                            ? seedPalette.shade900
                            : seedPalette.shade100,
                        child: Center(child: LoadingIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 200,
                        color: themeController.isDark
                            ? seedPalette.shade900
                            : seedPalette.shade100,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedImageNotFound02,
                                color: greyColor,
                                size: 48,
                              ),
                              const Gap(8.0),
                              Text(
                                l10n.newSubscriptionPage_stopPreview_noImage,
                                style: AppTextStyles.small.copyWith(
                                  color: greyColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else if (stop.hasMapEmbed)
                    Container(
                      height: 200.0,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: themeController.isDark
                            ? seedPalette.shade900
                            : seedPalette.shade100,
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(mapsBg, fit: BoxFit.cover),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  seedColor.withValues(alpha: 0.1),
                                  seedColor.withValues(alpha: 0.3),
                                ],
                              ),
                            ),
                          ),
                          Center(
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedMaps,
                              color: lightColor,
                              size: 64.0,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.5),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Google Maps button
                  if (stop.hasMapEmbed)
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _openInGoogleMaps(context),
                          borderRadius: borderRadius * 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 10.0,
                            ),
                            decoration: BoxDecoration(
                              color: lightColor.withValues(alpha: 0.95),
                              borderRadius: borderRadius * 2,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                HugeIcon(
                                  icon: HugeIcons.strokeRoundedMaps,
                                  color: seedColor,
                                  size: 18,
                                ),
                                const Gap(6.0),
                                Text(
                                  l10n.newSubscriptionPage_stopPreview_mapsCta,
                                  style: AppTextStyles.body.copyWith(
                                    color: seedColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // Stop info section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedLocation06,
                      color: themeController.isDark
                          ? seedPalette.shade50
                          : seedColor,
                      size: 20,
                    ),
                    const Gap(8.0),
                    Expanded(child: Text(stop.name, style: AppTextStyles.h3)),
                  ],
                ),
                const Gap(12.0),
                Row(
                  spacing: 8.0,
                  children: [
                    if (stop.hasImage)
                      _Badge(
                        icon: HugeIcons.strokeRoundedImage02,
                        label: l10n.image,
                        color: successColor,
                      ),
                    if (stop.hasMapEmbed)
                      _Badge(
                        icon: HugeIcons.strokeRoundedMaps,
                        label: l10n.map,
                        color: infoColor,
                      ),
                    if (!stop.hasImage && !stop.hasMapEmbed)
                      _Badge(
                        icon: HugeIcons.strokeRoundedAlert01,
                        label: l10n.newSubscriptionPage_stopPreview_noMedia,
                        color: greyColor,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Badge widget for stop features
class _Badge extends StatelessWidget {
  final dynamic icon;
  final String label;
  final Color color;

  const _Badge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: borderRadius,
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, color: color, size: 14),
          const Gap(4.0),
          Text(
            label,
            style: AppTextStyles.small.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isLink;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.isLink = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HugeIcon(
            icon: icon,
            size: 18.0,
            color: themeController.isDark
                ? seedPalette.shade300
                : seedColor.withValues(alpha: 0.7),
          ),
          const Gap(12.0),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTextStyles.small.copyWith(
                color: themeController.isDark ? seedPalette.shade50 : greyColor,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppTextStyles.body.copyWith(
                color: valueColor,
                fontWeight: FontWeight.w600,
                decoration: isLink ? TextDecoration.underline : null,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
