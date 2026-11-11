import 'dart:async';

import 'package:busin_app/busin_app.dart';
import 'package:busin_core/busin_core.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mobile_scanner/mobile_scanner.dart' show BarcodeFormat, MobileScanner, MobileScannerController;
import 'package:uuid/uuid.dart';

import '../providers.dart';
import '../queue/scan_queue.dart';
import '../router.dart';
import '../trips/trip_providers.dart';
import 'scan_decision.dart';
import 'scan_providers.dart';

/// The camera, given the function to call with each code it reads. A provider, so tests use a stand-in.
typedef ScannerView = Widget Function(BuildContext context, void Function(String code) onCode);

final scannerViewProvider = Provider<ScannerView>((ref) => (context, onCode) => _CameraView(onCode: onCode));

class _CameraView extends StatefulWidget {
  const _CameraView({required this.onCode});
  final void Function(String code) onCode;

  @override
  State<_CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<_CameraView> {
  final _controller = MobileScannerController(formats: const [BarcodeFormat.qrCode]);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MobileScanner(
        controller: _controller,
        onDetect: (capture) {
          for (final barcode in capture.barcodes) {
            final value = barcode.rawValue;
            if (value != null) widget.onCode(value);
          }
        },
        errorBuilder: (context, error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(BusinSpace.x5),
            child: Text(BusinL10n.of(context).opsCameraDenied, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
          ),
        ),
      );
}

/// What the result card shows.
sealed class _Result {
  const _Result();
}

class _Checking extends _Result {
  const _Checking();
}

class _Good extends _Result {
  const _Good({required this.name, this.avatarUrl, this.matricule, this.again = false});
  final String name;
  final String? avatarUrl;
  final String? matricule;
  final bool again;
}

class _Bad extends _Result {
  const _Bad(this.message);
  final String message;
}

/// Scanning at the door: each code is checked on the phone with today's list (offline too), the scan is queued with
/// the stop and the time, and the queue is sent when it can be.
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  _Result? _result;
  String? _lastCode;
  DateTime? _lastAt;
  bool _busy = false;
  Timer? _clear;
  Fix? _fix;
  StreamSubscription<Fix>? _positions;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startLocation());
  }

  @override
  void dispose() {
    _clear?.cancel();
    _positions?.cancel();
    super.dispose();
  }

  Future<void> _startLocation() async {
    final source = ref.read(locationFeedProvider);
    var allowed = await source.hasPermission();
    if (!allowed && mounted) {
      final go = await showBusinSheet<bool>(context, builder: (context) => const _LocationWhy());
      if (go == true) allowed = await source.requestPermission();
    }
    if (!allowed || !mounted) return;
    _positions = source.watch().listen((fix) => _fix = fix, onError: (Object _) {});
  }

  void _show(_Result result) {
    _clear?.cancel();
    setState(() => _result = result);
    _clear = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _result = null);
    });
  }

  Future<void> _onCode(String code) async {
    final now = ref.read(nowProvider)();
    // A code held in front of the camera is read many times a second: once is enough.
    if (_busy || (code == _lastCode && _lastAt != null && now.difference(_lastAt!) < const Duration(seconds: 4))) return;
    _lastCode = code;
    _lastAt = now;
    _busy = true;
    try {
      await _decide(code, now);
    } finally {
      _busy = false;
    }
  }

  Future<void> _decide(String code, DateTime now) async {
    final l10n = BusinL10n.of(context);
    final school = await ref.read(schoolProvider.future);
    final clock = ref.read(schoolClockProvider);
    DateTime schoolDate(DateTime instant) => clock.today(school.timezone, now: instant);
    final roster = ref.read(rosterProvider).value;
    final online = ref.read(connectivityProvider).value ?? true;
    final mine = await ref.read(scanQueueProvider).forTrip(widget.tripId);
    final manifest = ref.read(manifestProvider(widget.tripId)).value ?? const <ManifestEntry>[];
    final boarded = {
      for (final s in mine) if (s.state != QueuedState.refused) s.studentId,
      for (final m in manifest) m.studentId,
    };

    final decision = decideScan(code: code, now: now, roster: roster, schoolDate: schoolDate, boarded: boarded, online: online);
    switch (decision) {
      case Admit(:final rider):
        await _queue(code, rider.studentId, now);
        BusinHaptics.medium();
        _show(_Good(name: rider.fullName, avatarUrl: rider.avatarUrl, matricule: rider.matricule));
      case AlreadyOnBoard(:final rider):
        BusinHaptics.light();
        _show(_Good(name: rider.fullName, avatarUrl: rider.avatarUrl, matricule: rider.matricule, again: true));
      case Refuse(:final kind):
        unawaited(HapticFeedback.vibrate());
        _show(_Bad(switch (kind) {
          RefusalKind.invalid => l10n.opsResultInvalid,
          RefusalKind.expired => l10n.opsResultExpired,
          RefusalKind.notOnList => l10n.opsResultNotOnList,
          RefusalKind.noKeys => l10n.opsResultNoKeys,
        }));
      case AskServer():
        _show(const _Checking());
        await _askServer(code, now);
    }
  }

  ({String? stopId, double? lat, double? lng, double? accuracy}) _where() {
    final fix = _fix;
    if (fix == null) return (stopId: null, lat: null, lng: null, accuracy: null);
    final stops = ref.read(stopsProvider).value ?? const <Stop>[];
    return (stopId: nearestStop(stops, fix.point)?.id, lat: fix.point.latitude, lng: fix.point.longitude, accuracy: fix.accuracy);
  }

  Future<void> _queue(String code, String studentId, DateTime now, {bool accepted = false}) async {
    final where = _where();
    final queue = ref.read(scanQueueProvider);
    final id = const Uuid().v4();
    await queue.add(QueuedScan(
      clientId: id,
      tripId: widget.tripId,
      code: code,
      studentId: studentId,
      scannedAt: now.toUtc(),
      stopId: where.stopId,
      lat: where.lat,
      lng: where.lng,
      accuracy: where.accuracy,
    ));
    if (accepted) await queue.markAccepted(id);
    ref.invalidate(tripScansProvider(widget.tripId));
    if (!accepted) unawaited(ref.read(scanSyncerProvider).run().then((_) => ref.invalidate(manifestProvider(widget.tripId))));
  }

  /// The phone could not decide on its own: the server checks the code now.
  Future<void> _askServer(String code, DateTime now) async {
    final l10n = BusinL10n.of(context);
    final where = _where();
    try {
      final outcome = await ref.read(scansRepositoryProvider).recordScan(
            tripId: widget.tripId,
            code: code,
            stopId: where.stopId,
            location: where.lat == null ? null : GeoPoint(where.lat!, where.lng!),
            accuracyMeters: where.accuracy,
          );
      if (!mounted) return;
      switch (outcome) {
        case ScanAccepted(:final student, :final duplicate):
          final parsed = QrCodeVerifier.parse(code);
          if (parsed != null && !duplicate) await _queue(code, parsed.studentId, now, accepted: true);
          ref.invalidate(manifestProvider(widget.tripId));
          BusinHaptics.medium();
          _show(_Good(name: student.fullName, avatarUrl: student.avatarUrl, matricule: student.matricule, again: duplicate));
        case ScanRefused(:final reason):
          unawaited(HapticFeedback.vibrate());
          _show(_Bad(switch (reason) {
            ScanFailure.invalidCode => l10n.opsResultInvalid,
            ScanFailure.expiredCode => l10n.opsResultExpired,
            ScanFailure.studentNotFound => l10n.opsResultUnknown,
            ScanFailure.accountNotVerified => l10n.opsResultNotVerified,
            ScanFailure.noActiveSubscription => l10n.opsResultNoSubscription,
          }));
      }
    } on Offline {
      if (mounted) _show(_Bad(l10n.opsResultNoKeys));
    } catch (_) {
      if (mounted) _show(_Bad(l10n.errorGeneric));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final roster = ref.watch(rosterProvider);
    final pending = ref.watch(pendingCountProvider).value ?? 0;
    // Loaded while the scanner is open, so each scan can be tagged with its stop.
    ref.watch(stopsProvider);
    final bus = ref.watch(tripBusProvider(widget.tripId)).value;
    final mine = ref.watch(tripScansProvider(widget.tripId)).value ?? const <QueuedScan>[];
    final manifest = ref.watch(manifestProvider(widget.tripId)).value ?? const <ManifestEntry>[];
    final onBoard = {
      for (final s in mine) if (s.state != QueuedState.refused) s.studentId,
      for (final m in manifest) m.studentId,
    }.length;
    final zone = ref.watch(schoolProvider).value?.timezone ?? 'UTC';
    final list = roster.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(bus?.label ?? l10n.opsScan),
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go(Routes.trip(widget.tripId))),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(BusinSpace.x4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(BusinRadius.lg),
                  child: ColoredBox(
                    color: Colors.black,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ref.watch(scannerViewProvider)(context, _onCode),
                        IgnorePointer(
                          child: Center(
                            child: FractionallySizedBox(
                              widthFactor: 0.7,
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 3),
                                    borderRadius: BorderRadius.circular(BusinRadius.md),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: BusinSpace.x3),
              AnimatedSwitcher(
                duration: BusinMotion.of(context, BusinMotion.normal),
                child: _ResultCard(key: ValueKey(_result), result: _result),
              ),
              const SizedBox(height: BusinSpace.x3),
              Row(
                children: [
                  HugeIcon(icon: HugeIcons.strokeRoundedUserGroup, size: 18, color: p.fg),
                  const SizedBox(width: BusinSpace.x2),
                  Text(bus == null ? '$onBoard' : l10n.opsBoarded(onBoard, bus.capacity), style: text.titleSmall),
                  const Spacer(),
                  HugeIcon(icon: HugeIcons.strokeRoundedCloudUpload, size: 18, color: pending == 0 ? p.muted : p.accent),
                  const SizedBox(width: BusinSpace.x2),
                  Flexible(child: Text(l10n.opsPending(pending), style: text.bodySmall?.copyWith(color: p.muted), overflow: TextOverflow.ellipsis)),
                ],
              ),
              const SizedBox(height: BusinSpace.x2),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      list == null
                          ? l10n.opsKeysMissing
                          : l10n.opsKeysStatus(
                              list.length,
                              MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(const SchoolClock().wallClock(zone, list.downloadedAt))),
                            ),
                      style: text.bodySmall?.copyWith(color: list == null ? p.bad : p.muted),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.opsKeysRefresh,
                    onPressed: roster.isLoading
                        ? null
                        : () => ref.read(rosterProvider.notifier).refresh().catchError((Object _) {
                              if (context.mounted) BusinToast.show(context, l10n.opsKeysMissing, tone: ToastTone.warning);
                            }),
                    icon: HugeIcon(icon: HugeIcons.strokeRoundedRefresh, size: 20, color: p.fg),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({super.key, required this.result});

  final _Result? result;

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final r = result;
    if (r == null) {
      return BusinCard(
        child: Row(
          children: [
            HugeIcon(icon: HugeIcons.strokeRoundedQrCode, size: 28, color: p.muted),
            const SizedBox(width: BusinSpace.x3),
            Expanded(child: Text(l10n.opsScanHint, style: text.bodyMedium?.copyWith(color: p.muted))),
          ],
        ),
      );
    }
    final (fill, ink, icon, title, body, avatar) = switch (r) {
      _Checking() => (p.surface2, p.fg, HugeIcons.strokeRoundedLoading03, l10n.opsResultChecking, null, null),
      _Good(:final name, :final matricule, :final again, :final avatarUrl) => (
          again ? p.warnBg : p.okBg,
          again ? p.warn : p.ok,
          HugeIcons.strokeRoundedCheckmarkCircle02,
          again ? l10n.opsResultAlready : l10n.opsResultBoarded,
          [name, if (matricule != null && matricule.isNotEmpty) matricule].join(' · '),
          (name: name, url: avatarUrl),
        ),
      _Bad(:final message) => (p.badBg, p.bad, HugeIcons.strokeRoundedCancelCircle, message, null, null),
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(BusinSpace.x4),
        decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(BusinRadius.md)),
        child: Row(
          children: [
            if (avatar != null) UserAvatar(name: avatar.name, imageUrl: avatar.url, size: 48) else HugeIcon(icon: icon, size: 32, color: ink),
            const SizedBox(width: BusinSpace.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.titleMedium?.copyWith(color: ink, fontWeight: FontWeight.w800)),
                  if (body != null) Text(body, style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            if (avatar != null) HugeIcon(icon: icon, size: 28, color: ink),
          ],
        ),
      ),
    );
  }
}

class _LocationWhy extends StatelessWidget {
  const _LocationWhy();

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.all(BusinSheetFrame.contentInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.opsLocationWhyTitle, style: text.titleLarge),
          const SizedBox(height: BusinSpace.x2),
          Text(l10n.opsLocationWhyBody, style: text.bodyMedium?.copyWith(color: p.muted)),
          const SizedBox(height: BusinSpace.x4),
          BusinButton(label: l10n.opsLocationContinue, expand: true, onPressed: () => Navigator.of(context).pop(true)),
        ],
      ),
    );
  }
}
