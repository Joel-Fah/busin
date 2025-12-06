import 'package:busin/controllers/bus_stop_controller.dart';
import 'package:busin/models/subscription.dart';
import 'package:busin/ui/components/widgets/default_snack_bar.dart';
import 'package:busin/ui/components/widgets/form_fields/select_image.dart';
import 'package:busin/ui/components/widgets/form_fields/simple_text_field.dart';
import 'package:busin/utils/constants.dart';
import 'package:busin/utils/utils.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';

import '../../../models/value_objects/bus_stop_selection.dart';

// Schedule presets for quick selection
enum _ScheduleMode { everyday, normalWeek, custom }

class NewSubscriptionPage extends StatefulWidget {
  const NewSubscriptionPage({super.key});

  static const String routeName = "/new-subscription";

  @override
  State<NewSubscriptionPage> createState() => _NewSubscriptionPageState();
}

class _NewSubscriptionPageState extends State<NewSubscriptionPage> {
  int _currentStep = 0;
  static const TimeOfDay _minMorningTime = TimeOfDay(hour: 6, minute: 30);
  static const TimeOfDay _maxClosingTime = TimeOfDay(hour: 17, minute: 0);

  // GetX Controllers
  final BusStopController busStopController = Get.find<BusStopController>();

  // Term
  late Semester _semester;
  final TextEditingController _yearController = TextEditingController(
    text: DateTime
        .now()
        .year
        .toString(),
  );

  // Proof (moved into stepper)
  String? _proofUrl;

  // Stops - curated list
  // final List<Map<String, String>> _availableStops = [
  //   {'id': 'stop_01', 'name': 'Main Gate'},
  //   {'id': 'stop_02', 'name': 'Library Stop'},
  //   {'id': 'stop_03', 'name': 'North Residence'},
  // ];
  String? _selectedStopId;

  // Weekly schedules
  List<BusSubscriptionSchedule> _schedules = [];
  _ScheduleMode _scheduleMode = _ScheduleMode.normalWeek;

  // Simple helper to simulate current logged-in student id
  String get _currentStudentId {
    // TODO: replace with real auth user id fetch
    return 'stu_current';
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _semester = _detectSemesterFromDate(now);
    _yearController.text = now.year.toString();

    // Default schedule mode -> normal week
    _applyScheduleMode(_scheduleMode);

    // keep proof url if passed via navigation or previous step
    _proofUrl = null; // assume already handled elsewhere
  }

  @override
  void dispose() {
    _yearController.dispose();
    super.dispose();
  }

  Semester _detectSemesterFromDate(DateTime d) {
    final m = d.month;
    if (m >= 9) return Semester.fall; // Sep - Dec
    if (m >= 6) return Semester.summer; // Jun - Aug
    return Semester.spring; // Jan - May
  }

  void _applyScheduleMode(_ScheduleMode mode) {
    const defaultStart = '07:00';
    const defaultEnd = '17:00';
    List<BusSubscriptionSchedule> gen;
    switch (mode) {
      case _ScheduleMode.everyday:
        gen = List.generate(
          6,
              (i) =>
              BusSubscriptionSchedule(
                weekday: i + 1,
                morningTime: defaultStart,
                closingTime: defaultEnd,
              ),
        );
        break;
      case _ScheduleMode.normalWeek:
        gen = List.generate(
          5,
              (i) =>
              BusSubscriptionSchedule(
                weekday: i + 1,
                morningTime: defaultStart,
                closingTime: defaultEnd,
              ),
        );
        break;
      case _ScheduleMode.custom:
        gen = List.of(_schedules); // keep existing custom entries
        break;
    }
    setState(() {
      _scheduleMode = mode;
      _schedules = _uniqueSortedSchedules(gen);
    });
  }

