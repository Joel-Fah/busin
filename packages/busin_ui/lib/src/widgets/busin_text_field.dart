import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../tokens/palette.dart';
import '../tokens/shape.dart';

/// A text field with its label above and a leading icon, as every field in BusIn has. A [hint]
/// (placeholder) is always given, because a search or entry field with nothing in it says nothing.
class BusinTextField extends StatelessWidget {
  const BusinTextField({
    super.key,
    required this.label,
    required this.icon,
    required this.hint,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.errorText,
    this.helperText,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.maxLines = 1,
    this.enabled = true,
  });

  final String label;
  final List<List<dynamic>> icon;
  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? errorText;
  final String? helperText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final int maxLines;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final p = BusinPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: BusinSpace.x2),
        TextField(
          controller: controller,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          maxLines: maxLines,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            helperText: helperText,
            errorText: errorText,
            semanticCounterText: null,
            prefixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: BusinSpace.x3),
              child: HugeIcon(icon: icon, size: 20, color: p.muted),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
        ),
      ],
    );
  }
}
