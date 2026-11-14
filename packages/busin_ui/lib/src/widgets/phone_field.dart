import 'package:busin_core/busin_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hugeicons/hugeicons.dart';

import '../l10n/busin_l10n.dart';
import '../phone/countries.dart';
import '../tokens/palette.dart';
import '../tokens/shape.dart';
import 'busin_sheet.dart';

/// A country's flag, from the same SVG files as the web (never an emoji).
class CountryFlag extends StatelessWidget {
  const CountryFlag(this.code, {super.key, this.width = 24});

  final String code;
  final double width;

  @override
  Widget build(BuildContext context) {
    final p = BusinPalette.of(context);
    return Container(
      width: width,
      height: width * 2 / 3,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), border: Border.all(color: p.line, width: 0.5)),
      clipBehavior: Clip.antiAlias,
      child: SvgPicture.asset('packages/busin_ui/assets/flags/$code.svg', fit: BoxFit.cover, excludeFromSemantics: true),
    );
  }
}

PhoneCountry? _countryOf(String code) {
  for (final c in phoneCountries) {
    if (c.code == code) return c;
  }
  return null;
}

/// Formats the digits for the country as they are typed, and takes a pasted full number (with `+`) apart: its country
/// is told to [onCountry], and only its national part stays in the field.
class _PhoneFormatter extends TextInputFormatter {
  _PhoneFormatter(this.country, this.onCountry);

