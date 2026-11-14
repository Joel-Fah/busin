import 'dart:async';

import 'package:busin_core/busin_core.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../router.dart';
import 'area_providers.dart';

enum _Step { overview, ask, name, search }

/// My area (ADR 0013): the student says roughly where they live, by one approximate reading at home or by searching a
/// place. What is stored is rounded to about 500 m by the server; the student can change or remove it at any time.
///
/// With [intro], it is the one-time invitation right after setup (ADR 0023): a short welcome on top, and "Not now"
/// instead of a back arrow. Either way the student then goes on to the subscription tab.
class MyAreaScreen extends ConsumerStatefulWidget {
  const MyAreaScreen({super.key, this.intro = false});

  final bool intro;

  @override
  ConsumerState<MyAreaScreen> createState() => _MyAreaScreenState();
}

class _MyAreaScreenState extends ConsumerState<MyAreaScreen> {
  _Step? _step;
  Located? _reading;
  final _name = TextEditingController();
  final _query = TextEditingController();
  Timer? _debounce;
  List<PlaceResult>? _results;
  bool _searching = false;
  bool _busy = false;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    // Seen once is enough: it is not offered again, here or as a card.
    if (widget.intro) ref.read(markAreaOfferedProvider)();
  }

  /// Where the student goes when done or not now: back where they came from, or on with the app after setup.
  void _leave() {
    if (widget.intro) {
      context.go(Routes.subscription);
    } else {
      context.canPop() ? context.pop() : context.go(Routes.profile);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _name.dispose();
    _query.dispose();
    super.dispose();
  }

  BusinL10n get _l10n => BusinL10n.of(context);

  void _go(_Step step) => setState(() => _step = step);

  Future<void> _readAtHome() async {
    final go = await showBusinSheet<bool>(context, builder: (context) => const _ExplainSheet());
    if (go != true || !mounted) return;
    setState(() => _busy = true);
    final result = await ref.read(areaLocatorProvider).readOnce();
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Located():
        _reading = result;
        if (_name.text.trim().isEmpty) _name.text = _l10n.areaDefaultName;
        _go(_Step.name);
      case LocationDenied(forever: true):
        BusinToast.show(
          context,
          _l10n.areaDeniedForever,
          tone: ToastTone.warning,
        );
        await ref.read(areaLocatorProvider).openSettings();
      case LocationDenied():
        BusinToast.show(context, _l10n.areaDenied, tone: ToastTone.info);
      case LocationOff():
        BusinToast.show(context, _l10n.areaOff, tone: ToastTone.info);
      case LocationFailed():
        BusinToast.show(context, _l10n.areaFailed, tone: ToastTone.error);
    }
  }

  void _onQuery(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(value));
  }

  Future<void> _search(String value) async {
    final query = value.trim();
    if (query.length < 2) {
      setState(() => _results = null);
      return;
    }
    setState(() {
      _searching = true;
      _searchError = null;
    });
    try {
      final places = await ref.read(areaRepositoryProvider).searchPlaces(query);
      if (!mounted || _query.text.trim() != query) return;
      setState(() => _results = places);
    } on NotAllowed {
      if (mounted) setState(() => _searchError = _l10n.areaTooMany);
    } catch (_) {
      if (mounted) setState(() => _searchError = _l10n.errorGeneric);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _save({required double lat, required double lng, required String label, required AreaSource source}) async {
    setState(() => _busy = true);
    try {
      await ref.read(areaRepositoryProvider).setArea(lat: lat, lng: lng, label: label, source: source);
      await ref.read(setAreaLaterProvider)(false);
      ref.invalidate(myAreaProvider);
      if (!mounted) return;
      BusinHaptics.medium();
      BusinToast.show(context, _l10n.areaSaved, tone: ToastTone.success);
      _reading = null;
      _query.clear();
      _results = null;
      if (widget.intro) {
        _leave();
        return;
      }
      _go(_Step.overview);
    } on Invalid {
      if (mounted) BusinToast.show(context, _l10n.areaTooFar, tone: ToastTone.warning);
    } catch (_) {
      if (mounted) BusinToast.show(context, _l10n.errorGeneric, tone: ToastTone.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    setState(() => _busy = true);
    try {
      await ref.read(areaRepositoryProvider).clearArea();
      ref.invalidate(myAreaProvider);
      if (!mounted) return;
      BusinToast.show(context, _l10n.areaRemoved, tone: ToastTone.info);
      _go(_Step.ask);
    } catch (_) {
      if (mounted) BusinToast.show(context, _l10n.errorGeneric, tone: ToastTone.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _later() async {
    await ref.read(setAreaLaterProvider)(true);
    if (!mounted) return;
    _leave();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    final area = ref.watch(myAreaProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.areaTitle),
        automaticallyImplyLeading: !widget.intro,
        leading: widget.intro ? null : BackButton(onPressed: _leave),
        actions: [if (widget.intro) TextButton(onPressed: _leave, child: Text(l10n.areaIntroSkip))],
      ),
      body: SafeArea(
        child: ContentColumn(
          child: area.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(child: Text(l10n.errorGeneric)),
            data: (current) {
              final step = _step ?? (current == null ? _Step.ask : _Step.overview);
              return ListView(
                padding: const EdgeInsets.all(BusinSpace.x5),
                children: switch (step) {
                  _Step.overview when current != null => _overview(current),
                  _Step.overview || _Step.ask => _ask(),
                  _Step.name => _nameIt(),
                  _Step.search => _searchStep(),
                },
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _overview(StudentArea area) {
    final l10n = _l10n;
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    return [
      BusinCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                HugeIcon(icon: HugeIcons.strokeRoundedHome01, size: 22, color: p.accent),
                const SizedBox(width: BusinSpace.x3),
                Expanded(child: Text(area.label, style: text.titleLarge)),
              ],
            ),
            const SizedBox(height: BusinSpace.x2),
            Text(l10n.areaRounded, style: text.bodySmall?.copyWith(color: p.muted)),
          ],
        ),
      ),
      const SizedBox(height: BusinSpace.x4),
      BusinButton(label: l10n.areaChange, icon: HugeIcons.strokeRoundedEdit02, expand: true, onPressed: _busy ? null : () => _go(_Step.ask)),
      const SizedBox(height: BusinSpace.x3),
      BusinButton(
        label: l10n.areaRemove,
        variant: BusinButtonVariant.danger,
        icon: HugeIcons.strokeRoundedDelete02,
        expand: true,
        loading: _busy,
        onPressed: _busy ? null : _remove,
      ),
    ];
  }

  List<Widget> _ask() {
    final l10n = _l10n;
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    return [
      if (widget.intro) ...[
        Text(l10n.areaIntroTitle, style: text.headlineSmall),
        const SizedBox(height: BusinSpace.x2),
      ],
      Text(l10n.areaIntro, style: text.bodyMedium?.copyWith(color: p.muted)),
      const SizedBox(height: BusinSpace.x5),
      Text(l10n.areaAtHome, style: text.titleLarge),
      const SizedBox(height: BusinSpace.x4),
      BusinButton(
        label: l10n.areaYesHome,
        icon: HugeIcons.strokeRoundedLocation01,
        expand: true,
        loading: _busy,
        onPressed: _busy ? null : _readAtHome,
      ),
      const SizedBox(height: BusinSpace.x3),
      BusinButton(
        label: l10n.areaNoSearch,
        variant: BusinButtonVariant.secondary,
        icon: HugeIcons.strokeRoundedSearch01,
        expand: true,
        onPressed: _busy ? null : () => _go(_Step.search),
      ),
    ];
  }

  List<Widget> _nameIt() {
    final l10n = _l10n;
    final reading = _reading;
    return [
      BusinTextField(
        label: l10n.areaNameLabel,
        hint: l10n.areaNameHint,
        icon: HugeIcons.strokeRoundedHome01,
        controller: _name,
        textInputAction: TextInputAction.done,
      ),
      const SizedBox(height: BusinSpace.x4),
      BusinButton(
        label: l10n.areaSave,
        expand: true,
        loading: _busy,
        onPressed: _busy || reading == null
            ? null
            : () {
                final label = _name.text.trim();
                _save(lat: reading.lat, lng: reading.lng, label: label.isEmpty ? l10n.areaDefaultName : label.characters.take(80).toString(), source: AreaSource.device);
              },
      ),
    ];
  }

  List<Widget> _searchStep() {
    final l10n = _l10n;
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final results = _results;
    return [
      BusinTextField(
        label: l10n.areaSearchLabel,
        hint: l10n.areaNameHint,
        icon: HugeIcons.strokeRoundedSearch01,
        controller: _query,
        onChanged: _onQuery,
        onSubmitted: _search,
        textInputAction: TextInputAction.search,
      ),
      const SizedBox(height: BusinSpace.x3),
      if (_searching) const LinearProgressIndicator(),
      if (_searchError != null) Notice(tone: StatusTone.warn, child: Text(_searchError!)),
      if (results != null && results.isEmpty && !_searching) Text(l10n.areaSearchEmpty, style: text.bodyMedium?.copyWith(color: p.muted)),
      if (results != null)
        for (final place in results)
          Padding(
            padding: const EdgeInsets.only(bottom: BusinSpace.x2),
            child: BusinCard(
              onTap: _busy ? null : () => _save(lat: place.lat, lng: place.lng, label: place.label, source: AreaSource.search),
              child: Row(
                children: [
                  HugeIcon(icon: HugeIcons.strokeRoundedLocation01, size: 20, color: p.muted),
                  const SizedBox(width: BusinSpace.x3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(place.label, style: text.titleSmall),
                        Text(_kindLabel(l10n, place.kind), style: text.bodySmall?.copyWith(color: p.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      // The places come from OpenStreetMap, whose licence asks for this credit where they are shown.
      if (results != null && results.isNotEmpty) Text(l10n.areaOsmCredit, style: text.labelSmall?.copyWith(color: p.muted)),
      const SizedBox(height: BusinSpace.x4),
      BusinCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.areaNotSeeing, style: text.titleMedium),
            const SizedBox(height: BusinSpace.x1),
            Text(l10n.areaNotSeeingBody, style: text.bodySmall?.copyWith(color: p.muted)),
            const SizedBox(height: BusinSpace.x3),
            BusinButton(label: l10n.areaRemindMe, variant: BusinButtonVariant.secondary, icon: HugeIcons.strokeRoundedClock01, onPressed: _later),
          ],
        ),
      ),
    ];
  }
}

String _kindLabel(BusinL10n l10n, PlaceKind kind) => switch (kind) {
      PlaceKind.area => l10n.placeKindArea,
      PlaceKind.village => l10n.placeKindVillage,
      PlaceKind.street => l10n.placeKindStreet,
      PlaceKind.landmark => l10n.placeKindLandmark,
    };

class _ExplainSheet extends StatelessWidget {
  const _ExplainSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.all(BusinSheetFrame.contentInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.areaExplainTitle, style: text.titleLarge),
          const SizedBox(height: BusinSpace.x2),
          Text(l10n.areaExplainBody, style: text.bodyMedium?.copyWith(color: p.muted)),
          const SizedBox(height: BusinSpace.x4),
          BusinButton(label: l10n.areaContinue, expand: true, onPressed: () => Navigator.of(context).pop(true)),
        ],
      ),
    );
  }
}
