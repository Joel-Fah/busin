import 'package:busin_core/busin_core.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import 'trip_providers.dart';

/// The words for why a trip could not be started in the field, from what the server said (ADR 0020).
String fieldTripRefusal(BusinL10n l10n, Object error) {
  final reason = error is RepositoryException ? error.reason : null;
  return switch (reason) {
    'use_scheduled_trip' => l10n.opsFieldScheduled,
    'bus_busy' => l10n.opsFieldBusBusy,
    'bus_out_of_service' => l10n.opsFieldOutOfService,
    'too_many_field_trips' => l10n.opsFieldLimit,
    'field_trips_off' => l10n.opsFieldOff,
    'invalid_crew' => l10n.opsFieldCrew,
    _ => l10n.errorGeneric,
  };
}

/// Starts a trip nobody scheduled: the bus, the direction, whether the caller is the driver or the assistant, and the
/// other crew member if known. Closes with the new trip's id.
class FieldTripSheet extends ConsumerStatefulWidget {
  const FieldTripSheet({super.key});

  @override
  ConsumerState<FieldTripSheet> createState() => _FieldTripSheetState();
}

class _FieldTripSheetState extends ConsumerState<FieldTripSheet> {
  String? _busId;
  TripDirection _direction = TripDirection.inbound;
  CrewRole _role = CrewRole.driver;
  String? _otherId;
  bool _busy = false;

  Future<void> _start() async {
    final busId = _busId;
    if (busId == null || _busy) return;
    final l10n = BusinL10n.of(context);
    setState(() => _busy = true);
    try {
      final id = await ref.read(tripsRepositoryProvider).startFieldTrip(busId: busId, direction: _direction, role: _role, otherId: _otherId);
      BusinHaptics.medium();
      if (mounted) Navigator.of(context).pop(id);
    } catch (e) {
      if (!mounted) return;
      BusinToast.show(context, fieldTripRefusal(l10n, e), tone: e is Offline ? ToastTone.error : ToastTone.warning);
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final options = ref.watch(fieldTripOptionsProvider);
    return Padding(
      padding: EdgeInsets.all(BusinSheetFrame.contentInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.opsFieldTitle, style: text.titleLarge),
            const SizedBox(height: BusinSpace.x2),
            Text(l10n.opsFieldBody, style: text.bodyMedium?.copyWith(color: p.muted)),
            const SizedBox(height: BusinSpace.x4),
            ...switch (options) {
              AsyncData(:final value) when !value.allowed => [Text(l10n.opsFieldOff, style: text.bodyMedium)],
              AsyncData(:final value) => _form(context, l10n, p, text, value),
              AsyncError() => [Text(l10n.errorGeneric, style: text.bodyMedium)],
              _ => const [Center(child: Padding(padding: EdgeInsets.all(BusinSpace.x4), child: CircularProgressIndicator()))],
            },
          ],
        ),
      ),
    );
  }

  List<Widget> _form(BuildContext context, BusinL10n l10n, BusinPalette p, TextTheme text, FieldTripOptions options) {
    final isDriver = _role == CrewRole.driver;
    return [
      Text(l10n.opsFieldBus, style: text.titleSmall),
      const SizedBox(height: BusinSpace.x2),
      if (options.buses.isEmpty)
        Text(l10n.opsFieldNoBuses, style: text.bodyMedium?.copyWith(color: p.muted))
      else
        Wrap(
          spacing: BusinSpace.x2,
          runSpacing: BusinSpace.x2,
          children: [
            for (final bus in options.buses)
              ChoiceChip(label: Text(bus.label), selected: _busId == bus.id, onSelected: (_) => setState(() => _busId = bus.id)),
          ],
        ),
      const SizedBox(height: BusinSpace.x4),
      Text(l10n.opsFieldDirection, style: text.titleSmall),
      const SizedBox(height: BusinSpace.x2),
      BusinSegmented<TripDirection>(
        groupLabel: l10n.opsFieldDirection,
        selected: _direction,
        onChanged: (v) => setState(() => _direction = v),
        segments: [for (final d in TripDirection.values) BusinSegment(value: d, label: l10n.direction(d))],
      ),
      const SizedBox(height: BusinSpace.x4),
      Text(l10n.opsFieldRole, style: text.titleSmall),
      const SizedBox(height: BusinSpace.x2),
      BusinSegmented<CrewRole>(
        groupLabel: l10n.opsFieldRole,
        selected: _role,
        // The other person's seat changes with ours, so the old pick no longer applies.
        onChanged: (v) => setState(() {
          _role = v;
          _otherId = null;
        }),
        segments: [
          BusinSegment(value: CrewRole.driver, label: l10n.opsFieldRoleDriver),
          BusinSegment(value: CrewRole.assistant, label: l10n.opsFieldRoleAssistant),
        ],
      ),
      const SizedBox(height: BusinSpace.x4),
      Text(isDriver ? l10n.opsFieldOtherAssistant : l10n.opsFieldOtherDriver, style: text.titleSmall),
      const SizedBox(height: BusinSpace.x2),
      DropdownButtonFormField<String?>(
        key: ValueKey(_role),
        initialValue: _otherId,
        isExpanded: true,
        decoration: InputDecoration(helperText: l10n.opsFieldOtherHint, helperMaxLines: 2),
        items: [
          DropdownMenuItem<String?>(value: null, child: Text(l10n.opsFieldOtherNone)),
          for (final person in options.staff) DropdownMenuItem<String?>(value: person.id, child: Text(person.name, overflow: TextOverflow.ellipsis)),
        ],
        onChanged: (v) => setState(() => _otherId = v),
      ),
      const SizedBox(height: BusinSpace.x5),
      BusinButton(label: l10n.opsFieldConfirm, expand: true, loading: _busy, onPressed: _busId == null ? null : _start),
    ];
  }
}
