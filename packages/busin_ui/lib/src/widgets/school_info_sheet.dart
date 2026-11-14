import 'package:busin_core/busin_core.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/busin_l10n.dart';
import '../phone/countries.dart';
import '../tokens/palette.dart';
import '../tokens/shape.dart';
import 'busin_sheet.dart';
import 'busin_toast.dart';
import 'phone_field.dart';
import 'school_logo.dart';

/// Opens a link in the phone's own app (mail, phone, browser). True when something opened it. Replaced in tests.
typedef LinkOpener = Future<bool> Function(Uri uri);

Future<bool> _openExternally(Uri uri) => launchUrl(uri, mode: LaunchMode.externalApplication);

/// Shows what the school's administrators wrote about it (the school profile in the portal): its logo, name, about text,
/// address, email, phone numbers and website. The email, the numbers and the website open in the phone's own apps.
Future<void> showSchoolInfoSheet(BuildContext context, {required School school, required String supabaseUrl, LinkOpener? open}) {
  return showBusinSheet<void>(
    context,
    isScrollControlled: true,
    builder: (_) => SchoolInfoSheet(school: school, supabaseUrl: supabaseUrl, open: open ?? _openExternally),
  );
}

/// The body of [showSchoolInfoSheet].
class SchoolInfoSheet extends StatelessWidget {
  const SchoolInfoSheet({super.key, required this.school, required this.supabaseUrl, this.open = _openExternally});

  final School school;
  final String supabaseUrl;
  final LinkOpener open;

  /// The address on one line: street, city and country (in the app's language), the parts the school gave.
  static String? addressLine(School school, String language) {
    final code = phoneCountryCodeOf(school.country);
    String? country = school.country;
    if (code != null) {
      for (final c in phoneCountries) {
        if (c.code == code) country = c.name(language);
      }
    }
    final parts = [school.address, school.city, country].whereType<String>().map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final language = Localizations.localeOf(context).languageCode;
    final address = addressLine(school, language);
    final about = school.about?.trim();
    final website = school.website?.trim();

    Future<void> go(Uri uri) async {
      final opened = await open(uri).catchError((Object _) => false);
      if (!opened && context.mounted) BusinToast.show(context, l10n.schoolLinkFailed, tone: ToastTone.warning);
    }

    final rows = <Widget>[
      if (address != null) _InfoRow(icon: HugeIcons.strokeRoundedLocation01, label: l10n.schoolAddress, value: address),
      if (school.contactEmail != null)
        _InfoRow(icon: HugeIcons.strokeRoundedMail01, label: l10n.schoolEmail, value: school.contactEmail!, onTap: () => go(Uri(scheme: 'mailto', path: school.contactEmail))),
      if (school.phone != null)
        _InfoRow(icon: HugeIcons.strokeRoundedCall02, label: l10n.schoolPhone, value: PhoneNumbers.display(school.phone!), onTap: () => go(Uri(scheme: 'tel', path: school.phone))),
      if (school.phoneSecondary != null)
        _InfoRow(
          icon: HugeIcons.strokeRoundedCall02,
          label: l10n.schoolPhoneSecondary,
          value: PhoneNumbers.display(school.phoneSecondary!),
          onTap: () => go(Uri(scheme: 'tel', path: school.phoneSecondary)),
        ),
      if (website != null && website.isNotEmpty)
        _InfoRow(icon: HugeIcons.strokeRoundedGlobe02, label: l10n.schoolWebsite, value: website.replaceFirst(RegExp(r'^https?://'), ''), onTap: () => go(Uri.parse(website))),
    ];

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(BusinSpace.x5, 0, BusinSpace.x5, BusinSpace.x5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: SchoolLogo(url: school.logoUrl(supabaseUrl), size: 72)),
              const SizedBox(height: BusinSpace.x3),
              Text(school.name, style: text.titleLarge, textAlign: TextAlign.center),
              if (school.shortName != null && school.shortName != school.name) ...[
                const SizedBox(height: BusinSpace.x1),
                Text(school.shortName!, style: text.bodyMedium?.copyWith(color: p.muted), textAlign: TextAlign.center),
              ],
              if (about != null && about.isNotEmpty) ...[
                const SizedBox(height: BusinSpace.x4),
                Text(about, style: text.bodyMedium, textAlign: TextAlign.center),
              ],
              const SizedBox(height: BusinSpace.x4),
              if (rows.isEmpty)
                Text(l10n.schoolNoDetails, style: text.bodyMedium?.copyWith(color: p.muted), textAlign: TextAlign.center)
              else
                ...rows,
            ],
          ),
        ),
      ),
    );
  }
}

/// One detail: an icon, what it is, and its value. With [onTap] it opens in another app, which the arrow says.
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value, this.onTap});

  final List<List<dynamic>> icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: BusinSpace.x2, vertical: BusinSpace.x3),
      child: Row(
        children: [
          HugeIcon(icon: icon, size: 22, color: p.muted),
          const SizedBox(width: BusinSpace.x4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: text.labelMedium?.copyWith(color: p.muted)),
                const SizedBox(height: 2),
                Text(value, style: text.bodyLarge?.copyWith(color: onTap == null ? null : p.link, fontWeight: onTap == null ? null : FontWeight.w600)),
              ],
            ),
          ),
          if (onTap != null) HugeIcon(icon: HugeIcons.strokeRoundedLinkSquare02, size: 18, color: p.muted),
        ],
      ),
    );
    if (onTap == null) return Semantics(container: true, child: row);
    return Semantics(
      button: true,
      link: true,
      child: InkWell(borderRadius: BorderRadius.circular(BusinRadius.sm), onTap: onTap, child: row),
    );
  }
}
