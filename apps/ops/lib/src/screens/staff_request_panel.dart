import 'package:busin_core/busin_core.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../providers.dart';

/// The account's own staff request (ADR 0026), read again whenever it changes. Null for an account that is not a student.
final myStaffRequestProvider = FutureProvider.autoDispose<JoinRequest?>((ref) async {
  if (ref.watch(authUserIdProvider).value == null) return null;
  return ref.watch(staffAccessRepositoryProvider).myRequest();
});

/// The schools the account may ask: the one its email's domain belongs to, its own, or every active school (ADR 0026).
final staffRequestSchoolsProvider = FutureProvider.autoDispose<List<OpenSchool>>((ref) async {
  if (ref.watch(authUserIdProvider).value == null) return const [];
  return ref.watch(staffAccessRepositoryProvider).listSchools();
});

/// For a student account that opened the ops app (signed in before their school invited them): ask a school for staff
/// access, see where the request stands, withdraw it, or ask again after a decline. The school's administrators decide in
/// the portal; when they approve, the account watcher opens the app by itself. An account sends at most 3 requests
/// (issue #543): it is told how many are left, and once none are, to ask its school's administrator for an invite.
class StaffRequestPanel extends ConsumerStatefulWidget {
  const StaffRequestPanel({super.key});

  @override
  ConsumerState<StaffRequestPanel> createState() => _StaffRequestPanelState();
}

class _StaffRequestPanelState extends ConsumerState<StaffRequestPanel> {
  bool _busy = false;

  Future<void> _send(String? schoolId) async {
    final l10n = BusinL10n.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(staffAccessRepositoryProvider).requestStaffAccess(schoolId);
      if (mounted && schoolId != null) BusinToast.show(context, l10n.opsStaffSent, tone: ToastTone.success);
    } on NotAllowed catch (e) {
      if (mounted) BusinToast.show(context, e.reason == 'too_many' ? l10n.opsStaffTooSoon : l10n.errorGeneric, tone: ToastTone.warning);
    } on Conflict catch (e) {
      // The account sent its 3 requests (issue #543): the panel, read again below, then says to ask for an invite.
      if (mounted) BusinToast.show(context, e.reason == 'requests_used_up' ? l10n.opsStaffRequestsUsedUp : l10n.errorGeneric, tone: ToastTone.warning);
    } on Offline {
      if (mounted) BusinToast.show(context, l10n.offlineTitle, tone: ToastTone.warning);
    } catch (_) {
      if (mounted) BusinToast.show(context, l10n.errorGeneric, tone: ToastTone.error);
    } finally {
      ref.invalidate(myStaffRequestProvider);
      if (mounted) setState(() => _busy = false);
    }
  }

  /// One school (the email's, or the account's own): asked straight away. Several: the person picks one first.
  Future<void> _ask(List<OpenSchool> schools) async {
    final l10n = BusinL10n.of(context);
    if (schools.isEmpty) {
      BusinToast.show(context, l10n.opsStaffNoSchools, tone: ToastTone.info);
      return;
    }
    if (schools.length == 1) return _send(schools.single.id);
    final url = ref.read(appConfigProvider).supabaseUrl;
    final chosen = await showBusinSheet<OpenSchool>(
      context,
      isScrollControlled: true,
      builder: (sheet) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheet).height * 0.7),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(BusinSpace.x4, 0, BusinSpace.x4, BusinSpace.x4),
            children: [
              Text(l10n.opsStaffChooseSchool, style: Theme.of(sheet).textTheme.titleMedium),
              const SizedBox(height: BusinSpace.x1),
              Text(l10n.opsStaffChooseHint, style: Theme.of(sheet).textTheme.bodySmall?.copyWith(color: BusinPalette.of(sheet).muted)),
              const SizedBox(height: BusinSpace.x3),
              for (final school in schools)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: SchoolLogo(url: school.logoUrl(url), size: 40),
                  title: Text(school.name),
                  subtitle: school.place == null ? null : Text(school.place!),
                  onTap: () => Navigator.of(sheet).pop(school),
                ),
            ],
          ),
        ),
      ),
    );
    if (chosen != null && mounted) await _send(chosen.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final request = ref.watch(myStaffRequestProvider);
    final value = request.value;
    final schools = ref.watch(staffRequestSchoolsProvider).value ?? const <OpenSchool>[];
    final text = Theme.of(context).textTheme;

    if (request.isLoading && value == null) {
      return const Padding(padding: EdgeInsets.all(BusinSpace.x4), child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5)));
    }

    final children = <Widget>[];
    if (value != null && value.isWaiting) {
      children.addAll([
        Notice(
          tone: StatusTone.info,
          icon: HugeIcons.strokeRoundedHourglass,
          child: Text(l10n.opsStaffWaiting(value.schoolName ?? '')),
        ),
        const SizedBox(height: BusinSpace.x3),
        BusinButton(label: l10n.opsStaffWithdraw, variant: BusinButtonVariant.secondary, loading: _busy, onPressed: _busy ? null : () => _send(null)),
      ]);
    } else {
      if (value != null && value.wasDeclined) {
        children.addAll([
          Notice(
            tone: StatusTone.warn,
            icon: HugeIcons.strokeRoundedCancelCircle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.opsStaffDeclined(value.declinedSchoolName ?? ''), style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                if (value.declineNote != null) Text(l10n.opsStaffDeclinedNote(value.declineNote!)),
              ],
            ),
          ),
          const SizedBox(height: BusinSpace.x3),
        ]);
      }
      if (value != null && value.requestsUsedUp) {
        // At most 3 requests per account (issue #543): no button any more, only an administrator lets them in.
        children.add(Notice(
          tone: StatusTone.info,
          icon: HugeIcons.strokeRoundedUserShield01,
          child: Text(l10n.opsStaffRequestsUsedUp),
        ));
      } else {
        children.add(BusinButton(
          // With one school to ask (the email's, or the account's own), the button names it and sends at once.
          label: value != null && value.wasDeclined
              ? l10n.opsStaffAskAgain
              : schools.length == 1
                  ? l10n.opsStaffAskSchool(schools.single.name)
                  : l10n.opsStaffAsk,
          icon: HugeIcons.strokeRoundedUserShield01,
          loading: _busy,
          onPressed: _busy ? null : () => _ask(schools),
        ));
        // Once the account has asked before, it is told how many requests are left.
        final left = value?.requestsLeft;
        if (left != null && left < JoinRequest.staffRequestLimit) {
          children.addAll([
            const SizedBox(height: BusinSpace.x2),
            Text(l10n.opsStaffRequestsLeft(left), textAlign: TextAlign.center, style: text.bodySmall?.copyWith(color: BusinPalette.of(context).muted)),
          ]);
        }
      }
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}
