import 'dart:async';

import 'package:busin_core/busin_core.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../push/push_providers.dart';
import '../reminders/notification_providers.dart';
import '../subscription/subscription_providers.dart';
import 'boarding_card.dart';

/// A boarding the phone learns about later than this is not announced (it was a while ago).
const lateBoardingWindow = Duration(hours: 6);

/// The key of the last boarding announced to this student on this phone, so a boarding is announced once.
String seenBoardingKey(String userId) => 'boarding.seen.$userId';

/// Listens to the student's newest boarding while the app is open. When a new one arrives (the code was just scanned)
/// it shows the "on board" card with a line that fits the moment. When the newest boarding on first arrival is one this
/// phone has not announced and it is recent (the phone was offline at the door), a quieter card names the time.
/// Respects "A word when I board" in the notification preferences.
class BoardingBinder extends ConsumerStatefulWidget {
  const BoardingBinder({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<BoardingBinder> createState() => _BoardingBinderState();
}

class _BoardingBinderState extends ConsumerState<BoardingBinder> {
  StreamSubscription<Scan?>? _feed;
  bool _first = true;

  @override
  void initState() {
    super.initState();
    final userId = ref.read(authUserIdProvider).value;
    if (userId == null) return;
    _feed = ref.read(scansRepositoryProvider).watchLatestForStudent(userId).listen((scan) => _arrived(userId, scan), onError: (Object _) {
      // A convenience: if the feed drops, nothing is lost (the history still lists every boarding).
    });
  }

  @override
  void dispose() {
    _feed?.cancel();
    super.dispose();
  }

  Future<void> _arrived(String userId, Scan? scan) async {
    final first = _first;
    _first = false;
    if (scan == null) return;
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final key = seenBoardingKey(userId);
    if (prefs.getString(key) == scan.id) return;
    await prefs.setString(key, scan.id);

    final now = ref.read(nowProvider)();
    if (first && now.difference(scan.scannedAt) > lateBoardingWindow) return;
    final wants = ref.read(notificationPreferencesProvider).value?.boardingMessagesOn ?? true;
    if (!wants || !mounted) return;

    final l10n = BusinL10n.of(context);
    final code = Localizations.localeOf(context).languageCode;
    try {
      final school = await ref.read(schoolProvider.future);
      final clock = ref.read(schoolClockProvider);
      final at = clock.wallClock(school.timezone, scan.scannedAt);
      if (first) {
        // Learned late: say when, without a cheer.
        if (!mounted) return;
        final time = MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay(hour: at.hour, minute: at.minute));
        await showBoardingCard(context, title: l10n.boardedEarlier(time), line: boardingLine(BoardingMoment(at: at), seed: scan.id, languageCode: code));
        return;
      }
      final overview = await ref.read(subscriptionOverviewProvider.future);
      final semester = overview.semester;
      final phase = semester == null ? SemesterPhase.middle : phaseOf(at, semester.startDate, semester.endDate);
      final rides = semester == null ? null : await ref.read(scansRepositoryProvider).countForStudentSince(userId, semester.startDate).catchError((Object _) => -1);
      if (!mounted) return;
      final moment = BoardingMoment(at: at, phase: phase, rideNumber: rides == null || rides < 0 ? null : rides);
      await showBoardingCard(context, title: l10n.boardedTitle, line: boardingLine(moment, seed: scan.id, languageCode: code));
    } catch (_) {
      // Without the school or the semester the card still says something kind.
      if (!mounted) return;
      await showBoardingCard(context, title: l10n.boardedTitle, line: boardingLine(BoardingMoment(at: now), seed: scan.id, languageCode: code));
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