  List<BusSubscriptionSchedule> _uniqueSortedSchedules(
      List<BusSubscriptionSchedule> list,) {
    final map = <int, BusSubscriptionSchedule>{};
    for (var s in list) {
      map[s.weekday] = s; // last wins
    }
    final sortedKeys = map.keys.toList()
      ..sort();
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
      _schedules = _uniqueSortedSchedules(List.of(_schedules)
        ..add(newItem));
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
    final s = _schedules[index];
    final current = morning ? s.morningTime : s.closingTime;
    final picked = await _pickTime(context, current);
    if (picked == null) return;

    if (morning) {
      if (_isBefore(picked, _minMorningTime)) {
        _showScheduleError('Earliest morning time is 6:30 AM.');
        return;
      }
      if (_isAfter(picked, _timeOfDayFromString(s.closingTime))) {
        _showScheduleError('Morning time must be <= closing time.');
        return;
      }
    } else {
      if (_isAfter(picked, _maxClosingTime)) {
        _showScheduleError('Latest close time is 5:00 PM.');
        return;
      }
      if (_isBefore(picked, _timeOfDayFromString(s.morningTime))) {
        _showScheduleError('Close time must be >= morning time.');
        return;
      }
    }

    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute
        .toString()
        .padLeft(2, '0')}';
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
      final list = List.of(_schedules)
        ..removeAt(index);
      _schedules = _uniqueSortedSchedules(list);
    });
  }

  bool _validateStep(int step) {
    switch (step) {
      case 0:
        if (_proofUrl == null) {
          _showScheduleError('Upload a proof of payment.');
          return false;
        }
        return true;
      case 1:
        final year = int.tryParse(_yearController.text);
        if (year == null || year < 2000) {
          _showScheduleError('Enter a valid subscription year.');
          return false;
        }
        return true;
      case 2:
        if (_selectedStopId == null) {
          _showScheduleError('Select a preferred stop.');
          return false;
        }
        return true;
      case 3:
        if (_schedules.isEmpty) {
          _showScheduleError('Add at least one schedule.');
          return false;
        }
        for (final s in _schedules) {
          if (!s.isValidTimes) {
            _showScheduleError('One or more schedule times are invalid.');
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

  void _submit() {
    // Basic validation
    final year = int.tryParse(_yearController.text) ?? DateTime
        .now()
        .year;
    if (_selectedStopId == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          buildSnackBar(
            backgroundColor: errorColor,
            prefixIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedDirectionRight02,
              color: lightColor,
            ),
            label: Text('Please select a preferred stop.'),
          ),
        );
      setState(() => _currentStep = 2);
      return;
    }
    // Validate schedules times
    for (var s in _schedules) {
      if (!s.isValidTimes) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            buildSnackBar(
              backgroundColor: errorColor,
              prefixIcon: HugeIcon(
                icon: HugeIcons.strokeRoundedCalendarRemove02,
                color: lightColor,
              ),
              label: Text('One or more schedule times are invalid.'),
            ),
          );
        setState(() => _currentStep = 3);
        return;
      }
    }

    final stopMap = busStopController.stops.firstWhere(
          (s) => s.id == _selectedStopId,
    );

    final newSub = BusSubscription.pending(
      id: 'sub_${DateTime
          .now()
          .millisecondsSinceEpoch}',
      studentId: _currentStudentId,
      semester: _semester,
      year: year,
      proofOfPaymentUrl: _proofUrl,
      stop: stopMap,
      schedules: _schedules,
    );

    // TODO: send newSub to API / persistence layer
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        buildSnackBar(
          backgroundColor: successColor,
          prefixIcon: HugeIcon(
            icon: HugeIcons.strokeRoundedTaskDone01,
            color: lightColor,
          ),
          label: Text('Subscription created (pending review)'),
        ),
      );
    context.pop(newSub);
  }

  @override
  Widget build(BuildContext context) {
    final nextWeekday = _nextAvailableWeekday();
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('New Subscription')),
        body: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Image.asset(newSubscription),
            ),
            Stepper(
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
                return Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: details.onStepContinue,
                        child: Text(
                          _currentStep == 4 ? 'Submit' : 'Next',
                          style: AppTextStyles.body,
                        ),
                      ),
                      const Gap(8.0),
                      TextButton(
                        onPressed: details.onStepCancel,
                        child: const Text('Back', style: AppTextStyles.body),
                      ),
                    ],
                  ),
                );
              },
              steps: [
                Step(
                  stepStyle: StepStyle(
                    indexStyle: AppTextStyles.body.copyWith(color: lightColor),
                  ),
                  title: Text(
                    'Receipt',
                    style: AppTextStyles.body.copyWith(
                      color: _currentStep >= 0 ? seedColor : greyColor,
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
                        'Proof of payment',
                        style: AppTextStyles.body.copyWith(
                          color: greyColor,
                          fontSize: 14.0,
                        ),
                      ),
                      const Gap(8.0),
                      ImageBox(
                        onImageSelected: (filePath) =>
                            setState(() {
                              _proofUrl = filePath;
                            }),
                        label: 'Upload a copy of your receipt',
                      ),
                    ],
                  ),
                ),
                Step(
                  stepStyle: StepStyle(
                    indexStyle: AppTextStyles.body.copyWith(color: lightColor),
                  ),
                  title: Text(
                    'Semester',
                    style: AppTextStyles.body.copyWith(
                      color: _currentStep >= 1 ? seedColor : greyColor,
                    ),
                  ),
                  state: _currentStep > 1
                      ? StepState.complete
                      : StepState.indexed,
                  isActive: _currentStep >= 1,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8.0,
                    children: [
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: Semester.values.map((s) {
                          final selected = s == _semester;
                          return ChoiceChip(
                            label: Text(s.label),
                            selected: selected,
                            onSelected: (_) => setState(() => _semester = s),
                          );
                        }).toList(),
                      ),
                      const Gap(8.0),
                      SimpleTextFormField(
                        controller: _yearController,
                        hintText: "Subscription year",
                        label: Text("Subscription year"),
                        keyboardType: TextInputType.number,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Builder(
                          builder: (context) {
                            final year =
                                int.tryParse(_yearController.text) ??
                                    DateTime
                                        .now()
                                        .year;
                            final span = _semester.defaultSpanForYear(year);
                            return Row(
                              children: [
                                const HugeIcon(
                                  icon: HugeIcons.strokeRoundedCalendar01,
                                  size: 16.0,
                                  color: greyColor,
                                ),
                                const Gap(8.0),
                                Text(
                                  'From: ${dateFormatter(
                                      span.start)} — To: ${dateFormatter(
                                      span.end)}',
                                  style: AppTextStyles.body.copyWith(
                                    color: greyColor,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Step(
                  stepStyle: StepStyle(
                    indexStyle: AppTextStyles.body.copyWith(color: lightColor),
                  ),
                  title: Text(
                    'Preferred stop',
                    style: AppTextStyles.body.copyWith(
                      color: _currentStep >= 2 ? seedColor : greyColor,
                    ),
                  ),
                  state: _currentStep > 2
                      ? StepState.complete
                      : StepState.indexed,
                  isActive: _currentStep >= 2,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(() {
                        return DropdownButtonFormField<String>(
                          initialValue: _selectedStopId,
                          items: busStopController.stops
                              .map(
                                (s) =>
                                DropdownMenuItem(
                                  value: s.id,
                                  child: Text(
                                    s.name,
                                    style: AppTextStyles.body,
                                  ),
                                ),
                          )
                              .toList(),
                          style: AppTextStyles.body.copyWith(color: seedColor),
                          dropdownColor: seedPalette.shade50,
                          onChanged: (v) => setState(() => _selectedStopId = v),
                          icon: HugeIcon(
                            icon: HugeIcons.strokeRoundedArrowDown01,
                          ),
                          borderRadius: borderRadius * 2.5,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12.0,
                              horizontal: 16.0,
                            ),
                            labelText: 'Select stop',
                            labelStyle: AppTextStyles.body,
                            hintText: "Select stop",
                            hintStyle: AppTextStyles.body.copyWith(
                              color: themeController.isDark
                                  ? lightColor.withValues(alpha: 0.6)
                                  : seedColor.withValues(alpha: 0.6),
                            ),
                            border: AppInputBorders.border,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                Step(
                  stepStyle: StepStyle(
                    indexStyle: AppTextStyles.body.copyWith(color: lightColor),
                  ),
                  title: Text(
                    'Weekly schedules',
                    style: AppTextStyles.body.copyWith(
                      color: _currentStep >= 3 ? seedColor : greyColor,
                    ),
                  ),
                  state: _currentStep > 3
                      ? StepState.complete
                      : StepState.indexed,
                  isActive: _currentStep >= 3,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // presets
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Everyday'),
                            selected: _scheduleMode == _ScheduleMode.everyday,
                            onSelected: (_) =>
                                _applyScheduleMode(_ScheduleMode.everyday),
                          ),
                          const Gap(8.0),
                          ChoiceChip(
                            label: const Text('Normal week'),
                            selected: _scheduleMode == _ScheduleMode.normalWeek,
                            onSelected: (_) =>
                                _applyScheduleMode(_ScheduleMode.normalWeek),
                          ),
                          const Gap(8.0),
                          ChoiceChip(
                            label: const Text('Custom'),
                            selected: _scheduleMode == _ScheduleMode.custom,
                            onSelected: (_) =>
                                _applyScheduleMode(_ScheduleMode.custom),
                          ),
                        ],
                      ),
                      const Gap(8.0),
                      if (_schedules.isEmpty)
                        Container(
                          decoration: BoxDecoration(
                            color: greyColor.withValues(alpha: .1),
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
                              'No schedules added. Add the days you take the bus.',
                              style: AppTextStyles.body.copyWith(
                                color: greyColor,
                              ),
                            ),
                          ),
                        ),
                      for (var i = 0; i < _schedules.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Animate(
                            key: ValueKey(_schedules[i].weekday),
                            effects: const [
                              FadeEffect(duration: Duration(milliseconds: 220)),
                              SlideEffect(
                                begin: Offset(0, 0.05),
                                duration: Duration(milliseconds: 220),
                              ),
                            ],
                            child: Container(
                              padding: EdgeInsets.all(12.0).copyWith(top: 4.0),
                              decoration: BoxDecoration(
                                borderRadius: borderRadius * 2.5,
                                color: seedPalette.shade50.withValues(
                                  alpha: 0.5,
                                ),
                                border: Border.all(
                                  color: seedPalette.shade800.withValues(
                                    alpha: 0.15,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    spacing: 8.0,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _weekdayLabelLong(
                                            _schedules[i].weekday,
                                          ),
                                          style: AppTextStyles.h4.copyWith(
                                            color: seedColor,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        tooltip:
                                        'Remove ${_weekdayLabelLong(
                                            _schedules[i].weekday)}',
                                        style: IconButton.styleFrom(
                                          overlayColor: errorColor.withValues(
                                            alpha: 0.12,
                                          ),
                                        ),
                                        onPressed: () => _removeSchedule(i),
                                        icon: const HugeIcon(
                                          icon: HugeIcons.strokeRoundedDelete03,
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
                                          borderRadius: borderRadius * 1.5,
                                          onTap: () =>
                                              _editScheduleTime(
                                                i,
                                                morning: true,
                                              ),
                                          child: InputDecorator(
                                            decoration: InputDecoration(
                                              labelText: 'Morning',
                                              labelStyle: AppTextStyles.body,
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                borderRadius * 1.5,
                                                borderSide: BorderSide(
                                                  color: seedColor,
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
                                          borderRadius: borderRadius * 1.5,
                                          onTap: () =>
                                              _editScheduleTime(
                                                i,
                                                morning: false,
                                              ),
                                          child: InputDecorator(
                                            decoration: InputDecoration(
                                              labelText: 'Close',
                                              labelStyle: AppTextStyles.body,
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                borderRadius * 1.5,
                                                borderSide: BorderSide(
                                                  color: seedColor,
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
                              color: infoColor.withValues(alpha: .1),
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
                                'Maximum of 6 days reached (Mon–Sat).',
                                style: AppTextStyles.body.copyWith(
                                  color: infoColor,
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
                                'Add ${_weekdayLabelLong(nextWeekday)}',
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
                    indexStyle: AppTextStyles.body.copyWith(color: lightColor),
                  ),
                  title: Text(
                    'Review & submit',
                    style: AppTextStyles.body.copyWith(
                      color: _currentStep >= 4 ? seedColor : greyColor,
                    ),
                  ),
                  state: _currentStep == 4
                      ? StepState.editing
                      : StepState.indexed,
                  isActive: _currentStep >= 4,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          borderRadius: borderRadius * 2.5,
                          color: seedPalette.shade50.withValues(alpha: 0.65),
                          border: Border.all(
                            color: seedPalette.shade800.withValues(alpha: 0.15),
                          ),
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
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6.0,
                                  ),
                                  child: Text(
                                    'Student',
                                    style: AppTextStyles.body.copyWith(
                                      color: greyColor,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6.0,
                                  ),
                                  child: Text(
                                    _currentStudentId,
                                    style: AppTextStyles.h3,
                                  ),
                                ),
                                const SizedBox(),
                              ],
                            ),
                            TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6.0,
                                  ),
                                  child: Text(
                                    'Semester',
                                    style: AppTextStyles.body.copyWith(
                                      color: greyColor,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6.0,
                                  ),
                                  child: Text(
                                    '${_semester.label} ${_yearController
                                        .text}',
                                    style: AppTextStyles.h3,
                                  ),
                                ),
                                const SizedBox(),
                              ],
                            ),
                            TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6.0,
                                  ),
                                  child: Text(
                                    'Stop',
                                    style: AppTextStyles.body.copyWith(
                                      color: greyColor,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6.0,
                                  ),
                                  child: Obx(() {
                                    return Text(
                                      busStopController.stops.firstWhere(
                                            (e) => e.id == _selectedStopId,
                                        orElse: () => BusStop(
                                          id: 'none',
                                          name: 'Not selected',
                                        ),
                                      ).name,
                                      style: AppTextStyles.h3,
                                    );
                                  }),
                                ),
                                const SizedBox(),
                              ],
                            ),
                            TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6.0,
                                  ),
                                  child: Text(
                                    'Schedules',
                                    style: AppTextStyles.body.copyWith(
                                      color: greyColor,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6.0,
                                  ),
                                  child: Text(
                                    "${_schedules.length} day${_schedules
                                        .length > 1 ? 's' : ''}",
                                    style: AppTextStyles.h3,
                                  ),
                                ),
                                const SizedBox(),
                              ],
                            ),
                            const TableRow(
                              children: [Gap(16.0), SizedBox(), SizedBox()],
                            ),
                            TableRow(
                              decoration: BoxDecoration(
                                color: seedPalette.shade100.withValues(
                                  alpha: 0.4,
                                ),
                                borderRadius: borderRadius * 1.5,
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    'Day',
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    'Morning',
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    'Close',
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            ..._schedules.map(
                                  (s) =>
                                  TableRow(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          _weekdayLabelLong(s.weekday),
                                          style: AppTextStyles.body,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          s.morningTime,
                                          style: AppTextStyles.body,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          s.closingTime,
                                          style: AppTextStyles.body,
                                        ),
                                      ),
                                    ],
                                  ),
                            ),
                            if (_schedules.isEmpty)
                              TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      'Aucun horaire sélectionné',
                                      style: AppTextStyles.body.copyWith(
                                        color: greyColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(),
                                  const SizedBox(),
                                ],
                              ),
                          ],
                        ),
                      ),
                      const Gap(12.0),
                      Text(
                        'Submit your subscription request for review. You will be notified once it has been processed.',
                        style: AppTextStyles.body.copyWith(
                          color: greyColor,
                          fontSize: 13.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _weekdayLabelLong(int w) {
    switch (w) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      default:
        return 'Day';
    }
  }
}
