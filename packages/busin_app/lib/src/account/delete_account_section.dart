import 'package:busin_core/busin_core.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// "Delete my account" on a profile screen, the same in the student and ops apps (ADR 0028). Asking opens a sheet that
/// says what is erased, what the school keeps and that it happens in 7 days; once asked, the card says when, with a
/// button to keep the account. The app passes its repository, so tests give a fake.
class DeleteAccountSection extends StatefulWidget {
  const DeleteAccountSection({super.key, required this.repository});

  final AccountDeletionRepository repository;

  @override
  State<DeleteAccountSection> createState() => _DeleteAccountSectionState();
}

class _DeleteAccountSectionState extends State<DeleteAccountSection> {
  ScheduledDeletion? _scheduled;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final mine = await widget.repository.mine();
      if (mounted) setState(() => _scheduled = mine);
    } catch (_) {
      // Unknown for now (offline): the card offers the deletion; asking again tells the truth.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toastError(Object error) {
    final l10n = BusinL10n.of(context);
    final message = switch (error) {
      Conflict(reason: 'last_admin') => l10n.accountDeleteLastAdmin,
      Conflict(reason: 'active_trip') => l10n.accountDeleteActiveTrip,
      Offline() => l10n.offlineTitle,
      _ => l10n.errorGeneric,
    };
    BusinToast.show(context, message, tone: ToastTone.warning);
  }

  Future<void> _ask() async {
    final l10n = BusinL10n.of(context);
    final confirmed = await showBusinSheet<bool>(
      context,
      isScrollControlled: true,
      builder: (sheet) => _ConfirmSheet(l10n: l10n),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.repository.request();
      await _load();
      if (mounted) BusinToast.show(context, l10n.accountDeleteRequested, tone: ToastTone.info);
    } catch (error) {
      if (mounted) _toastError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _keep() async {
    final l10n = BusinL10n.of(context);
    setState(() => _busy = true);
    try {
      await widget.repository.cancel();
      if (mounted) setState(() => _scheduled = null);
      if (mounted) BusinToast.show(context, l10n.accountDeleteCancelled, tone: ToastTone.success);
    } catch (error) {
      if (mounted) _toastError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final text = Theme.of(context).textTheme;
    final p = BusinPalette.of(context);
    final scheduled = _scheduled;
    final date = scheduled == null ? null : MaterialLocalizations.of(context).formatFullDate(scheduled.dueAt.toLocal());

    return BusinCard(
      padding: const EdgeInsets.all(BusinSpace.x5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.accountDeleteTitle, style: text.titleMedium),
          const SizedBox(height: BusinSpace.x2),
          if (_loading)
            const Align(alignment: Alignment.centerLeft, child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
          else if (scheduled != null && date != null) ...[
            Notice(
              tone: StatusTone.warn,
              icon: HugeIcons.strokeRoundedDelete02,
              child: Text(scheduled.byPlatform ? l10n.accountDeleteScheduledByPlatform(date) : l10n.accountDeleteScheduled(date)),
            ),
            const SizedBox(height: BusinSpace.x3),
            BusinButton(
              label: l10n.accountDeleteKeep,
              icon: HugeIcons.strokeRoundedUserCheck01,
              variant: BusinButtonVariant.secondary,
              loading: _busy,
              onPressed: _busy ? null : _keep,
            ),
          ] else ...[
            Text(l10n.accountDeleteBody, style: text.bodyMedium?.copyWith(color: p.muted)),
            const SizedBox(height: BusinSpace.x3),
            BusinButton(
              label: l10n.accountDeleteOpen,
              icon: HugeIcons.strokeRoundedDelete02,
              variant: BusinButtonVariant.danger,
              loading: _busy,
              onPressed: _busy ? null : _ask,
            ),
          ],
        ],
      ),
    );
  }
}

/// What deleting means, before it is asked: erased, kept, the pass, signing in again. Returns true to ask.
class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({required this.l10n});

  final BusinL10n l10n;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = BusinPalette.of(context);
    final erased = [l10n.accountDeleteErased1, l10n.accountDeleteErased2, l10n.accountDeleteErased3, l10n.accountDeleteErased4];
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(BusinSpace.x5, 0, BusinSpace.x5, BusinSpace.x5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.accountDeleteConfirmTitle, style: text.titleLarge),
            const SizedBox(height: BusinSpace.x3),
            Text(l10n.accountDeleteConfirmIntro, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: BusinSpace.x1),
            for (final line in erased)
              Padding(
                padding: const EdgeInsets.only(top: BusinSpace.x1),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(padding: const EdgeInsets.only(top: 2), child: HugeIcon(icon: HugeIcons.strokeRoundedMinusSign, size: 16, color: p.muted)),
                    const SizedBox(width: BusinSpace.x2),
                    Expanded(child: Text(line, style: text.bodyMedium)),
                  ],
                ),
              ),
            const SizedBox(height: BusinSpace.x3),
            Text(l10n.accountDeleteKept, style: text.bodyMedium),
            const SizedBox(height: BusinSpace.x2),
            Text(l10n.accountDeletePass, style: text.bodyMedium),
            const SizedBox(height: BusinSpace.x2),
            Text(l10n.accountDeleteSignInAgain, style: text.bodySmall?.copyWith(color: p.muted)),
            const SizedBox(height: BusinSpace.x5),
            BusinButton(
              label: l10n.accountDeleteConfirm,
              icon: HugeIcons.strokeRoundedDelete02,
              variant: BusinButtonVariant.danger,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: BusinSpace.x2),
            BusinButton(label: l10n.accountDeleteKeep, variant: BusinButtonVariant.ghost, onPressed: () => Navigator.of(context).pop(false)),
          ],
        ),
      ),
    );
  }
}

/// "Delete my account" as a quiet text button, for the screens where an account waits or is blocked (a student waiting
/// for a school, a student account in the staff app, a suspended account): it opens [DeleteAccountSection] in a sheet,
/// so deleting is possible from wherever the person is stuck (ADR 0028).
class DeleteAccountLink extends StatelessWidget {
  const DeleteAccountLink({super.key, required this.repository});

  final AccountDeletionRepository repository;

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    return TextButton(
      onPressed: () => showBusinSheet<void>(
        context,
        isScrollControlled: true,
        builder: (sheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(BusinSpace.x4, 0, BusinSpace.x4, BusinSpace.x4),
            child: DeleteAccountSection(repository: repository),
          ),
        ),
      ),
      child: Text(l10n.accountDeleteOpen),
    );
  }
}