  final String Function() country;
  final void Function(String code) onCountry;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var code = country();
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final full = PhoneNumbers.splitInternational(newValue.text);
    if (newValue.text.trim().startsWith('+') && full != null) {
      code = full.country;
      digits = full.national;
      onCountry(code);
    }
    final text = digits.startsWith('0') ? digits : PhoneNumbers.formatTyping(digits, code);
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

/// A phone number with its country, on one row (ADR 0024): the flag and the dialling code open a searchable list of
/// countries (names in the app's language), and the number is written the country's way as it is typed. A number pasted
/// with `+` picks its country. The stored form, E.164, is worked out from [controller]'s text and the country with
/// [PhoneNumbers.parse].
class BusinPhoneField extends StatefulWidget {
  const BusinPhoneField({
    super.key,
    required this.label,
    required this.controller,
    required this.country,
    required this.onCountryChanged,
    this.hint,
    this.errorText,
    this.helperText,
    this.onChanged,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;

  /// The chosen country, two letters (`CM`).
  final String country;
  final ValueChanged<String> onCountryChanged;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  @override
  State<BusinPhoneField> createState() => _BusinPhoneFieldState();
}

class _BusinPhoneFieldState extends State<BusinPhoneField> {
  late String _country = widget.country;
  late final _formatter = _PhoneFormatter(() => _country, _setCountry);

  @override
  void didUpdateWidget(BusinPhoneField old) {
    super.didUpdateWidget(old);
    if (widget.country != old.country) _country = widget.country;
  }

  void _setCountry(String code) {
    if (code == _country) return;
    // At once (the formatter runs on a text input event, not during a build), so a save right after a paste reads the
    // number for its own country.
    setState(() => _country = code);
    widget.onCountryChanged(code);
  }

  Future<void> _pick() async {
    final code = await showBusinSheet<String>(context, isScrollControlled: true, builder: (_) => _CountrySheet(selected: _country));
    if (code == null || !mounted) return;
    setState(() => _country = code);
    widget.onCountryChanged(code);
    // The digits already typed are written the new country's way.
    final digits = widget.controller.text.replaceAll(RegExp(r'[^0-9]'), '');
    final text = digits.startsWith('0') ? digits : PhoneNumbers.formatTyping(digits, code);
    widget.controller.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
    widget.onChanged?.call(text);
  }

  @override
  Widget build(BuildContext context) {
    final p = BusinPalette.of(context);
    final l10n = BusinL10n.of(context);
    final text = Theme.of(context).textTheme;
    final current = _countryOf(_country);
    final language = Localizations.localeOf(context).languageCode;
    final border = widget.errorText != null ? p.bad : p.line;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: text.labelLarge),
        const SizedBox(height: BusinSpace.x2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              button: true,
              label: '${l10n.phoneCountry}: ${current?.name(language) ?? _country}',
              excludeSemantics: true,
              child: Material(
                color: p.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BusinRadius.sm), side: BorderSide(color: border)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(BusinRadius.sm),
                  onTap: widget.enabled ? _pick : null,
                  child: SizedBox(
                    height: 56,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: BusinSpace.x3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CountryFlag(_country),
                          const SizedBox(width: BusinSpace.x2),
                          Text('+${current?.dial ?? ''}', style: text.bodyLarge),
                          const SizedBox(width: BusinSpace.x1),
                          HugeIcon(icon: HugeIcons.strokeRoundedArrowDown01, size: 16, color: p.muted),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: BusinSpace.x2),
            Expanded(
              child: TextField(
                controller: widget.controller,
                onChanged: widget.onChanged,
                enabled: widget.enabled,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumberNational],
                inputFormatters: [_formatter],
                decoration: InputDecoration(hintText: widget.hint, errorText: widget.errorText, helperText: widget.helperText, helperMaxLines: 3, errorMaxLines: 3),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The list of countries with a search box: by name in either language, two-letter code or dialling code.
class _CountrySheet extends StatefulWidget {
  const _CountrySheet({required this.selected});

  final String selected;

  @override
  State<_CountrySheet> createState() => _CountrySheetState();
}

class _CountrySheetState extends State<_CountrySheet> {
  String _query = '';

  static String _plain(String text) {
    const from = 'àáâãäåçèéêëìíîïñòóôõöùúûüýÿ';
    const to = 'aaaaaaceeeeiiiinooooouuuuyy';
    final lower = text.toLowerCase();
    final out = StringBuffer();
    for (final rune in lower.runes) {
      final ch = String.fromCharCode(rune);
      final i = from.indexOf(ch);
      out.write(i >= 0 ? to[i] : ch);
    }
    return out.toString();
  }

  @override
  Widget build(BuildContext context) {
    final p = BusinPalette.of(context);
    final l10n = BusinL10n.of(context);
    final text = Theme.of(context).textTheme;
    final language = Localizations.localeOf(context).languageCode;
    final q = _plain(_query.trim()).replaceFirst('+', '');
    final shown = q.isEmpty
        ? phoneCountries
        : [
            for (final c in phoneCountries)
              if (_plain(c.en).contains(q) || _plain(c.fr).contains(q) || c.code.toLowerCase() == q || c.dial.startsWith(q)) c,
          ];

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.7,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(BusinSpace.x4, 0, BusinSpace.x4, BusinSpace.x3),
                child: TextField(
                  autofocus: true,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: l10n.phoneSearch,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: BusinSpace.x3),
                      child: HugeIcon(icon: HugeIcons.strokeRoundedSearch01, size: 20, color: p.muted),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  ),
                ),
              ),
              Expanded(
                child: shown.isEmpty
                    ? Center(child: Text(l10n.phoneNoMatch, style: TextStyle(color: p.muted)))
                    : ListView.builder(
                        itemCount: shown.length,
                        itemBuilder: (context, index) {
                          final c = shown[index];
                          final selected = c.code == widget.selected;
                          return ListTile(
                            leading: CountryFlag(c.code),
                            title: Text(c.name(language), style: text.bodyLarge?.copyWith(fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('+${c.dial}', style: text.bodyMedium?.copyWith(color: p.muted)),
                                if (selected) ...[
                                  const SizedBox(width: BusinSpace.x2),
                                  HugeIcon(icon: HugeIcons.strokeRoundedTick02, size: 18, color: p.ok),
                                ],
                              ],
                            ),
                            selected: selected,
                            onTap: () => Navigator.of(context).pop(c.code),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
