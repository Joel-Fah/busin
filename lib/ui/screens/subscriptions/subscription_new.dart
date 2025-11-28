import 'package:busin/models/subscription.dart';
import 'package:busin/utils/constants.dart';
import 'package:busin/utils/utils.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

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

  // Term
  late Semester _semester;
  final TextEditingController _yearController = TextEditingController();

  // Proof (moved into stepper)
  String? _proofUrl;

  // Stops - curated list
  final List<Map<String, String>> _availableStops = [
    {'id': 'stop_01', 'name': 'Main Gate'},
    {'id': 'stop_02', 'name': 'Library Stop'},
    {'id': 'stop_03', 'name': 'North Residence'},
  ];
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
        gen = List.generate(6, (i) => BusSubscriptionSchedule(weekday: i + 1, morningTime: defaultStart, closingTime: defaultEnd));
        break;
      case _ScheduleMode.normalWeek:
        gen = List.generate(5, (i) => BusSubscriptionSchedule(weekday: i + 1, morningTime: defaultStart, closingTime: defaultEnd));
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

  List<BusSubscriptionSchedule> _uniqueSortedSchedules(List<BusSubscriptionSchedule> list) {
    final map = <int, BusSubscriptionSchedule>{};
    for (var s in list) {
      map[s.weekday] = s; // last wins
    }
    final sortedKeys = map.keys.toList()..sort();
    return sortedKeys.map((k) => map[k]!).toList();
  }

  void _addEmptySchedule() {
    if (_schedules.length >= 6) return; // max Mon-Sat
    // find first missing weekday from 1..6
    final present = _schedules.map((s) => s.weekday).toSet();
    int? pick;
    for (var i = 1; i <= 6; i++) {
      if (!present.contains(i)) {
        pick = i;
        break;
      }
    }
    if (pick == null) return;
    final newItem = BusSubscriptionSchedule(weekday: pick, morningTime: '07:00', closingTime: '17:00');
    setState(() {
      _schedules = _uniqueSortedSchedules(List.of(_schedules)..add(newItem));
      _scheduleMode = _ScheduleMode.custom;
    });
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
    final formatted = picked.hour.toString().padLeft(2, '0') + ':' + picked.minute.toString().padLeft(2, '0');
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

  void _onStepContinue() {
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
    final year = int.tryParse(_yearController.text) ?? DateTime.now().year;
    if (_selectedStopId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a preferred stop.')),
      );
      setState(() => _currentStep = 2);
      return;
    }
    // Validate schedules times
    for (var s in _schedules) {
      if (!s.isValidTimes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('One or more schedule times are invalid.'),
          ),
        );
        setState(() => _currentStep = 3);
        return;
      }
    }

    final stopMap = _availableStops.firstWhere(
      (e) => e['id'] == _selectedStopId,
    );
    final stop = BusStopSelection(id: stopMap['id']!, name: stopMap['name']!);

    final newSub = BusSubscription.pending(
      id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
      studentId: _currentStudentId,
      semester: _semester,
      year: year,
      proofOfPaymentUrl: _proofUrl,
      stop: stop,
      schedules: _schedules,
    );

    // TODO: send newSub to API / persistence layer

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subscription created (pending review)')),
    );
    Navigator.of(context).maybePop(newSub);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Subscription')),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        children: [
          Image.asset(newSubscription),
          const Gap(12.0),

          // Stepper with proof included
          Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(primary: seedColor),
            ),
            child: Stepper(
              currentStep: _currentStep,
              onStepContinue: _onStepContinue,
              onStepCancel: _onStepCancel,
              physics: const ClampingScrollPhysics(),
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: details.onStepContinue,
                        child: Text(_currentStep == 4 ? 'Submit' : 'Next'),
                      ),
                      const Gap(8.0),
                      TextButton(onPressed: details.onStepCancel, child: const Text('Back')),
                    ],
                  ),
                );
              },
              steps: [
                Step(
                  title: const Text('Receipt'),
                  state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                  isActive: _currentStep >= 0,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Proof of payment', style: AppTextStyles.body.copyWith(color: greyColor)),
                      const Gap(8.0),
                      InkWell(
                        onTap: () {
                          // TODO: integrate image picker/upload and set _proofUrl
                        },
                        borderRadius: borderRadius * 2,
                        child: DottedBorder(
                          options: RoundedRectDottedBorderOptions(
                            color: themeController.isDark ? seedPalette.shade50 : seedColor,
                            strokeWidth: 1.5,
                            dashPattern: const [4, 6, 8, 10],
                            radius: const Radius.circular(20.0),
                            padding: const EdgeInsets.all(4.0),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            constraints: const BoxConstraints(minHeight: 120.0),
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              borderRadius: borderRadius * 2.25,
                              gradient: LinearGradient(
                                colors: themeController.isDark
                                    ? [lightColor.withValues(alpha: 0.08), lightColor.withValues(alpha: 0.03)]
                                    : [seedColor.withValues(alpha: 0.08), seedColor.withValues(alpha: 0.03)],
                              ),
                            ),
                            child: _proofUrl == null
                                ? Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.upload_file, size: 36.0),
                                      const Gap(8.0),
                                      Text('Attach receipt', style: AppTextStyles.body),
                                      Text('You can attach or change the receipt here', style: AppTextStyles.body.copyWith(fontSize: 13.0, color: greyColor)),
                                    ],
                                  )
                                : Image.network(_proofUrl!, height: 120),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Step(
                  title: const Text('Term'),
                  state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                  isActive: _currentStep >= 1,
                  content: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Wrap(
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
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: _yearController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Year', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const Gap(12.0),
                      // show computed default date span preview
                      Builder(builder: (context) {
                        final year = int.tryParse(_yearController.text) ?? DateTime.now().year;
                        final span = _semester.defaultSpanForYear(year);
                        return Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16.0, color: greyColor),
                            const Gap(8.0),
                            Text('${dateFormatter(span.start)} — ${dateFormatter(span.end)}', style: AppTextStyles.body.copyWith(color: greyColor)),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                Step(
                  title: const Text('Preferred stop'),
                  state: _currentStep > 2 ? StepState.complete : StepState.indexed,
                  isActive: _currentStep >= 2,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _selectedStopId,
                        items: _availableStops.map((s) => DropdownMenuItem(value: s['id'], child: Text(s['name']!))).toList(),
                        onChanged: (v) => setState(() => _selectedStopId = v),
                        decoration: const InputDecoration(labelText: 'Select stop', border: OutlineInputBorder()),
                      ),
                    ],
                  ),
                ),
                Step(
                  title: const Text('Weekly schedules'),
                  state: _currentStep > 3 ? StepState.complete : StepState.indexed,
                  isActive: _currentStep >= 3,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // presets
                      Row(
                        children: [
                          ChoiceChip(label: const Text('Everyday'), selected: _scheduleMode == _ScheduleMode.everyday, onSelected: (_) => _applyScheduleMode(_ScheduleMode.everyday)),
                          const Gap(8.0),
                          ChoiceChip(label: const Text('Normal week'), selected: _scheduleMode == _ScheduleMode.normalWeek, onSelected: (_) => _applyScheduleMode(_ScheduleMode.normalWeek)),
                          const Gap(8.0),
                          ChoiceChip(label: const Text('Custom'), selected: _scheduleMode == _ScheduleMode.custom, onSelected: (_) => _applyScheduleMode(_ScheduleMode.custom)),
                        ],
                      ),
                      const Gap(12.0),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _schedules.length >= 6 ? null : _addEmptySchedule,
                          icon: const Icon(Icons.add),
                          label: const Text('Add day'),
                        ),
                      ),
                      const Gap(8.0),
                      if (_schedules.isEmpty)
                        Text('No schedules added. Add the days you take the bus.', style: AppTextStyles.body.copyWith(color: greyColor)),
                      for (var i = 0; i < _schedules.length; i++)
                        Card(
                          margin: const EdgeInsets.symmetric(vertical: 6.0),
                          child: ListTile(
                            title: DropdownButton<int>(
                              value: _schedules[i].weekday,
                              items: const [
                                DropdownMenuItem(value: 1, child: Text('Monday')),
                                DropdownMenuItem(value: 2, child: Text('Tuesday')),
                                DropdownMenuItem(value: 3, child: Text('Wednesday')),
                                DropdownMenuItem(value: 4, child: Text('Thursday')),
                                DropdownMenuItem(value: 5, child: Text('Friday')),
                                DropdownMenuItem(value: 6, child: Text('Saturday')),
                              ],
                              onChanged: (v) {
                                if (v == null) return;
                                // prevent duplicate day selection
                                if (_schedules.where((s) => s.weekday == v).isNotEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('That day is already added.')));
                                  return;
                                }
                                setState(() {
                                  final s = _schedules[i];
                                  _schedules[i] = BusSubscriptionSchedule(weekday: v, morningTime: s.morningTime, closingTime: s.closingTime);
                                  _schedules = _uniqueSortedSchedules(_schedules);
                                  _scheduleMode = _ScheduleMode.custom;
                                });
                              },
                            ),
                            subtitle: Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _editScheduleTime(i, morning: true),
                                    child: InputDecorator(
                                      decoration: const InputDecoration(labelText: 'Morning', border: OutlineInputBorder()),
                                      child: Text(_schedules[i].morningTime),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _editScheduleTime(i, morning: false),
                                    child: InputDecorator(
                                      decoration: const InputDecoration(labelText: 'Close', border: OutlineInputBorder()),
                                      child: Text(_schedules[i].closingTime),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: IconButton(onPressed: () => _removeSchedule(i), icon: const Icon(Icons.delete_outline)),
                          ),
                        ),
                      if (_schedules.length >= 6)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text('Maximum of 6 days reached (Mon–Sat).', style: AppTextStyles.body.copyWith(color: greyColor)),
                        ),
                    ],
                  ),
                ),
                Step(
                  title: const Text('Review & submit'),
                  state: _currentStep == 4 ? StepState.editing : StepState.indexed,
                  isActive: _currentStep >= 4,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Student', style: AppTextStyles.body.copyWith(color: greyColor)),
                              const Gap(6.0),
                              Text(_currentStudentId, style: AppTextStyles.title),
                              const Gap(12.0),
                              Text('Term', style: AppTextStyles.body.copyWith(color: greyColor)),
                              const Gap(6.0),
                              Text('${_semester.label} ${_yearController.text}', style: AppTextStyles.title),
                              const Gap(12.0),
                              Text('Stop', style: AppTextStyles.body.copyWith(color: greyColor)),
                              const Gap(6.0),
                              Text(_availableStops.firstWhere((e) => e['id'] == _selectedStopId, orElse: () => {'name': 'Not selected'})['name']!, style: AppTextStyles.title),
                            ],
                          ),
                        ),
                      ),
                      const Gap(12.0),

                      // Schedules summary table
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Schedules', style: AppTextStyles.body.copyWith(color: greyColor)),
                              const Gap(8.0),
                              Table(
                                columnWidths: const {
                                  0: FlexColumnWidth(2),
                                  1: FlexColumnWidth(2),
                                  2: FlexColumnWidth(2),
                                },
                                border: TableBorder(horizontalInside: BorderSide(color: greyColor.withValues(alpha: 0.12))),
                                children: [
                                  TableRow(children: [
                                    Padding(padding: const EdgeInsets.all(8.0), child: Text('Day', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold))),
                                    Padding(padding: const EdgeInsets.all(8.0), child: Text('Morning', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold))),
                                    Padding(padding: const EdgeInsets.all(8.0), child: Text('Close', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold))),
                                  ]),
                                  ..._schedules.map((s) => TableRow(children: [
                                    Padding(padding: const EdgeInsets.all(8.0), child: Text(_weekdayLabelLong(s.weekday))),
                                    Padding(padding: const EdgeInsets.all(8.0), child: Text(s.morningTime)),
                                    Padding(padding: const EdgeInsets.all(8.0), child: Text(s.closingTime)),
                                  ])),
                                  if (_schedules.isEmpty)
                                    TableRow(children: [
                                      Padding(padding: const EdgeInsets.all(8.0), child: Text('No schedules selected', style: AppTextStyles.body.copyWith(color: greyColor))),
                                      const SizedBox(),
                                      const SizedBox(),
                                    ]),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Gap(12.0),
                      Text('By submitting you agree to the terms and fees.', style: AppTextStyles.body.copyWith(color: greyColor, fontSize: 13.0)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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
