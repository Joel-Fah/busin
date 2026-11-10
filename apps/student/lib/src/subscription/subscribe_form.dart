import 'package:busin_core/busin_core.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../auth/access.dart';
import '../providers.dart';
import 'proof_picker.dart';
import 'stop_picker_sheet.dart';
import 'subscription_providers.dart';

/// The request form: a stop, a photo of the payment receipt, and Send. Nothing is sent until both are chosen.
class SubscribeForm extends ConsumerStatefulWidget {
  const SubscribeForm({super.key, required this.semester, this.offline = false});

  final Semester semester;

  /// The screen is showing the copy saved on the phone: nothing can be sent until the phone is connected again.
  final bool offline;

  @override
  ConsumerState<SubscribeForm> createState() => _SubscribeFormState();
}

class _SubscribeFormState extends ConsumerState<SubscribeForm> {
  Stop? _stop;
  PickedProof? _proof;
  bool _busy = false;
  String? _error;

  Future<void> _chooseStop(List<Stop> stops) async {
    final stop = await showStopPicker(context, stops, selectedId: _stop?.id);
    if (stop != null && mounted) setState(() => _stop = stop);
  }

  Future<void> _chooseProof() async {
    final l10n = BusinL10n.of(context);
    final source = await showBusinSheet<ProofSource>(
      context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const HugeIcon(icon: HugeIcons.strokeRoundedCamera01),
              title: Text(l10n.proofTakePhoto),
              onTap: () => Navigator.of(context).pop(ProofSource.camera),
            ),
            ListTile(
              leading: const HugeIcon(icon: HugeIcons.strokeRoundedImage01),
              title: Text(l10n.proofChoosePhoto),
              onTap: () => Navigator.of(context).pop(ProofSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final proof = await ref.read(proofPickerProvider).pick(source);
      if (proof != null && mounted) {
        setState(() {
          _proof = proof;
          _error = null;
        });
      }
    } on ProofException catch (e) {
      if (mounted) setState(() => _error = e.problem == ProofProblem.type ? l10n.subscribeErrorType : l10n.subscribeErrorTooLarge);
    }
  }

  Future<void> _submit() async {
    final l10n = BusinL10n.of(context);
    final access = ref.read(accessProvider);
    final stop = _stop;
    final proof = _proof;
    if (access is! Allowed || stop == null || proof == null) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(subscriptionServiceProvider).submit(profile: access.profile, semester: widget.semester, stop: stop, proof: proof);
      // The overview reloads and replaces this form with the pending card.
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = switch (failureFor(e)) {
          SubscribeFailure.alreadyRequested => l10n.subscribeErrorExists,
          SubscribeFailure.offline => l10n.errorOffline,
          SubscribeFailure.rejectedFile => l10n.subscribeErrorType,
          SubscribeFailure.other => l10n.errorGeneric,
        };
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final palette = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final stops = ref.watch(stopsProvider);
    final ready = _stop != null && _proof != null && !_busy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.subscribeIntro, style: text.bodyMedium?.copyWith(color: palette.muted)),
        const SizedBox(height: BusinSpace.x5),
        StaggeredIn(
          child: FieldTile(
            label: l10n.subscribeStopLabel,
            icon: HugeIcons.strokeRoundedFlag02,
            value: _stop?.name,
            placeholder: l10n.subscribeStopHint,
            onTap: stops.hasValue && !_busy ? () => _chooseStop(stops.requireValue) : null,
          ),
        ),
        if (stops.hasError) ...[
          const SizedBox(height: BusinSpace.x2),
          Notice(
            tone: StatusTone.bad,
            child: Row(
              children: [
                Expanded(child: Text(l10n.errorGeneric)),
                TextButton(onPressed: () => ref.invalidate(stopsProvider), child: Text(l10n.actionRetry)),
              ],
            ),
          ),
        ],
        const SizedBox(height: BusinSpace.x4),
        StaggeredIn(
          index: 1,
          child: FieldTile(
            label: l10n.subscribeProofLabel,
            icon: HugeIcons.strokeRoundedReceiptText,
            value: _proof == null ? null : l10n.proofAdded,
            placeholder: l10n.subscribeProofHint,
            onTap: _busy ? null : _chooseProof,
            preview: _proof == null ? null : Image.memory(_proof!.bytes, height: 180, fit: BoxFit.cover, semanticLabel: l10n.subscribeProofLabel),
          ),
        ),
        const SizedBox(height: BusinSpace.x3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.only(top: 2), child: HugeIcon(icon: HugeIcons.strokeRoundedShield01, size: 16, color: palette.muted)),
            const SizedBox(width: BusinSpace.x2),
            Expanded(child: Text(l10n.subscribeProofPrivacy, style: text.bodySmall?.copyWith(color: palette.muted))),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: BusinSpace.x4),
          Notice(tone: StatusTone.bad, child: Text(_error!)),
        ],
        const SizedBox(height: BusinSpace.x6),
        BusinButton(label: l10n.subscribeSubmit, onPressed: ready && !widget.offline ? _submit : null, loading: _busy, expand: true),
        if (widget.offline) ...[
          const SizedBox(height: BusinSpace.x2),
          Text(l10n.offlineNeedsConnection, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: BusinPalette.of(context).muted), textAlign: TextAlign.center),
        ],
      ],
    );
  }
}
